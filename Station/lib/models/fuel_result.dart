import 'fuel_transaction.dart';

class FuelResult {
  final bool success;
  final String message;
  final String code;
  final FuelTransaction transaction;
  final double litersDispensed;
  final double remainingAfter;
  final String vehiclePlate;
  final int vehicleId;
  final String vehicleType;
  final String fuelType;
  final double unitPrice;
  final String currency;
  final double amountPaid;

  const FuelResult({
    required this.success,
    required this.message,
    required this.code,
    required this.transaction,
    required this.litersDispensed,
    required this.remainingAfter,
    required this.vehiclePlate,
    required this.vehicleId,
    required this.vehicleType,
    required this.fuelType,
    required this.unitPrice,
    required this.currency,
    required this.amountPaid,
  });

  factory FuelResult.fromJson(Map<String, dynamic> json) {
    final vehicle = Map<String, dynamic>.from(json['vehicle'] ?? const {});
    final transaction = Map<String, dynamic>.from(
      json['transaction'] ?? const {},
    );

    return FuelResult(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      transaction: FuelTransaction.fromJson(transaction),
      litersDispensed:
          double.tryParse(json['liters_dispensed']?.toString() ?? '') ?? 0,
      remainingAfter:
          double.tryParse(json['remaining_after']?.toString() ?? '') ?? 0,
      vehiclePlate: vehicle['plate_number']?.toString() ?? '',
      vehicleId: int.tryParse(vehicle['id']?.toString() ?? '') ?? 0,
      vehicleType: vehicle['vehicle_type']?.toString() ?? '',
      fuelType: json['fuel_type']?.toString() ??
          transaction['fuel_type']?.toString() ??
          vehicle['fuel_type']?.toString() ?? '',
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '') ??
          double.tryParse(transaction['unit_price']?.toString() ?? '') ??
          0,
      currency: json['currency']?.toString() ?? 'MMK',
      amountPaid:
          double.tryParse(json['amount_paid']?.toString() ?? '') ??
          double.tryParse(transaction['amount_paid']?.toString() ?? '') ??
          0,
    );
  }
}
