import 'package:flutter_test/flutter_test.dart';
import 'package:lifezen_app/services/imaluum/imaluum_timetable.dart';

void main() {
  const parser = ImaluumTimetableParser();

  test('parses metadata and expands a multi-day i-Ma\'luum meeting', () {
    final meetings = parser.parseTables([
      {
        'headers': ['Course Code', 'Course Name', 'Section', 'Day', 'Time', 'Venue', 'Lecturer', 'Semester'],
        'rows': [
          ['CSC 1234', 'Data Structures', '2', 'Mon / Wed', '9:00 AM - 10:20 AM', 'E0-01', 'Dr Noor', '1 2026/2027'],
        ],
      },
    ]);

    expect(meetings, hasLength(2));
    expect(meetings.first.courseCode, 'CSC 1234');
    expect(meetings.first.courseName, 'Data Structures');
    expect(meetings.first.section, '2');
    expect(meetings.first.venue, 'E0-01');
    expect(meetings.first.lecturer, 'Dr Noor');
    expect(meetings.first.start.hour, 9);
    expect(meetings.first.end.minute, 20);
    expect(meetings.map((item) => item.day), containsAll([DateTime.monday, DateTime.wednesday]));
  });

  test('deduplicates an identical rendered class meeting', () {
    final source = {
      'headers': ['Course', 'Day', 'Time'],
      'rows': [
        ['ENG 1001', 'Friday', '14:00 - 16:00'],
        ['ENG 1001', 'Friday', '14:00 - 16:00'],
      ],
    };
    final meetings = parser.parseTables([source]);
    expect(meetings, hasLength(1));
    expect(meetings.single.start.hour, 14);
    expect(meetings.single.end.hour, 16);
  });

  test('ignores a table that is not a timetable', () {
    expect(parser.parseTables([
      {'headers': ['Name', 'Email'], 'rows': [['Student', 'student@example.com']]},
    ]), isEmpty);
  });
}
