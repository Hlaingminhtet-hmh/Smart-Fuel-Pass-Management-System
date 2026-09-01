import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../models/qr_verification.dart';
import '../fuel_entry/fuel_entry_screen.dart';

class VehicleVerificationScreen extends StatefulWidget {
  final String qrPayload;
  const VehicleVerificationScreen({
    super.key,
    required this.qrPayload,
  });

  @override
  State<VehicleVerificationScreen> createState() =>
      _VehicleVerificationScreenState();
}

class _VehicleVerificationScreenState
    extends State<VehicleVerificationScreen> {
  final ApiClient _apiClient = const ApiClient();
  QrVerification? _verification;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _verifyQr();
  }

  Future<void> _verifyQr() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _apiClient.verifyVehicleQr(widget.qrPayload);
      if (!mounted) return;

      setState(() {
        _verification = result;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Vehicle verification failed. Please try again.';
        _loading = false;
      });
    }
  }

  void _continueToFuel() {
    final result = _verification;
    if (result == null || !result.quota.canFuel) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FuelEntryScreen(
          verification: result,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Verification'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppTheme.danger,
                size: 56,
              ),
              const SizedBox(height: 16),
              const Text(
                'Vehicle verification failed',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _verifyQr,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final result = _verification!;
    final vehicle = result.vehicle;
    final quota = result.quota;
    final progress = quota.weeklyQuota <= 0
        ? 0.0
        : (quota.usedThisWeek / quota.weeklyQuota).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  label: 'Vehicle Number',
                  value: vehicle.plateNumber,
                ),
                _InfoRow(
                  label: 'Vehicle Type',
                  value: vehicle.vehicleType.isEmpty
                      ? '—'
                      : vehicle.vehicleType,
                ),
                _InfoRow(
                  label: 'Fuel Type',
                  value: vehicle.fuelType.isEmpty ? '—' : vehicle.fuelType,
                ),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 14),
                Text(
                  'Fuel Quota',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  label: 'Weekly Quota',
                  value: '${quota.weeklyQuota.toStringAsFixed(1)} L',
                ),
                _InfoRow(
                  label: 'Used This Week',
                  value: '${quota.usedThisWeek.toStringAsFixed(1)} L',
                ),
                _InfoRow(
                  label: 'Remaining',
                  value: '${quota.remaining.toStringAsFixed(1)} L',
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 9,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: quota.canFuel
                ? AppTheme.success.withValues(alpha: .08)
                : AppTheme.warning.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                quota.canFuel
                    ? Icons.check_circle_outline_rounded
                    : Icons.warning_amber_rounded,
                color: quota.canFuel ? AppTheme.success : AppTheme.warning,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  quota.canFuel
                      ? 'Vehicle is eligible for fueling.'
                      : 'This vehicle cannot receive fuel at this time.',
                  style: TextStyle(
                    color: quota.canFuel
                        ? AppTheme.success
                        : AppTheme.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: quota.canFuel ? _continueToFuel : null,
            child: const Text(
              'CONTINUE',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
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
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppTheme.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
