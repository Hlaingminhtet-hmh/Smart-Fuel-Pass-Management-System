import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../models/vehicle.dart';

class VehicleScreen extends StatefulWidget {
  final UserVehicle vehicle;

  const VehicleScreen({super.key, required this.vehicle});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  final api = ApiClient();
  Uint8List? image;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final q = await api.qr(widget.vehicle.id);
      final raw = q['qr_code_image']?.toString();
      if (raw != null && raw.isNotEmpty) {
        image = base64Decode(raw);
      }
    } catch (e) {
      error = '$e';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.vehicle.plateNumber)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    widget.vehicle.plateNumber,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${widget.vehicle.vehicleType} • ${widget.vehicle.fuelType}',
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value:
                        widget.vehicle.weeklyQuota <= 0
                            ? 0
                            : (widget.vehicle.usedThisWeek /
                                    widget.vehicle.weeklyQuota)
                                .clamp(0, 1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.vehicle.remaining.toStringAsFixed(2)} L remaining',
                  ),
                  const SizedBox(height: 18),
                  if (loading)
                    const CircularProgressIndicator()
                  else if (error != null)
                    Text(error!)
                  else if (image != null)
                    Image.memory(image!, width: 260, height: 260),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
