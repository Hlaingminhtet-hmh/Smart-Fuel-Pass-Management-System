class StationTransaction {
  final int id;
  final int vehicleId;
  final int stationId;
  final double litersPumped;
  final double amountPaid;
  final DateTime? pumpedAt;
  final String syncStatus;
  final String plateNumber;
  final String vehicleType;
  final String fuelType;
  final double unitPrice;

  const StationTransaction({
    required this.id,
    required this.vehicleId,
    required this.stationId,
    required this.litersPumped,
    required this.amountPaid,
    required this.pumpedAt,
    required this.syncStatus,
    required this.plateNumber,
    required this.vehicleType,
    required this.fuelType,
    required this.unitPrice,
  });

  factory StationTransaction.fromJson(Map<String, dynamic> json) {
    final vehicle = Map<String, dynamic>.from(
      json['vehicle'] ?? json['vehicles'] ?? const {},
    );
    return StationTransaction(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      vehicleId: int.tryParse(json['vehicle_id']?.toString() ?? '') ?? 0,
      stationId: int.tryParse(json['station_id']?.toString() ?? '') ?? 0,
      litersPumped:
          double.tryParse(json['liters_pumped']?.toString() ?? '') ?? 0,
      amountPaid:
          double.tryParse(json['amount_paid']?.toString() ?? '') ?? 0,
      pumpedAt: DateTime.tryParse(json['pumped_at']?.toString() ?? ''),
      syncStatus: json['sync_status']?.toString() ?? '',
      plateNumber: vehicle['plate_number']?.toString() ?? '',
      vehicleType: vehicle['vehicle_type']?.toString() ?? '',
      fuelType: json['fuel_type']?.toString() ??
          vehicle['fuel_type']?.toString() ?? '',
      unitPrice:
          double.tryParse(json['unit_price']?.toString() ?? '') ?? 0,
    );
  }
}
