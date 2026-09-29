import 'package:flutter/material.dart';

/// A portal-neutral meeting obtained from the i-Ma'luum timetable page.
/// Keeping this model separate makes portal markup changes local to this folder.
class ImaluumMeeting {
  const ImaluumMeeting({
    required this.courseCode,
    required this.courseName,
    required this.day,
    required this.start,
    required this.end,
    this.venue,
    this.lecturer,
    this.section,
    this.semester,
  });

  final String courseCode;
  final String courseName;
  final int day;
  final TimeOfDay start;
  final TimeOfDay end;
  final String? venue;
  final String? lecturer;
  final String? section;
  final String? semester;

  String get importKey => [
        courseCode.toUpperCase(),
        section ?? '',
        semester ?? '',
        day,
        _minutes(start),
        _minutes(end),
        venue?.toUpperCase() ?? '',
      ].join('|');

  static int _minutes(TimeOfDay value) => value.hour * 60 + value.minute;
}

/// Parses the visible table text, not credentials, cookies, or raw HTML.
class ImaluumTimetableParser {
  const ImaluumTimetableParser();

  List<ImaluumMeeting> parseTables(List<Map<String, dynamic>> tables) {
    final results = <ImaluumMeeting>[];
    for (final table in tables) {
      final headers = List<String>.from(table['headers'] ?? [])
          .map(_normalise)
          .toList();
      final rows = List<dynamic>.from(table['rows'] ?? []);
      final courseIndex = _column(headers, ['course code', 'course']);
      final dayIndex = _column(headers, ['day']);
      final timeIndex = _column(headers, ['time']);
      if (courseIndex == null || dayIndex == null || timeIndex == null) continue;

      for (final rawRow in rows) {
        final row = List<String>.from(rawRow as List);
        if (row.length <= [courseIndex, dayIndex, timeIndex].reduce((a, b) => a > b ? a : b)) {
          continue;
        }
        final course = row[courseIndex].trim();
        final days = _days(row[dayIndex]);
        final period = _timeRange(row[timeIndex]);
        if (course.isEmpty || days.isEmpty || period == null) continue;
        final titleIndex = _column(headers, ['course name', 'title', 'subject name']);
        final sectionIndex = _column(headers, ['section', 'sect']);
        final venueIndex = _column(headers, ['venue', 'room', 'location']);
        final lecturerIndex = _column(headers, ['lecturer', 'instructor', 'staff']);
        final semesterIndex = _column(headers, ['semester', 'session', 'sem year']);
        for (final day in days) {
          results.add(ImaluumMeeting(
            courseCode: course,
            courseName: _value(row, titleIndex) ?? course,
            day: day,
            start: period.$1,
            end: period.$2,
            section: _value(row, sectionIndex),
            venue: _value(row, venueIndex),
            lecturer: _value(row, lecturerIndex),
            semester: _value(row, semesterIndex) ?? (table['semester'] as String?),
          ));
        }
      }
    }
    final unique = <String, ImaluumMeeting>{};
    for (final item in results) {
      unique[item.importKey] = item;
    }
    return unique.values.toList();
  }

  int? _column(List<String> headers, List<String> candidates) {
    for (final candidate in candidates) {
      final index = headers.indexWhere((header) => header == candidate || header.contains(candidate));
      if (index >= 0) return index;
    }
    return null;
  }

  String? _value(List<String> row, int? index) {
    if (index == null || index >= row.length) return null;
    final value = row[index].trim();
    return value.isEmpty || value == '-' ? null : value;
  }

  List<int> _days(String input) {
    const mapping = {
      'monday': 1, 'mon': 1, 'tuesday': 2, 'tue': 2, 'tues': 2,
      'wednesday': 3, 'wed': 3, 'thursday': 4, 'thu': 4, 'thur': 4, 'thurs': 4,
      'friday': 5, 'fri': 5, 'saturday': 6, 'sat': 6, 'sunday': 7, 'sun': 7,
    };
    final lower = input.toLowerCase();
    return mapping.entries.where((entry) => RegExp('\\b${entry.key}\\b').hasMatch(lower)).map((entry) => entry.value).toSet().toList();
  }

  (TimeOfDay, TimeOfDay)? _timeRange(String input) {
    final matches = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(a\.?m\.?|p\.?m\.?)?', caseSensitive: false).allMatches(input).toList();
    if (matches.length < 2) return null;
    TimeOfDay? parse(RegExpMatch match) {
      var hour = int.parse(match.group(1)!);
      final minute = int.tryParse(match.group(2) ?? '') ?? 0;
      final suffix = (match.group(3) ?? '').toLowerCase().replaceAll('.', '');
      if (suffix == 'pm' && hour < 12) hour += 12;
      if (suffix == 'am' && hour == 12) hour = 0;
      return hour <= 23 && minute <= 59 ? TimeOfDay(hour: hour, minute: minute) : null;
    }
    final start = parse(matches[0]);
    final end = parse(matches[1]);
    if (start == null || end == null || ImaluumMeeting._minutes(end) <= ImaluumMeeting._minutes(start)) return null;
    return (start, end);
  }

  String _normalise(String value) => value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Selects only meetings that have not already been saved by an earlier import.
/// The schedule layer persists these keys; no portal state is kept.
List<ImaluumMeeting> excludeImportedMeetings(
  Iterable<ImaluumMeeting> meetings,
  Iterable<String> existingImportKeys,
) {
  final keys = existingImportKeys.toSet();
  return meetings.where((meeting) => keys.add(meeting.importKey)).toList();
}
