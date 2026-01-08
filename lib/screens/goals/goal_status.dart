import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Widgets
import 'package:pingy/widgets/CustomAppBar.dart';

// Models
import 'package:pingy/models/hive/activity.dart';
import 'package:pingy/models/hive/activity_item.dart';
import 'package:pingy/models/hive/rewards.dart';

// Services
import 'package:pingy/services/goals.dart';
import 'package:pingy/services/activity.dart';

// Utils
import 'package:pingy/utils/navigators.dart';
import 'package:pingy/utils/color.dart';

class GoalStatusScreen extends StatefulWidget {
  final String? goalId;

  const GoalStatusScreen({Key? key, this.goalId}) : super(key: key);

  @override
  _GoalStatusScreenState createState() => _GoalStatusScreenState();
}

class _GoalStatusScreenState extends State<GoalStatusScreen> {
  late Box rewardBox;
  late Box activityBox;
  late Box activityTypeBox;

  RewardsModel? activeGoal;
  int totalScore = 0;
  int daysCompleted = 0;
  int totalDays = 0;
  int daysRemaining = 0;
  double averageScore = 0.0;
  String projectedPrize = '';
  List<DailyProgress> dailyProgress = [];
  Map<String, ActivityTypeStats> activityStats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    rewardBox = Hive.box('rewards');
    activityBox = Hive.box('activity');
    activityTypeBox = Hive.box('activity_type');

    activeGoal = _getActiveGoal();
    if (activeGoal == null) return;

