import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Widgets
import 'package:pingy/widgets/CustomAppBar.dart';

// Models
import 'package:pingy/models/hive/activity.dart';
import 'package:pingy/models/hive/rewards.dart';

// Services
import 'package:pingy/services/activity.dart';

// Utils
import 'package:pingy/utils/navigators.dart';

class GoalStatusScreen extends StatefulWidget {
  final String? goalId;

  const GoalStatusScreen({Key? key, this.goalId}) : super(key: key);

  @override
  _GoalStatusScreenState createState() => _GoalStatusScreenState();
}

class _GoalStatusScreenState extends State<GoalStatusScreen> {
  late final Box _rewardBox;
  late final Box _activityBox;
  late final Box _activityTypeBox;

  RewardsModel? activeGoal;
  int totalScore = 0;
  int daysCompleted = 0;
  int totalDays = 0;
  int daysRemaining = 0;
  double averageScore = 0.0;
  String projectedPrize = '';
  bool isGoalEnded = false;
  bool isGoalStarted = false;
  List<DailyProgress> dailyProgress = [];
  Map<String, ActivityTypeStats> activityStats = {};

  // ─── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    try {
      _rewardBox = Hive.box('rewards');
      _activityBox = Hive.box('activity');
      _activityTypeBox = Hive.box('activity_type');
    } catch (e) {
      // Boxes not open — should never happen given main.dart, but be safe.
      debugPrint('[GoalStatusScreen] Hive box not open: $e');
      return;
    }

    activeGoal = _resolveGoal();
    if (activeGoal == null) return;

    _calculateStats();
    _analyzeActivities();
  }

  // ─── Goal resolution ────────────────────────────────────────────────────────

  /// Returns the goal to display, in priority order:
  ///   1. Goal matching widget.goalId (when navigated from list)
  ///   2. Currently active goal (today falls within start–end)
  ///   3. Most recently ended goal
  /// Returns null only when the box is empty.
  RewardsModel? _resolveGoal() {
    if (_rewardBox.isEmpty) return null;

    // Safe cast — whereType skips anything that isn't a RewardsModel instead
    // of throwing. This is the correct approach when Hive boxes are untyped.
    final all = _rewardBox.values.whereType<RewardsModel>().toList();
    if (all.isEmpty) return null;

    // 1. Explicit goalId lookup (from GoalListScreen tap)
    if (widget.goalId != null && widget.goalId!.isNotEmpty) {
      final match = all.firstWhere(
        (g) => g.rewardId == widget.goalId,
        orElse: () => all.last, // fallback: show most recent rather than crash
      );
      return match;
    }

    // 2. Currently active goal
    final today = _today();
    for (final goal in all) {
      try {
        final start = _parseDate(goal.startPeriod);
        final end = _parseDate(goal.endPeriod);
        if (!today.isBefore(start) && !today.isAfter(end)) return goal;
      } catch (_) {
        continue;
      }
    }

    // 3. Most recently ended goal
    return all.last;
  }

  // ─── Stats ──────────────────────────────────────────────────────────────────

  void _calculateStats() {
    if (activeGoal == null) return;

    try {
      final start = _parseDate(activeGoal!.startPeriod);
      final end = _parseDate(activeGoal!.endPeriod);
      final today = _today();

      isGoalStarted = !today.isBefore(start);
      isGoalEnded = today.isAfter(end);

      totalDays = end.difference(start).inDays + 1;

      if (!isGoalStarted) {
        daysCompleted = 0;
        daysRemaining = totalDays;
      } else if (isGoalEnded) {
        daysCompleted = totalDays;
        daysRemaining = 0;
      } else {
        daysCompleted = (today.difference(start).inDays + 1).clamp(0, totalDays);
        daysRemaining = end.difference(today).inDays.clamp(0, totalDays);
      }

      // Activities for this goal only
      final activities = _activityBox.values
          .whereType<Activity>()
          .where((a) => a.goalId == activeGoal!.rewardId)
          .toList();

      dailyProgress.clear();
      int cumulative = 0;

      for (final activity in activities) {
        final dayScore = _calculateDayScore(activity);
        cumulative += dayScore;
        dailyProgress.add(DailyProgress(
          date: activity.activityDate ?? DateTime.now(),
          score: dayScore,
          cumulativeScore: cumulative,
        ));
      }

      totalScore = cumulative;
      averageScore =
          activities.isNotEmpty ? totalScore / activities.length : 0.0;

      // Projected prize
      if (daysRemaining > 0 && averageScore > 0) {
        final projected =
            totalScore + (averageScore * daysRemaining).round();
        projectedPrize = _getPrizeForScore(projected);
      } else {
        projectedPrize = _getPrizeForScore(totalScore);
      }
    } catch (e, st) {
      debugPrint('[GoalStatusScreen] _calculateStats error: $e\n$st');
    }
  }

  int _calculateDayScore(Activity activity) {
    try {
      final maxScore = getActivitiesTotalMaximumScore();
      if (maxScore == 0) return 0;

      int score = 0;
      for (final item in activity.activityItems) {
        score += int.tryParse(item.score ?? '0') ?? 0;
      }
      return ((score / maxScore) * 100).round();
    } catch (e) {
      return 0;
    }
  }

  String _getPrizeForScore(int score) {
    if (activeGoal == null) return 'No Goal';
    final avg = totalDays > 0 ? (score / totalDays).round() : 0;
    if (avg >= 90) return activeGoal!.firstPrice;
    if (avg >= 70) return activeGoal!.secondPrice;
    if (avg >= 50) return activeGoal!.thirdPrice;
    return 'Keep trying!';
  }

  void _analyzeActivities() {
    if (activeGoal == null) return;

    try {
      activityStats.clear();

      final activities = _activityBox.values
          .whereType<Activity>()
          .where((a) => a.goalId == activeGoal!.rewardId)
          .toList();

      for (final typeKey in _activityTypeBox.keys) {
        final activityType = _activityTypeBox.get(typeKey);
        if (activityType == null) continue;

        int totalPoints = 0;
        int daysTracked = 0;
        final maxPossible =
            int.tryParse(activityType.fullScore ?? '0') ?? 0;

        for (final activity in activities) {
          for (final item in activity.activityItems) {
            if (item.activityItemId == typeKey) {
              final points = int.tryParse(item.score ?? '0') ?? 0;
              if (points > 0) {
                totalPoints += points;
                daysTracked++;
              }
            }
          }
        }

        final avgScore =
            daysTracked > 0 ? totalPoints / daysTracked : 0.0;
        final percentage =
            maxPossible > 0 ? (avgScore / maxPossible) * 100 : 0.0;

        activityStats[typeKey.toString()] = ActivityTypeStats(
          name: activityType.activityName ?? 'Unknown',
          averageScore: avgScore,
          percentage: percentage,
          daysTracked: daysTracked,
          maxPossible: maxPossible,
        );
      }
    } catch (e, st) {
      debugPrint('[GoalStatusScreen] _analyzeActivities error: $e\n$st');
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  /// Normalised today (no time component).
  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Parses dd/MM/yyyy. Throws FormatException on bad input.
  DateTime _parseDate(String date) {
    final parts = date.split('/');
    if (parts.length != 3) {
      throw FormatException('Expected dd/MM/yyyy, got: $date');
    }
    return DateTime(
      int.parse(parts[2]), // year
      int.parse(parts[1]), // month
      int.parse(parts[0]), // day
    );
  }

  Color _statusColor(double pct) {
    if (pct >= 80) return Colors.green;
    if (pct >= 60) return Colors.blue;
    if (pct >= 40) return Colors.orange;
    return Colors.red;
  }

  String _statusText(double pct) {
    if (pct >= 80) return 'Excellent! Keep it up!';
    if (pct >= 60) return 'Good progress!';
    if (pct >= 40) return 'Needs attention';
    return 'Critical - Focus here!';
  }

  IconData _statusIcon(double pct) {
    if (pct >= 80) return Icons.check_circle;
    if (pct >= 60) return Icons.trending_up;
    if (pct >= 40) return Icons.warning;
    return Icons.error;
  }

  // ─── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildOverviewCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activeGoal?.title ?? 'No Active Goal',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${activeGoal?.startPeriod} to ${activeGoal?.endPeriod}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const Divider(height: 24),
            _statRow('Days Completed', '$daysCompleted / $totalDays'),
            _statRow('Days Remaining', '$daysRemaining'),
            _statRow('Average Score', '${averageScore.toStringAsFixed(1)}%'),
            _statRow('Total Score', '$totalScore'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.green[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Projected Prize',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          projectedPrize,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActivityAnalysis() {
    if (activityStats.isEmpty) return const SizedBox.shrink();

    final sorted = activityStats.entries.toList()
      ..sort((a, b) => b.value.percentage.compareTo(a.value.percentage));

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Activity Breakdown',
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...sorted.map((e) => _buildActivityBar(e.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityBar(ActivityTypeStats stats) {
    final color = _statusColor(stats.percentage);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(stats.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              Text(
                '${stats.percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              // clamp: percentage can exceed 100 if data is dirty
              value: (stats.percentage / 100).clamp(0.0, 1.0),
              minHeight: 20,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(_statusIcon(stats.percentage), size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                _statusText(stats.percentage),
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Text(
                'Avg: ${stats.averageScore.toStringAsFixed(1)}/${stats.maxPossible}',
                style:
                    TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsights() {
    if (activityStats.isEmpty) return const SizedBox.shrink();

    final sorted = activityStats.entries.toList()
      ..sort((a, b) => b.value.percentage.compareTo(a.value.percentage));

    final excellent = sorted
        .where((e) => e.value.percentage >= 80)
        .map((e) => e.value.name)
        .toList();
    final needsAttention = sorted
        .where(
            (e) => e.value.percentage >= 40 && e.value.percentage < 80)
        .map((e) => e.value.name)
        .toList();
    final critical = sorted
        .where((e) => e.value.percentage < 40)
        .map((e) => e.value.name)
        .toList();

    String motivation;
    if (averageScore >= 80) {
      motivation = '🎉 Outstanding! You\'re on track for your top prize!';
    } else if (averageScore >= 60) {
      motivation = '💪 Great effort! A little more push to reach excellence!';
    } else if (averageScore >= 40) {
      motivation =
          '🎯 You can do this! Focus on consistency and you\'ll improve!';
    } else {
      motivation =
          '🌱 Every journey starts somewhere. Small steps lead to big changes!';
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Insights & Recommendations',
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (excellent.isNotEmpty)
              _insightSection('🌟 Excellent Progress', excellent,
                  Colors.green,
                  'You\'re doing amazing in these areas! Keep it up!'),
            if (needsAttention.isNotEmpty)
              _insightSection('⚠️ Needs Attention', needsAttention,
                  Colors.orange,
                  'These areas could use more focus. Try to improve consistency.'),
            if (critical.isNotEmpty)
              _insightSection('🚨 Critical Areas', critical, Colors.red,
                  'Priority focus needed here! Small improvements make a big difference.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [Colors.blue[300]!, Colors.purple[300]!]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(motivation,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _insightSection(
      String title, List<String> names, Color color, String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 8),
          ...names.map((name) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 6, color: color),
                    const SizedBox(width: 8),
                    Text(name,
                        style: const TextStyle(fontSize: 14)),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          Text(message,
              style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700])),
        ],
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        goToGoalsListScreen(context);
      },
      child: Scaffold(
        appBar: customAppBar(
          title: 'Goal Status',
          actions: const [],
          leading: IconButton(
            onPressed: () => goToGoalsListScreen(context),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: activeGoal == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.flag_outlined,
                        size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No goal found',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700]),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async => setState(_loadData),
                child: ListView(
                  children: [
                    _buildOverviewCard(),
                    _buildActivityAnalysis(),
                    _buildInsights(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}

// ─── Data classes ────────────────────────────────────────────────────────────

class DailyProgress {
  final DateTime date;
  final int score;
  final int cumulativeScore;

  const DailyProgress({
    required this.date,
    required this.score,
    required this.cumulativeScore,
  });
}

class ActivityTypeStats {
  final String name;
  final double averageScore;
  final double percentage;
  final int daysTracked;
  final int maxPossible;

  const ActivityTypeStats({
    required this.name,
    required this.averageScore,
    required this.percentage,
    required this.daysTracked,
    required this.maxPossible,
  });
}