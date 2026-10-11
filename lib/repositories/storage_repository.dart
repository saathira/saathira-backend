import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';

class StorageRepository {
  StorageRepository(this._ref);
  final Ref _ref;

  /// Uploads avatar image to Supabase avatars bucket and returns public photoUrl
  Future<String> uploadAvatar(File imageFile) async {
    final fileName = imageFile.path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(imageFile.path, filename: fileName),
    });

    final res = await _ref.read(apiClientProvider).post<Map<String, dynamic>>(
      '/uploads/avatar',
      data: formData,
    );

    return res.data!['photoUrl'] as String;
  }

  /// Uploads KYC document or selfie to private Supabase verifications bucket and returns storage path
  Future<String> uploadVerificationDocument(File file, {required String type}) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });

    final res = await _ref.read(apiClientProvider).post<Map<String, dynamic>>(
      '/uploads/verification?type=$type',
      data: formData,
    );

    return res.data!['path'] as String;
  }
}

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository(ref);
});
