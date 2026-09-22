import 'package:flutter/material.dart';

class ScheduleItem {
  final int id;
  String title;
  TimeOfDay time;
  List<int> repeatDays;

  ScheduleItem({
    required this.id,
    required this.title,
    required this.time,
    required this.repeatDays,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'hour': time.hour,
      'minute': time.minute,
      'repeatDays': repeatDays,
    };
  }

  factory ScheduleItem.fromMap(Map<String, dynamic> map) {
    return ScheduleItem(
      id: map['id'] as int,
      title: map['title'] as String,
      time: TimeOfDay(
        hour: map['hour'] as int,
        minute: map['minute'] as int,
      ),
      repeatDays: List<int>.from(map['repeatDays'] ?? []),
    );
  }
}
