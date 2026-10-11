import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';

/// Shared Dio client that attaches the current Firebase ID token.
final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      options.headers['Authorization'] = 'Bearer ${await user.getIdToken()}';
    }
    handler.next(options);
  }));
  return dio;
});

/// Extracts a readable message from API errors.
String apiErrorMessage(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      final m = data['message'];
      return m is List ? m.join('\n') : m.toString();
    }
    return e.message ?? 'Network error';
  }
  return e.toString();
}
