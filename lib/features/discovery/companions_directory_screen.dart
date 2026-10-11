import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../models/discovery_companion.dart';
import '../../repositories/discovery_repository.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import 'discovery_filter_sheet.dart';

class CompanionsDirectoryScreen extends ConsumerStatefulWidget {
  const CompanionsDirectoryScreen({super.key});

  @override
  ConsumerState<CompanionsDirectoryScreen> createState() =>
      _CompanionsDirectoryScreenState();
}

class _CompanionsDirectoryScreenState
    extends ConsumerState<CompanionsDirectoryScreen> {
  final _searchCtrl = TextEditingController();
  String? _selectedActivity;
  bool _detectingLocation = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  static const List<Map<String, String>> _activities = [
    {'slug': '', 'name': 'All Activities', 'icon': '🌟'},
    {'slug': 'shopping', 'name': 'Shopping', 'icon': '🛍️'},
    {'slug': 'doctor-visit', 'name': 'Doctor Visit', 'icon': '🏥'},
    {'slug': 'movies', 'name': 'Movies & Events', 'icon': '🎬'},
    {'slug': 'cafe-dinner', 'name': 'Cafe & Dining', 'icon': '☕'},
    {'slug': 'city-exploration', 'name': 'City Exploration', 'icon': '🗺️'},
    {'slug': 'conversation', 'name': 'Conversation', 'icon': '💬'},
  ];

  Future<void> _autoDetectLocation() async {
    setState(() => _detectingLocation = true);
    try {
      final loc = await ref.read(currentLocationProvider.notifier).autoDetectLocation();
      ref.read(discoveryFilterProvider.notifier).setLocation(
            city: loc.city,
            lat: loc.latitude,
            lng: loc.longitude,
          );
      if (mounted) {
        final precision = loc.isGpsPrecise ? ' (🎯 High-Accuracy GPS)' : ' (Network)';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Location: ${loc.displayName}$precision'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not detect location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _detectingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final companionsAsync = ref.watch(discoveredCompanionsProvider);
    final filter = ref.watch(discoveryFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verified Companions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
            Row(
              children: [
                const Icon(Icons.shield_rounded, size: 12, color: Colors.greenAccent),
                const SizedBox(width: 4),
                Text(
                  filter.city != null ? 'In ${filter.city} • Background Verified' : 'All India • 100% Background Verified',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: _detectingLocation
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary),
                  )
                : const Icon(Icons.my_location_rounded, color: AppColors.secondary),
            tooltip: 'Auto-detect location',
            onPressed: _detectingLocation ? null : _autoDetectLocation,
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Filters',
            onPressed: () => DiscoveryFilterSheet.show(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.refresh(discoveredCompanionsProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          children: [
            // Search Input Bar
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search companions by name, language or hobby...',
                prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(discoveryFilterProvider.notifier).setQuery('');
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) {
                ref.read(discoveryFilterProvider.notifier).setQuery(val);
                setState(() {});
              },
            ),

            const SizedBox(height: 14),

            // Activity Filter Chips Horizontal Scroll
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _activities.map((act) {
                  final isSelected = (_selectedActivity ?? '') == act['slug'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: Text(act['icon']!, style: const TextStyle(fontSize: 14)),
                      label: Text(act['name']!),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.text,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12.5,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : Colors.white12,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedActivity = selected ? (act['slug']!.isEmpty ? null : act['slug']) : null;
                        });
                        ref.read(discoveryFilterProvider.notifier).setActivity(_selectedActivity);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Companion Count & Active Filter Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                companionsAsync.maybeWhen(
                  data: (list) => Text(
                    '${list.length} Verified Companions Available',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.white70),
                  ),
                  orElse: () => const Text(
                    'Searching verified companions...',
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                ),
                if (filter.city != null || filter.activity != null || filter.query != null)
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() {
                        _selectedActivity = null;
                      });
                      ref.read(discoveryFilterProvider.notifier).reset();
                    },
                    child: const Text(
                      'Clear Filters',
                      style: TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Companions List
            companionsAsync.when(
              loading: () => Column(
                children: List.generate(4, (_) => _buildShimmerCompanionCard()),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.muted),
                      const SizedBox(height: 12),
                      const Text('Could not load companions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text(apiErrorMessage(e), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.refresh(discoveredCompanionsProvider),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (companions) {
                if (companions.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.people_outline_rounded, size: 48, color: AppColors.muted),
                        const SizedBox(height: 14),
                        const Text('No Companions Found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        const SizedBox(height: 6),
                        const Text(
                          'Try clearing your filters or selecting a different city or activity.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted, fontSize: 13),
                        ),
                        const SizedBox(height: 18),
                        OutlinedButton(
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _selectedActivity = null);
                            ref.read(discoveryFilterProvider.notifier).reset();
                          },
                          child: const Text('Show All Companions'),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: companions.map((c) => _buildCompanionItemCard(context, c)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanionItemCard(BuildContext context, DiscoveryCompanion companion) {
    final name = companion.user.fullName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'C';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => context.push('/companion/detail/${companion.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar, Info, Rate & Rating
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar with verified badge
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primary,
                          backgroundImage: (companion.user.photoUrl != null &&
                                  companion.user.photoUrl!.isNotEmpty)
                              ? NetworkImage(companion.user.photoUrl!)
                              : null,
                          child: (companion.user.photoUrl == null ||
                                  companion.user.photoUrl!.isEmpty)
                              ? Text(
                                  initial,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        if (companion.verificationStatus == 'APPROVED')
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified,
                                color: Colors.lightGreenAccent,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(width: 14),

                    // Name, City & Languages
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 13, color: AppColors.muted),
                              const SizedBox(width: 3),
                              Text(
                                companion.user.city ?? 'India',
                                style: const TextStyle(color: AppColors.muted, fontSize: 12),
                              ),
                              if (companion.distanceKm != null) ...[
                                const Text(' • ', style: TextStyle(color: AppColors.muted)),
                                Text(
                                  '${companion.distanceKm} km',
                                  style: const TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ],
                          ),
                          if (companion.languages.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '🗣️ ${companion.languages.take(3).join(', ')}',
                              style: const TextStyle(fontSize: 11.5, color: Colors.white60),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Rate & Rating
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${companion.hourlyRateInRupees}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            color: Colors.white,
                          ),
                        ),
                        const Text('/ hr', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                              const SizedBox(width: 3),
                              Text(
                                companion.ratingAvg > 0 ? companion.ratingAvg.toStringAsFixed(1) : 'New',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                if (companion.bio != null && companion.bio!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    companion.bio!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.3),
                  ),
                ],

                const SizedBox(height: 14),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: Colors.white24),
                          minimumSize: const Size(0, 36),
                        ),
                        onPressed: () => context.push('/companion/detail/${companion.id}'),
                        child: const Text('View Profile', style: TextStyle(fontSize: 12.5, color: Colors.white70)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(0, 36),
                        ),
                        onPressed: () => context.push('/companion/detail/${companion.id}'),
                        child: const Text('Book Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCompanionCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
      ),
    );
  }
}
