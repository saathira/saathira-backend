import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/chat/incoming_call_listener.dart';
import 'repositories/auth_repository.dart';
import 'routing/app_router.dart';
import 'services/push_notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var firebaseReady = false;
  try {
    // Uses android/app/google-services.json (run `flutterfire configure`).
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
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
    final sessionAsync = ref.watch(sessionProvider); // keep session alive

    // Initialize notification listeners and token sync once Firebase is ready
    if (ref.watch(firebaseReadyProvider)) {
      ref.read(pushNotificationServiceProvider).initialize();
    }

    ref.listen(sessionProvider, (_, next) {
      router.refresh();
      final session = next.value;
      if (session != null && session.registered) {
        ref.read(pushNotificationServiceProvider).syncToken();
      }
    });

    // Handle cold starts where session is already cached
    if (sessionAsync.value?.registered == true) {
      ref.read(pushNotificationServiceProvider).syncToken();
    }

    return MaterialApp.router(
      title: 'Saathira',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: router,
      builder: (context, child) => IncomingCallListenerWrapper(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