    _calculateStats();
    _analyzeActivities();
  }

  RewardsModel? _getActiveGoal() {
    if (rewardBox.isEmpty) return null;

    // If a specific goalId is provided, return that goal
    if (widget.goalId != null && widget.goalId!.isNotEmpty) {
      for (final goal in rewardBox.values.cast<RewardsModel>()) {
        if (goal.rewardId == widget.goalId) {
          return goal;
        }
      }
    }

    // Otherwise, find the currently active goal
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    for (final goal in rewardBox.values.cast<RewardsModel>()) {
      final start = _parseDate(goal.startPeriod);
      final end = _parseDate(goal.endPeriod);

      if (!normalizedToday.isBefore(start) && !normalizedToday.isAfter(end)) {
        return goal;
      }
    }

    // Return last goal if no active goal
    return rewardBox.values.last as RewardsModel;
  }

  DateTime _parseDate(String date) {
    final parts = date.split('/');
    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);
    return DateTime(year, month, day);
  }

  void _calculateStats() {
    if (activeGoal == null) return;

    final start = _parseDate(activeGoal!.startPeriod);
    final end = _parseDate(activeGoal!.endPeriod);
    final today = DateTime.now();

    totalDays = end.difference(start).inDays + 1;
    daysCompleted = today.difference(start).inDays;
    if (daysCompleted > totalDays) daysCompleted = totalDays;
    daysRemaining = totalDays - daysCompleted;
    if (daysRemaining < 0) daysRemaining = 0;

    // Get activities for this goal
    final activities = activityBox.values
        .cast<Activity>()
        .where((a) => a.goalId == activeGoal!.rewardId)
        .toList();

    // Calculate daily progress
    dailyProgress.clear();
    int cumulativeScore = 0;

    for (var activity in activities) {
      int dayScore = _calculateDayScore(activity);
      cumulativeScore += dayScore;

      dailyProgress.add(DailyProgress(
        date: activity.activityDate ?? DateTime.now(),
        score: dayScore,
        cumulativeScore: cumulativeScore,
      ));
    }

    totalScore = cumulativeScore;
    averageScore = activities.isNotEmpty ? totalScore / activities.length : 0;

    // Project final score
    if (daysRemaining > 0 && averageScore > 0) {
      int projectedTotal = totalScore + (averageScore * daysRemaining).round();
      projectedPrize = _getPrizeForScore(projectedTotal);
    } else {
      projectedPrize = _getPrizeForScore(totalScore);
    }
  }

  int _calculateDayScore(Activity activity) {
    int maxScore = getActivitiesTotalMaximumScore();
    if (maxScore == 0) return 0;

    int score = 0;
    for (var item in activity.activityItems) {
      score += int.tryParse(item.score ?? '0') ?? 0;
    }

    return ((score / maxScore) * 100).round();
  }

  String _getPrizeForScore(int score) {
    if (activeGoal == null) return 'No Goal';

    int avgScore = totalDays > 0 ? (score / totalDays).round() : 0;

    if (avgScore >= 90) return activeGoal!.firstPrice;
    if (avgScore >= 70) return activeGoal!.secondPrice;
    if (avgScore >= 50) return activeGoal!.thirdPrice;
    return 'Keep trying!';
  }

  void _analyzeActivities() {
    if (activeGoal == null) return;

    activityStats.clear();

    final activities = activityBox.values
        .cast<Activity>()
        .where((a) => a.goalId == activeGoal!.rewardId)
        .toList();

    // Analyze each activity type
    for (var typeKey in activityTypeBox.keys) {
      final activityType = activityTypeBox.get(typeKey);
      int totalPoints = 0;
      int daysTracked = 0;
      int maxPossible = int.tryParse(activityType?.fullScore ?? '0') ?? 0;

      for (var activity in activities) {
        for (var item in activity.activityItems) {
          if (item.activityItemId == typeKey) {
            int points = int.tryParse(item.score ?? '0') ?? 0;
            if (points > 0) {
              totalPoints += points;
              daysTracked++;
            }
          }
        }
      }

      double avgScore = daysTracked > 0 ? totalPoints / daysTracked : 0;
      double percentage = maxPossible > 0 ? (avgScore / maxPossible) * 100 : 0;

      activityStats[typeKey] = ActivityTypeStats(
        name: activityType?.activityName ?? 'Unknown',
        averageScore: avgScore,
        percentage: percentage,
        daysTracked: daysTracked,
        maxPossible: maxPossible,
      );
    }
  }

  Color _getStatusColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.blue;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getStatusText(double percentage) {
    if (percentage >= 80) return 'Excellent! Keep it up!';
    if (percentage >= 60) return 'Good progress!';
    if (percentage >= 40) return 'Needs attention';
    return 'Critical - Focus here!';
  }

  IconData _getStatusIcon(double percentage) {
    if (percentage >= 80) return Icons.check_circle;
    if (percentage >= 60) return Icons.trending_up;
    if (percentage >= 40) return Icons.warning;
    return Icons.error;
  }

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
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const Divider(height: 24),
            _buildStatRow('Days Completed', '$daysCompleted / $totalDays'),
            _buildStatRow('Days Remaining', '$daysRemaining'),
            _buildStatRow(
                'Average Score', '${averageScore.toStringAsFixed(1)}%'),
            _buildStatRow('Total Score', '${totalScore.toStringAsFixed(0)}'),
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
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
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

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityAnalysis() {
    List<MapEntry<String, ActivityTypeStats>> sortedStats =
        activityStats.entries.toList()
          ..sort((a, b) => b.value.percentage.compareTo(a.value.percentage));

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity Breakdown',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedStats.map((entry) => _buildActivityBar(entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityBar(ActivityTypeStats stats) {
    Color statusColor = _getStatusColor(stats.percentage);
    String statusText = _getStatusText(stats.percentage);
    IconData statusIcon = _getStatusIcon(stats.percentage);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  stats.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${stats.percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: stats.percentage / 100,
              minHeight: 20,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(statusIcon, size: 16, color: statusColor),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                'Avg: ${stats.averageScore.toStringAsFixed(1)}/${stats.maxPossible}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsights() {
    List<MapEntry<String, ActivityTypeStats>> sortedStats =
        activityStats.entries.toList()
          ..sort((a, b) => b.value.percentage.compareTo(a.value.percentage));

    List<ActivityTypeStats> excellent = sortedStats
        .where((e) => e.value.percentage >= 80)
        .map((e) => e.value)
        .toList();
    List<ActivityTypeStats> needsAttention = sortedStats
        .where((e) => e.value.percentage >= 40 && e.value.percentage < 80)
        .map((e) => e.value)
        .toList();
    List<ActivityTypeStats> critical = sortedStats
        .where((e) => e.value.percentage < 40)
        .map((e) => e.value)
        .toList();

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Insights & Recommendations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (excellent.isNotEmpty)
              _buildInsightSection(
                '🌟 Excellent Progress',
                excellent.map((e) => e.name).toList(),
                Colors.green,
                'You\'re doing amazing in these areas! Keep up the great work!',
              ),
            if (needsAttention.isNotEmpty)
              _buildInsightSection(
                '⚠️ Needs Attention',
                needsAttention.map((e) => e.name).toList(),
                Colors.orange,
                'These areas could use more focus. Try to improve consistency.',
              ),
            if (critical.isNotEmpty)
              _buildInsightSection(
                '🚨 Critical Areas',
                critical.map((e) => e.name).toList(),
                Colors.red,
                'Priority focus needed here! Small improvements will make a big difference.',
              ),
            const SizedBox(height: 16),
            _buildMotivationalMessage(),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightSection(
    String title,
    List<String> activities,
    Color color,
    String message,
  ) {
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
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          ...activities.map((name) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 6, color: color),
                    const SizedBox(width: 8),
                    Text(name, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationalMessage() {
    String message = '';
    if (averageScore >= 80) {
      message = '🎉 Outstanding! You\'re on track for your top prize!';
    } else if (averageScore >= 60) {
      message = '💪 Great effort! A little more push to reach excellence!';
    } else if (averageScore >= 40) {
      message = '🎯 You can do this! Focus on consistency and you\'ll improve!';
    } else {
      message =
          '🌱 Every journey starts somewhere. Small steps lead to big changes!';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[300]!, Colors.purple[300]!],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        // If the system already handled the pop, do nothing
        if (didPop) return;
        goToGoalsListScreen(context);
        return;
      },
      child: Scaffold(
        appBar: customAppBar(
          title: 'Goal Status',
          actions: [],
          leading: IconButton(
            onPressed: () {
              goToGoalsListScreen(context);
            },
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: activeGoal == null
            ? const Center(
                child: Text(
                  'No active goal found',
                  style: TextStyle(fontSize: 18),
                ),
              )
            : ListView(
                children: [
                  _buildOverviewCard(),
                  _buildActivityAnalysis(),
                  _buildInsights(),
                  const SizedBox(height: 20),
                ],
              ),
      ),
    );
  }
}

class DailyProgress {
  final DateTime date;
  final int score;
  final int cumulativeScore;

  DailyProgress({
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

  ActivityTypeStats({
    required this.name,
    required this.averageScore,
    required this.percentage,
    required this.daysTracked,
    required this.maxPossible,
  });
}
