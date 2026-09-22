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
  });

  void showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Settings'),
          content: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: isDarkMode,
            onChanged: (_) {
              onToggleTheme();
              Navigator.pop(dialogContext);
            },
          ),
        );
      },
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning 👋';
    }

    if (hour < 18) {
      return 'Good afternoon 👋';
    }

    return 'Good evening 👋';
  }

  @override
  Widget build(BuildContext context) {
    final completedTasks = tasks.where((task) => task.completed).length;

    final totalExpenses = expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    final latestSleep = sleepRecords.isNotEmpty ? sleepRecords.first : null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _greeting(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    showSettingsDialog(context);
                  },
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Settings',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Your day at a glance',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            _sectionTitle('Today'),
            const SizedBox(height: 12),
            ..._todayScheduleCards(),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text(
                  'Tasks',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '$completedTasks/${tasks.length}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (tasks.isEmpty) _emptyCard('No tasks yet.'),
            ...tasks.take(4).map(
              (task) => Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
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
                    ),
                  ),
                  subtitle: Text(formatDate(task.dueDate)),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _infoCard(
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
              _emptyCard('No savings goal yet.\nCreate one from Money.')
            else
              Card(
                elevation: 0,
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
    );
  }

  List<Widget> _todayScheduleCards() {
    final today = DateTime.now().weekday;
    final todaySchedules = schedule.where((item) => item.repeatDays.contains(today)).toList();

    todaySchedules.sort((a, b) {
      final aMinutes = a.time.hour * 60 + a.time.minute;
      final bMinutes = b.time.hour * 60 + b.time.minute;
      return aMinutes.compareTo(bMinutes);
    });

    if (todaySchedules.isEmpty) {
      return [_emptyCard('No schedule for today.')];
    }

    return todaySchedules.map((item) {
      return _scheduleCard(
        formatTimeOfDay(item.time),
        item.title,
        repeatText(item.repeatDays),
        Icons.schedule_outlined,
      );
    }).toList();
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

  Widget _scheduleCard(String time, String title, String repeat, IconData icon) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        subtitle: Text(repeat),
        trailing: Text(
          time,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String value, String subtitle) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 10),
            Text(title),
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
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: Text(text, textAlign: TextAlign.center)),
      ),
    );
  }
}
