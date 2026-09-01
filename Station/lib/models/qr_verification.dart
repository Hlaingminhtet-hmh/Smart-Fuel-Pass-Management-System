import 'quota.dart';
import 'vehicle.dart';

class QrVerification {
  final bool success;
  final String message;
  final Vehicle vehicle;
  final FuelQuota quota;

  const QrVerification({
    required this.success,
    required this.message,
    required this.vehicle,
    required this.quota,
  });

  factory QrVerification.fromJson(Map<String, dynamic> json) {
    final vehicleJson =
        Map<String, dynamic>.from(json['vehicle'] ?? const {});
    final quotaJson =
        Map<String, dynamic>.from(json['quota'] ?? const {});

    // The backend may return `vehicle` directly, or only identifiers
    // when the QR service has limited vehicle details. Keep the model
    // tolerant so the UI can still show the verified plate.
    if (vehicleJson.isEmpty) {
      vehicleJson['id'] = json['vehicle_id'];
      vehicleJson['plate_number'] = json['plate'];
      vehicleJson['vehicle_type'] = json['vehicle_type'];
      vehicleJson['fuel_type'] = json['fuel_type'];
    }

    return QrVerification(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      vehicle: Vehicle.fromJson(vehicleJson),
      quota: FuelQuota.fromJson(quotaJson),
    );
  }
}
