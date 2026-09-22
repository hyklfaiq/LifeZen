import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/app_helpers.dart';

class SchedulePage extends StatefulWidget {
  final List<ScheduleItem> schedule;
  final int firstDayOfWeek;
  final Future<void> Function(int day) onFirstDayChanged;
  final Future<void> Function(ScheduleItem item) onAddSchedule;
  final Future<void> Function(ScheduleItem item) onUpdateSchedule;
  final Future<void> Function(int id) onDeleteSchedule;

  const SchedulePage({
    super.key,
    required this.schedule,
    required this.firstDayOfWeek,
    required this.onFirstDayChanged,
    required this.onAddSchedule,
    required this.onUpdateSchedule,
    required this.onDeleteSchedule,
  });

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  Future<void> showScheduleDialog({ScheduleItem? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    TimeOfDay selectedTime = existing?.time ?? TimeOfDay.now();
    List<int> selectedDays = List<int>.from(existing?.repeatDays ?? [1, 2, 3, 4, 5]);

    final result = await showDialog<ScheduleItem>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add Schedule' : 'Edit Schedule'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Schedule name',
                        hintText: 'e.g. Study',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time),
                      title: const Text('Time'),
                      subtitle: Text(formatTimeOfDay(selectedTime)),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );

                        if (picked != null) {
                          setDialogState(() => selectedTime = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Repeat',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: List.generate(7, (index) {
                        final day = index + 1;
                        final selected = selectedDays.contains(day);
                        const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

                        return FilterChip(
                          label: Text(names[index]),
                          selected: selected,
                          onSelected: (value) {
                            setDialogState(() {
                              if (value) {
                                selectedDays.add(day);
                              } else {
                                selectedDays.remove(day);
                              }
                              selectedDays.sort();
                            });
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty || selectedDays.isEmpty) {
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      ScheduleItem(
                        id: existing?.id ?? 0,
                        title: titleController.text.trim(),
                        time: selectedTime,
                        repeatDays: selectedDays,
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

    titleController.dispose();

    if (result == null) return;
    if (existing == null) {
      widget.onAddSchedule(result);
    } else {
      widget.onUpdateSchedule(result);
    }
  }

  Future<void> showFirstDayDialog() async {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    int selected = widget.firstDayOfWeek;
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('First day of week'),
              content: RadioGroup<int>(
                groupValue: selected,
                onChanged: (value) {
                  if (value == null) return;
                  setDialogState(() => selected = value);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(7, (index) {
                    final day = index + 1;
                    return RadioListTile<int>(
                      value: day,
                      title: Text(days[index]),
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
                  onPressed: () => Navigator.pop(dialogContext, selected),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      widget.onFirstDayChanged(result);
    }
  }

  DateTime _weekStart() {
    final today = DateTime.now();
    final difference = (today.weekday - widget.firstDayOfWeek + 7) % 7;
    return DateTime(today.year, today.month, today.day).subtract(Duration(days: difference));
  }

  List<int> _orderedDays() {
    return List.generate(7, (index) => ((widget.firstDayOfWeek - 1 + index) % 7) + 1);
  }

  String _fullDayName(int weekday) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[weekday - 1];
  }

  Widget _buildWeekSchedule() {
    final weekStart = _weekStart();
    final orderedDays = _orderedDays();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(7, (index) {
          final weekday = orderedDays[index];
          final date = weekStart.add(Duration(days: index));
          final items = widget.schedule
              .where((item) => item.repeatDays.contains(weekday))
              .toList();

          items.sort((a, b) {
            final aMinutes = a.time.hour * 60 + a.time.minute;
            final bMinutes = b.time.hour * 60 + b.time.minute;
            return aMinutes.compareTo(bMinutes);
          });

          final isToday = DateUtils.isSameDay(date, DateTime.now());

          return Container(
            width: 190,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fullDayName(weekday),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  '${date.day}/${date.month}',
                  style: TextStyle(
                    color: isToday
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: isToday ? FontWeight.bold : null,
                  ),
                ),
                const SizedBox(height: 8),
                Divider(color: isToday ? Theme.of(context).colorScheme.primary : null),
                const SizedBox(height: 8),
                Expanded(
                  child: items.isEmpty
                      ? Card(
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No schedule',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      : ListView(
                          padding: EdgeInsets.zero,
                          children: items.map((item) => _scheduleCard(item)).toList(),
                        ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _scheduleCard(ScheduleItem item) {
    return Dismissible(
      key: ValueKey('${item.id}_${item.time.hour}_${item.time.minute}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        widget.onDeleteSchedule(item.id);
      },
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => showScheduleDialog(existing: item),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatTimeOfDay(item.time),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstDayName = _fullDayName(widget.firstDayOfWeek);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 10),
            child: Row(
              children: [
                const Text(
                  'Schedule',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: showFirstDayDialog,
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Schedule settings',
                ),
                IconButton(
                  onPressed: () => showScheduleDialog(),
                  icon: const Icon(Icons.add),
                  tooltip: 'Add schedule',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_view_week,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Week starts $firstDayName',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: widget.schedule.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_view_week_outlined,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        const Text('No schedules yet.'),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => showScheduleDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add schedule'),
                        ),
                      ],
                    ),
                  )
                : _buildWeekSchedule(),
          ),
        ],
      ),
    );
  }
}
