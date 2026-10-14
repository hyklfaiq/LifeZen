class Task {
  final int id;
  String title;
  DateTime? dueDate;
  DateTime? doAt;

  /// Minutes before [notifyAt] to remind.
  /// `-1` (or null resolved to none) = no notification.
  /// `null` = use the smart default for this task's type.
  int? reminderMinutes;
  bool completed;

  Task({
    required this.id,
    required this.title,
    this.dueDate,
    this.doAt,
    this.reminderMinutes,
    this.completed = false,
  });

  /// Suggested default notification for a task type:
  /// - no date at all            → none (-1)
  /// - scheduled time present    → 10 min before that time
  /// - due date only (all-day)   → 9:00 AM on the due date (lead = 0,
  ///   anchored at 9 AM — see [notifyAt])
  static int smartDefaultReminder({DateTime? dueDate, DateTime? doAt}) {
    if (dueDate == null && doAt == null) return -1;
    if (doAt != null) return 10;
    return 0;
  }

  /// Effective lead time in minutes, resolving null to the smart default.
  int get effectiveReminderMinutes =>
      reminderMinutes ?? smartDefaultReminder(dueDate: dueDate, doAt: doAt);

  /// The moment a notification should be anchored to.
  /// - scheduled time present → that exact time
  /// - due date only          → 9:00 AM on the due date
  /// - neither                → null (no notification)
  DateTime? get notifyAt {
    if (doAt != null) return doAt;
    if (dueDate != null) {
      return DateTime(dueDate!.year, dueDate!.month, dueDate!.day, 9, 0);
    }
    return null;
  }

  /// True when neither a due date nor a do-at time is set.
  /// Such tasks "float" like Google Tasks without a date.
  bool get isFloating => dueDate == null && doAt == null;

  /// Date used for calendar dots / grouping (date part only matters).
  DateTime? get displayDate => dueDate ?? doAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      if (doAt != null) 'doAt': doAt!.toIso8601String(),
      if (reminderMinutes != null) 'reminderMinutes': reminderMinutes,
      'completed': completed,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String && value.isEmpty) return null;
      try {
        return DateTime.parse(value as String);
      } catch (_) {
        return null;
      }
    }

    int? parseReminder(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    // Backward compat: old tasks always had a non-null dueDate string.
    // New tasks may omit both dates (floating).
    return Task(
      id: map['id'] as int,
      title: map['title'] as String? ?? '',
      dueDate: parseDate(map['dueDate']),
      doAt: parseDate(map['doAt']),
      reminderMinutes: parseReminder(map['reminderMinutes']),
      completed: map['completed'] ?? false,
    );
  }
}

