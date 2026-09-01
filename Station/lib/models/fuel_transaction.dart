class FuelTransaction {
  final int id;
  final int vehicleId;
  final int stationId;
  final double litersPumped;
  final double amountPaid;
  final DateTime? pumpedAt;
  final String syncStatus;
  final String fuelType;
  final double unitPrice;

  const FuelTransaction({
    required this.id,
    required this.vehicleId,
    required this.stationId,
    required this.litersPumped,
    required this.amountPaid,
    required this.pumpedAt,
    required this.syncStatus,
    required this.fuelType,
    required this.unitPrice,
  });

  factory FuelTransaction.fromJson(Map<String, dynamic> json) {
    return FuelTransaction(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      vehicleId: int.tryParse(json['vehicle_id']?.toString() ?? '') ?? 0,
      stationId: int.tryParse(json['station_id']?.toString() ?? '') ?? 0,
      litersPumped:
          double.tryParse(json['liters_pumped']?.toString() ?? '') ?? 0,
      amountPaid:
          double.tryParse(json['amount_paid']?.toString() ?? '') ?? 0,
      pumpedAt: DateTime.tryParse(json['pumped_at']?.toString() ?? ''),
      syncStatus: json['sync_status']?.toString() ?? '',
      fuelType: json['fuel_type']?.toString() ?? '',
      unitPrice:
          double.tryParse(json['unit_price']?.toString() ?? '') ?? 0,
    );
  }
}
