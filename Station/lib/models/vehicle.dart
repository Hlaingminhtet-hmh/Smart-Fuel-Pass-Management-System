class Vehicle {
  final int id;
  final String plateNumber;
  final String vehicleType;
  final String fuelType;

  const Vehicle({
    required this.id,
    required this.plateNumber,
    required this.vehicleType,
    required this.fuelType,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      plateNumber: json['plate_number']?.toString() ??
          json['plate']?.toString() ?? '',
      vehicleType: json['vehicle_type']?.toString() ?? '',
      fuelType: json['fuel_type']?.toString() ??
          json['fuel']?.toString() ?? '—',
    );
  }
}
