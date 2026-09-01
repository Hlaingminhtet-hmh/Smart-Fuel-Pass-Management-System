import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../models/vehicle.dart';

class ClaimScreen extends StatefulWidget {
  const ClaimScreen({super.key});

  @override
  State<ClaimScreen> createState() => _ClaimScreenState();
}

class _ClaimScreenState extends State<ClaimScreen> {
  final _formKey = GlobalKey<FormState>();

  final _ownerNameController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _plateController = TextEditingController();

  final _api = ApiClient();

  UserVehicle? _officialVehicle;

  bool _checking = false;
  bool _claiming = false;
  String? _error;

  String _vehicleType = 'car';

  @override
  void dispose() {
    _ownerNameController.dispose();
    _nationalIdController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _checkOfficialVehicle() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _checking = true;
      _claiming = false;
      _officialVehicle = null;
      _error = null;
    });

    try {
      final vehicle = await _api.checkVehicle(
        ownerName: _ownerNameController.text.trim(),
        nationalId: _nationalIdController.text.trim(),
        plateNumber: _plateController.text.trim().toUpperCase(),
        vehicleType: _vehicleType,
      );

      if (!mounted) return;

      setState(() {
        _officialVehicle = vehicle;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _checking = false;
        });
      }
    }
  }

  Future<void> _claimVehicle() async {
    if (_officialVehicle == null) {
      return;
    }

    setState(() {
      _claiming = true;
      _error = null;
    });

    try {
      await _api.claimVehicle(
        ownerName: _ownerNameController.text.trim(),
        nationalId: _nationalIdController.text.trim(),
        plateNumber: _plateController.text.trim().toUpperCase(),
        vehicleType: _vehicleType,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle registered successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _claiming = false;
        });
      }
    }
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Register Vehicle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Official Vehicle Registration',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the official vehicle information exactly as registered by the authority.',
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _ownerNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Owner Name',
                hintText: 'Enter registered owner name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) => _required(value, 'Owner name'),
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: _nationalIdController,
              decoration: const InputDecoration(
                labelText: 'National ID',
                hintText: 'Enter registered National ID',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (value) => _required(value, 'National ID'),
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: _plateController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Plate Number',
                hintText: 'e.g. YGN-7674',
                prefixIcon: Icon(Icons.directions_car_outlined),
              ),
              validator: (value) => _required(value, 'Plate number'),
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: _vehicleType,
              decoration: const InputDecoration(
                labelText: 'Vehicle Type',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'car', child: Text('Car')),
                DropdownMenuItem(value: 'bike', child: Text('Bike')),
                DropdownMenuItem(
                  value: 'three_wheel',
                  child: Text('Three Wheel'),
                ),
                DropdownMenuItem(value: 'bus', child: Text('Bus')),
                DropdownMenuItem(value: 'truck', child: Text('Truck')),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _vehicleType = value;
                  _officialVehicle = null;
                  _error = null;
                });
              },
            ),

            const SizedBox(height: 18),

            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _checking ? null : _checkOfficialVehicle,
                child:
                    _checking
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text('Check Official Vehicle'),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],

            if (_officialVehicle != null) ...[
              const SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified_rounded, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Official Record Verified',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      _InfoRow(
                        label: 'Plate Number',
                        value: _officialVehicle!.plateNumber,
                      ),
                      _InfoRow(
                        label: 'Vehicle Type',
                        value: _officialVehicle!.vehicleType,
                      ),
                      _InfoRow(
                        label: 'Fuel Type',
                        value: _officialVehicle!.fuelType,
                      ),
                      _InfoRow(
                        label: 'Engine Capacity',
                        value: _officialVehicle!.engineCapacity ?? '-',
                      ),
                      _InfoRow(
                        label: 'Weekly Quota',
                        value:
                            '${_officialVehicle!.weeklyQuota.toStringAsFixed(2)} L',
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        'Vehicle details and quota are controlled by the authority registry and cannot be edited here.',
                        style: TextStyle(color: Colors.black54),
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: _claiming ? null : _claimVehicle,
                          child:
                              _claiming
                                  ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Text('Register This Vehicle'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
