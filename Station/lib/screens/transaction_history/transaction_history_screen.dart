import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../models/station_report.dart';
import '../../models/station_transaction.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final int days;

  const TransactionHistoryScreen({
    super.key,
    this.days = 7,
  });

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final ApiClient _api = const ApiClient();
  late Future<StationReport> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<StationReport> _load() => _api.getStationReport(days: widget.days);

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History')),
      body: FutureBuilder<StationReport>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'Could not load transaction history.';
            return _ErrorState(message: message, onRetry: _refresh);
          }

          final report = snapshot.data!;
          if (report.transactions.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 90),
                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.black26),
                  SizedBox(height: 18),
                  Text(
                    'No transactions yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Completed fueling transactions for this station will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: report.transactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _TransactionCard(
                transaction: report.transactions[index],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final StationTransaction transaction;

  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final success = transaction.syncStatus.toLowerCase() == 'online';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_gas_station_outlined, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.plateNumber.isEmpty
                            ? 'Vehicle #${transaction.vehicleId}'
                            : transaction.plateNumber,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(transaction.pumpedAt),
                        style: const TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${transaction.litersPumped.toStringAsFixed(1)} L',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _Meta(label: 'Amount', value: '${transaction.amountPaid.toStringAsFixed(0)} MMK'),
                ),
                Expanded(
                  child: _Meta(label: 'Transaction', value: '#${transaction.id}'),
                ),
                _StatusBadge(success: success, value: transaction.syncStatus),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return 'Unknown time';
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }
}

class _Meta extends StatelessWidget {
  final String label;
  final String value;
  const _Meta({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black45, fontSize: 11)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool success;
  final String value;
  const _StatusBadge({required this.success, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = success ? AppTheme.success : AppTheme.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 10),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 56, color: AppTheme.danger),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
