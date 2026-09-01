class FuelQuota {
  final double weeklyQuota;
  final double usedThisWeek;
  final double remaining;
  final bool canFuel;
  final String week;

  const FuelQuota({
    required this.weeklyQuota,
    required this.usedThisWeek,
    required this.remaining,
    required this.canFuel,
    required this.week,
  });

  factory FuelQuota.fromJson(Map<String, dynamic> json) {
    double number(dynamic value) =>
        double.tryParse(value?.toString() ?? '') ?? 0;

    return FuelQuota(
      weeklyQuota: number(json['weekly_quota']),
      usedThisWeek: number(json['used_this_week']),
      remaining: number(json['remaining']),
      canFuel: json['can_fuel'] == true,
      week: json['week']?.toString() ?? '',
    );
  }
}
