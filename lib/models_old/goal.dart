class Goal {
  final String name;
  final double targetAmount;
  final double? monthlySaving;
  final int? monthsToTarget;

  const Goal({
    required this.name,
    required this.targetAmount,
    this.monthlySaving,
    this.monthsToTarget,
  });
}