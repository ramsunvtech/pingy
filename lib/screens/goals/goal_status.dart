import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Widgets
import 'package:pingy/widgets/CustomAppBar.dart';

// Models
import 'package:pingy/models/hive/activity.dart';
import 'package:pingy/models/hive/rewards.dart';

// Utils
import 'package:pingy/utils/navigators.dart';

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
  String currentPrize = '';
  String projectedPrize = '';
  bool isGoalEnded = false;
  bool isGoalStarted = false;
  List<DailyProgress> dailyProgress = [];
  Map<String, ActivityTypeStats> activityStats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    try {
      rewardBox = Hive.box('rewards');
      activityBox = Hive.box('activity');
      activityTypeBox = Hive.box('activity_type');

      activeGoal = _getActiveGoal();
      if (activeGoal == null) return;

      _calculateStats();
      _analyzeActivities();
    } catch (e) {
      print('Error loading data: $e');
    }
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
      try {
        final start = _parseDate(goal.startPeriod);
        final end = _parseDate(goal.endPeriod);

        if (!normalizedToday.isBefore(start) && !normalizedToday.isAfter(end)) {
          return goal;
        }
      } catch (e) {
        print('Error parsing dates for goal: $e');
        continue;
      }
    }

    // Return last goal if no active goal
    return rewardBox.values.last as RewardsModel?;
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

    try {
      final start = _parseDate(activeGoal!.startPeriod);
      final end = _parseDate(activeGoal!.endPeriod);
      final today = DateTime.now();
      final normalizedToday = DateTime(today.year, today.month, today.day);

      // Check if goal has started and ended
      isGoalStarted = !normalizedToday.isBefore(start);
      isGoalEnded = normalizedToday.isAfter(end);

      totalDays = end.difference(start).inDays + 1;
      
      if (!isGoalStarted) {
        daysCompleted = 0;
        daysRemaining = totalDays;
      } else if (isGoalEnded) {
        daysCompleted = totalDays;
        daysRemaining = 0;
      } else {
        daysCompleted = normalizedToday.difference(start).inDays + 1;
        daysRemaining = end.difference(normalizedToday).inDays;
        if (daysCompleted > totalDays) daysCompleted = totalDays;
        if (daysRemaining < 0) daysRemaining = 0;
      }

      // Get activities for this goal
      final activities = activityBox.values
          .cast<Activity>()
          .where((a) => a.goalId == activeGoal!.rewardId)
          .toList();

      dailyProgress.clear();
      int totalScoreSum = 0;
      int validDaysCount = 0;

      for (var activity in activities) {
        int dayScore = _calculateDayScore(activity);
        if (dayScore > 0) {
          totalScoreSum += dayScore;
          validDaysCount++;
        }

        dailyProgress.add(DailyProgress(
          date: activity.activityDate ?? DateTime.now(),
          score: dayScore,
          cumulativeScore: totalScoreSum,
        ));
      }

      totalScore = totalScoreSum;
      averageScore = validDaysCount > 0 ? totalScoreSum / validDaysCount : 0;

      // Determine current and projected prize
      if (isGoalEnded) {
        currentPrize = _getPrizeForScore(averageScore.round());
        projectedPrize = '';
      } else if (!isGoalStarted) {
        currentPrize = '';
        projectedPrize = 'Goal starts on ${activeGoal!.startPeriod}';
      } else {
        currentPrize = _getPrizeForScore(averageScore.round());
        
        if (daysRemaining > 0 && averageScore > 0) {
          projectedPrize = _getPrizeForScore(averageScore.round());
        } else {
          projectedPrize = currentPrize;
        }
      }
    } catch (e) {
      print('Error calculating stats: $e');
    }
  }

  int _calculateDayScore(Activity activity) {
    try {
      // Calculate max score from activity type box
      int maxScore = 0;
      activityTypeBox.toMap().forEach((key, value) {
        final scoreStr = value?.fullScore;
        if (scoreStr != null) {
          maxScore += int.tryParse(scoreStr) ?? 0;
        }
      });
      
      if (maxScore == 0) return 0;

      int score = 0;
      for (var item in activity.activityItems) {
        score += int.tryParse(item.score ?? '0') ?? 0;
      }

      return ((score / maxScore) * 100).round();
    } catch (e) {
      print('Error calculating day score: $e');
      return 0;
    }
  }

  String _getPrizeForScore(int avgScore) {
    if (activeGoal == null) return 'No Goal';

    if (avgScore >= 95) return activeGoal!.firstPrice;
    if (avgScore >= 85) return activeGoal!.secondPrice;
    if (avgScore >= 75) return activeGoal!.thirdPrice;
    
    if (!isGoalEnded && avgScore > 0) {
      return 'Below target - Push harder!';
    }
    
    return 'No prize earned';
  }

  IconData _getPrizeIcon(String prize) {
    if (activeGoal == null) return Icons.emoji_events;
    
    if (prize == activeGoal!.firstPrice) {
      return Icons.emoji_events;
    } else if (prize == activeGoal!.secondPrice) {
      return Icons.workspace_premium;
    } else if (prize == activeGoal!.thirdPrice) {
      return Icons.military_tech;
    }
    
    return Icons.flag;
  }

  Color _getPrizeColor(String prize) {
    if (activeGoal == null) return Colors.grey;
    
    if (prize == activeGoal!.firstPrice) {
      return Colors.amber;
    } else if (prize == activeGoal!.secondPrice) {
      return Colors.blueGrey;
    } else if (prize == activeGoal!.thirdPrice) {
      return Colors.brown;
    }
    
    return Colors.grey;
  }

  void _analyzeActivities() {
    if (activeGoal == null) return;

    try {
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
              totalPoints += points;
              if (points >= 0) {
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
    } catch (e) {
      print('Error analyzing activities: $e');
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
    String statusMessage = '';
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.info;

    if (!isGoalStarted) {
      statusMessage = 'Goal hasn\'t started yet';
      statusColor = Colors.blue;
      statusIcon = Icons.schedule;
    } else if (isGoalEnded) {
      statusMessage = 'Goal Completed';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else {
      statusMessage = 'Goal In Progress';
      statusColor = Colors.orange;
      statusIcon = Icons.trending_up;
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    activeGoal?.title ?? 'No Active Goal',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusMessage,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
            _buildStatRow('Average Score', '${averageScore.toStringAsFixed(1)}%'),
            _buildStatRow('Cumulative Score', '${totalScore.toStringAsFixed(0)}'),
            
            const SizedBox(height: 16),
            
            if (isGoalEnded)
              _buildFinalPrizeSection()
            else if (isGoalStarted)
              _buildProjectedPrizeSection()
            else
              _buildNotStartedSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalPrizeSection() {
    Color prizeColor = _getPrizeColor(currentPrize);
    IconData prizeIcon = _getPrizeIcon(currentPrize);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: prizeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: prizeColor, width: 2),
      ),
      child: Row(
        children: [
          Icon(prizeIcon, color: prizeColor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🎉 Final Prize Earned',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  currentPrize,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: prizeColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectedPrizeSection() {
    Color currentPrizeColor = _getPrizeColor(currentPrize);
    IconData currentPrizeIcon = _getPrizeIcon(currentPrize);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: currentPrizeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: currentPrizeColor),
          ),
          child: Row(
            children: [
              Icon(currentPrizeIcon, color: currentPrizeColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Standing',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      currentPrize,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: currentPrizeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.trending_up, color: Colors.blue[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  projectedPrize == currentPrize
                      ? 'Maintain this pace to earn: $projectedPrize!'
                      : 'On track for: $projectedPrize',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotStartedSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Goal Not Started',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Starts on ${activeGoal?.startPeriod}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
        ],
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
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityAnalysis() {
    if (activityStats.isEmpty) {
      return const SizedBox.shrink();
    }

    List<MapEntry<String, ActivityTypeStats>> sortedStats =
        activityStats.entries.toList()
          ..sort((a, b) => b.value.percentage.compareTo(a.value.percentage));

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity Breakdown',
              style: TextStyle(
                fontSize: 18,
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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${stats.percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 15,
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
              minHeight: 18,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(statusIcon, size: 14, color: statusColor),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 11,
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                'Avg: ${stats.averageScore.toStringAsFixed(1)}/${stats.maxPossible} • ${stats.daysTracked} days',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
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
        if (didPop) return;
        goToGoalsListScreen(context);
        return;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
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
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No goal found',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _loadData();
                  });
                },
                child: ListView(
                  children: [
                    _buildOverviewCard(),
                    _buildActivityAnalysis(),
                    const SizedBox(height: 20),
                  ],
                ),
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