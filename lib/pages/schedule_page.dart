import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/imaluum/imaluum_timetable.dart';
import '../utils/app_helpers.dart';
import 'imaluum_import_page.dart';

class SchedulePage extends StatefulWidget {
  final List<ScheduleItem> schedule;
  final int firstDayOfWeek;

  final Future<void> Function(int day) onFirstDayChanged;
  final Future<void> Function(ScheduleItem item) onAddSchedule;
  final Future<void> Function(ScheduleItem item) onUpdateSchedule;
  final Future<void> Function(int id) onDeleteSchedule;

  final Future<int> Function(List<ImaluumMeeting> meetings) onImportImaluum;

  final Future<void> Function() onClearAll;

  const SchedulePage({
    super.key,
    required this.schedule,
    required this.firstDayOfWeek,
    required this.onFirstDayChanged,
    required this.onAddSchedule,
    required this.onUpdateSchedule,
    required this.onDeleteSchedule,
    required this.onImportImaluum,
    required this.onClearAll,
  });

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  Future<void> _openImaluumImport() async {
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImaluumImportPage(onImport: widget.onImportImaluum),
      ),
    );
  }

  Future<void> _clearAll() async {
    if (widget.schedule.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear all schedules?'),
          content: Text(
            'This will remove all '
            '${widget.schedule.length} schedules. '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Clear all'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await widget.onClearAll();
  }

  Future<void> showScheduleDialog({ScheduleItem? existing}) async {
    final result = await showDialog<ScheduleItem>(
      context: context,
      builder: (_) {
        return _ScheduleEditorDialog(existing: existing);
      },
    );

    if (!mounted || result == null) {
      return;
    }

    if (existing == null) {
      await widget.onAddSchedule(result);
    } else {
      await widget.onUpdateSchedule(result);
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
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('First day of week'),
              content: RadioGroup<int>(
                groupValue: selected,
                onChanged: (value) {
                  if (value == null) return;

                  setDialogState(() {
                    selected = value;
                  });
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
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(selected);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    await widget.onFirstDayChanged(result);
  }

  DateTime _weekStart() {
    final today = DateTime.now();

    final difference = (today.weekday - widget.firstDayOfWeek + 7) % 7;

    return DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: difference));
  }

  List<int> _orderedDays() {
    return List.generate(
      7,
      (index) => ((widget.firstDayOfWeek - 1 + index) % 7) + 1,
    );
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

  String _shortDayName(int weekday) {
    const names = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    return names[weekday - 1];
  }

  String _formatHour(int hour) {
    final period = hour >= 12 ? 'PM' : 'AM';

    final displayHour = hour % 12 == 0 ? 12 : hour % 12;

    return '$displayHour $period';
  }

  Widget _buildWeekSchedule() {
    final weekStart = _weekStart();
    final orderedDays = _orderedDays();

    int earliestMinutes = 8 * 60;
    int latestMinutes = 18 * 60;

    for (final item in widget.schedule) {
      final start = item.time.hour * 60 + item.time.minute;

      final end = item.endTime.hour * 60 + item.endTime.minute;

      if (start < earliestMinutes) {
        earliestMinutes = start;
      }

      if (end > latestMinutes) {
        latestMinutes = end;
      }
    }

    final firstHour = earliestMinutes ~/ 60;
    final lastHour = (latestMinutes + 59) ~/ 60;

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final hourHeight = isLandscape ? 60.0 : 76.0;

    const timeColumnWidth = 62.0;

    final dayWidth = isLandscape ? 135.0 : 150.0;

    final headerHeight = isLandscape ? 48.0 : 62.0;

    final gridHeight = (lastHour - firstHour) * hourHeight;

    final totalWidth = timeColumnWidth + (dayWidth * orderedDays.length);

    return Scrollbar(
      thumbVisibility: false,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.fromLTRB(
          isLandscape ? 6 : 12,
          isLandscape ? 6 : 12,
          isLandscape ? 6 : 12,
          isLandscape ? 10 : 20,
        ),
        child: SizedBox(
          width: totalWidth,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SizedBox(
              width: totalWidth,
              child: Column(
                children: [
                  SizedBox(
                    height: headerHeight,
                    child: Row(
                      children: [
                        const SizedBox(width: timeColumnWidth),
                        ...List.generate(orderedDays.length, (index) {
                          final weekday = orderedDays[index];

                          final date = weekStart.add(Duration(days: index));

                          final isToday = DateUtils.isSameDay(
                            date,
                            DateTime.now(),
                          );

                          return SizedBox(
                            width: dayWidth,
                            child: Container(
                              margin: const EdgeInsets.only(right: 1),
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: isLandscape ? 4 : 6,
                              ),
                              decoration: BoxDecoration(
                                color: isToday
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer
                                    : Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(10),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    _shortDayName(weekday),
                                    style: TextStyle(
                                      fontSize: isLandscape ? 11 : 14,
                                      fontWeight: FontWeight.bold,
                                      color: isToday
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${date.day}/${date.month}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  SizedBox(
                    height: gridHeight,
                    width: totalWidth,
                    child: Stack(
                      children: [
                        // Full-hour horizontal lines.
                        ...List.generate(lastHour - firstHour + 1, (index) {
                          final hour = firstHour + index;

                          return Positioned(
                            top: index * hourHeight,
                            left: 0,
                            right: 0,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: timeColumnWidth,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      _formatHour(hour),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        // Half-hour lines.
                        ...List.generate(lastHour - firstHour, (index) {
                          return Positioned(
                            top: (index * hourHeight) + (hourHeight / 2),
                            left: timeColumnWidth,
                            right: 0,
                            child: Container(
                              height: 1,
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant
                                  .withValues(alpha: 0.25),
                            ),
                          );
                        }),

                        // Vertical day separators.
                        Positioned(
                          left: timeColumnWidth,
                          top: 0,
                          bottom: 0,
                          child: Row(
                            children: List.generate(orderedDays.length, (
                              index,
                            ) {
                              return Container(
                                width: dayWidth,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),

                        // Schedule cards.
                        ...List.generate(orderedDays.length, (index) {
                          final weekday = orderedDays[index];

                          final items = widget.schedule
                              .where(
                                (item) => item.repeatDays.contains(weekday),
                              )
                              .toList();

                          return Stack(
                            children: items.map((item) {
                              final startMinutes =
                                  item.time.hour * 60 + item.time.minute;

                              final endMinutes =
                                  item.endTime.hour * 60 + item.endTime.minute;

                              final top =
                                  ((startMinutes - firstHour * 60) / 60) *
                                  hourHeight;

                              final height =
                                  ((endMinutes - startMinutes) / 60) *
                                  hourHeight;

                              final cardHeight = height > 8 ? height - 4 : 8.0;

                              return Positioned(
                                left: timeColumnWidth + (index * dayWidth) + 4,
                                top: top + 2,
                                width: dayWidth - 8,
                                height: cardHeight,
                                child: _gridScheduleCard(item, cardHeight),
                              );
                            }).toList(),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _gridScheduleCard(ScheduleItem item, double height) {
    final subject = (item.courseName?.trim().isNotEmpty ?? false)
        ? item.courseName!.trim()
        : item.title.trim();

    final lecturer = item.lecturer?.trim();

    final venue = item.venue?.trim().isNotEmpty == true
        ? item.venue!.trim()
        : 'No venue yet';

    final startMinutes = item.time.hour * 60 + item.time.minute;

    final endMinutes = item.endTime.hour * 60 + item.endTime.minute;

    String formatTime(int minutes) {
      final hour = minutes ~/ 60;
      final minute = minutes % 60;

      final period = hour >= 12 ? 'PM' : 'AM';

      final displayHour = hour % 12 == 0 ? 12 : hour % 12;

      return minute == 0
          ? '$displayHour $period'
          : '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    }

    final timeText = '${formatTime(startMinutes)} - ${formatTime(endMinutes)}';

    final colorScheme = Theme.of(context).colorScheme;

    Widget infoRow({required IconData icon, required String text}) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 12, color: colorScheme.onPrimaryContainer),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  height: 1.15,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Dismissible(
      key: ValueKey('${item.id}_${item.importKey ?? ''}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Delete schedule?'),
              content: Text('Delete "$subject" from your schedule?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (_) async {
        await widget.onDeleteSchedule(item.id);
      },
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 14),
        child: Icon(Icons.delete_outline, color: colorScheme.onErrorContainer),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            showScheduleDialog(existing: item);
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.25),
              ),
            ),
            padding: const EdgeInsets.all(7),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableHeight = constraints.maxHeight;

                return SingleChildScrollView(
                  physics: availableHeight < 100
                      ? const BouncingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        subject,
                        maxLines: availableHeight >= 140 ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          height: 1.1,
                          color: colorScheme.onPrimaryContainer.withValues(
                            alpha: 0.75,
                          ),
                        ),
                      ),
                      if (lecturer != null && lecturer.isNotEmpty)
                        infoRow(icon: Icons.person_outline, text: lecturer),
                      infoRow(icon: Icons.location_on_outlined, text: venue),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstDayName = _fullDayName(widget.firstDayOfWeek);

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              isLandscape ? 4 : 20,
              20,
              isLandscape ? 4 : 10,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Schedule',
                        style: TextStyle(
                          fontSize: isLandscape ? 22 : 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: isLandscape
                          ? VisualDensity.compact
                          : VisualDensity.standard,
                      onPressed: showFirstDayDialog,
                      icon: const Icon(Icons.settings_outlined),
                      tooltip: 'Schedule settings',
                    ),
                    IconButton(
                      visualDensity: isLandscape
                          ? VisualDensity.compact
                          : VisualDensity.standard,
                      onPressed: () {
                        showScheduleDialog();
                      },
                      icon: const Icon(Icons.add),
                      tooltip: 'Add schedule',
                    ),
                  ],
                ),

                SizedBox(height: isLandscape ? 2 : 8),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openImaluumImport,
                        icon: const Icon(Icons.school_outlined, size: 18),
                        label: const Text("i-Ma'luum"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.schedule.isEmpty ? null : _clearAll,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Clear all'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: isLandscape ? 2 : 0,
            ),
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
                  style: TextStyle(
                    fontSize: isLandscape ? 11 : 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          if (widget.schedule.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(20, isLandscape ? 2 : 10, 20, 0),
              child: Row(
                children: [
                  Icon(
                    Icons.swipe_left_alt_rounded,
                    size: 15,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Swipe left to delete',
                    style: TextStyle(
                      fontSize: isLandscape ? 10 : 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: isLandscape ? 4 : 12),

          Expanded(
            child: widget.schedule.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_view_week_outlined,
                            size: isLandscape ? 40 : 60,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          const Text('No schedules yet.'),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: () {
                              showScheduleDialog();
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add schedule'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _buildWeekSchedule(),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Dialog for adding and editing schedules.
// -----------------------------------------------------------------------------

class _ScheduleEditorDialog extends StatefulWidget {
  final ScheduleItem? existing;

  const _ScheduleEditorDialog({this.existing});

  @override
  State<_ScheduleEditorDialog> createState() => _ScheduleEditorDialogState();
}

class _ScheduleEditorDialogState extends State<_ScheduleEditorDialog> {
  late final TextEditingController titleController;

  late TimeOfDay selectedTime;
  late TimeOfDay selectedEndTime;
  late List<int> selectedDays;

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;

    titleController = TextEditingController(text: existing?.title ?? '');

    selectedTime = existing?.time ?? const TimeOfDay(hour: 9, minute: 0);

    selectedEndTime =
        existing?.endTime ??
        TimeOfDay(
          hour: selectedTime.hour < 23 ? selectedTime.hour + 1 : 23,
          minute: selectedTime.minute,
        );

    selectedDays = List<int>.from(existing?.repeatDays ?? [1, 2, 3, 4, 5]);
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      selectedTime = picked;

      final startMinutes = selectedTime.hour * 60 + selectedTime.minute;

      final endMinutes = selectedEndTime.hour * 60 + selectedEndTime.minute;

      if (endMinutes <= startMinutes) {
        final newHour = selectedTime.hour < 23 ? selectedTime.hour + 1 : 23;

        selectedEndTime = TimeOfDay(hour: newHour, minute: selectedTime.minute);
      }
    });
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedEndTime,
    );

    if (picked == null || !mounted) {
      return;
    }

    final startMinutes = selectedTime.hour * 60 + selectedTime.minute;

    final endMinutes = picked.hour * 60 + picked.minute;

    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }

    setState(() {
      selectedEndTime = picked;
    });
  }

  void _toggleDay(int day, bool selected) {
    setState(() {
      if (selected) {
        if (!selectedDays.contains(day)) {
          selectedDays.add(day);
        }
      } else {
        selectedDays.remove(day);
      }

      selectedDays.sort();
    });
  }

  void _save() {
    final title = titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a schedule name.')),
      );
      return;
    }

    if (selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day.')),
      );
      return;
    }

    final startMinutes = selectedTime.hour * 60 + selectedTime.minute;

    final endMinutes = selectedEndTime.hour * 60 + selectedEndTime.minute;

    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }

    final existing = widget.existing;

    final item = ScheduleItem(
      id: existing?.id ?? 0,
      title: title,
      time: selectedTime,
      endTime: selectedEndTime,
      repeatDays: List<int>.from(selectedDays),

      // Preserve imported i-Ma'luum information.
      importKey: existing?.importKey,
      courseCode: existing?.courseCode,
      courseName: existing?.courseName,
      venue: existing?.venue,
      lecturer: existing?.lecturer,
      section: existing?.section,
      semester: existing?.semester,
    );

    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Schedule' : 'Edit Schedule'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: widget.existing == null,
              decoration: const InputDecoration(
                labelText: 'Schedule name',
                hintText: 'e.g. Study',
              ),
            ),

            const SizedBox(height: 16),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: const Text('Start time'),
              subtitle: Text(formatTimeOfDay(selectedTime)),
              onTap: _pickStartTime,
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.timelapse_outlined),
              title: const Text('End time'),
              subtitle: Text(formatTimeOfDay(selectedEndTime)),
              onTap: _pickEndTime,
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
              runSpacing: 4,
              children: List.generate(7, (index) {
                final day = index + 1;
                final selected = selectedDays.contains(day);

                return FilterChip(
                  label: Text(names[index]),
                  selected: selected,
                  onSelected: (value) {
                    _toggleDay(day, value);
                  },
                );
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
