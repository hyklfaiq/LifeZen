import 'package:flutter/material.dart';

/// A meeting parsed from the i-Ma'luum timetable.
///
/// This model keeps portal data separate from the rest of the app, so
/// changes to the portal can be handled inside this folder.
class ImaluumMeeting {
  const ImaluumMeeting({
    required this.courseCode,
    required this.courseName,
    this.day,
    this.start,
    this.end,
    this.venue,
    this.lecturer,
    this.section,
    this.semester,
  });

  final String courseCode;
  final String courseName;

  /// These values are null when the meeting has no valid day or time.
  /// The schedule can then show it under "No fixed time".
  final int? day;
  final TimeOfDay? start;
  final TimeOfDay? end;

  final String? venue;
  final String? lecturer;
  final String? section;
  final String? semester;

  bool get hasTime => day != null && start != null && end != null;

  /// Creates a key used to identify meetings during timetable imports.
  String get importKey {
    if (!hasTime) {
      return [
        courseCode.toUpperCase(),
        section ?? '',
        semester ?? '',
        'notime',
        venue?.toUpperCase() ?? '',
      ].join('|');
    }

    return [
      courseCode.toUpperCase(),
      section ?? '',
      semester ?? '',
      day,
      _minutes(start!),
      _minutes(end!),
      venue?.toUpperCase() ?? '',
    ].join('|');
  }

  static int _minutes(TimeOfDay value) => value.hour * 60 + value.minute;
}

/// Reads timetable data from the visible table text.
/// It does not access portal credentials, cookies, or raw HTML.
class ImaluumTimetableParser {
  const ImaluumTimetableParser();

  List<ImaluumMeeting> parseTables(List<Map<String, dynamic>> tables) {
    final results = <ImaluumMeeting>[];

    for (final table in tables) {
      final headers = List<String>.from(
        table['headers'] ?? [],
      ).map(_normalise).toList();

      final rows = List<dynamic>.from(table['rows'] ?? []);

      final courseIndex = _column(headers, ['course code', 'course', 'code']);
      final dayIndex = _column(headers, ['day']);
      final timeIndex = _column(headers, ['time']);

      if (courseIndex == null || dayIndex == null || timeIndex == null) {
        continue;
      }

      // Find optional columns once for the current table.
      final titleIndex = _column(headers, [
        'course name',
        'title',
        'subject name',
        'name',
      ]);
      final sectionIndex = _column(headers, ['section', 'sect', 'sec']);
      final venueIndex = _column(headers, ['venue', 'room', 'location']);
      final lecturerIndex = _column(headers, [
        'lecturer',
        'instructor',
        'staff',
      ]);
      final semesterIndex = _column(headers, [
        'semester',
        'session',
        'sem year',
      ]);

      for (final rawRow in rows) {
        final row = List<String>.from(rawRow as List);

        // Skip repeated headers and separator rows.
        if (_looksLikeHeader(row)) {
          continue;
        }

        // Fill missing cells at the end of a row to keep column positions
        // aligned with the table headers.
        final aligned = _alignRow(row, headers.length);

        final lastRequiredIndex = [
          courseIndex,
          dayIndex,
          timeIndex,
        ].reduce((a, b) => a > b ? a : b);

        if (aligned.length <= lastRequiredIndex) {
          continue;
        }

        final course = aligned[courseIndex].trim();
        if (course.isEmpty) continue;

        final days = _days(aligned[dayIndex]);
        final period = _timeRange(aligned[timeIndex]);

        if (days.isNotEmpty && period != null) {
          for (final day in days) {
            results.add(
              ImaluumMeeting(
                courseCode: course,
                courseName: _value(aligned, titleIndex) ?? course,
                day: day,
                start: period.$1,
                end: period.$2,
                section: _value(aligned, sectionIndex),
                venue: _venue(_value(aligned, venueIndex)),
                lecturer: _lecturer(_value(aligned, lecturerIndex)),
                semester:
                    _value(aligned, semesterIndex) ??
                    (table['semester'] as String?),
              ),
            );
          }
        } else {
          // Keep subjects that have no usable day or time.
          // Rows with fewer than two filled cells are usually table
          // labels or other content, so they are skipped.
          final filled = aligned.where((cell) {
            final value = cell.trim();
            return value.isNotEmpty && value != '-';
          }).length;

          if (filled < 2) continue;

          results.add(
            ImaluumMeeting(
              courseCode: course,
              courseName: _value(aligned, titleIndex) ?? course,
              day: null,
              start: null,
              end: null,
              section: _value(aligned, sectionIndex),
              venue: _venue(_value(aligned, venueIndex)),
              lecturer: _lecturer(_value(aligned, lecturerIndex)),
              semester:
                  _value(aligned, semesterIndex) ??
                  (table['semester'] as String?),
            ),
          );
        }
      }
    }

    // Remove duplicate meetings before returning the results.
    final unique = <String, ImaluumMeeting>{};

    for (final item in results) {
      unique[item.importKey] = item;
    }

    return unique.values.toList();
  }

  int? _column(List<String> headers, List<String> candidates) {
    for (final candidate in candidates) {
      final index = headers.indexWhere(
        (header) => header == candidate || header.contains(candidate),
      );

      if (index >= 0) return index;
    }

    return null;
  }

