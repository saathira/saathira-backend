import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/otp_screen.dart';
import '../features/auth/phone_login_screen.dart';
import '../features/auth/welcome_screen.dart';
import '../features/booking/booking_detail_screen.dart';
import '../features/booking/booking_request_screen.dart';
import '../features/booking/my_bookings_screen.dart';
import '../features/chat/chat_list_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/companion/companion_activities_screen.dart';
import '../features/companion/companion_availability_screen.dart';
import '../features/companion/companion_dashboard_screen.dart';
import '../features/companion/companion_profile_edit_screen.dart';
import '../features/companion/companion_verification_screen.dart';
import '../features/discovery/companion_detail_screen.dart';
import '../features/home/home_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/onboarding/register_screen.dart';
import '../features/onboarding/splash_screen.dart';
import '../features/profile/customer_profile_screen.dart';
import '../features/safety/safety_center_screen.dart';
import '../models/app_user.dart';
import '../models/companion_profile.dart';
import '../repositories/auth_repository.dart';

const _publicPaths = {'/', '/welcome', '/login', '/otp'};
const _entryPaths = {'/', '/welcome', '/login', '/otp', '/register'};

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen(sessionProvider, (prev, next) => notifyListeners());
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) => RouterNotifier(ref));

/// Auth-aware and role-aware routing.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);
  return GoRouter(
    refreshListenable: notifier,
    initialLocation: '/',
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final session = ref.read(sessionProvider);

      if (session.isLoading) return loc == '/' ? null : '/';
      final value = session.hasError ? null : session.value;

      if (value == null) return _publicPaths.contains(loc) ? null : '/welcome';
      if (!value.registered) return loc == '/register' ? null : '/register';

      // Registered user landing redirection
      if (_entryPaths.contains(loc)) {
        if (value.user?.role == AppRole.companion) {
          return '/companion/dashboard';
        }
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, _) => const PhoneLoginScreen()),
      GoRoute(
        path: '/otp',
        builder: (_, s) {
          final extra = s.extra as Map<String, String>;
          return OtpScreen(phone: extra['phone']!, verificationId: extra['verificationId']!);
        },
      ),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),

      // Booking Routes
      GoRoute(path: '/bookings', builder: (_, _) => const MyBookingsScreen()),
      GoRoute(
        path: '/bookings/:id',
        builder: (_, s) => BookingDetailScreen(bookingId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/booking/request/:companionId',
        builder: (_, s) {
          final companionId = s.pathParameters['companionId']!;
          final extra = s.extra as CompanionProfile?;
          return BookingRequestScreen(companionId: companionId, companionInitial: extra);
        },
      ),

      // Communication & Safety Routes
      GoRoute(path: '/chat', builder: (_, _) => const ChatListScreen()),
      GoRoute(
        path: '/chat/:id',
        builder: (_, s) => ChatScreen(bookingId: s.pathParameters['id']!),
      ),
      GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),
      GoRoute(path: '/safety', builder: (_, _) => const SafetyCenterScreen()),
      GoRoute(path: '/profile', builder: (_, _) => const CustomerProfileScreen()),

      // Companion Routes
      GoRoute(path: '/companion/dashboard', builder: (_, _) => const CompanionDashboardScreen()),
      GoRoute(path: '/companion/verification', builder: (_, _) => const CompanionVerificationScreen()),
      GoRoute(path: '/companion/activities', builder: (_, _) => const CompanionActivitiesScreen()),
      GoRoute(path: '/companion/availability', builder: (_, _) => const CompanionAvailabilityScreen()),
      GoRoute(path: '/companion/profile-edit', builder: (_, _) => const CompanionProfileEditScreen()),
      GoRoute(
        path: '/companion/detail/:id',
        builder: (_, s) => CompanionDetailScreen(companionId: s.pathParameters['id']!),
      ),
    ],
  );
});
