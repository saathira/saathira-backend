import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../models/booking.dart';

class PaymentOrderResponse {
  final String orderId;
  final int amount; // paise
  final String currency;
  final String keyId;
  final String bookingId;
  final String activityName;
  final String companionName;

  const PaymentOrderResponse({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.keyId,
    required this.bookingId,
    required this.activityName,
    required this.companionName,
  });

  int get amountInRupees => amount ~/ 100;

  factory PaymentOrderResponse.fromJson(Map<String, dynamic> json) {
    return PaymentOrderResponse(
      orderId: json['orderId'] as String? ?? '',
      amount: json['amount'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      keyId: json['keyId'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      activityName: json['activityName'] as String? ?? 'Companionship',
      companionName: json['companionName'] as String? ?? 'Companion',
    );
  }
}

class PaymentsRepository {
  PaymentsRepository(this._ref);
  final Ref _ref;

  Future<PaymentOrderResponse> createOrder(String bookingId) async {
    final res = await _ref.read(apiClientProvider).post<Map<String, dynamic>>(
      '/payments/orders',
      data: {'bookingId': bookingId},
    );
    return PaymentOrderResponse.fromJson(res.data!);
  }

  Future<Booking> verifyPayment({
    required String bookingId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    String? razorpaySignature,
  }) async {
    final res = await _ref.read(apiClientProvider).post<Map<String, dynamic>>(
      '/payments/verify',
      data: {
        'bookingId': bookingId,
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': ?razorpaySignature,
      },
    );
    return Booking.fromJson(res.data!);
  }
}

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return PaymentsRepository(ref);
});
