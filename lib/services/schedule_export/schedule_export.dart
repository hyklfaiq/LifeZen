import '../../models/models.dart';

/// Builders for schedule export formats (ICS calendar, CSV spreadsheet).
class ScheduleExport {
  const ScheduleExport._();

  static const _dayNames = <int, String>{
    DateTime.monday: 'Monday',
    DateTime.tuesday: 'Tuesday',
    DateTime.wednesday: 'Wednesday',
    DateTime.thursday: 'Thursday',
    DateTime.friday: 'Friday',
    DateTime.saturday: 'Saturday',
    DateTime.sunday: 'Sunday',
  };

  static const _icsDays = <int, String>{
    DateTime.monday: 'MO',
    DateTime.tuesday: 'TU',
    DateTime.wednesday: 'WE',
    DateTime.thursday: 'TH',
    DateTime.friday: 'FR',
    DateTime.saturday: 'SA',
    DateTime.sunday: 'SU',
  };

  /// Human-readable day name for [weekday] (DateTime.monday..sunday).
  static String dayName(int weekday) =>
      _dayNames[weekday] ?? 'Day $weekday';

  /// "x:xx AM" style label for CSV readability.
  static String clockLabel(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  static String displayTitle(ScheduleItem item) {
    final code = item.courseCode?.trim() ?? '';
    final name = item.courseName?.trim() ?? '';
    if (code.isNotEmpty && name.isNotEmpty) return '$code $name';
    if (name.isNotEmpty) return name;
    if (code.isNotEmpty) return code;
    return item.title;
  }

  /// Next calendar date (including today) falling on [weekday].
  static DateTime nextWeekday(DateTime from, int weekday) {
    var date = DateTime(from.year, from.month, from.day);
    var delta = (weekday - date.weekday) % 7;
    if (delta < 0) delta += 7;
    return date.add(Duration(days: delta));
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  /// Local floating ICS date-time: YYYYMMDDTHHMMSS (no Z suffix).
  static String icsLocal(DateTime date, int hour, int minute) =>
      '${date.year}${_two(date.month)}${_two(date.day)}'
      'T${_two(hour)}${_two(minute)}00';

  /// UTC ICS timestamp for DTSTAMP.
  static String icsUtcNow() {
    final now = DateTime.now().toUtc();
    return '${now.year}${_two(now.month)}${_two(now.day)}'
        'T${_two(now.hour)}${_two(now.minute)}${_two(now.second)}Z';
  }

  static String escapeIcs(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll(';', '\\;')
      .replaceAll(',', '\\,')
      .replaceAll('\n', '\\n');

  static String escapeCsv(String value) {
    if (value.contains(RegExp(r'["\n,]'))) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static String? icsDay(int weekday) => _icsDays[weekday];

  /// Builds a weekly-recurring ICS calendar for [schedule].
  /// imports cleanly into Google / Apple / Outlook calendars.
  static String buildIcs(List<ScheduleItem> schedule) {
    final buffer = StringBuffer()
      ..writeln('BEGIN:VCALENDAR')
      ..writeln('VERSION:2.0')
      ..writeln('PRODID:-//LifeZen//Schedule//EN')
      ..writeln('CALSCALE:GREGORIAN');

    final today = DateTime.now();
    final stamp = icsUtcNow();

    for (final item in schedule) {
      final days = item.repeatDays.toSet().toList()..sort();
      for (final day in days) {
        final date = nextWeekday(today, day);
        final byday = icsDay(day) ?? 'MO';
        final title = displayTitle(item);
        final descriptionParts = <String>[
          if ((item.lecturer?.trim().isNotEmpty ?? false))
            'Lecturer: ${item.lecturer!.trim()}',
          if ((item.section?.trim().isNotEmpty ?? false))
            'Section: ${item.section!.trim()}',
          if ((item.semester?.trim().isNotEmpty ?? false))
            'Semester: ${item.semester!.trim()}',
        ];

        buffer
          ..writeln('BEGIN:VEVENT')
          ..writeln(
            'UID:${escapeIcs(item.importKey ?? 'lifezen-${item.id}-$day')}'
            '@lifezen',
          )
          ..writeln('DTSTAMP:$stamp')
          ..writeln(
            'DTSTART:${icsLocal(date, item.time.hour, item.time.minute)}',
          )
          ..writeln(
            'DTEND:${icsLocal(date, item.endTime.hour, item.endTime.minute)}',
          )
          ..writeln('RRULE:FREQ=WEEKLY;BYDAY=$byday')
          ..writeln('SUMMARY:${escapeIcs(title)}');
        if ((item.venue?.trim().isNotEmpty ?? false)) {
          buffer.writeln('LOCATION:${escapeIcs(item.venue!.trim())}');
        }
        if (descriptionParts.isNotEmpty) {
          buffer.writeln(
            'DESCRIPTION:${escapeIcs(descriptionParts.join(' | '))}',
          );
        }
        buffer.writeln('END:VEVENT');
      }
    }

    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
  }

  /// Builds a spreadsheet-friendly CSV for [schedule].
  ///
  /// One row per item x repeat day, sorted by day then start time.
  static String buildCsv(List<ScheduleItem> schedule) {
    final buffer = StringBuffer()
      ..writeln(
        'Subject,Course Code,Course Name,Day,Start,End,Venue,'
        'Lecturer,Section,Semester',
      );

    final rows = <_ExportRow>[];
    for (final item in schedule) {
      final days = item.repeatDays.toSet().toList()..sort();
      for (final day in days) {
        rows.add(_ExportRow(day: day, item: item));
      }
    }
    rows.sort((a, b) {
      final dayOrder = a.day.compareTo(b.day);
      if (dayOrder != 0) return dayOrder;
      final startA = a.item.time.hour * 60 + a.item.time.minute;
      final startB = b.item.time.hour * 60 + b.item.time.minute;
      return startA.compareTo(startB);
    });

    for (final row in rows) {
      final item = row.item;
      buffer.writeln([
        escapeCsv(item.title),
        escapeCsv(item.courseCode ?? ''),
        escapeCsv(item.courseName ?? ''),
        escapeCsv(dayName(row.day)),
        escapeCsv(clockLabel(item.time.hour, item.time.minute)),
        escapeCsv(clockLabel(item.endTime.hour, item.endTime.minute)),
        escapeCsv(item.venue ?? ''),
        escapeCsv(item.lecturer ?? ''),
        escapeCsv(item.section ?? ''),
        escapeCsv(item.semester ?? ''),
      ].join(','));
    }

    return buffer.toString();
  }
}

class _ExportRow {
  const _ExportRow({required this.day, required this.item});

  final int day;
  final ScheduleItem item;
}
