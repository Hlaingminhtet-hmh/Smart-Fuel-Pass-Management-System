import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../home/home_screen.dart';
import '../register/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final nid = TextEditingController();
  final pw = TextEditingController();
  final api = ApiClient();
  bool loading = false;

  @override
  void dispose() {
    nid.dispose();
    pw.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (nid.text.trim().isEmpty || pw.text.isEmpty) return;

    setState(() => loading = true);

    try {
      final u = await api.login(nid.text.trim(), pw.text);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(user: u)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Petro Manager')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 30),
          const Icon(Icons.account_circle_rounded, size: 80),
          const Text(
            'Vehicle Owner',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: nid,
            decoration: const InputDecoration(labelText: 'National ID'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: pw,
            obscureText: true,
            onSubmitted: (_) => login(),
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: loading ? null : login,
              child:
                  loading
                      ? const CircularProgressIndicator()
                      : const Text('Sign In'),
            ),
          ),
          TextButton(
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
            child: const Text('Create new account'),
          ),
        ],
      ),
    );
  }
}
