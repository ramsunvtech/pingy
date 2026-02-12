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
    rewardsBox = Hive.box('rewards');
  }

  Widget getFloatingButton(BuildContext context) {
    if (rewardsBox.isEmpty) {
      return Container();
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

    return FloatingActionButton.extended(
      onPressed: () {
        goToGoalsForm(context);
      },
      backgroundColor: Theme.of(context).primaryColor,
      elevation: 2,
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        'New Goal',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  String getPrize(String prize) {
    return (prize == '') ? 'Not set' : prize;
  }

  String getGoalResult(RewardsModel rewardDetails) {
    if (rewardDetails.won != '') {
      return rewardDetails.won;
    }
    return '';
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
      return Icons.radio_button_checked_rounded;
    } else if (isGoalEnded(goal)) {
      return Icons.check_circle_rounded;
    } else {
      return Icons.schedule_rounded;
    }
  }

  Color getGoalStatusColor(RewardsModel goal) {
    if (isGoalActive(goal)) {
      return const Color(0xFF34C759); // iOS green
    } else if (isGoalEnded(goal)) {
      return const Color(0xFF007AFF); // iOS blue
    } else {
      return const Color(0xFFFF9500); // iOS orange
    }
  }

  String _formatDateRange(RewardsModel goal) {
    try {
      final start = _parseDate(goal.startPeriod);
      final end = _parseDate(goal.endPeriod);
      
      final startMonth = _getMonthAbbr(start.month);
      final endMonth = _getMonthAbbr(end.month);
      
      if (start.year == end.year) {
        if (start.month == end.month) {
          return '$startMonth ${start.day}-${end.day}, ${end.year}';
        }
        return '$startMonth ${start.day} - $endMonth ${end.day}, ${end.year}';
      }
      return '$startMonth ${start.day}, ${start.year} - $endMonth ${end.day}, ${end.year}';
    } catch (e) {
      return '${goal.startPeriod} - ${goal.endPeriod}';
    }
  }

  String _getMonthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
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
      if (goal.won != '') {
        return goal.won;
      }
      return 'Goal period ended';
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

  Widget _buildPrizeChip(String label, String prize, Color color) {
    if (prize == '' || prize == 'Not set') return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              prize,
              style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.9),
              ),
              overflow: TextOverflow.ellipsis,
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
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.flag_rounded,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No goals yet',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set your first goal to start tracking',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        goToGoalsForm(context);
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create Goal'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return ListView.builder(
                itemCount: rewardsBox.length,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                physics: const AlwaysScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  var currentBox = rewardsBox;
                  RewardsModel rewardsData = currentBox.getAt(index)!;
                  String statusText = getGoalStatusText(rewardsData);
                  Color statusColor = getGoalStatusColor(rewardsData);
                  IconData statusIcon = getGoalStatusIcon(rewardsData);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      elevation: 0,
                      shadowColor: Colors.black12,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          goToGoalStatusScreenWithId(
                            context,
                            rewardsData.rewardId ?? '',
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with status badge
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Icon container
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        statusIcon,
                                        color: statusColor,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Title and status
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            rewardsData.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 17,
                                              color: Colors.black87,
                                              height: 1.3,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  statusText,
                                                  style: TextStyle(
                                                    color: statusColor,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Chevron
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: Colors.grey[400],
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Divider
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: Colors.grey[100],
                              ),
                              
                              // Content section
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Date range
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatDateRange(rewardsData),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // Progress text
                                    Row(
                                      children: [
                                        Icon(
                                          isGoalEnded(rewardsData) 
                                            ? Icons.check_circle_outline_rounded
                                            : Icons.timer_outlined,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _getProgressText(rewardsData),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Prizes section
                                    Text(
                                      'Prizes',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[800],
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _buildPrizeChip(
                                          '🥇 95%',
                                          getPrize(rewardsData.firstPrice),
                                          const Color(0xFFFFD700),
                                        ),
                                        _buildPrizeChip(
                                          '🥈 85%',
                                          getPrize(rewardsData.secondPrice),
                                          const Color(0xFFC0C0C0),
                                        ),
                                        _buildPrizeChip(
                                          '🥉 75%',
                                          getPrize(rewardsData.thirdPrice),
                                          const Color(0xFFCD7F32),
                                        ),
                                      ],
                                    ),
                                    
                                    // Goal result if exists
                                    if (getGoalResult(rewardsData).isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: Colors.green.withOpacity(0.2),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.celebration_rounded,
                                              size: 18,
                                              color: Colors.green[700],
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                getGoalResult(rewardsData),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.green[800],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
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
        if (didPop) return;
        Navigator.pop(context);
        return;
      },
    );
  }
}