import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class UserLocation {
  final String city;
  final String state;
  final String country;
  final double latitude;
  final double longitude;
  final String? zipCode;
  final String? ip;
  final DateTime detectedAt;
  final bool isGpsPrecise;
  final double? accuracyMeters;

  const UserLocation({
    required this.city,
    required this.state,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.zipCode,
    this.ip,
    required this.detectedAt,
    this.isGpsPrecise = false,
    this.accuracyMeters,
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
      isGpsPrecise: false,
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

  /// Automatically fetch device location:
  /// 1. Tries precise device hardware GPS via Geolocator first
  /// 2. If denied or unavailable, falls back to IP geolocation
  Future<UserLocation> fetchCurrentLocation() async {
    // 1. Primary: Device-level GPS Coordinates
    try {
      final gpsLoc = await _tryGetDeviceGpsLocation();
      if (gpsLoc != null) {
        return gpsLoc;
      }
    } catch (_) {
      // Fall through to IP geolocation
    }

    // 2. Secondary fallback: ip-api.com
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
            isGpsPrecise: false,
          );
        }
      }
    } catch (_) {
      // Ignore and fallback to secondary provider
    }

    // 3. Tertiary fallback: ipapi.co
    try {
      final res = await _dio.get('https://ipapi.co/json/');
      if (res.statusCode == 200 && res.data is Map) {
        final data = res.data as Map;
        final city = (data['city'] as String?)?.trim();
        final region = (data['regionName'] as String?)?.trim();
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
            isGpsPrecise: false,
          );
        }
      }
    } catch (_) {
      // Ignore and proceed to fallback
    }

    // 4. Default fallback for sandbox / offline
    return UserLocation.fallback();
  }

  /// Attempts to acquire device-level GPS coordinates and reverse geocode city name
  Future<UserLocation?> _tryGetDeviceGpsLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    // Fetch high-accuracy device GPS position
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 8),
      ),
    );

    String city = 'Nearby';
    String state = '';
    String country = 'India';

    // Reverse geocode GPS coordinates to obtain readable city/locality
    try {
      final geoRes = await _dio.get(
        'https://api.bigdatacloud.net/data/reverse-geocode-client',
        queryParameters: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'localityLanguage': 'en',
        },
      );

      if (geoRes.statusCode == 200 && geoRes.data is Map) {
        final d = geoRes.data as Map;
        final detectedCity = (d['city'] as String?)?.trim() ?? (d['locality'] as String?)?.trim();
        final detectedState = (d['principalSubdivision'] as String?)?.trim();
        final detectedCountry = (d['countryName'] as String?)?.trim();

        if (detectedCity != null && detectedCity.isNotEmpty) {
          city = detectedCity;
        }
        if (detectedState != null && detectedState.isNotEmpty) {
          state = detectedState;
        }
        if (detectedCountry != null && detectedCountry.isNotEmpty) {
          country = detectedCountry;
        }
      }
    } catch (_) {
      // Keep coordinates even if reverse geocoding fails
    }

    return UserLocation(
      city: city,
      state: state,
      country: country,
      latitude: position.latitude,
      longitude: position.longitude,
      detectedAt: DateTime.now(),
      isGpsPrecise: true,
      accuracyMeters: position.accuracy,
    );
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
        isGpsPrecise: lat != null && lng != null,
      ),
    );
  }
}

final currentLocationProvider =
    NotifierProvider<CurrentLocationNotifier, AsyncValue<UserLocation?>>(() {
  return CurrentLocationNotifier();
});
