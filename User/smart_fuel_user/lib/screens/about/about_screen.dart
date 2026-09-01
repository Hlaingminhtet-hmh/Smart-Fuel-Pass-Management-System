import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.local_gas_station_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Petro Manager',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Vehicle Owner Application',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'About Petro Manager',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Petro Manager helps registered vehicle owners '
                    'manage their official vehicle information, fuel '
                    'quota, QR fuel pass and fueling history.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.verified_outlined),
                  title: Text('Official Vehicle Registry'),
                  subtitle: Text(
                    'Vehicle registration is controlled by the authority registry.',
                  ),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.qr_code_2),
                  title: Text('QR Fuel Pass'),
                  subtitle: Text(
                    'Use your official QR pass at authorized fuel stations.',
                  ),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.history),
                  title: Text('Fuel History'),
                  subtitle: Text(
                    'View where and when your vehicle received fuel.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Version 1.0.0',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.black45),
          ),
        ],
      ),
    );
  }
}
