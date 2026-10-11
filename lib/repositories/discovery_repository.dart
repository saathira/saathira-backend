import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../models/companion_profile.dart';
import '../models/discovery_companion.dart';

class DiscoveryRepository {
  DiscoveryRepository(this._ref);
  final Ref _ref;

  Future<List<DiscoveryCompanion>> searchCompanions(DiscoveryFilter filter) async {
    final res = await _ref.read(apiClientProvider).get<Map<String, dynamic>>(
      '/discovery/companions',
      queryParameters: filter.toQueryParameters(),
    );

    final data = res.data;
    if (data == null || data['items'] == null) return [];

    final list = data['items'] as List<dynamic>;
    return list.map((e) => DiscoveryCompanion.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CompanionProfile> getCompanionDetails(String id) async {
    final res = await _ref.read(apiClientProvider).get<Map<String, dynamic>>('/companions/$id');
    return CompanionProfile.fromJson(res.data!);
  }
}

final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  return DiscoveryRepository(ref);
});

class DiscoveryFilterNotifier extends Notifier<DiscoveryFilter> {
  @override
  DiscoveryFilter build() => const DiscoveryFilter();

  void setActivity(String? slug) {
    if (state.activity == slug) {
      state = state.copyWith(clearActivity: true);
    } else {
      state = state.copyWith(activity: slug);
    }
  }

  void setQuery(String q) {
    state = state.copyWith(query: q.trim().isEmpty ? null : q.trim(), clearQuery: q.trim().isEmpty);
  }

  void setCity(String? city) {
    state = state.copyWith(city: city, clearCity: city == null);
  }

  void setPriceRange(int? min, int? max) {
    state = state.copyWith(minPrice: min, maxPrice: max, clearPrice: min == null && max == null);
  }

  void setMinRating(double? rating) {
    state = state.copyWith(minRating: rating, clearRating: rating == null);
  }

  void setSort(String? sort) {
    state = state.copyWith(sort: sort);
  }

  void reset() {
    state = const DiscoveryFilter();
  }
}

final discoveryFilterProvider =
    NotifierProvider<DiscoveryFilterNotifier, DiscoveryFilter>(DiscoveryFilterNotifier.new);

final discoveredCompanionsProvider = FutureProvider<List<DiscoveryCompanion>>((ref) async {
  final filter = ref.watch(discoveryFilterProvider);
  return ref.watch(discoveryRepositoryProvider).searchCompanions(filter);
});

final companionDetailProvider = FutureProvider.family<CompanionProfile, String>((ref, id) async {
  return ref.watch(discoveryRepositoryProvider).getCompanionDetails(id);
});
