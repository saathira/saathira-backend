import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserLocation {
  final String city;
  final String state;
  final String country;
  final double latitude;
  final double longitude;
  final String? zipCode;
  final String? ip;
  final DateTime detectedAt;

  const UserLocation({
    required this.city,
    required this.state,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.zipCode,
    this.ip,
    required this.detectedAt,
  });

  String get displayName => state.isNotEmpty ? '$city, $state' : city;

  factory UserLocation.fallback({String city = 'Mumbai', String state = 'Maharashtra'}) {
    return UserLocation(
      city: city,
      state: state,
      country: 'India',
      latitude: 19.0760,
      longitude: 72.8777,
      detectedAt: DateTime.now(),
    );
  }
}

class LocationService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  /// Automatically fetch device location via high-speed geo-IP & reverse lookup
  Future<UserLocation> fetchCurrentLocation() async {
    // 1. Primary source: ip-api.com
    try {
      final res = await _dio.get('http://ip-api.com/json/?fields=status,country,regionName,city,zip,lat,lon,query');
      if (res.statusCode == 200 && res.data is Map && res.data['status'] == 'success') {
        final data = res.data as Map;
        final city = (data['city'] as String?)?.trim();
        final region = (data['regionName'] as String?)?.trim();
        final country = (data['country'] as String?)?.trim() ?? 'India';
        final lat = (data['lat'] as num?)?.toDouble() ?? 19.0760;
        final lon = (data['lon'] as num?)?.toDouble() ?? 72.8777;
        final zip = data['zip']?.toString();
        final ip = data['query']?.toString();

        if (city != null && city.isNotEmpty) {
          return UserLocation(
            city: city,
            state: region ?? '',
            country: country,
            latitude: lat,
            longitude: lon,
            zipCode: zip,
            ip: ip,
            detectedAt: DateTime.now(),
          );
        }
      }
    } catch (_) {
      // Ignore and fallback to secondary provider
    }

    // 2. Secondary fallback: ipapi.co
    try {
      final res = await _dio.get('https://ipapi.co/json/');
      if (res.statusCode == 200 && res.data is Map) {
        final data = res.data as Map;
        final city = (data['city'] as String?)?.trim();
        final region = (data['region'] as String?)?.trim();
        final country = (data['country_name'] as String?)?.trim() ?? 'India';
        final lat = (data['latitude'] as num?)?.toDouble() ?? 19.0760;
        final lon = (data['longitude'] as num?)?.toDouble() ?? 72.8777;
        final postal = data['postal']?.toString();
        final ip = data['ip']?.toString();

        if (city != null && city.isNotEmpty) {
          return UserLocation(
            city: city,
            state: region ?? '',
            country: country,
            latitude: lat,
            longitude: lon,
            zipCode: postal,
            ip: ip,
            detectedAt: DateTime.now(),
          );
        }
      }
    } catch (_) {
      // Ignore and proceed to fallback
    }

    // 3. Fallback for offline or sandbox mode
    return UserLocation.fallback();
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

class CurrentLocationNotifier extends Notifier<AsyncValue<UserLocation?>> {
  @override
  AsyncValue<UserLocation?> build() => const AsyncValue.data(null);

  Future<UserLocation> autoDetectLocation() async {
    state = const AsyncValue.loading();
    try {
      final loc = await ref.read(locationServiceProvider).fetchCurrentLocation();
      state = AsyncValue.data(loc);
      return loc;
    } catch (_) {
      final fallback = UserLocation.fallback();
      state = AsyncValue.data(fallback);
      return fallback;
    }
  }

  void setManualLocation(String city, {String stateName = 'India', double? lat, double? lng}) {
    state = AsyncValue.data(
      UserLocation(
        city: city,
        state: stateName,
        country: 'India',
        latitude: lat ?? 19.0760,
        longitude: lng ?? 72.8777,
        detectedAt: DateTime.now(),
      ),
    );
  }
}

final currentLocationProvider =
    NotifierProvider<CurrentLocationNotifier, AsyncValue<UserLocation?>>(() {
  return CurrentLocationNotifier();
});
