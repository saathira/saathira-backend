import 'activity.dart';
import 'discovery_companion.dart';

class CompanionActivityItem {
  final String activityId;
  final Activity activity;
  final int? customRate; // in paise

  const CompanionActivityItem({
    required this.activityId,
    required this.activity,
    this.customRate,
  });

  factory CompanionActivityItem.fromJson(Map<String, dynamic> json) {
    return CompanionActivityItem(
      activityId: json['activityId'] as String,
      activity: Activity.fromJson(json['activity'] as Map<String, dynamic>),
      customRate: json['customRate'] as int?,
    );
  }
}

class AvailabilitySlot {
  final String? id;
  final int dayOfWeek; // 0 = Sun..6 = Sat
  final int startMinute;
  final int endMinute;

  const AvailabilitySlot({
    this.id,
    required this.dayOfWeek,
    required this.startMinute,
    required this.endMinute,
  });

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      id: json['id'] as String?,
      dayOfWeek: json['dayOfWeek'] as int,
      startMinute: json['startMinute'] as int,
      endMinute: json['endMinute'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'dayOfWeek': dayOfWeek,
        'startMinute': startMinute,
        'endMinute': endMinute,
      };

  String get dayName {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[dayOfWeek.clamp(0, 6)];
  }

  String formatTime(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get timeRangeLabel => '${formatTime(startMinute)} - ${formatTime(endMinute)}';
}

class VerificationRecord {
  final String id;
  final String documentType;
  final String documentPath;
  final String status;
  final String? reviewNote;
  final DateTime createdAt;

  const VerificationRecord({
    required this.id,
    required this.documentType,
    required this.documentPath,
    required this.status,
    this.reviewNote,
    required this.createdAt,
  });

  factory VerificationRecord.fromJson(Map<String, dynamic> json) {
    return VerificationRecord(
      id: json['id'] as String,
      documentType: json['documentType'] as String,
      documentPath: json['documentPath'] as String,
      status: json['status'] as String,
      reviewNote: json['reviewNote'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class CompanionProfile {
  final String id;
  final String userId;
  final String? bio;
  final List<String> languages;
  final int hourlyRate; // in paise
  final double? latitude;
  final double? longitude;
  final int serviceRadiusKm;
  final String verificationStatus;
  final bool isAvailable;
  final double ratingAvg;
  final int ratingCount;
  final String? payoutUpi;
  final DiscoveryUser? user;
  final List<CompanionActivityItem> activities;
  final List<AvailabilitySlot> availability;
  final List<VerificationRecord> verifications;

  const CompanionProfile({
    required this.id,
    required this.userId,
    this.user,
    this.bio,
    this.languages = const [],
    required this.hourlyRate,
    this.latitude,
    this.longitude,
    required this.serviceRadiusKm,
    required this.verificationStatus,
    required this.isAvailable,
    required this.ratingAvg,
    required this.ratingCount,
    this.payoutUpi,
    this.activities = const [],
    this.availability = const [],
    this.verifications = const [],
  });

  factory CompanionProfile.fromJson(Map<String, dynamic> json) {
    return CompanionProfile(
      id: json['id'] as String,
      userId: json['userId'] as String,
      user: json['user'] != null ? DiscoveryUser.fromJson(json['user'] as Map<String, dynamic>) : null,
      bio: json['bio'] as String?,
      languages: (json['languages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      hourlyRate: json['hourlyRate'] as int? ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      serviceRadiusKm: json['serviceRadiusKm'] as int? ?? 10,
      verificationStatus: json['verificationStatus'] as String? ?? 'NOT_SUBMITTED',
      isAvailable: json['isAvailable'] as bool? ?? true,
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['ratingCount'] as int? ?? 0,
      payoutUpi: json['payoutUpi'] as String?,
      activities: (json['activities'] as List<dynamic>?)
              ?.map((a) => CompanionActivityItem.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      availability: (json['availability'] as List<dynamic>?)
              ?.map((s) => AvailabilitySlot.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      verifications: (json['verifications'] as List<dynamic>?)
              ?.map((v) => VerificationRecord.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  int get hourlyRateInRupees => hourlyRate ~/ 100;
}
