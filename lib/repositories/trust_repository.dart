import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../models/safety.dart';

class TrustRepository {
  TrustRepository(this._ref);
  final Ref _ref;

  Future<void> submitReview({
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    await _ref.read(apiClientProvider).post<Map<String, dynamic>>(
      '/reviews',
      data: {
        'bookingId': bookingId,
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
    );
  }

  Future<void> reportUser({
    required String reportedUserId,
    String? bookingId,
    required String reason,
    String? details,
  }) async {
    await _ref.read(apiClientProvider).post<Map<String, dynamic>>(
      '/reports',
      data: {
        'reportedUserId': reportedUserId,
        'bookingId': ?bookingId,
        'reason': reason,
        'details': ?details,
      },
    );
  }

  Future<void> blockUser(String blockedId) async {
    await _ref.read(apiClientProvider).post<Map<String, dynamic>>(
      '/blocks',
      data: {'blockedId': blockedId},
    );
  }

  Future<void> unblockUser(String blockedId) async {
    await _ref.read(apiClientProvider).delete<Map<String, dynamic>>('/blocks/$blockedId');
  }

  Future<List<BlockedUser>> getBlockedUsers() async {
    final res = await _ref.read(apiClientProvider).get<List<dynamic>>('/blocks');
    final list = res.data ?? [];
    return list.map((e) => BlockedUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> submitComplaint({
    required String subject,
    required String message,
  }) async {
    await _ref.read(apiClientProvider).post<Map<String, dynamic>>(
      '/complaints',
      data: {
        'subject': subject,
        'message': message,
      },
    );
  }

  Future<List<ComplaintRecord>> getMyComplaints() async {
    final res = await _ref.read(apiClientProvider).get<List<dynamic>>('/complaints');
    final list = res.data ?? [];
    return list.map((e) => ComplaintRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> raiseDispute({
    required String bookingId,
    required String reason,
  }) async {
    await _ref.read(apiClientProvider).post<Map<String, dynamic>>(
      '/disputes',
      data: {
        'bookingId': bookingId,
        'reason': reason,
      },
    );
  }

  Future<List<DisputeRecord>> getMyDisputes() async {
    final res = await _ref.read(apiClientProvider).get<List<dynamic>>('/disputes');
    final list = res.data ?? [];
    return list.map((e) => DisputeRecord.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final trustRepositoryProvider = Provider<TrustRepository>((ref) {
  return TrustRepository(ref);
});

final blockedUsersProvider = FutureProvider<List<BlockedUser>>((ref) async {
  return ref.watch(trustRepositoryProvider).getBlockedUsers();
});
