import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/app_user.dart';
import '../../repositories/auth_repository.dart';
import '../../theme/app_theme.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone, required this.verificationId});
  final String phone;
  final String verificationId;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _ctrl = TextEditingController();
  late String _verificationId = widget.verificationId;
  bool _loading = false;
  String? _error;

  Future<void> _verify() async {
    if (_ctrl.text.length != 6) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).verifyOtp(_verificationId, _ctrl.text);
      if (!mounted) return;
      ref.invalidate(sessionProvider);
      final session = await ref.read(authRepositoryProvider).fetchSession();
      if (!mounted) return;
      if (session.registered) {
        if (session.user?.role == AppRole.companion) {
          context.go('/companion/dashboard');
        } else {
          context.go('/home');
        }
      } else {
        context.go('/register');
      }
    } catch (_) {
      setState(() => _error = 'Incorrect code. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    try {
      final id = await ref.read(authRepositoryProvider).sendOtp(widget.phone);
      if (id != null) _verificationId = id;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code resent')));
    } catch (e) {
      setState(() => _error = e.toString());
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
            Text('Enter code', style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Sent to ${widget.phone}', style: t.bodyMedium?.copyWith(color: AppColors.muted)),
            const SizedBox(height: 28),
            TextField(
              key: const Key('input_otp'),
              controller: _ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: t.headlineSmall?.copyWith(letterSpacing: 12),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (v) => v.length == 6 ? _verify() : null,
              decoration: InputDecoration(counterText: '', errorText: _error),
            ),
            TextButton(key: const Key('btn_resend_otp'), onPressed: _resend, child: const Text('Resend code')),
            const Spacer(),
            ElevatedButton(
              key: const Key('btn_verify_otp'),
              onPressed: _loading ? null : _verify,
              child: _loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Verify'),
            ),
          ]),
        ),
      ),
    );
  }
}
