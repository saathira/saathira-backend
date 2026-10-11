import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../repositories/auth_repository.dart';
import '../../theme/app_theme.dart';

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});
  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _send() async {
    final digits = _ctrl.text.trim();
    if (digits.length != 10) {
      setState(() => _error = 'Enter a valid 10-digit mobile number');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final phone = '+91$digits';
    try {
      final id = await ref.read(authRepositoryProvider).sendOtp(phone);
      if (!mounted) return;
      if (id != null) context.push('/otp', extra: {'phone': phone, 'verificationId': id});
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Your mobile number', style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text("We'll send a one-time code to verify it.", style: t.bodyMedium?.copyWith(color: AppColors.muted)),
            const SizedBox(height: 28),
            TextField(
              key: const Key('input_phone'),
              controller: _ctrl,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(prefixText: '+91  ', counterText: '', errorText: _error),
            ),
            const Spacer(),
            ElevatedButton(
              key: const Key('btn_send_otp'),
              onPressed: _loading ? null : _send,
              child: _loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Send OTP'),
            ),
          ]),
        ),
      ),
    );
  }
}
