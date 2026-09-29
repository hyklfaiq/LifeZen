import 'dart:io';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/app_helpers.dart';

class HomePage extends StatelessWidget {
  final List<ScheduleItem> schedule;
  final List<Task> tasks;
  final List<SleepRecord> sleepRecords;
  final List<Expense> expenses;
  final SavingsGoal? savingsGoal;
  final Function(int) onToggleTask;

  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final int reminderMinutes;
  final ValueChanged<int> onReminderMinutesChanged;

  const HomePage({
    super.key,
    required this.schedule,
    required this.tasks,
    required this.sleepRecords,
    required this.expenses,
    required this.savingsGoal,
    required this.onToggleTask,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.reminderMinutes,
    required this.onReminderMinutesChanged,
  });
void showSettingsDialog(BuildContext context) { showDialog( context: context, builder: (dialogContext) { return AlertDialog( title: const Text('Settings'), content: SizedBox( width: 300, child: Column( mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [ SwitchListTile( contentPadding: EdgeInsets.zero, title: const Text('Dark Mode'), subtitle: const Text('Use dark theme'), value: isDarkMode, onChanged: (_) { onToggleTheme(); Navigator.pop(dialogContext); }, ), const Divider(), const SizedBox(height: 8), const Text( 'Reminder lead time', style: TextStyle( fontWeight: FontWeight.w700, ), ), const SizedBox(height: 8), RadioGroup<int>( groupValue: reminderMinutes, onChanged: (value) { if (value != null) { onReminderMinutesChanged(value); } Navigator.pop(dialogContext); }, child: Column( children: [5, 10, 15, 30] .map( (minutes) => RadioListTile<int>( dense: true, contentPadding: EdgeInsets.zero, title: Text('$minutes minutes'), value: minutes, ), ) .toList(), ), ), ], ), ), ); }, ); }
  String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning';
    }

    if (hour < 18) {
      return 'Good afternoon';
    }

    return 'Good evening';
  }

  String _taskOverviewValue(int completed, int total) {
    if (total == 0) return '0 done';
    return '$completed/$total';
  }

  Map<String, dynamic>? _nextOrActiveSchedule() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    Map<String, dynamic>? active;
    Map<String, dynamic>? upcoming;

    for (final item in schedule) {
      if (!item.repeatDays.contains(today.weekday)) {
        continue;
      }

      final start = DateTime(
        today.year,
        today.month,
        today.day,
        item.time.hour,
        item.time.minute,
      );

      final end = DateTime(
        today.year,
        today.month,
        today.day,
        item.endTime.hour,
        item.endTime.minute,
      );

      final event = {
        'title': item.title,
        'start': start,
        'end': end,
        'isActive': start.isBefore(now) && end.isAfter(now),
      };

      if (event['isActive'] as bool) {
        if (active == null || (event['end'] as DateTime).isBefore(active['end'] as DateTime)) {
          active = event;
        }
      } else if (start.isAfter(now)) {
        if (upcoming == null || start.isBefore(upcoming['start'] as DateTime)) {
          upcoming = event;
        }
      }
    }

    if (active != null) {
      active['isActive'] = true;
      return active;
    }

    return upcoming;
  }

  String _countdownText(DateTime eventTime) {
    final diff = eventTime.difference(DateTime.now());

    if (diff.inMinutes <= 0) {
      return 'Now';
    }

    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);

    if (hours == 0) {
      return '${minutes}m';
    }

    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayTasks = tasks
        .where((task) => DateUtils.isSameDay(task.dueDate, today))
        .toList();
    final completedTasks = todayTasks.where((task) => task.completed).length;
    final nextSchedule = _nextOrActiveSchedule();
    final isScheduleActive = nextSchedule != null && nextSchedule['isActive'] == true;
    final totalExpenses = expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final latestSleep = sleepRecords.isNotEmpty ? sleepRecords.first : null;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overviewGradientColors = isDark
        ? const [
            Color(0xFF1C2A3D),
            Color(0xFF2A3B60),
            Color(0xFF172532),
          ]
        : [
            colorScheme.primary,
            colorScheme.secondary,
          ];

    return SafeArea(
      child: AnimatedOpacity(
        opacity: 1,
        duration: const Duration(milliseconds: 350),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        text: _greeting(),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.6,
                        ),
                        children: [
                          TextSpan(
                            text: '\nHeyoooo!',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outlineVariant,
                      ),
                    ),
                    child: IconButton(
                      onPressed: () => showSettingsDialog(context),
                      icon: Icon(
                        Icons.settings_outlined,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      tooltip: 'Settings',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: overviewGradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.18),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? const Color(0xFF0F172A) : colorScheme.primary)
                          .withValues(alpha: isDark ? 0.52 : 0.25),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Today',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${DateTime.now().day}/${DateTime.now().month}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _taskOverviewValue(completedTasks, todayTasks.length),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 31,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                todayTasks.isEmpty ? 'No tasks today' : 'Tasks done',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 18,
                          height: 58,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          alignment: Alignment.center,
                          child: CustomPaint(
                            size: const Size(18, 58),
                            painter: _DividerPainter(),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              nextSchedule == null
                                  ? 'No upcoming event'
                                  : isScheduleActive
                                      ? 'Live now'
                                      : 'Next up',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 120,
                              child: Text(
                                nextSchedule == null
                                    ? 'Your day is clear'
                                    : nextSchedule['title'] as String,
                                textAlign: TextAlign.right,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              nextSchedule == null
                                  ? ''
                                  : isScheduleActive
                                      ? '${_countdownText(nextSchedule['end'] as DateTime)} left'
                                      : 'in ${_countdownText(nextSchedule['start'] as DateTime)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text(
                    'Tasks due today',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '$completedTasks/${todayTasks.length}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (todayTasks.isEmpty) _emptyCard(context, 'No tasks due today.'),
              ...todayTasks.take(4).map(
                (task) => AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: task.completed
                            ? Colors.transparent
                            : Theme.of(context).dividerColor.withValues(alpha: 0.18),
                      ),
                    ),
                    child: CheckboxListTile(
                      value: task.completed,
                      onChanged: (_) {
                        onToggleTask(task.id);
                      },
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.completed
                              ? TextDecoration.lineThrough
                              : null,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(formatDate(task.dueDate)),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _infoCard(
                      context,
                      Icons.bedtime_outlined,
                      'Sleep',
                      latestSleep == null
                          ? 'No data'
                          : formatDuration(latestSleep.duration),
                      'Last night',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _infoCard(
                      context,
                      Icons.wallet_outlined,
                      'Spent',
                      'RM${totalExpenses.toStringAsFixed(2)}',
                      'This month',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _sectionTitle('Savings'),
              const SizedBox(height: 12),
              if (savingsGoal == null)
                _emptyCard(context, 'No savings goal yet.\nCreate one from Money.')
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: savingsGoal!.imagePath == null
                                  ? null
                                  : FileImage(File(savingsGoal!.imagePath!)),
                              child: savingsGoal!.imagePath == null
                                  ? const Icon(Icons.savings_outlined, size: 16)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                savingsGoal!.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Text(
                              '${(savingsGoal!.progress * 100).round()}%',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        LinearProgressIndicator(
                          value: savingsGoal!.progress,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'RM${savingsGoal!.currentAmount.toStringAsFixed(2)} '
                          '/ RM${savingsGoal!.targetAmount.toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String repeatText(List<int> days) {
    if (days.length == 7) {
      return 'Every day';
    }

    if (days.length == 5 &&
        days.contains(1) &&
        days.contains(2) &&
        days.contains(3) &&
        days.contains(4) &&
        days.contains(5)) {
      return 'Weekdays';
    }

    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.map((day) => names[day - 1]).join(', ');
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }


  Widget _infoCard(
    BuildContext context,
    IconData icon,
    String title,
    String value,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(BuildContext context, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(child: Text(text, textAlign: TextAlign.center)),
    );
  }
}

class _DividerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    const dashLength = 5.0;
    const gapLength = 5.0;

    for (double y = 0; y < size.height; y += dashLength + gapLength) {
      final endY = (y + dashLength).clamp(0.0, size.height);
      canvas.drawLine(
        Offset(centerX, y),
        Offset(centerX, endY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
