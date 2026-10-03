class SavingsGoal {
  String id;
  String name;
  double targetAmount;
  double currentAmount;
  String? imagePath;

  SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.imagePath,
  });

  double get progress {
    if (targetAmount <= 0) {
      return 0;
    }

    return (currentAmount / targetAmount).clamp(0.0, 1.0).toDouble();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'imagePath': imagePath,
    };
  }

  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      id:
          map['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: map['name'] as String? ?? '',
      targetAmount: (map['targetAmount'] as num?)?.toDouble() ?? 0,
      currentAmount: (map['currentAmount'] as num?)?.toDouble() ?? 0,
      imagePath: map['imagePath'] as String?,
    );
  }
}
