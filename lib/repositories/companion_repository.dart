import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../models/activity.dart';
import '../models/companion_profile.dart';

class CompanionRepository {
  CompanionRepository(this._ref);
  final Ref _ref;

  Future<List<Activity>> fetchActivities() async {
    final res = await _ref.read(apiClientProvider).get<List<dynamic>>('/activities');
    return (res.data ?? [])
        .map((e) => Activity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CompanionProfile> fetchMyProfile() async {
    final res = await _ref.read(apiClientProvider).get<Map<String, dynamic>>('/companions/me');
    return CompanionProfile.fromJson(res.data!);
  }

  Future<void> updateProfile({
    String? bio,
    List<String>? languages,
    int? hourlyRate, // in paise
    String? payoutUpi,
    int? serviceRadiusKm,
    bool? isAvailable,
  }) async {
    await _ref.read(apiClientProvider).patch('/companions/me', data: {
      'bio': ?bio,
      'languages': ?languages,
      'hourlyRate': ?hourlyRate,
      'payoutUpi': ?payoutUpi,
      'serviceRadiusKm': ?serviceRadiusKm,
      'isAvailable': ?isAvailable,
    });
  }

  Future<void> submitVerification({
    required String documentType,
    required String documentPath,
    String? selfiePath,
  }) async {
    await _ref.read(apiClientProvider).post('/companions/me/verification', data: {
      'documentType': documentType,
      'documentPath': documentPath,
      'selfiePath': ?selfiePath,
    });
  }

  Future<void> syncActivities(List<Map<String, dynamic>> activities) async {
    await _ref.read(apiClientProvider).put('/companions/me/activities', data: {
      'activities': activities,
    });
  }

  Future<void> syncAvailability(List<AvailabilitySlot> slots) async {
    await _ref.read(apiClientProvider).put('/companions/me/availability', data: {
      'slots': slots.map((s) => s.toJson()).toList(),
    });
  }
}

final companionRepositoryProvider = Provider<CompanionRepository>((ref) {
  return CompanionRepository(ref);
});

final activitiesListProvider = FutureProvider<List<Activity>>((ref) async {
  return ref.watch(companionRepositoryProvider).fetchActivities();
});

class MyCompanionProfileNotifier extends AsyncNotifier<CompanionProfile?> {
  @override
  Future<CompanionProfile?> build() async {
    try {
      return await ref.read(companionRepositoryProvider).fetchMyProfile();
    } catch (_) {
      return null;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(companionRepositoryProvider).fetchMyProfile());
  }
}

final myCompanionProfileProvider =
    AsyncNotifierProvider<MyCompanionProfileNotifier, CompanionProfile?>(MyCompanionProfileNotifier.new);
