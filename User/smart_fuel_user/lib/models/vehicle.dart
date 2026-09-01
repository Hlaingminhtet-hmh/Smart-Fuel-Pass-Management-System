class UserVehicle {
  final int id;
  final String plateNumber;
  final String vehicleType;
  final String fuelType;
  final String? engineCapacity;
  final double weeklyQuota;
  final double usedThisWeek;
  final double remaining;
  final String? qrImage;

  const UserVehicle({
    required this.id,
    required this.plateNumber,
    required this.vehicleType,
    required this.fuelType,
    required this.engineCapacity,
    required this.weeklyQuota,
    required this.usedThisWeek,
    required this.remaining,
    required this.qrImage,
  });

  factory UserVehicle.fromJson(Map<String, dynamic> j) {
    final q = Map<String, dynamic>.from(j['quota'] ?? const {});
    return UserVehicle(
      id: int.tryParse('${j['id'] ?? 0}') ?? 0,
      plateNumber: '${j['plate_number'] ?? ''}',
      vehicleType: '${j['vehicle_type'] ?? ''}',
      fuelType: '${j['fuel_type'] ?? 'petrol_92'}',
      engineCapacity: j['engine_capacity']?.toString(),
      weeklyQuota:
          double.tryParse('${q['weekly_quota'] ?? j['weekly_quota'] ?? 0}') ??
          0,
      usedThisWeek: double.tryParse('${q['used_this_week'] ?? 0}') ?? 0,
      remaining: double.tryParse('${q['remaining'] ?? 0}') ?? 0,
      qrImage: j['qr_code_image']?.toString(),
    );
  }
}
