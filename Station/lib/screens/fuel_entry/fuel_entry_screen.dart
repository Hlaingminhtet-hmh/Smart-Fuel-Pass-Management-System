import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../models/fuel_price.dart';
import '../../models/qr_verification.dart';
import '../transaction_confirmation/transaction_confirmation_screen.dart';

class FuelEntryScreen extends StatefulWidget {
  final QrVerification verification;

  const FuelEntryScreen({super.key, required this.verification});

  @override
  State<FuelEntryScreen> createState() => _FuelEntryScreenState();
}

class _FuelEntryScreenState extends State<FuelEntryScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ApiClient _apiClient = const ApiClient();

  FuelPrice? _price;

  bool _loadingPrice = true;
  String? _priceError;

  double get remaining => widget.verification.quota.remaining;

  double get enteredAmount =>
      double.tryParse(_amountController.text.trim()) ?? 0.0;

  double get estimatedLiters {
    if (_price == null || _price!.pricePerLiter <= 0) {
      return 0.0;
    }

    return enteredAmount / _price!.pricePerLiter;
  }

  double get remainingAfter {
    return (remaining - estimatedLiters).clamp(0.0, remaining).toDouble();
  }

  @override
  void initState() {
    super.initState();

    _amountController.addListener(_onAmountChanged);

    _loadPrice();
  }

  @override
  void dispose() {
    _amountController
      ..removeListener(_onAmountChanged)
      ..dispose();

    super.dispose();
  }

  void _onAmountChanged() {
    setState(() {});
  }

  Future<void> _loadPrice() async {
    setState(() {
      _loadingPrice = true;
      _priceError = null;
    });

    try {
      final fuelType =
          widget.verification.vehicle.fuelType.isEmpty ||
                  widget.verification.vehicle.fuelType == '—'
              ? 'petrol_92'
              : widget.verification.vehicle.fuelType;

      final price = await _apiClient.getCurrentFuelPrice(fuelType);

      if (!mounted) return;

      setState(() {
        _price = price;
        _loadingPrice = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _priceError = error.message;
        _loadingPrice = false;
      });
    }
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_price == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => TransactionConfirmationScreen(
              verification: widget.verification,
              amountMm: enteredAmount,
              estimatedLiters: estimatedLiters,
              price: _price!,
            ),
      ),
    );
  }

  String _fuelLabel(String value) {
    switch (value) {
      case 'petrol_92':
        return 'Petrol 92';
      case 'petrol_95':
        return 'Petrol 95';
      case 'diesel':
        return 'Diesel';
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final quota = widget.verification.quota;
    final vehicle = widget.verification.vehicle;

    return Scaffold(
      appBar: AppBar(title: const Text('Fuel Dispensing')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vehicle',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      vehicle.plateNumber,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.text,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Fuel Type: ${_fuelLabel(vehicle.fuelType)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Remaining Quota',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${quota.remaining.toStringAsFixed(1)} L',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Today's fuel price
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child:
                    _loadingPrice
                        ? const Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text('Loading today\'s fuel price...'),
                          ],
                        )
                        : _priceError != null
                        ? Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppTheme.danger,
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(_priceError!)),
                          ],
                        )
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Today's Fuel Price",
                              style: TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_price!.pricePerLiter.toStringAsFixed(0)} ${_price!.currency} / L',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Fuel Amount',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 10),

            TextFormField(
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                hintText: 'Enter amount',
                suffixText: 'MMK',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');

                if (amount == null || amount <= 0) {
                  return 'Enter a valid amount';
                }

                if (_price == null || _price!.pricePerLiter <= 0) {
                  return 'Fuel price is unavailable';
                }

                final liters = amount / _price!.pricePerLiter;

                if (liters > remaining) {
                  return 'Maximum amount is '
                      '${(remaining * _price!.pricePerLiter).toStringAsFixed(0)} MMK';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            // Auto-calculated liters
            Card(
              color: AppTheme.primary.withValues(alpha: 0.06),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    const Text(
                      'Estimated Fuel',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${estimatedLiters.toStringAsFixed(2)} L',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$enteredAmount MMK ÷ '
                      '${_price?.pricePerLiter.toStringAsFixed(0) ?? 0} MMK/L',
                      style: const TextStyle(color: Colors.black45),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _SummaryRow(
                      label: 'Amount Requested',
                      value: '${enteredAmount.toStringAsFixed(0)} MMK',
                    ),
                    _SummaryRow(
                      label: 'Fuel Quantity',
                      value: '${estimatedLiters.toStringAsFixed(2)} L',
                    ),
                    _SummaryRow(
                      label: 'Remaining After',
                      value: '${remainingAfter.toStringAsFixed(2)} L',
                      strong: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: (_loadingPrice || _price == null) ? null : _continue,
                child: const Text(
                  'CONTINUE',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              color: strong ? AppTheme.success : AppTheme.text,
            ),
          ),
        ],
      ),
    );
  }
}
