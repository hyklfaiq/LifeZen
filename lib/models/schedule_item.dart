import 'package:flutter/material.dart';

class ScheduleItem {
  final int id;
  String title;
  TimeOfDay time;
  TimeOfDay endTime;
  List<int> repeatDays;
  final String? importKey;
  final String? courseCode;
  final String? courseName;
  final String? venue;
  final String? lecturer;
  final String? section;
  final String? semester;

  ScheduleItem({
    required this.id,
    required this.title,
    required this.time,
    required this.endTime,
    required this.repeatDays,
    this.importKey,
    this.courseCode,
    this.courseName,
    this.venue,
    this.lecturer,
    this.section,
    this.semester,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'hour': time.hour,
      'minute': time.minute,
      'endHour': endTime.hour,
      'endMinute': endTime.minute,
      'repeatDays': repeatDays,
      if (importKey != null) 'importKey': importKey,
      if (courseCode != null) 'courseCode': courseCode,
      if (courseName != null) 'courseName': courseName,
      if (venue != null) 'venue': venue,
      if (lecturer != null) 'lecturer': lecturer,
      if (section != null) 'section': section,
      if (semester != null) 'semester': semester,
    };
  }

  factory ScheduleItem.fromMap(Map<String, dynamic> map) {
    final startTime = TimeOfDay(
      hour: map['hour'] as int,
      minute: map['minute'] as int,
    );

    final endTimeValue = map['endHour'] != null || map['endMinute'] != null
        ? TimeOfDay(
            hour: map['endHour'] ?? startTime.hour,
            minute: map['endMinute'] ?? startTime.minute,
          )
        : TimeOfDay(
            hour: startTime.hour == 23 ? 23 : startTime.hour + 1,
            minute: startTime.minute,
          );

    return ScheduleItem(
      id: map['id'] as int,
      title: map['title'] as String,
      time: startTime,
      endTime: endTimeValue,
      repeatDays: List<int>.from(map['repeatDays'] ?? []),
      importKey: map['importKey'] as String?,
      courseCode: map['courseCode'] as String?,
      courseName: map['courseName'] as String?,
      venue: map['venue'] as String?,
      lecturer: map['lecturer'] as String?,
      section: map['section']?.toString(),
      semester: map['semester'] as String?,
    );
  }
}
