import 'package:flutter/material.dart';

class ScheduleItem {
  final int id;
  String title;
  TimeOfDay time;
  TimeOfDay endTime;
  List<int> repeatDays;

  ScheduleItem({
    required this.id,
    required this.title,
    required this.time,
    required this.endTime,
    required this.repeatDays,
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
    );
  }
}
