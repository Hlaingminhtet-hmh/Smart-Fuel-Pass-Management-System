import 'package:flutter_test/flutter_test.dart';
import 'package:smart_fuel_station/main.dart';
import 'package:smart_fuel_station/models/fuel_result.dart';

void main() {
  testWidgets('Smart Fuel Pass launches', (tester) async {
    await tester.pumpWidget(const SmartFuelStationApp());
    expect(find.text('Smart Fuel Pass'), findsOneWidget);
    expect(find.text('Station Operator'), findsOneWidget);
  });

  test('FuelResult parses backend transaction response', () {
    final result = FuelResult.fromJson({
      'success': true,
      'message': 'ဆီဖြည့်သွင်းခွင့် ပြုလိုက်ပါပြီ',
      'code': 'SUCCESS',
      'liters_dispensed': 10,
      'remaining_after': 30,
      'vehicle': {
        'id': 2,
        'plate_number': 'YGN-2222',
        'vehicle_type': 'car',
      },
      'transaction': {
        'id': 123,
        'vehicle_id': 2,
        'station_id': 1,
        'liters_pumped': 10,
        'amount_paid': 20000,
        'pumped_at': '2026-08-16T03:00:00Z',
        'sync_status': 'online',
      },
    });

    expect(result.success, isTrue);
    expect(result.vehiclePlate, 'YGN-2222');
    expect(result.litersDispensed, 10);
    expect(result.remainingAfter, 30);
    expect(result.transaction.id, 123);
  });
}

// Station authentication contract test
