import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../models/fuel_price.dart';
import '../../models/qr_verification.dart';
import '../transaction_success/transaction_success_screen.dart';

class TransactionConfirmationScreen extends StatefulWidget {
  final QrVerification verification;
  final double amountMm;
  final double estimatedLiters;
  final FuelPrice price;

  const TransactionConfirmationScreen({
    super.key,
    required this.verification,
    required this.amountMm,
    required this.estimatedLiters,
    required this.price,
  });

  @override
  State<TransactionConfirmationScreen> createState() =>
      _TransactionConfirmationScreenState();
}

class _TransactionConfirmationScreenState
    extends State<TransactionConfirmationScreen> {
  final ApiClient _apiClient = const ApiClient();

  FuelPrice? _price;
  bool _loadingPrice = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPrice();
  }

  Future<void> _loadPrice() async {
    setState(() {
      _loadingPrice = true;
      _error = null;
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
        _error = error.message;
        _loadingPrice = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Could not load current fuel price.';
        _loadingPrice = false;
      });
    }
  }

  Future<void> _confirm() async {
    if (_submitting || _loadingPrice || _price == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final result = await _apiClient.processFuel(
        vehicleId: widget.verification.vehicle.id,
        liters: widget.estimatedLiters,
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => TransactionSuccessScreen(result: result),
        ),
        (route) => route.isFirst,
      );
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.message;
        _submitting = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Transaction failed. Please try again.';
        _submitting = false;
      });
    }
  }

  String _money(double value, String currency) {
    return '${value.toStringAsFixed(0)} $currency';
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
        return value.isEmpty ? '—' : value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.verification.vehicle;
    final quotaBefore = widget.verification.quota.remaining;
    final quotaAfter =
        (quotaBefore - widget.estimatedLiters)
            .clamp(0.0, double.infinity)
            .toDouble();
    final displayPrice = _price ?? widget.price;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Transaction')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  const Icon(
                    Icons.receipt_long_rounded,
                    size: 46,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Review Before Dispensing',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 20),
                  _ConfirmRow(label: 'Vehicle', value: vehicle.plateNumber),
                  _ConfirmRow(
                    label: 'Vehicle Type',
                    value: vehicle.vehicleType,
                  ),
                  _ConfirmRow(
                    label: 'Fuel Type',
                    value: _fuelLabel(vehicle.fuelType),
                  ),
                  const Divider(height: 24),
                  _ConfirmRow(
                    label: 'Amount',
                    value: _money(widget.amountMm, displayPrice.currency),
                  ),
                  _ConfirmRow(
                    label: 'Estimated Fuel',
                    value: '${widget.estimatedLiters.toStringAsFixed(2)} L',
                  ),
                  _ConfirmRow(
                    label: 'Price / Liter',
                    value: _money(
                      displayPrice.pricePerLiter.toDouble(),
                      displayPrice.currency,
                    ),
                  ),
                  const Divider(height: 24),
                  _ConfirmRow(
                    label: 'Quota Before',
                    value: '${quotaBefore.toStringAsFixed(2)} L',
                  ),
                  _ConfirmRow(
                    label: 'Quota After',
                    value: '${quotaAfter.toStringAsFixed(2)} L',
                    success: true,
                  ),
                ],
              ),
            ),
          ),
          if (_loadingPrice) ...[
            const SizedBox(height: 14),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Text('Loading current fuel price...'),
                  ],
                ),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppTheme.danger,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppTheme.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loadingPrice ? null : _loadPrice,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('RELOAD PRICE'),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 58,
            child: FilledButton.icon(
              onPressed:
                  (_submitting || _loadingPrice || _price == null)
                      ? null
                      : _confirm,
              icon:
                  _submitting
                      ? const SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.check_circle_outline_rounded),
              label: Text(_submitting ? 'PROCESSING...' : 'CONFIRM FUELING'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;
  final bool success;

  const _ConfirmRow({
    required this.label,
    required this.value,
    this.success = false,
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
          const SizedBox(width: 12),
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
