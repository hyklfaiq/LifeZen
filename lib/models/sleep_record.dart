class SleepRecord {
  final int id;
  DateTime sleepTime;
  DateTime wakeTime;
  String? note;

  SleepRecord({
    required this.id,
    required this.sleepTime,
    required this.wakeTime,
    this.note,
  });

  Duration get duration => wakeTime.difference(sleepTime);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sleepTime': sleepTime.toIso8601String(),
      'wakeTime': wakeTime.toIso8601String(),
      'note': note,
    };
  }

  factory SleepRecord.fromMap(Map<String, dynamic> map) {
    return SleepRecord(
      id: map['id'] as int,
      sleepTime: DateTime.parse(map['sleepTime'] as String),
      wakeTime: DateTime.parse(map['wakeTime'] as String),
      note: map['note'] as String?,
    );
  }
}
