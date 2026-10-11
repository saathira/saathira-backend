import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/app_user.dart';
import '../../repositories/auth_repository.dart';
import '../../theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    // Show splash animation for 1.4s
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    final firebaseReady = ref.read(firebaseReadyProvider);
    if (!firebaseReady) {
      context.go('/welcome');
      return;
    }

    User? fbUser;
    try {
      fbUser = FirebaseAuth.instance.currentUser;
    } catch (_) {
      fbUser = null;
    }

    if (fbUser == null) {
      context.go('/welcome');
      return;
    }

    try {
      final session = await ref.read(authRepositoryProvider).fetchSession();
      if (!mounted) return;

      if (!session.registered) {
        context.go('/register');
      } else if (session.user?.role == AppRole.companion) {
        context.go('/companion/dashboard');
      } else {
        context.go('/home');
      }
    } catch (e) {
      debugPrint('Error fetching session in splash: $e');
      if (mounted) context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutBack,
              builder: (_, v, child) =>
                  Opacity(opacity: v.clamp(0, 1), child: Transform.scale(scale: v, child: child)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 108,
                    height: 108,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ShaderMask(
                    shaderCallback: (r) => AppColors.brandGradient.createShader(r),
                    child: Text(
                      'Saathira',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Trusted Activity Companions',
              style: TextStyle(
                fontSize: 13,
                letterSpacing: 0.5,
                color: AppColors.muted.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