  /// Adds empty cells to short rows so the column positions stay aligned.
  List<String> _alignRow(List<String> row, int width) {
    if (row.length >= width) return row;

    return [...row, ...List.filled(width - row.length, '')];
  }

  /// Checks whether a row is a repeated header or a separator.
  bool _looksLikeHeader(List<String> row) {
    final text = row.join(' ').toLowerCase();

    if (text.contains('course') &&
        text.contains('day') &&
        text.contains('time')) {
      return true;
    }

    if (row.isNotEmpty &&
        row.every((cell) {
          final value = cell.trim();

          return value.isEmpty ||
              RegExp(r'^[-\s\u2013\u2014]+$').hasMatch(value);
        })) {
      return true;
    }

    return false;
  }

  String? _value(List<String> row, int? index) {
    if (index == null || index >= row.length) return null;

    final value = row[index].trim();

    return value.isEmpty || value == '-' ? null : value;
  }

  String _venue(String? value) {
    if (value == null) return 'No venue yet';

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

  /// Combines lecturer names into one readable string.
  ///
  /// The portal may separate names using line breaks or semicolons.
  String? _lecturer(String? value) {
    if (value == null) return null;

    final parts = value
        .split(RegExp(r'[\n\r;]+'))
        .map((part) => part.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((part) => part.isNotEmpty && part != '-')
        .toList();

    if (parts.isEmpty) return null;

    return parts.join(', ');
  }

  List<int> _days(String input) {
    final value = input.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');

    final days = <int>{};

    // Full day names and common abbreviations.
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

    // Match longer day names first to avoid partial matches.
    var remaining = value;

    final sortedWords = words.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final word in sortedWords) {
      if (remaining.contains(word)) {
        days.add(words[word]!);
        remaining = remaining.replaceFirst(word, '');
      }
    }

    // Handle compact IIUM day combinations:
    // M = Monday, T = Tuesday, W = Wednesday, TH = Thursday,
    // F = Friday, S = Saturday, SU = Sunday.
    //
    // Examples: MTWTH, MWF, TTH, T-TH and MWTH.
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
    // Handles times such as 10:00 - 11:20 or 4.00 PM - 5.20 PM.
    final dotted = RegExp(
      r'(\d{1,2})[.:](\d{2})\s*(?:-|–|to)\s*'
      r'(\d{1,2})(?:[.:](\d{2}))?\s*'
      r'(a\.?m\.?|p\.?m\.?)?',
      caseSensitive: false,
    ).firstMatch(input);

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

      if (start.hour <= 23 &&
          end.hour <= 23 &&
          start.minute <= 59 &&
          end.minute <= 59 &&
          ImaluumMeeting._minutes(end) > ImaluumMeeting._minutes(start)) {
        return (start, end);
      }
    }

    // Handles compact times such as 1000 - 1120.
    final compact = RegExp(
      r'\b(\d{1,2})(\d{2})\s*(?:-|–|to)\s*'
      r'(\d{1,2})(\d{2})\b',
    ).firstMatch(input);

    if (compact != null) {
      final startHour = int.parse(compact.group(1)!);
      final startMinute = int.parse(compact.group(2)!);
      final endHour = int.parse(compact.group(3)!);
      final endMinute = int.parse(compact.group(4)!);

      if (startHour <= 23 &&
          endHour <= 23 &&
          startMinute <= 59 &&
          endMinute <= 59) {
        final start = TimeOfDay(hour: startHour, minute: startMinute);
        final end = TimeOfDay(hour: endHour, minute: endMinute);

        if (ImaluumMeeting._minutes(end) > ImaluumMeeting._minutes(start)) {
          return (start, end);
        }
      }
    }

    // Fallback for times such as 10 AM - 11 AM or 10 - 11.
    final matches = RegExp(
      r'(\d{1,2})(?::(\d{2}))?\s*'
      r'(a\.?m\.?|p\.?m\.?)?',
      caseSensitive: false,
    ).allMatches(input).toList();

    if (matches.length < 2) return null;

    TimeOfDay? parse(RegExpMatch match) {
      var hour = int.parse(match.group(1)!);
      final minute = int.tryParse(match.group(2) ?? '') ?? 0;

      final suffix = (match.group(3) ?? '').toLowerCase().replaceAll('.', '');

      if (suffix == 'pm' && hour < 12) hour += 12;
      if (suffix == 'am' && hour == 12) hour = 0;

      if (hour > 23 || minute > 59) return null;

      return TimeOfDay(hour: hour, minute: minute);
    }

    final start = parse(matches[0]);
    final end = parse(matches[1]);

    if (start == null || end == null) return null;

    if (ImaluumMeeting._minutes(end) <= ImaluumMeeting._minutes(start)) {
      return null;
    }

    return (start, end);
  }

  String _normalise(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

/// Removes meetings that have already been imported.
///
/// The schedule stores these keys so the same meeting is not added twice.
List<ImaluumMeeting> excludeImportedMeetings(
  Iterable<ImaluumMeeting> meetings,
  Iterable<String> existingImportKeys,
) {
  final keys = existingImportKeys.toSet();

  return meetings.where((meeting) => keys.add(meeting.importKey)).toList();
}
