import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pingy/models/hive/rewards.dart';
import 'package:pingy/utils/navigators.dart';

import 'package:pingy/widgets/icons/settings.dart';
import 'package:pingy/widgets/SettingsBottomNavigation.dart';
import 'package:pingy/widgets/CustomAppBar.dart';

class GoalListScreen extends StatefulWidget {
  @override
  _GoalListScreenState createState() => _GoalListScreenState();
}

class _GoalListScreenState extends State<GoalListScreen> {
  late final Box rewardsBox;

  @override
  void initState() {
    super.initState();
    // Get reference to an already opened box
    rewardsBox = Hive.box('rewards');
  }

  Widget getFloatingButton(BuildContext context) {
    if (rewardsBox.isEmpty) {
      return FloatingActionButton(
        onPressed: () {
          goToGoalsForm(context);
        },
        backgroundColor: Colors.lightGreen,
        child: const Icon(Icons.add),
      );
    } else if (rewardsBox.isNotEmpty) {
      RewardsModel latestGoal = rewardsBox.values.last;
      List endPeriod = latestGoal.endPeriod.split('/').toList();

      DateTime today = DateTime.now();
      DateTime endDate =
          DateTime.parse('${endPeriod[2]}-${endPeriod[1]}-${endPeriod[0]}');
      Duration diff = endDate.difference(today);

      if (diff.inDays > 0) {
        return Container();
      }
    }

    return FloatingActionButton(
      onPressed: () {
        goToGoalsForm(context);
      },
      backgroundColor: Colors.lightGreen,
      child: const Icon(Icons.add),
    );
  }

  String getPrize(String? prize) {
    if (prize == null || prize.isEmpty) return 'Not set';
    return prize;
  }

  String getGoalResult(RewardsModel rewardDetails) {
    if (rewardDetails.won != null && rewardDetails.won!.isNotEmpty) {
      return rewardDetails.won!;
    }
    return '';
  }

  bool hasImage(RewardsModel rewardDetails) {
    return rewardDetails.rewardPicture != null && 
           rewardDetails.rewardPicture!.isNotEmpty;
  }

  bool isGoalActive(RewardsModel goal) {
    try {
      final today = DateTime.now();
      final normalizedToday = DateTime(today.year, today.month, today.day);

      final start = _parseDate(goal.startPeriod);
      final end = _parseDate(goal.endPeriod);

      return !normalizedToday.isBefore(start) && !normalizedToday.isAfter(end);
    } catch (e) {
      return false;
    }
  }

  bool isGoalEnded(RewardsModel goal) {
    try {
      final today = DateTime.now();
      final normalizedToday = DateTime(today.year, today.month, today.day);
      final end = _parseDate(goal.endPeriod);
      return normalizedToday.isAfter(end);
    } catch (e) {
      return false;
    }
  }

