import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      type: json['type'] as String? ?? 'SYSTEM',
      title: json['title'] as String? ?? 'Notification',
      body: json['body'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>?,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt'] as String) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  IconData get icon {
    switch (type.toUpperCase()) {
      case 'BOOKING_REQUEST':
      case 'BOOKING_ACCEPTED':
      case 'BOOKING_CONFIRMED':
        return Icons.calendar_today_rounded;
      case 'PAYMENT_RECEIVED':
      case 'PAYMENT_CONFIRMED':
        return Icons.payment_rounded;
      case 'SAFETY_ALERT':
        return Icons.shield_rounded;
      case 'REVIEW_RECEIVED':
        return Icons.star_rounded;
      case 'VERIFICATION_APPROVED':
        return Icons.verified_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get color {
    switch (type.toUpperCase()) {
      case 'BOOKING_CONFIRMED':
      case 'VERIFICATION_APPROVED':
        return Colors.green;
      case 'PAYMENT_RECEIVED':
      case 'PAYMENT_CONFIRMED':
        return const Color(0xFF6366F1);
      case 'SAFETY_ALERT':
        return Colors.redAccent;
      case 'REVIEW_RECEIVED':
        return Colors.amber;
      default:
        return Colors.white70;
    }
  }
}
