import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final nid = TextEditingController();
  final phone = TextEditingController();
  final pw = TextEditingController();
  final cf = TextEditingController();
  final api = ApiClient();
  bool loading = false;

  @override
  void dispose() {
    for (final x in [name, nid, phone, pw, cf]) {
      x.dispose();
    }
    super.dispose();
  }

  Future<void> reg() async {
    if (name.text.trim().isEmpty ||
        nid.text.trim().isEmpty ||
        phone.text.trim().isEmpty ||
        pw.text.length < 8 ||
        pw.text != cf.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete the form correctly')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final u = await api.register(
        nid.text.trim(),
        name.text.trim(),
        phone.text.trim(),
        pw.text,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(user: u)),
        (_) => false,
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
      appBar: AppBar(title: const Text('Create Account')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Full Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nid,
            decoration: const InputDecoration(labelText: 'National ID'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: pw,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: cf,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirm Password'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: loading ? null : reg,
              child:
                  loading
                      ? const CircularProgressIndicator()
                      : const Text('Create Account'),
            ),
          ),
        ],
      ),
    );
  }
}
