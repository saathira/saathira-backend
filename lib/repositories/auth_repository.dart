import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../models/app_user.dart';

class AuthRepository {
  AuthRepository(this._ref);
  final Ref _ref;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  Stream<User?> authChanges() => _auth.authStateChanges();

  /// Sends OTP. Returns verificationId (or null if Android auto-verified and signed in).
  Future<String?> sendOtp(String phoneE164, {int? resendToken}) {
    final c = Completer<String?>();
    _auth.verifyPhoneNumber(
      phoneNumber: phoneE164,
      forceResendingToken: resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (cred) async {
        await _auth.signInWithCredential(cred);
        if (!c.isCompleted) c.complete(null);
      },
      verificationFailed: (e) {
        if (!c.isCompleted) c.completeError(e.message ?? 'Verification failed');
      },
      codeSent: (id, _) {
        if (!c.isCompleted) c.complete(id);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
    return c.future;
  }

  Future<void> verifyOtp(String verificationId, String code) async {
    final cred = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: code);
    await _auth.signInWithCredential(cred);
  }

  Future<Session> fetchSession() async {
    final res = await _ref.read(apiClientProvider).get<Map<String, dynamic>>('/auth/me');
    final data = res.data!;
    final registered = data['registered'] == true;
    return Session(
      registered: registered,
      user: registered ? AppUser.fromJson(data['user'] as Map<String, dynamic>) : null,
    );
  }

  Future<void> register({
    required AppRole role,
    required String fullName,
    String? email,
    String? gender,
    DateTime? dateOfBirth,
    String? city,
  }) async {
    await _ref.read(apiClientProvider).post('/auth/register', data: {
      'role': role.api,
      'fullName': fullName,
      if (email != null && email.isNotEmpty) 'email': email,
      'gender': ?gender,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth.toIso8601String(),
      if (city != null && city.isNotEmpty) 'city': city,
    });
  }

  Future<void> updateProfile({
    String? fullName,
    String? email,
    String? gender,
    DateTime? dateOfBirth,
    String? city,
  }) async {
    await _ref.read(apiClientProvider).patch('/users/me', data: {
      'fullName': ?fullName,
      'email': ?email,
      'gender': ?gender,
      'dateOfBirth': ?dateOfBirth?.toIso8601String(),
      'city': ?city,
    });
    _ref.invalidate(sessionProvider);
  }

  Future<void> signOut() => _auth.signOut();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(ref));

/// True once Firebase.initializeApp() succeeded (overridden in main.dart).
final firebaseReadyProvider = Provider<bool>((ref) => false);

final firebaseUserProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authChanges(),
);

final sessionProvider = FutureProvider<Session?>((ref) async {
  if (!ref.watch(firebaseReadyProvider)) return null;
  ref.watch(firebaseUserProvider); // re-run on sign-in / sign-out
  if (FirebaseAuth.instance.currentUser == null) return null;
  try {
    return await ref.read(authRepositoryProvider).fetchSession();
  } catch (e) {
    // Return null or rethrow so the app knows it's loading / connecting rather than unregistered
    return null;
  }
});

/// Role picked on the welcome screen before sign-up.
class SelectedRole extends Notifier<AppRole> {
  @override
  AppRole build() => AppRole.customer;
  void set(AppRole r) => state = r;
}

final selectedRoleProvider = NotifierProvider<SelectedRole, AppRole>(SelectedRole.new);
