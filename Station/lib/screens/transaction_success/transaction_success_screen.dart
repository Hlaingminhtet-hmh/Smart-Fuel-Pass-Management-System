import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/fuel_result.dart';
import 'fuel_receipt_screen.dart';

class TransactionSuccessScreen extends StatelessWidget {
  final FuelResult result;

  const TransactionSuccessScreen({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final transaction = result.transaction;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Transaction Complete'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 28),
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: .1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 52,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Fueling Successful',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result.message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    _Row('Transaction ID', '#${transaction.id}'),
                    _Row('Vehicle', result.vehiclePlate),
                    _Row('Fuel Type', result.fuelType),
                    _Row(
                      'Price / Liter',
                      _formatMoney(result.unitPrice, result.currency),
                    ),
                    _Row(
                      'Fuel Dispensed',
                      '${result.litersDispensed.toStringAsFixed(1)} L',
                    ),
                    _Row(
                      'Amount Paid',
                      _formatMoney(result.amountPaid),
                    ),
                    _Row(
                      'Remaining Quota',
                      '${result.remainingAfter.toStringAsFixed(1)} L',
                      success: true,
                    ),
                    _Row('Status', transaction.syncStatus.toUpperCase()),
                    if (transaction.pumpedAt != null)
                      _Row(
                        'Time',
                        _formatTime(transaction.pumpedAt!),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FuelReceiptScreen(result: result),
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long_rounded),
                label: const Text('VIEW RECEIPT'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('NEW TRANSACTION'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMoney(double amount, [String currency = 'MMK']) {
    return '${amount.toStringAsFixed(0)} $currency';
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool success;

  const _Row(
    this.label,
    this.value, {
    this.success = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: success ? AppTheme.success : AppTheme.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
