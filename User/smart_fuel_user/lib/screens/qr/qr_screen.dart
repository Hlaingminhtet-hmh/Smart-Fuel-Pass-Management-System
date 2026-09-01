import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';

class QrScreen extends StatefulWidget {
  final int id;

  const QrScreen({super.key, required this.id});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final api = ApiClient();
  Uint8List? img;
  String? plate;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final d = await api.qr(widget.id);
      final raw = d['qr_code_image']?.toString();

      if (mounted) {
        setState(() {
          plate = d['vehicle']?['plate_number']?.toString();
          img = raw == null || raw.isEmpty ? null : base64Decode(raw);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Fuel Pass')),
      body: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Petro Manager',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                Text(plate ?? ''),
                const SizedBox(height: 20),
                if (img != null)
                  Image.memory(img!, width: 270, height: 270)
                else
                  const CircularProgressIndicator(),
                const SizedBox(height: 12),
                const Text(
                  'Show this QR at an authorized fuel station.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
