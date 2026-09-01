import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/fuel_result.dart';

class FuelReceiptScreen extends StatelessWidget {
  final FuelResult result;

  const FuelReceiptScreen({super.key, required this.result});

  String _money(double value, String currency) =>
      '${value.toStringAsFixed(0)} $currency';

  String _formatTime(DateTime? value) {
    if (value == null) return '—';
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final tx = result.transaction;
    return Scaffold(
      appBar: AppBar(title: const Text('Fuel Receipt')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.local_gas_station_rounded,
                    color: AppTheme.primary,
                    size: 46,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Petro Manager',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'FUEL DISPENSING RECEIPT',
                    style: TextStyle(color: Colors.black54, letterSpacing: .8),
                  ),
                  const Divider(height: 30),
                  _Row('Transaction ID', '#${tx.id}'),
                  _Row('Vehicle', result.vehiclePlate),
                  _Row('Fuel Type', result.fuelType),
                  _Row(
                    'Quantity',
                    '${result.litersDispensed.toStringAsFixed(1)} L',
                  ),
                  _Row(
                    'Price / Liter',
                    _money(result.unitPrice, result.currency),
                  ),
                  _Row(
                    'Amount Paid',
                    _money(result.amountPaid, result.currency),
                    strong: true,
                  ),
                  _Row(
                    'Quota Remaining',
                    '${result.remainingAfter.toStringAsFixed(1)} L',
                    strong: true,
                  ),
                  _Row('Status', tx.syncStatus.toUpperCase()),
                  _Row('Date / Time', _formatTime(tx.pumpedAt)),
                  const Divider(height: 30),
                  const Text(
                    'Please keep this receipt for your records.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;

  const _Row(this.label, this.value, {this.strong = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
                color: strong ? AppTheme.primary : AppTheme.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
