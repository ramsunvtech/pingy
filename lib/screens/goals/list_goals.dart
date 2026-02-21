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
  late final Box _rewardsBox;

  @override
  void initState() {
    super.initState();
    _rewardsBox = Hive.box('rewards');
  }

  // ─── Date parsing ────────────────────────────────────────────────────────────

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

  // ─── FAB ─────────────────────────────────────────────────────────────────────

  Widget _buildFloatingButton(BuildContext context) {
    try {
      if (_rewardsBox.isEmpty) {
        return _addFab(context);
      }

      // Safe cast — the box is untyped so we must check
      final latest = _rewardsBox.values.last;
      if (latest is! RewardsModel) return _addFab(context);

      final end = _parseDate(latest.endPeriod);
      final today = DateTime.now();

      // Still within the current goal period — hide FAB
      if (end.difference(DateTime(today.year, today.month, today.day)).inDays > 0) {
        return const SizedBox.shrink();
      }

      return _addFab(context);
    } catch (e) {
      debugPrint('[GoalListScreen] _buildFloatingButton error: $e');
      return _addFab(context);
    }
  }

  FloatingActionButton _addFab(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => goToGoalsForm(context),
      backgroundColor: Colors.lightGreen,
      child: const Icon(Icons.add),
    );
  }

  // ─── Goal helpers ─────────────────────────────────────────────────────────────

  String _getPrize(String? prize) =>
      (prize == null || prize.isEmpty) ? 'Not set' : prize;

  String _getGoalResult(RewardsModel goal) =>
      (goal.won != null && goal.won!.isNotEmpty) ? goal.won! : '';

  bool _hasImage(RewardsModel goal) =>
      goal.rewardPicture != null && goal.rewardPicture!.isNotEmpty;

  bool _isGoalActive(RewardsModel goal) {
    try {
      final today =
          DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      return !today.isBefore(_parseDate(goal.startPeriod)) &&
          !today.isAfter(_parseDate(goal.endPeriod));
    } catch (_) {
      return false;
    }
  }

  bool _isGoalEnded(RewardsModel goal) {
    try {
      final today =
          DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      return today.isAfter(_parseDate(goal.endPeriod));
    } catch (_) {
      return false;
    }
  }

  String _statusText(RewardsModel goal) {
    if (_isGoalActive(goal)) return 'Active';
    if (_isGoalEnded(goal)) return 'Completed';
    return 'Upcoming';
  }

  IconData _statusIcon(RewardsModel goal) {
    if (_isGoalActive(goal)) return Icons.timer;
    if (_isGoalEnded(goal)) return Icons.check_circle;
    return Icons.schedule;
  }

  Color _statusColor(RewardsModel goal) {
    if (_isGoalActive(goal)) return Colors.green;
    if (_isGoalEnded(goal)) return Colors.blue;
    return Colors.orange;
  }

  int _remainingDays(RewardsModel goal) {
    try {
      final today =
          DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      return _parseDate(goal.endPeriod).difference(today).inDays;
    } catch (_) {
      return 0;
    }
  }

  String _progressText(RewardsModel goal) {
    if (_isGoalEnded(goal)) {
      final result = _getGoalResult(goal);
      return result.isNotEmpty ? result : 'Goal ended';
    }

    if (_isGoalActive(goal)) {
      final remaining = _remainingDays(goal);
      if (remaining == 0) return 'Last day!';
      if (remaining == 1) return '1 day left';
      return '$remaining days left';
    }

    // Upcoming
    try {
      final today =
          DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final daysUntil = _parseDate(goal.startPeriod).difference(today).inDays;
      if (daysUntil == 0) return 'Starts today';
      if (daysUntil == 1) return 'Starts tomorrow';
      return 'Starts in $daysUntil days';
    } catch (_) {
      return 'Upcoming';
    }
  }

  // ─── Widgets ──────────────────────────────────────────────────────────────────

  Widget _buildGoalImage(RewardsModel goal, Color statusColor) {
    if (!_hasImage(goal)) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(_statusIcon(goal), color: statusColor, size: 28),
      );
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
      ),
      child: ClipOval(
        child: Image.network(
          goal.rewardPicture!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: statusColor.withOpacity(0.15),
            child: Icon(_statusIcon(goal), color: statusColor, size: 28),
          ),
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(
              color: Colors.grey[100],
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
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

  Widget _buildGoalCard(BuildContext context, RewardsModel goal, Color statusColor) {
    final hasWon = _getGoalResult(goal).isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => goToGoalStatusScreenWithId(
          context,
          goal.rewardId ?? '',
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildGoalImage(goal, statusColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + status badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            goal.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: statusColor.withOpacity(0.4), width: 1),
                          ),
                          child: Text(
                            _statusText(goal),
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Date range
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 13, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${goal.startPeriod} - ${goal.endPeriod}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Progress
                    Row(
                      children: [
                        Icon(
                          hasWon
                              ? Icons.emoji_events
                              : (_isGoalActive(goal)
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
                            _progressText(goal),
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
                        if (goal.firstPrice.isNotEmpty) ...[
                          const Text('🥇',
                              style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              _getPrize(goal.firstPrice),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[700]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (goal.firstPrice.isNotEmpty &&
                            goal.secondPrice.isNotEmpty)
                          Text(' • ',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[400])),
                        if (goal.secondPrice.isNotEmpty) ...[
                          const Text('🥈',
                              style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              _getPrize(goal.secondPrice),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[700]),
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
              Icon(Icons.chevron_right,
                  color: Colors.grey[400], size: 20),
            ],
          ),
        ),
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
        Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: customAppBar(
          title: 'Goals',
          actions: [settingsLinkIconButton(context)],
        ),
        body: ValueListenableBuilder(
          valueListenable: _rewardsBox.listenable(),
          builder: (context, Box box, _) {
            if (box.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.flag_outlined,
                        size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('No goals yet',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700])),
                    const SizedBox(height: 8),
                    Text('Create your first goal to get started',
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey[500])),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: box.length,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                // Safe read — getAt can return null on Hive untyped boxes
                final raw = box.getAt(index);
                if (raw == null || raw is! RewardsModel) {
                  return const SizedBox.shrink();
                }
                final goal = raw;
                final color = _statusColor(goal);
                return _buildGoalCard(context, goal, color);
              },
            );
          },
        ),
        floatingActionButton: _buildFloatingButton(context),
        bottomNavigationBar: settingsBottomNavigationBar(context),
      ),
    );
  }
}