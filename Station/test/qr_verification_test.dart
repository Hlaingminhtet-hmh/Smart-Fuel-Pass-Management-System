import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fuel_station/models/qr_verification.dart';

void main() {
  test('parses real station QR verification response', () {
    final result = QrVerification.fromJson({
      'success': true,
      'message': 'Vehicle QR verified',
      'vehicle': {
        'id': 2,
        'plate_number': 'YGN-2222',
        'vehicle_type': 'car',
        'fuel_type': '92',
      },
      'quota': {
        'weekly_quota': 40,
        'used_this_week': 0,
        'remaining': 40,
        'can_fuel': true,
        'week': '2026-W32',
      },
    });

    expect(result.success, isTrue);
    expect(result.vehicle.id, 2);
    expect(result.vehicle.plateNumber, 'YGN-2222');
    expect(result.quota.remaining, 40);
    expect(result.quota.canFuel, isTrue);
  });
}
