import 'package:flutter/material.dart';

String formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

String formatDateTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  return '${formatDate(date)} $hour:$minute';
}

/// Human label for a reminder lead time.
/// `null` (or negative) means no reminder.
String formatReminderLabel(int? minutes, {int? fallbackMinutes}) {
  final value = minutes ?? fallbackMinutes;
  if (minutes != null && minutes < 0) return 'None';
  if (value == null) return 'Default';
  if (value < 0) return 'None';
  if (value == 0) return 'At time';
  if (value < 60) return '$value min before';
  if (value % 1440 == 0) {
    final days = value ~/ 1440;
    return days == 1 ? '1 day before' : '$days days before';
  }
  if (value % 60 == 0) {
    final hours = value ~/ 60;
    return hours == 1 ? '1 hour before' : '$hours hours before';
  }
  final hours = value ~/ 60;
  final mins = value % 60;
  return '${hours}h ${mins}m before';
}

/// Preset + custom reminder picker shared by tasks and schedule.
///
/// Behavior:
/// - Task mode (allowUseDefault true): value == null means smart default
///   (none / 9 AM due / 10 min before scheduled).
/// - Schedule mode (allowUseDefault false): concrete value, default 10.
/// - value == -1: no reminder. value >= 0: minutes before
///   (0 = at time / 9 AM sharp for due-only tasks).
class ReminderPicker extends StatelessWidget {
  const ReminderPicker({
    super.key,
    required this.value,
    this.smartDueDate,
    this.smartDoAt,
    this.defaultMinutes = 10,
    required this.onChanged,
    this.allowUseDefault = true,
  });

  final int? value;
  final DateTime? smartDueDate;
  final DateTime? smartDoAt;
  final int defaultMinutes;
  final ValueChanged<int?> onChanged;
  final bool allowUseDefault;

  /// Slim sheet presets only; anything else goes through Custom.
  static const List<int> presets = [0, 10, 30, 60];

  /// Marker values that never reach onChanged.
  static const int _smartSentinel = -999998;
  static const int _customSentinel = -999999;

  String _smartLabel() {
    if (smartDoAt != null) return '10 min before scheduled time';
    if (smartDueDate != null) return '9:00 AM on due date';
    return 'No notification';
  }

  String _currentLabel() {
    if (value == null) return 'Smart: ${_smartLabel()}';
    if (value! < 0) return 'None';
    return formatReminderLabel(value);
  }

  Future<void> _pickCustom(BuildContext context) async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => const _CustomReminderDialog(),
    );
    if (result != null) onChanged(result);
  }

  Future<void> _openSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final options = <int>[
          if (allowUseDefault) _smartSentinel,
          -1,
          ...presets,
        ];
        // A saved custom value stays selectable even if not a preset.
        final isCustom =
            value != null && value! >= 0 && !presets.contains(value);
        final group = value == null
            ? _smartSentinel
            : (value! >= 0 && !presets.contains(value)
                ? _customSentinel
                : value);
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ListTile(
                  title: Text(
                    'Reminder',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                RadioGroup<int>(
                  groupValue: group,
                  onChanged: (v) => Navigator.of(sheetContext).pop(v),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final option in options)
                        RadioListTile<int>(
                          value: option,
                          title: Text(
                            option == _smartSentinel
                                ? 'Smart default'
                                : option == -1
                                    ? 'None'
                                    : formatReminderLabel(option),
                          ),
                          subtitle: option == _smartSentinel
                              ? Text(
                                  _smartLabel(),
                                  style: TextStyle(
                                    color: Theme.of(sheetContext)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                )
                              : null,
                        ),
                      if (isCustom)
                        RadioListTile<int>(
                          value: _customSentinel,
                          title: Text(formatReminderLabel(value)),
                          subtitle: const Text('Custom'),
                        ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.tune),
                  title: const Text('Custom...'),
                  subtitle: const Text('Pick any amount up to 7 days'),
                  onTap: () => Navigator.of(sheetContext).pop(_customSentinel),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
    if (!context.mounted) return;
    if (selected == _customSentinel) {
      await _pickCustom(context);
    } else if (selected == _smartSentinel) {
      onChanged(null);
    } else if (selected != null) {
      onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.notifications_outlined),
      title: const Text('Reminder'),
      subtitle: Text(_currentLabel()),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _openSheet(context),
    );
  }
}

class _CustomReminderDialog extends StatefulWidget {
  const _CustomReminderDialog();

  @override
  State<_CustomReminderDialog> createState() => _CustomReminderDialogState();
}

class _CustomReminderDialogState extends State<_CustomReminderDialog> {
  final _controller = TextEditingController(text: '15');
  String _unit = 'minutes';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = int.tryParse(_controller.text.trim());
    if (amount == null || amount < 0) return;
    final minutes = switch (_unit) {
      'hours' => amount * 60,
      'days' => amount * 1440,
      _ => amount,
    };
    // Cap at 7 days so weekly schedules stay sane.
    Navigator.of(context).pop(minutes.clamp(0, 10080));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom reminder'),
      content: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _unit,
            items: const [
              DropdownMenuItem(value: 'minutes', child: Text('min')),
              DropdownMenuItem(value: 'hours', child: Text('hours')),
              DropdownMenuItem(value: 'days', child: Text('days')),
            ],
            onChanged: (v) => setState(() => _unit = v ?? 'minutes'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}


String formatTimeOfDay(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';

  return '$hour:$minute $period';
}

String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);

  if (hours == 0) {
    return '${minutes}m';
  }

  return '${hours}h ${minutes}m';
}

String sleepQuality(Duration duration) {
  final hours = duration.inMinutes / 60;

  if (hours >= 7 && hours <= 9) {
    return 'Good';
  }

  if (hours >= 6) {
    return 'Okay';
  }

  return 'Low';
}

IconData categoryIcon(String category) {
  switch (category) {
    case 'Food':
      return Icons.restaurant_outlined;
    case 'Transport':
      return Icons.directions_bus_outlined;
    case 'Education':
      return Icons.school_outlined;
    case 'Entertainment':
      return Icons.movie_outlined;
    case 'Shopping':
      return Icons.shopping_bag_outlined;
    case 'Bills':
      return Icons.receipt_long_outlined;
    case 'Transfer':
      return Icons.swap_horiz_outlined;
    default:
      return Icons.more_horiz;
  }
}

Future<DateTime?> pickDateTime(BuildContext context, DateTime initial) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2020),
    lastDate: DateTime(2035),
  );

  if (date == null) {
    return null;
  }

  if (!context.mounted) {
    return null;
  }

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );

  if (time == null) {
    return null;
  }

  if (!context.mounted) {
    return null;
  }

  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
