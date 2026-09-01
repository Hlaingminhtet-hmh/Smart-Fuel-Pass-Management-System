import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/login/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartFuelStationApp());
}

class SmartFuelStationApp extends StatelessWidget {
  const SmartFuelStationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Petro Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const LoginScreen(),
    );
  }
}
