import 'station_transaction.dart';

class StationReport {
  final int stationId;
  final int rangeDays;
  final int totalTransactions;
  final double totalLiters;
  final int uniqueVehicles;
  final double averageLiters;
  final List<StationTransaction> transactions;

  const StationReport({
    required this.stationId,
    required this.rangeDays,
    required this.totalTransactions,
    required this.totalLiters,
    required this.uniqueVehicles,
    required this.averageLiters,
    required this.transactions,
  });

  factory StationReport.fromJson(Map<String, dynamic> json) {
    final summary = Map<String, dynamic>.from(json['summary'] ?? const {});
    final rows = (json['transactions'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => StationTransaction.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();

    return StationReport(
      stationId: int.tryParse(
            Map<String, dynamic>.from(json['station'] ?? const {})['id']?.toString() ?? '',
          ) ??
          0,
      rangeDays: int.tryParse(json['range_days']?.toString() ?? '') ?? 1,
      totalTransactions: int.tryParse(summary['total_transactions']?.toString() ?? '') ?? 0,
      totalLiters: double.tryParse(summary['total_liters']?.toString() ?? '') ?? 0,
      uniqueVehicles: int.tryParse(summary['unique_vehicles']?.toString() ?? '') ?? 0,
      averageLiters: double.tryParse(summary['avg_liters']?.toString() ?? '') ?? 0,
      transactions: rows,
    );
  }
}
