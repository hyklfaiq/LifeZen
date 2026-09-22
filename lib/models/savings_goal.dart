class SavingsGoal {
  String name;
  double targetAmount;
  double currentAmount;
  String? imagePath;

  SavingsGoal({
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.imagePath,
  });

  double get progress {
    if (targetAmount <= 0) return 0;

    return (currentAmount / targetAmount).clamp(0.0, 1.0).toDouble();
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'imagePath': imagePath,
    };
  }

  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      name: map['name'] as String,
      targetAmount: (map['targetAmount'] as num).toDouble(),
      currentAmount: (map['currentAmount'] as num).toDouble(),
      imagePath: map['imagePath'] as String?,
    );
  }
}
