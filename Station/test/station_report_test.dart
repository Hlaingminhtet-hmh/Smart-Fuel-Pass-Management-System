import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fuel_station/models/station_report.dart';

void main() {
  test('parses station report and transaction data', () {
    final report = StationReport.fromJson({
      'station': {'id': 1},
      'range_days': 1,
      'summary': {
        'total_transactions': 2,
        'total_liters': 25.0,
        'unique_vehicles': 2,
        'avg_liters': 12.5,
      },
      'transactions': [
        {
          'id': 10,
          'vehicle_id': 4,
          'station_id': 1,
          'liters_pumped': 5,
          'amount_paid': 10000,
          'pumped_at': '2026-08-16T09:25:09Z',
          'sync_status': 'online',
          'vehicles': {
            'plate_number': 'YGN-5454',
            'vehicle_type': 'car',
          },
        },
      ],
    });

    expect(report.stationId, 1);
    expect(report.totalTransactions, 2);
    expect(report.totalLiters, 25.0);
    expect(report.transactions.single.plateNumber, 'YGN-5454');
  });
}
