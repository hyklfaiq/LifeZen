class Task {
  final int id;
  String title;
  DateTime dueDate;
  bool completed;

  Task({
    required this.id,
    required this.title,
    required this.dueDate,
    this.completed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'dueDate': dueDate.toIso8601String(),
      'completed': completed,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int,
      title: map['title'] as String,
      dueDate: DateTime.parse(map['dueDate'] as String),
      completed: map['completed'] ?? false,
    );
  }
}
