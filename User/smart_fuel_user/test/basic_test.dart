import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fuel_user/models/vehicle.dart';

void main() {
  test('official vehicle parser', () {
    final v = UserVehicle.fromJson({
      'id': 1,
      'plate_number': 'YGN-7674',
      'vehicle_type': 'car',
      'fuel_type': 'petrol_92',
      'weekly_quota': 20,
    });

    expect(v.plateNumber, 'YGN-7674');
    expect(v.weeklyQuota, 20);
  });
}