  DateTime _parseDate(String date) {
    final parts = date.split('/');
    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);
    return DateTime(year, month, day);
  }

  String getGoalStatusText(RewardsModel goal) {
    if (isGoalActive(goal)) {
      return 'Active';
    } else if (isGoalEnded(goal)) {
      return 'Completed';
    } else {
      return 'Upcoming';
    }
  }

  IconData getGoalStatusIcon(RewardsModel goal) {
    if (isGoalActive(goal)) {
      return Icons.timer;
    } else if (isGoalEnded(goal)) {
      return Icons.check_circle;
    } else {
      return Icons.schedule;
    }
  }

  Color getGoalStatusColor(RewardsModel goal) {
    if (isGoalActive(goal)) {
      return Colors.green;
    } else if (isGoalEnded(goal)) {
      return Colors.blue;
    } else {
      return Colors.orange;
    }
  }

  int _getRemainingDays(RewardsModel goal) {
    try {
      final today = DateTime.now();
      final normalizedToday = DateTime(today.year, today.month, today.day);
      final end = _parseDate(goal.endPeriod);
      return end.difference(normalizedToday).inDays;
    } catch (e) {
      return 0;
    }
  }

  String _getProgressText(RewardsModel goal) {
    if (isGoalEnded(goal)) {
      final result = getGoalResult(goal);
      if (result.isNotEmpty) {
        return result;
      }
      return 'Goal ended';
    }
    
    if (isGoalActive(goal)) {
      final remaining = _getRemainingDays(goal);
      if (remaining == 0) {
        return 'Last day!';
      } else if (remaining == 1) {
        return '1 day left';
      } else {
        return '$remaining days left';
      }
    }
    
    // Upcoming
    final start = _parseDate(goal.startPeriod);
    final today = DateTime.now();
    final daysUntilStart = start.difference(DateTime(today.year, today.month, today.day)).inDays;
    
    if (daysUntilStart == 0) {
      return 'Starts today';
    } else if (daysUntilStart == 1) {
      return 'Starts tomorrow';
    } else {
      return 'Starts in $daysUntilStart days';
    }
  }

  Widget _buildGoalImage(RewardsModel goal, Color statusColor) {
    if (!hasImage(goal)) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          getGoalStatusIcon(goal),
          color: statusColor,
          size: 28,
        ),
      );
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: Image.network(
          goal.rewardPicture!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: statusColor.withOpacity(0.15),
              child: Icon(
                getGoalStatusIcon(goal),
                color: statusColor,
                size: 28,
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[100],
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: customAppBar(
          title: 'Goals',
          actions: [
            settingsLinkIconButton(context),
          ],
        ),
        body: ValueListenableBuilder(
          valueListenable: rewardsBox.listenable(),
          builder: (context, Box box, widget) {
            if (box.isEmpty) {
              return Center(
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
                      'No goals yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first goal to get started',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return ListView.builder(
                itemCount: rewardsBox.length,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                physics: const AlwaysScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  var currentBox = rewardsBox;
                  RewardsModel rewardsData = currentBox.getAt(index)!;
                  String statusText = getGoalStatusText(rewardsData);
                  Color statusColor = getGoalStatusColor(rewardsData);
                  String progressText = _getProgressText(rewardsData);
                  bool hasWon = getGoalResult(rewardsData).isNotEmpty;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        goToGoalStatusScreenWithId(
                          context,
                          rewardsData.rewardId ?? '',
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Goal Image/Icon
                            _buildGoalImage(rewardsData, statusColor),
                            
                            const SizedBox(width: 12),
                            
                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title and Status
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          rewardsData.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: statusColor.withOpacity(0.4),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          statusText,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 6),
                                  
                                  // Date Range
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 13,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${rewardsData.startPeriod} - ${rewardsData.endPeriod}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 4),
                                  
                                  // Progress/Result
                                  Row(
                                    children: [
                                      Icon(
                                        hasWon 
                                          ? Icons.emoji_events 
                                          : (isGoalActive(rewardsData) 
                                              ? Icons.trending_up 
                                              : Icons.schedule),
                                        size: 13,
                                        color: hasWon 
                                          ? Colors.amber[700]
                                          : Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          progressText,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: hasWon 
                                              ? Colors.amber[800]
                                              : Colors.grey[600],
                                            fontWeight: hasWon 
                                              ? FontWeight.w600 
                                              : FontWeight.normal,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 6),
                                  
                                  // Prizes
                                  Row(
                                    children: [
                                      if (rewardsData.firstPrice.isNotEmpty) ...[
                                        const Text(
                                          '🥇',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(width: 2),
                                        Flexible(
                                          child: Text(
                                            getPrize(rewardsData.firstPrice),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[700],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                      if (rewardsData.firstPrice.isNotEmpty && 
                                          rewardsData.secondPrice.isNotEmpty) ...[
                                        Text(
                                          ' • ',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ],
                                      if (rewardsData.secondPrice.isNotEmpty) ...[
                                        const Text(
                                          '🥈',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(width: 2),
                                        Flexible(
                                          child: Text(
                                            getPrize(rewardsData.secondPrice),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[700],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // Arrow
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey[400],
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
        floatingActionButton: getFloatingButton(context),
        bottomNavigationBar: settingsBottomNavigationBar(context),
      ),
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        // If the system already handled the pop, do nothing
        if (didPop) return;
        Navigator.pop(context);
        return;
      },
    );
  }
}