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
      final courseIndex = _column(headers, ['course code', 'course', 'code']);
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
        final titleIndex = _column(headers, ['course name', 'title', 'subject name', 'name']);
        final sectionIndex = _column(headers, ['section', 'sect', 'sec']);
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
            venue: _venue(_value(row, venueIndex)),
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

String _venue(String? value) {
    if (value == null) {
      return 'No venue yet';
    }

    final cleaned = value
        .replaceFirst(
          RegExp(r'^(?:a\.?m\.?|p\.?m\.?)\s+', caseSensitive: false),
          '',
        )
        .trim();

    if (cleaned.isEmpty || cleaned == '-') {
      return 'No venue yet';
    }

    return cleaned;
  }

List<int> _days(String input) {
    final value = input.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');

    final days = <int>{};

    // Full day names / normal abbreviations.
    const words = {
      'MONDAY': 1,
      'MON': 1,
      'TUESDAY': 2,
      'TUES': 2,
      'TUE': 2,
      'WEDNESDAY': 3,
      'WED': 3,
      'THURSDAY': 4,
      'THURS': 4,
      'THUR': 4,
      'THU': 4,
      'FRIDAY': 5,
      'FRI': 5,
      'SATURDAY': 6,
      'SAT': 6,
      'SUNDAY': 7,
      'SUN': 7,
    };

    // First handle normal words such as MON, TUE, WED.
    var remaining = value;

    final sortedWords = words.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final word in sortedWords) {
      if (remaining.contains(word)) {
        days.add(words[word]!);
        remaining = remaining.replaceFirst(word, '');
      }
    }

    // Handle compact IIUM-style combinations.
    //
    // M    = Monday
    // T    = Tuesday
    // W    = Wednesday
    // TH   = Thursday
    // F    = Friday
    // S    = Saturday
    // SU   = Sunday
    //
    // Examples:
    // MTWTH
    // MWF
    // TTH
    // T-TH
    // MWTH
    while (remaining.isNotEmpty) {
      if (remaining.startsWith('TH')) {
        days.add(4);
        remaining = remaining.substring(2);
      } else if (remaining.startsWith('SU')) {
        days.add(7);
        remaining = remaining.substring(2);
      } else {
        switch (remaining[0]) {
          case 'M':
            days.add(1);
            break;
          case 'T':
            days.add(2);
            break;
          case 'W':
            days.add(3);
            break;
          case 'F':
            days.add(5);
            break;
          case 'S':
            days.add(6);
            break;
        }

        remaining = remaining.substring(1);
      }
    }

    return days.toList()..sort();
  }

  (TimeOfDay, TimeOfDay)? _timeRange(String input) {
    final dotted = RegExp(r'(\d{1,2})[.:](\d{2})\s*(?:-|–|to)\s*(\d{1,2})(?:[.:](\d{2}))?\s*(a\.?m\.?|p\.?m\.?)?', caseSensitive: false).firstMatch(input);
    if (dotted != null) {
      var startHour = int.parse(dotted.group(1)!);
      var endHour = int.parse(dotted.group(3)!);
      final startMinute = int.parse(dotted.group(2)!);
      final endMinute = int.tryParse(dotted.group(4) ?? '') ?? 0;
      final suffix = (dotted.group(5) ?? '').toLowerCase().replaceAll('.', '');
      if (suffix == 'pm') {
        if (startHour < 12) startHour += 12;
        if (endHour < 12) endHour += 12;
      } else if (suffix == 'am') {
        if (startHour == 12) startHour = 0;
        if (endHour == 12) endHour = 0;
      }
      final start = TimeOfDay(hour: startHour, minute: startMinute);
      final end = TimeOfDay(hour: endHour, minute: endMinute);
      if (start.hour <= 23 && end.hour <= 23 &&
          ImaluumMeeting._minutes(end) > ImaluumMeeting._minutes(start)) {
        return (start, end);
      }
    }
    final compact = RegExp(r'\b(\d{2})(\d{2})\s*(?:-|–|to)\s*(\d{2})(\d{2})\b')
        .firstMatch(input);
    if (compact != null) {
      final start = TimeOfDay(
        hour: int.parse(compact.group(1)!),
        minute: int.parse(compact.group(2)!),
      );
      final end = TimeOfDay(
        hour: int.parse(compact.group(3)!),
        minute: int.parse(compact.group(4)!),
      );
      if (start.hour <= 23 && end.hour <= 23 &&
          ImaluumMeeting._minutes(end) > ImaluumMeeting._minutes(start)) {
        return (start, end);
      }
    }
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
