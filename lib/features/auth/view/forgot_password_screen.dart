// Location: agrivana\lib\features\auth\view\forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _identifierCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  int _step = 0; // 0=email, 1=otp+newpass
  bool _obscure = true;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _otpCtrl.dispose();
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Lupa Password')),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthOtpSent) setState(() => _step = 1);
          if (state is AuthPasswordResetSuccess) Navigator.of(context).pop();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _step == 0 ? _buildRequestOtp() : _buildResetPassword(),
        ),
      ),
    );
  }

  Widget _buildRequestOtp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reset Password', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        const Text('Masukkan email atau nomor telepon Anda', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
        const SizedBox(height: 24),
        TextField(controller: _identifierCtrl, decoration: const InputDecoration(hintText: 'Email atau Nomor Telepon')),
        const SizedBox(height: 24),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : () {
                  context.read<AuthBloc>().add(AuthForgotPasswordRequested(identifier: _identifierCtrl.text.trim()));
                },
                child: isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Kirim OTP'),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildResetPassword() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Masukkan Kode & Password Baru', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 24),
        TextField(controller: _otpCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Kode OTP')),
        const SizedBox(height: 12),
        TextField(
          controller: _newPasswordCtrl,
          obscureText: _obscure,
          decoration: InputDecoration(
            hintText: 'Password Baru',
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 24),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : () {
                  context.read<AuthBloc>().add(AuthResetPasswordRequested(
                    identifier: _identifierCtrl.text.trim(),
                    otp: _otpCtrl.text.trim(),
                    newPassword: _newPasswordCtrl.text,
                  ));
                },
                child: isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Reset Password'),
              ),
            );
          },
        ),
      ],
    );
  }
}
