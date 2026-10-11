import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        color: AppColors.bg,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Container(
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Image.asset('logo.png', fit: BoxFit.contain),
                ),
                const SizedBox(height: 20),
                // Brand pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_user_outlined, size: 16, color: Colors.greenAccent),
                      SizedBox(width: 6),
                      Text(
                        '100% Verified Community',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Never do it\nalone again.',
                  style: t.displaySmall?.copyWith(fontWeight: FontWeight.w700, height: 1.15),
                ),
                const SizedBox(height: 12),
                Text(
                  'Book verified companions for shopping, movies, doctor visits, cafe outings and city exploration.',
                  style: t.bodyLarge?.copyWith(color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 36),
                ElevatedButton(
                  key: const Key('btn_get_started'),
                  onPressed: () => context.push('/login'),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone_android, size: 20),
                      SizedBox(width: 10),
                      Text('Get Started with Mobile Number'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Safe • Escrow Protected • Emergency SOS Ready',
                    style: TextStyle(fontSize: 11.5, color: AppColors.muted),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
