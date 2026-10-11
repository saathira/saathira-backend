import 'package:flutter/material.dart';
import 'activity.dart';

enum BookingStatus {
  pending,
  paymentPending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  rejected,
  expired,
  disputed;

  static BookingStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return BookingStatus.pending;
      case 'PAYMENT_PENDING':
        return BookingStatus.paymentPending;
      case 'CONFIRMED':
        return BookingStatus.confirmed;
      case 'IN_PROGRESS':
        return BookingStatus.inProgress;
      case 'COMPLETED':
        return BookingStatus.completed;
      case 'CANCELLED':
        return BookingStatus.cancelled;
      case 'REJECTED':
        return BookingStatus.rejected;
      case 'EXPIRED':
        return BookingStatus.expired;
      case 'DISPUTED':
        return BookingStatus.disputed;
      default:
        return BookingStatus.pending;
    }
  }

  String get dbValue {
    switch (this) {
      case BookingStatus.pending:
        return 'PENDING';
      case BookingStatus.paymentPending:
        return 'PAYMENT_PENDING';
      case BookingStatus.confirmed:
        return 'CONFIRMED';
      case BookingStatus.inProgress:
        return 'IN_PROGRESS';
      case BookingStatus.completed:
        return 'COMPLETED';
      case BookingStatus.cancelled:
        return 'CANCELLED';
      case BookingStatus.rejected:
        return 'REJECTED';
      case BookingStatus.expired:
        return 'EXPIRED';
      case BookingStatus.disputed:
        return 'DISPUTED';
    }
  }

  String get label {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending Approval';
      case BookingStatus.paymentPending:
        return 'Awaiting Payment';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.rejected:
        return 'Declined';
      case BookingStatus.expired:
        return 'Expired';
      case BookingStatus.disputed:
        return 'Disputed';
    }
  }

  Color get color {
    switch (this) {
      case BookingStatus.pending:
        return Colors.amber;
      case BookingStatus.paymentPending:
        return const Color(0xFF6366F1);
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.inProgress:
        return Colors.cyan;
      case BookingStatus.completed:
        return const Color(0xFF10B981);
      case BookingStatus.cancelled:
        return Colors.redAccent;
      case BookingStatus.rejected:
        return Colors.deepOrange;
      case BookingStatus.expired:
        return Colors.grey;
      case BookingStatus.disputed:
        return Colors.purpleAccent;
    }
  }

  IconData get icon {
    switch (this) {
      case BookingStatus.pending:
        return Icons.hourglass_top_rounded;
      case BookingStatus.paymentPending:
        return Icons.payment_rounded;
      case BookingStatus.confirmed:
        return Icons.check_circle_rounded;
      case BookingStatus.inProgress:
        return Icons.run_circle_outlined;
      case BookingStatus.completed:
        return Icons.task_alt_rounded;
      case BookingStatus.cancelled:
        return Icons.cancel_outlined;
      case BookingStatus.rejected:
        return Icons.do_not_disturb_on_outlined;
      case BookingStatus.expired:
        return Icons.timer_off_outlined;
      case BookingStatus.disputed:
        return Icons.warning_amber_rounded;
    }
  }
}

class BookingUserSummary {
  final String id;
  final String fullName;
  final String? photoUrl;
  final String? city;
  final String? phone;
  final String? gender;

  const BookingUserSummary({
    required this.id,
    required this.fullName,
    this.photoUrl,
    this.city,
    this.phone,
    this.gender,
  });

  factory BookingUserSummary.fromJson(Map<String, dynamic> json) {
    return BookingUserSummary(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? 'User',
      photoUrl: json['photoUrl'] as String?,
      city: json['city'] as String?,
      phone: json['phone'] as String?,
      gender: json['gender'] as String?,
    );
  }
}

class BookingStatusHistory {
  final String id;
  final String? from;
  final String to;
  final String actorId;
  final String? note;
  final DateTime createdAt;

  const BookingStatusHistory({
    required this.id,
    this.from,
    required this.to,
    required this.actorId,
    this.note,
    required this.createdAt,
  });

  factory BookingStatusHistory.fromJson(Map<String, dynamic> json) {
    return BookingStatusHistory(
      id: json['id'] as String? ?? '',
      from: json['from'] as String?,
      to: json['to'] as String? ?? '',
      actorId: json['actorId'] as String? ?? '',
      note: json['note'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

class Booking {
  final String id;
  final String customerId;
  final String companionId;
  final String activityId;
  final DateTime startAt;
  final DateTime endAt;
  final String meetingPlace;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final int amount; // in paise
  final int commission; // in paise
  final BookingStatus status;
  final String? cancelledBy;
  final String? cancelReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined relations
  final Activity? activity;
  final BookingUserSummary? customer;
  final BookingUserSummary? companionUser;
  final List<BookingStatusHistory> history;

  const Booking({
    required this.id,
    required this.customerId,
    required this.companionId,
    required this.activityId,
    required this.startAt,
    required this.endAt,
    required this.meetingPlace,
    this.latitude,
    this.longitude,
    this.notes,
    required this.amount,
    required this.commission,
    required this.status,
    this.cancelledBy,
    this.cancelReason,
    required this.createdAt,
    required this.updatedAt,
    this.activity,
    this.customer,
    this.companionUser,
    this.history = const [],
  });

  int get amountInRupees => amount ~/ 100;
  int get commissionInRupees => commission ~/ 100;
  int get durationMinutes => endAt.difference(startAt).inMinutes;
  double get durationHours => durationMinutes / 60.0;

  factory Booking.fromJson(Map<String, dynamic> json) {
    BookingUserSummary? companionUserSummary;
    if (json['companion'] != null && json['companion']['user'] != null) {
      companionUserSummary = BookingUserSummary.fromJson(json['companion']['user'] as Map<String, dynamic>);
    }

    BookingUserSummary? customerSummary;
    if (json['customer'] != null) {
      customerSummary = BookingUserSummary.fromJson(json['customer'] as Map<String, dynamic>);
    }

    Activity? activityObj;
    if (json['activity'] != null) {
      activityObj = Activity.fromJson(json['activity'] as Map<String, dynamic>);
    }

    List<BookingStatusHistory> historyList = [];
    if (json['history'] is List) {
      historyList = (json['history'] as List)
          .map((h) => BookingStatusHistory.fromJson(h as Map<String, dynamic>))
          .toList();
    }

    return Booking(
      id: json['id'] as String? ?? '',
      customerId: json['customerId'] as String? ?? '',
      companionId: json['companionId'] as String? ?? '',
      activityId: json['activityId'] as String? ?? '',
      startAt: json['startAt'] != null
          ? DateTime.parse(json['startAt'] as String)
          : DateTime.now(),
      endAt: json['endAt'] != null
          ? DateTime.parse(json['endAt'] as String)
          : DateTime.now(),
      meetingPlace: json['meetingPlace'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      amount: json['amount'] as int? ?? 0,
      commission: json['commission'] as int? ?? 0,
      status: BookingStatus.fromString(json['status'] as String? ?? 'PENDING'),
      cancelledBy: json['cancelledBy'] as String?,
      cancelReason: json['cancelReason'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      activity: activityObj,
      customer: customerSummary,
      companionUser: companionUserSummary,
      history: historyList,
    );
  }
}
