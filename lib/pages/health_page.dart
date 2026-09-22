import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/app_helpers.dart';

class HealthPage extends StatelessWidget {
  final List<SleepRecord> sleepRecords;
  final int sleepGoalHours;

  final Function(SleepRecord) onAddSleep;
  final Function(int) onDeleteSleep;
  final Function(int) onUpdateSleepGoal;

  const HealthPage({
    super.key,
    required this.sleepRecords,
    required this.sleepGoalHours,
    required this.onAddSleep,
    required this.onDeleteSleep,
    required this.onUpdateSleepGoal,
  });

  @override
  Widget build(BuildContext context) {
    final latestSleep = sleepRecords.isNotEmpty ? sleepRecords.first : null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Health',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => showAddSleepDialog(context),
                  icon: const Icon(Icons.add),
                  tooltip: 'Add sleep',
                ),
              ],
            ),
            const SizedBox(height: 24),
            _sleepSummary(context, latestSleep),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text(
                  'Sleep history',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${sleepRecords.length} records',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (sleepRecords.isEmpty) _emptyCard('No sleep records yet.'),
            ...sleepRecords.map(
              (record) => Dismissible(
                key: ValueKey('sleep_${record.id}'),
                direction: DismissDirection.endToStart,
                background: _deleteBackground(),
                onDismissed: (_) {
                  onDeleteSleep(record.id);
                },
                child: Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.bedtime_outlined),
                    ),
                    title: Text(
                      formatDuration(record.duration),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${formatDateTime(record.sleepTime)} → ${formatDateTime(record.wakeTime)}',
                    ),
                    trailing: Text(sleepQuality(record.duration)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sleepSummary(BuildContext context, SleepRecord? latestSleep) {
    final duration = latestSleep?.duration;
    final progress = duration == null
        ? 0.0
        : (duration.inMinutes / (sleepGoalHours * 60)).clamp(0.0, 1.0).toDouble();

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.bedtime, size: 48),
            const SizedBox(height: 12),
            Text(
              duration == null ? '--' : formatDuration(duration),
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            Text(
              duration == null ? 'No sleep record' : sleepQuality(duration),
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Sleep goal: $sleepGoalHours hours'),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => showSleepGoalDialog(context),
                  child: const Text('Edit'),
                ),
              ],
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
        child: Center(child: Text(text)),
      ),
    );
  }

  Widget _deleteBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }

  Future<void> showSleepGoalDialog(BuildContext context) async {
    int selectedGoal = sleepGoalHours;
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Sleep goal'),
              content: RadioGroup<int>(
                groupValue: selectedGoal,
                onChanged: (value) {
                  if (value == null) return;
                  setDialogState(() => selectedGoal = value);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(6, (index) {
                    final hours = index + 5;
                    return RadioListTile<int>(
                      value: hours,
                      title: Text('$hours hours'),
                    );
                  }),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, selectedGoal),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      onUpdateSleepGoal(result);
    }
  }

  Future<void> showAddSleepDialog(BuildContext context) async {
    DateTime sleepTime = DateTime.now().subtract(const Duration(hours: 8));
    DateTime wakeTime = DateTime.now();

    final result = await showDialog<SleepRecord>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Sleep Record'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.nightlight_outlined),
                    title: const Text('Sleep time'),
                    subtitle: Text(formatDateTime(sleepTime)),
                    onTap: () async {
                      final value = await pickDateTime(context, sleepTime);
                      if (value != null) {
                        setDialogState(() => sleepTime = value);
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.wb_sunny_outlined),
                    title: const Text('Wake time'),
                    subtitle: Text(formatDateTime(wakeTime)),
                    onTap: () async {
                      final value = await pickDateTime(context, wakeTime);
                      if (value != null) {
                        setDialogState(() => wakeTime = value);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!wakeTime.isAfter(sleepTime)) return;

                    Navigator.pop(
                      dialogContext,
                      SleepRecord(
                        id: 0,
                        sleepTime: sleepTime,
                        wakeTime: wakeTime,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      onAddSleep(result);
    }
  }
}
