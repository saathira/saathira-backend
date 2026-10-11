import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repositories/auth_repository.dart';
import 'routing/app_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var firebaseReady = false;
  try {
    // Uses android/app/google-services.json (run `flutterfire configure`).
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (e) {
    debugPrint('Firebase not configured: $e');
  }
  runApp(ProviderScope(
    overrides: [firebaseReadyProvider.overrideWithValue(firebaseReady)],
    child: const SaathiraApp(),
  ));
}

class SaathiraApp extends ConsumerWidget {
  const SaathiraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    ref.watch(sessionProvider); // keep session alive
    ref.listen(sessionProvider, (_, _) => router.refresh());
    return MaterialApp.router(
      title: 'Saathira',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
