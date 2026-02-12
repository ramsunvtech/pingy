import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pingy/models/hive/activity.dart';
import 'package:pingy/models/hive/activity_item.dart';
import 'package:pingy/models/hive/activity_type.dart';

import 'package:pingy/widgets/icons/settings.dart';
import 'package:pingy/widgets/FutureWidgets.dart';
import 'package:pingy/widgets/SettingsBottomNavigation.dart';
import 'package:pingy/widgets/CustomAppBar.dart';

import 'package:pingy/utils/navigators.dart';

class ActivitiesListScreen extends StatefulWidget {
  @override
  _ActivitiesListScreenState createState() => _ActivitiesListScreenState();
}

class _ActivitiesListScreenState extends State<ActivitiesListScreen> {
  late final Box activityBox;
  late final Box activityTypeBox;

  String activityCount = '0';

  @override
  void initState() {
    super.initState();
    // Get reference to an already opened box
    activityBox = Hive.box('activity');
    activityTypeBox = Hive.box('activity_type');

    if (activityBox.isNotEmpty) {
      activityCount = activityBox.length.toString();
    }
  }

  Future<bool> _confirmDeleteActivity(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Delete Score'),
          content: const Text(
            'Are you sure you want to delete this score?\n\nThis action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  /// Safe method to get ActivityType by activityTypeId
  ActivityTypeModel? getActivityTypeById(String activityTypeId) {
    if (activityTypeBox.isEmpty) return null;
    
    for (var key in activityTypeBox.keys) {
      final activityType = activityTypeBox.get(key) as ActivityTypeModel?;
      if (activityType?.activityTypeId == activityTypeId) {
        return activityType;
      }
    }
    
    return null;
  }

  Color _getScoreColor(int percentage) {
    if (percentage >= 95) return const Color(0xFFFFD700); // Gold
    if (percentage >= 85) return const Color(0xFFC0C0C0); // Silver
    if (percentage >= 75) return const Color(0xFFCD7F32); // Bronze
    if (percentage >= 60) return Colors.green;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }

  IconData _getScoreIcon(int percentage) {
    if (percentage >= 95) return Icons.emoji_events;
    if (percentage >= 85) return Icons.workspace_premium;
    if (percentage >= 75) return Icons.military_tech;
    if (percentage >= 60) return Icons.thumb_up;
    if (percentage >= 40) return Icons.trending_up;
    return Icons.trending_down;
  }

  String _getScoreLabel(int percentage) {
    if (percentage >= 95) return 'Excellent!';
    if (percentage >= 85) return 'Great Job!';
    if (percentage >= 75) return 'Good Work';
    if (percentage >= 60) return 'Well Done';
    if (percentage >= 40) return 'Keep Going';
    return 'Try Harder';
  }

  bool _isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown Date';
    
    if (_isToday(date)) {
      return 'Today';
    }
    
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    
    if (date.year == yesterday.year && 
        date.month == yesterday.month && 
        date.day == yesterday.day) {
      return 'Yesterday';
    }
    
    final difference = now.difference(date).inDays;
    
    if (difference < 7) {
      return DateFormat('EEEE').format(date); // Day name
    }
    
    if (date.year == now.year) {
      return DateFormat('MMM d').format(date); // Jan 15
    }
    
    return DateFormat('MMM d, yyyy').format(date); // Jan 15, 2024
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: customAppBar(
          title: 'Scores ($activityCount days)',
          actions: [
            settingsLinkIconButton(context),
          ],
        ),
        body: ValueListenableBuilder(
          valueListenable: activityBox.listenable(),
          builder: (context, Box activityDataBox, widget) {
            if (activityDataBox.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No scores yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete activities to see your scores here',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            } else {
              // Get all activity keys and sort them by date (latest first)
              List<String> activityDataKeyList = activityDataBox.keys.toList().cast<String>();
              
              // Sort by date (latest first)
              activityDataKeyList.sort((a, b) {
                try {
                  Activity activityA = activityDataBox.get(a);
                  Activity activityB = activityDataBox.get(b);
                  
                  DateTime? dateA = activityA.activityDate;
                  DateTime? dateB = activityB.activityDate;
                  
                  // Handle null dates - put them at the end
                  if (dateA == null && dateB == null) return 0;
                  if (dateA == null) return 1;
                  if (dateB == null) return -1;
                  
                  // Sort descending (latest first)
                  return dateB.compareTo(dateA);
                } catch (e) {
                  // Fallback to reverse string comparison
                  return b.compareTo(a);
                }
              });
              
              return ListView.builder(
                itemCount: activityDataKeyList.length,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                physics: const AlwaysScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  String activityId = activityDataKeyList[index];
                  Activity activityData = activityDataBox.get(activityId);
                  
                  // Calculate total possible score
                  int activityTypeFullScore = 0;
                  activityTypeBox.toMap().forEach((key, value) {
                    activityTypeFullScore += int.tryParse(value.fullScore) ?? 0;
                  });

                  // Calculate day score
                  int dayScore = 0;
                  List<String> missedActivities = [];
                  
                  if (activityData.activityItems.isNotEmpty) {
                    for (var element in activityData.activityItems) {
                      var scoreValue = int.tryParse(element.score ?? "0") ?? 0;
                      dayScore += scoreValue;
                      
                      // Track missed activities
                      if (element.score == "0") {
                        var activityType = getActivityTypeById(element.activityItemId);
                        if (activityType != null) {
                          missedActivities.add(activityType.activityName);
                        }
                      }
                    }
                  }

                  int activityScorePercentage = activityTypeFullScore > 0
                      ? ((dayScore / activityTypeFullScore) * 100).ceil()
                      : 0;
                  
                  Color scoreColor = _getScoreColor(activityScorePercentage);
                  IconData scoreIcon = _getScoreIcon(activityScorePercentage);
                  String scoreLabel = _getScoreLabel(activityScorePercentage);
                  String formattedDate = _formatDate(activityData.activityDate);
                  bool isToday = _isToday(activityData.activityDate);
                  
                  var today = DateTime.now();
                  var todayActivityId = 'activity_${today.year}${today.month}${today.day}';
                  bool canDelete = activityId == todayActivityId;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isToday ? scoreColor.withOpacity(0.3) : Colors.grey[200]!,
                        width: isToday ? 2 : 1,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        if (!canDelete) {
                          goToPastActivityEditScreen(context, activityId);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Score Badge
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    scoreColor.withOpacity(0.2),
                                    scoreColor.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: scoreColor.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    scoreIcon,
                                    color: scoreColor,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$activityScorePercentage%',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: scoreColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(width: 12),
                            
                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Date and Label
                                  Row(
                                    children: [
                                      if (isToday)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: scoreColor.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'TODAY',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: scoreColor,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      if (isToday) const SizedBox(width: 6),
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 4),
                                  
                                  // Score Label
                                  Text(
                                    scoreLabel,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: scoreColor,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 4),
                                  
                                  // Score Details
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.assessment,
                                        size: 13,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Score: $dayScore/$activityTypeFullScore',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  // Missed Activities
                                  if (missedActivities.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.close_rounded,
                                          size: 13,
                                          color: Colors.red[400],
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Missed: ${missedActivities.join(', ')}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.red[600],
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            
                            // Action Button
                            if (canDelete)
                              IconButton(
                                onPressed: () async {
                                  final confirmed = await _confirmDeleteActivity(context);
                                  if (!confirmed) return;

                                  await activityBox.delete(activityId);
                                  showToastMessage(context, 'Score removed successfully!');
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                tooltip: 'Delete',
                              )
                            else
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
        bottomNavigationBar: settingsBottomNavigationBar(context),
      ),
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        // If the system already handled the pop, do nothing
        if (didPop) return;
        goToSettingScreen(context);
        return;
      },
    );
  }
}