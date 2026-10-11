import 'activity.dart';

class DiscoveryUser {
  final String id;
  final String fullName;
  final String? photoUrl;
  final String? city;
  final String? gender;

  const DiscoveryUser({
    required this.id,
    required this.fullName,
    this.photoUrl,
    this.city,
    this.gender,
  });

  factory DiscoveryUser.fromJson(Map<String, dynamic> json) {
    return DiscoveryUser(
      id: json['id'] as String,
      fullName: json['fullName'] as String? ?? 'Companion',
      photoUrl: json['photoUrl'] as String?,
      city: json['city'] as String?,
      gender: json['gender'] as String?,
    );
  }
}

class DiscoveryActivityItem {
  final String activityId;
  final int? customRate; // in paise
  final Activity activity;

  const DiscoveryActivityItem({
    required this.activityId,
    this.customRate,
    required this.activity,
  });

  factory DiscoveryActivityItem.fromJson(Map<String, dynamic> json) {
    return DiscoveryActivityItem(
      activityId: json['activityId'] as String,
      customRate: json['customRate'] as int?,
      activity: Activity.fromJson(json['activity'] as Map<String, dynamic>),
    );
  }
}

class DiscoveryCompanion {
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
  final double? distanceKm;
  final DiscoveryUser user;
  final List<DiscoveryActivityItem> activities;

  const DiscoveryCompanion({
    required this.id,
    required this.userId,
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
    this.distanceKm,
    required this.user,
    this.activities = const [],
  });

  factory DiscoveryCompanion.fromJson(Map<String, dynamic> json) {
    return DiscoveryCompanion(
      id: json['id'] as String,
      userId: json['userId'] as String,
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
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      user: DiscoveryUser.fromJson(json['user'] as Map<String, dynamic>),
      activities: (json['activities'] as List<dynamic>?)
              ?.map((a) => DiscoveryActivityItem.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  int get hourlyRateInRupees => hourlyRate ~/ 100;
}

class DiscoveryFilter {
  final String? activity;
  final String? city;
  final String? query;
  final int? minPrice;
  final int? maxPrice;
  final double? minRating;
  final String? sort;
  final double? lat;
  final double? lng;
  final int? radiusKm;

  const DiscoveryFilter({
    this.activity,
    this.city,
    this.query,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.sort,
    this.lat,
    this.lng,
    this.radiusKm,
  });

  DiscoveryFilter copyWith({
    String? activity,
    bool clearActivity = false,
    String? city,
    bool clearCity = false,
    String? query,
    bool clearQuery = false,
    int? minPrice,
    int? maxPrice,
    bool clearPrice = false,
    double? minRating,
    bool clearRating = false,
    String? sort,
    double? lat,
    double? lng,
    bool clearCoordinates = false,
    int? radiusKm,
    bool clearRadius = false,
  }) {
    return DiscoveryFilter(
      activity: clearActivity ? null : (activity ?? this.activity),
      city: clearCity ? null : (city ?? this.city),
      query: clearQuery ? null : (query ?? this.query),
      minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
      minRating: clearRating ? null : (minRating ?? this.minRating),
      sort: sort ?? this.sort,
      lat: clearCoordinates ? null : (lat ?? this.lat),
      lng: clearCoordinates ? null : (lng ?? this.lng),
      radiusKm: clearRadius ? null : (radiusKm ?? this.radiusKm),
    );
  }

  Map<String, dynamic> toQueryParameters() {
    return {
      'activity': ?activity,
      'city': ?city,
      'q': ?query,
      'minPrice': ?minPrice,
      'maxPrice': ?maxPrice,
      'minRating': ?minRating,
      'sort': ?sort,
      'lat': ?lat,
      'lng': ?lng,
      'radiusKm': ?radiusKm,
    };
  }
}
