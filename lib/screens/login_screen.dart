import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:sia_mobile_soosvaldo/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;

  void _showMessage(String msg, {bool error = true}) {
    final snackBar = SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : Colors.green,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _onLoginPressed() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Email dan password diperlukan');
      return;
    }

    setState(() => _loading = true);
    final result = await _authService.login(email, password);
    setState(() => _loading = false);

    if (result['status'] == 'success') {
      _showMessage(result['message'] ?? 'Login berhasil', error: false);
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      _showMessage(result['message'] ?? 'Login failed: Unknown error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.brightness_high, size: 64, color: AppColors.primary),
                  const SizedBox(height: 12),
                  const Text('SIA-KU', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  const Text('Sistem Informasi Akuntansi', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 20),
                  const SizedBox(height: 8),
                  CustomCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                        const SizedBox(height: 6),
                        CustomTextField(
                          controller: _emailController,
                          label: null,
                          hint: 'nama@email.com',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.mail_outline, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        const Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                        const SizedBox(height: 6),
                        CustomTextField(
                          controller: _passwordController,
                          hint: '********',
                          obscureText: true,
                          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 20),
                        CustomButton(
                          label: _loading ? 'Memproses...' : 'Login',
                          onPressed: _loading ? null : _onLoginPressed,
                          variant: ButtonVariant.filled,
                          fullWidth: true,
                          icon: Icons.login,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.center,
                          child: TextButton(
                            onPressed: null,
                            child: const Text('Lupa Password?', style: TextStyle(color: AppColors.primary)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}