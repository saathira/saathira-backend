import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../models/booking.dart';

class BookingsRepository {
  BookingsRepository(this._ref);
  final Ref _ref;

  Future<Booking> createBooking({
    required String companionId,
    required String activityId,
    required DateTime startAt,
    required DateTime endAt,
    required String meetingPlace,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    final res = await _ref.read(apiClientProvider).post<Map<String, dynamic>>(
      '/bookings',
      data: {
        'companionId': companionId,
        'activityId': activityId,
        'startAt': startAt.toUtc().toIso8601String(),
        'endAt': endAt.toUtc().toIso8601String(),
        'meetingPlace': meetingPlace,
        'latitude': ?latitude,
        'longitude': ?longitude,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );

    return Booking.fromJson(res.data!);
  }

  Future<List<Booking>> findMyBookings({String? status, int page = 1, int pageSize = 30}) async {
    final res = await _ref.read(apiClientProvider).get<Map<String, dynamic>>(
      '/bookings',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        'page': page,
        'pageSize': pageSize,
      },
    );

    final data = res.data;
    if (data == null || data['items'] == null) return [];

    final list = data['items'] as List<dynamic>;
    return list.map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Booking> getBookingById(String id) async {
    final res = await _ref.read(apiClientProvider).get<Map<String, dynamic>>('/bookings/$id');
    return Booking.fromJson(res.data!);
  }

  Future<Booking> acceptBooking(String id) async {
    final res = await _ref.read(apiClientProvider).post<Map<String, dynamic>>('/bookings/$id/accept');
    return Booking.fromJson(res.data!);
  }

  Future<Booking> rejectBooking(String id, {String? reason}) async {
    final res = await _ref.read(apiClientProvider).post<Map<String, dynamic>>(
      '/bookings/$id/reject',
      data: {
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
    return Booking.fromJson(res.data!);
  }

  Future<Booking> cancelBooking(String id, {required String reason}) async {
    final res = await _ref.read(apiClientProvider).post<Map<String, dynamic>>(
      '/bookings/$id/cancel',
      data: {'reason': reason},
    );
    return Booking.fromJson(res.data!);
  }

  Future<Booking> startBooking(String id) async {
    final res = await _ref.read(apiClientProvider).post<Map<String, dynamic>>('/bookings/$id/start');
    return Booking.fromJson(res.data!);
  }

  Future<Booking> completeBooking(String id) async {
    final res = await _ref.read(apiClientProvider).post<Map<String, dynamic>>('/bookings/$id/complete');
    return Booking.fromJson(res.data!);
  }
}

final bookingsRepositoryProvider = Provider<BookingsRepository>((ref) {
  return BookingsRepository(ref);
});

final myBookingsProvider = FutureProvider.family<List<Booking>, String?>((ref, statusFilter) async {
  return ref.watch(bookingsRepositoryProvider).findMyBookings(status: statusFilter);
});

final bookingDetailProvider = FutureProvider.family<Booking, String>((ref, id) async {
  return ref.watch(bookingsRepositoryProvider).getBookingById(id);
});
