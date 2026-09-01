class UserTransaction {
  final int id;
  final int vehicleId;
  final String plateNumber;
  final String stationName;
  final String stationRegion;
  final String fuelType;
  final double liters;
  final double amount;
  final double? unitPrice;
  final DateTime? pumpedAt;
  final String status;

  const UserTransaction({
    required this.id,
    required this.vehicleId,
    required this.plateNumber,
    required this.stationName,
    required this.stationRegion,
    required this.fuelType,
    required this.liters,
    required this.amount,
    required this.unitPrice,
    required this.pumpedAt,
    required this.status,
  });

  factory UserTransaction.fromJson(Map<String, dynamic> json) {
    return UserTransaction(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,

      vehicleId: int.tryParse('${json['vehicle_id'] ?? 0}') ?? 0,

      plateNumber: '${json['plate_number'] ?? '-'}',

      stationName: '${json['station_name'] ?? 'Unknown Station'}',

      stationRegion: '${json['station_region'] ?? '-'}',

      fuelType: '${json['fuel_type'] ?? '-'}',

      liters: double.tryParse('${json['liters_pumped'] ?? 0}') ?? 0.0,

      amount: double.tryParse('${json['amount_paid'] ?? 0}') ?? 0.0,

      unitPrice:
          json['unit_price'] == null
              ? null
              : double.tryParse('${json['unit_price']}'),

      pumpedAt:
          json['pumped_at'] == null
              ? null
              : DateTime.tryParse('${json['pumped_at']}'),

      status: '${json['sync_status'] ?? '-'}',
    );
  }
}
