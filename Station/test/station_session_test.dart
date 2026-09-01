import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fuel_station/models/station_session.dart';

void main() {
  test('parses real station login response', () {
    final session = StationSession.fromLoginJson({
      'success': true,
      'token': 'signed-test-token',
      'expires_in': 28800,
      'operator': {
        'id': 1,
        'operator_code': 'OP-001',
        'user_id': 3,
        'name': 'Station Operator',
      },
      'station': {
        'id': 1,
        'station_name': 'Smart Fuel Test Station',
        'license_no': 'DEV-001',
        'region_zone': 'Yangon',
        'status': 'active',
      },
    });

    expect(session.token, 'signed-test-token');
    expect(session.operatorCode, 'OP-001');
    expect(session.stationId, 1);
    expect(session.stationName, 'Smart Fuel Test Station');
    expect(session.regionZone, 'Yangon');
  });
}
