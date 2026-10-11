import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../models/app_user.dart';
import '../../models/discovery_companion.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/discovery_repository.dart';
import '../../repositories/notifications_repository.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../booking/my_bookings_screen.dart';
import '../chat/chat_list_screen.dart';
import '../discovery/companions_directory_screen.dart';
import '../discovery/discovery_filter_sheet.dart';
import '../profile/customer_profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentTabIndex = 0;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showLocationSelectorModal(BuildContext context) {
    final searchCityCtrl = TextEditingController();
    bool detecting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final activeCity = ref.watch(discoveryFilterProvider).city;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Location',
                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Discover verified companions near your current city or area.',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 18),

                    // Auto-Detect Location Action Button
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        key: const Key('btn_auto_detect_location'),
                        icon: detecting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.my_location_rounded, color: Colors.white, size: 20),
                        label: Text(
                          detecting ? 'Detecting Location...' : 'Fetch Location Automatically 🎯',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: detecting
                            ? null
                            : () async {
                                final nav = Navigator.of(context);
                                final messenger = ScaffoldMessenger.of(context);
                                setModalState(() => detecting = true);
                                try {
                                  final loc = await ref.read(currentLocationProvider.notifier).autoDetectLocation();
                                  ref.read(discoveryFilterProvider.notifier).setCity(loc.city);
                                  if (mounted) {
                                    nav.pop();
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text('📍 Location auto-detected: ${loc.displayName}'),
                                        backgroundColor: const Color(0xFF10B981),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) setModalState(() => detecting = false);
                                }
                              },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // City Search Input
                    TextField(
                      controller: searchCityCtrl,
                      decoration: InputDecoration(
                        hintText: 'Enter city or region (e.g. Pune, Delhi)...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
                          onPressed: () {
                            final text = searchCityCtrl.text.trim();
                            if (text.isNotEmpty) {
                              ref.read(discoveryFilterProvider.notifier).setCity(text);
                              Navigator.pop(context);
                            }
                          },
                        ),
                        filled: true,
                        fillColor: AppColors.bg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (val) {
                        final text = val.trim();
                        if (text.isNotEmpty) {
                          ref.read(discoveryFilterProvider.notifier).setCity(text);
                          Navigator.pop(context);
                        }
                      },
                    ),

                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Popular Cities', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        if (activeCity != null)
                          GestureDetector(
                            onTap: () {
                              ref.read(discoveryFilterProvider.notifier).setCity(null);
                              Navigator.pop(context);
                            },
                            child: const Text('Show All Cities', style: TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'Mumbai',
                        'Delhi NCR',
                        'Bengaluru',
                        'Pune',
                        'Hyderabad',
                        'Chennai',
                        'Kolkata',
                        'Ahmedabad',
                        'Jaipur',
                        'Goa',
                      ].map((cityName) {
                        final isSelected = activeCity?.toLowerCase() == cityName.toLowerCase();
                        return ActionChip(
                          label: Text(cityName),
                          avatar: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                          backgroundColor: isSelected ? AppColors.primary : AppColors.bg,
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : Colors.white12,
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.text,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                          onPressed: () {
                            ref.read(discoveryFilterProvider.notifier).setCity(cityName);
                            Navigator.pop(context);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static const List<Map<String, dynamic>> _featuredCategories = [
    {
      'slug': '',
      'name': 'All Services',
      'emoji': '🌟',
      'icon': Icons.auto_awesome_rounded,
      'badge': 'Explore All',
      'subtitle': 'Browse all companions',
    },
    {
      'slug': 'shopping',
      'name': 'Shopping & Malls',
      'emoji': '🛍️',
      'icon': Icons.shopping_bag_rounded,
      'badge': 'Popular',
      'subtitle': 'Retail & errands companion',
    },
    {
      'slug': 'doctor-visit',
      'name': 'Doctor Visit',
      'emoji': '🏥',
      'icon': Icons.local_hospital_rounded,
      'badge': 'Medical Care',
      'subtitle': 'Clinics & hospital wait support',
    },
    {
      'slug': 'cafe-dinner',
      'name': 'Cafe & Dining',
      'emoji': '☕',
      'icon': Icons.restaurant_rounded,
      'badge': 'Trending',
      'subtitle': 'Coffee talks & culinary outings',
    },
    {
      'slug': 'movies',
      'name': 'Movies & Events',
      'emoji': '🎬',
      'icon': Icons.movie_filter_rounded,
      'badge': 'Entertainment',
      'subtitle': 'Cinema, shows & exhibitions',
    },
    {
      'slug': 'city-exploration',
      'name': 'City Walks',
      'emoji': '🗺️',
      'icon': Icons.explore_rounded,
      'badge': 'Outdoor',
      'subtitle': 'Parks, monuments & photo strolls',
    },
    {
      'slug': 'conversation',
      'name': 'Friendly Chat',
      'emoji': '💬',
      'icon': Icons.forum_rounded,
      'badge': 'Social Talk',
      'subtitle': 'Meaningful discussions & tea chats',
    },
  ];

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _triggerEmergencySos() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Text('Emergency Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'If you are in immediate danger or require emergency assistance, please dial National Emergency Services immediately.',
              style: TextStyle(fontSize: 13.5, height: 1.4),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0x1AE53935),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(Icons.call, color: Colors.redAccent),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('National Emergency: 112', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 14)),
                      Text('Women Helpline: 1091', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }



  Widget _buildShimmerCompanionCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 140,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 90,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverTab(BuildContext context) {
    final user = ref.watch(sessionProvider).value?.user;
    final name = user?.fullName?.split(' ').first ?? 'Friend';
    final city = user?.city ?? 'India';
    final filter = ref.watch(discoveryFilterProvider);
    final companionsAsync = ref.watch(discoveredCompanionsProvider);
    final unreadNotifs = ref.watch(unreadNotificationsCountProvider);

    final hasActiveFilter = filter.activity != null ||
        filter.query != null ||
        filter.minPrice != null ||
        filter.maxPrice != null ||
        filter.city != null ||
        filter.minRating != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${_getGreeting()}, $name',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                ),
                const SizedBox(width: 4),
                const Text('👋', style: TextStyle(fontSize: 16)),
              ],
            ),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _showLocationSelectorModal(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 13, color: AppColors.secondary),
                  const SizedBox(width: 3),
                  Text(
                    filter.city ?? city,
                    style: const TextStyle(fontSize: 12.5, color: Colors.white70, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.muted),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Notifications with badge
          Stack(
            children: [
              IconButton(
                key: const Key('btn_notifications'),
                tooltip: 'Notifications',
                icon: const Icon(Icons.notifications_none_rounded, size: 24),
                onPressed: () => context.push('/notifications'),
              ),
              if (unreadNotifs > 0)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          if (user?.role == AppRole.companion)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.4)),
                label: const Text('Companion Hub', style: TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.bold)),
                avatar: const Icon(Icons.dashboard_outlined, size: 14, color: AppColors.secondary),
                onPressed: () => context.go('/companion/dashboard'),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(discoveredCompanionsProvider.future),
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            // Search & Filter Box
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 16, right: 10),
                    child: Icon(Icons.search, color: AppColors.muted, size: 22),
                  ),
                  Expanded(
                    child: TextField(
                      key: const Key('home_search'),
                      controller: _searchCtrl,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search companions or activities...',
                        hintStyle: TextStyle(color: AppColors.muted.withValues(alpha: 0.8), fontSize: 13.5),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  ref.read(discoveryFilterProvider.notifier).setQuery('');
                                },
                              )
                            : null,
                      ),
                      onSubmitted: (q) {
                        ref.read(discoveryFilterProvider.notifier).setQuery(q);
                      },
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: hasActiveFilter ? AppColors.primary : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.tune_rounded,
                        size: 20,
                        color: hasActiveFilter ? Colors.white : AppColors.muted,
                      ),
                      tooltip: 'Filter options',
                      onPressed: () => DiscoveryFilterSheet.show(context),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Permitted Activity Category Showcase Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Permitted Activities',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'Verified, non-romantic accompaniment only',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (filter.activity != null)
                      GestureDetector(
                        onTap: () => ref.read(discoveryFilterProvider.notifier).setActivity(null),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Clear',
                                style: TextStyle(
                                  color: AppColors.secondary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.close_rounded, size: 13, color: AppColors.secondary),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                // Horizontal Carousel of Rich Activity Cards
                SizedBox(
                  height: 142,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _featuredCategories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, idx) {
                      final cat = _featuredCategories[idx];
                      final slug = cat['slug'] as String;
                      final isAllOption = slug.isEmpty;
                      final isSelected = isAllOption
                          ? filter.activity == null
                          : filter.activity == slug;

                      return InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () {
                          if (isAllOption) {
                            ref.read(discoveryFilterProvider.notifier).setActivity(null);
                          } else {
                            ref.read(discoveryFilterProvider.notifier).setActivity(
                                  isSelected ? null : slug,
                                );
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          width: 168,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.18)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white.withValues(alpha: 0.08),
                              width: isSelected ? 1.8 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Top Row: Emoji/Icon Box + Tag Badge
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        cat['emoji'] as String,
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withValues(alpha: 0.3)
                                          : Colors.white.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isSelected) ...[
                                          const Icon(Icons.check_rounded, size: 11, color: Colors.white),
                                          const SizedBox(width: 3),
                                        ],
                                        Text(
                                          isSelected ? 'Active' : cat['badge'] as String,
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? Colors.white : Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              // Text Titles
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat['name'] as String,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    cat['subtitle'] as String,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: isSelected ? Colors.white70 : AppColors.muted,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Active Filter Status Micro-Bar
                if (filter.activity != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_alt_rounded, size: 14, color: AppColors.secondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Filtering: ${_featuredCategories.firstWhere((c) => c['slug'] == filter.activity, orElse: () => {'name': filter.activity})['name']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => ref.read(discoveryFilterProvider.notifier).setActivity(null),
                          child: const Text(
                            'Show All',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 22),

            // Safety & SOS Quick Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_outlined, color: Colors.greenAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '100% Verified Companions',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Escrow protection & Emergency 112 SOS',
                          style: TextStyle(color: AppColors.muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.emergency_outlined, color: Colors.redAccent, size: 24),
                    tooltip: 'Emergency SOS',
                    onPressed: _triggerEmergencySos,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Companions Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Available Companions',
                      style: TextStyle(fontSize: 17.5, fontWeight: FontWeight.bold, letterSpacing: -0.2),
                    ),
                    const SizedBox(width: 8),
                    companionsAsync.maybeWhen(
                      data: (list) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${list.length}',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.secondary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: AppColors.secondary,
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                  iconAlignment: IconAlignment.end,
                  label: const Text('View All', style: TextStyle(color: AppColors.secondary, fontSize: 13, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    setState(() => _currentTabIndex = 1);
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Companions Feed
            companionsAsync.when(
              loading: () => Column(
                children: List.generate(3, (_) => _buildShimmerCompanionCard()),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.muted),
                      const SizedBox(height: 12),
                      Text(
                        'Could not connect to server',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        apiErrorMessage(e),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(minimumSize: const Size(0, 36)),
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
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_search_rounded, size: 40, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Companions Found',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Try clearing filters, searching another activity, or expanding your location radius.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            _searchCtrl.clear();
                            ref.read(discoveryFilterProvider.notifier).reset();
                          },
                          child: const Text('Clear All Filters'),
                        ),
                      ],
                    ),
                  );
                }

                return AutoSlideCompanionsCarousel(
                  companions: companions,
                  onViewAll: () => setState(() => _currentTabIndex = 1),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          _buildDiscoverTab(context),
          const CompanionsDirectoryScreen(),
          const MyBookingsScreen(),
          const ChatListScreen(),
          const CustomerProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: (index) => setState(() => _currentTabIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.secondary,
          unselectedItemColor: AppColors.muted,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore_rounded),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_outlined),
              activeIcon: Icon(Icons.people_alt_rounded),
              label: 'Companions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month_rounded),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              activeIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class AutoSlideCompanionsCarousel extends StatefulWidget {
  final List<DiscoveryCompanion> companions;
  final VoidCallback onViewAll;

  const AutoSlideCompanionsCarousel({
    super.key,
    required this.companions,
    required this.onViewAll,
  });

  @override
  State<AutoSlideCompanionsCarousel> createState() =>
      _AutoSlideCompanionsCarouselState();
}

class _AutoSlideCompanionsCarouselState
    extends State<AutoSlideCompanionsCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.companions.length <= 1) return;
    _timer = Timer.periodic(const Duration(milliseconds: 3800), (t) {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_currentPage + 1) % widget.companions.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.companions.isEmpty) return const SizedBox.shrink();

    final count = widget.companions.length;

    return Column(
      children: [
        SizedBox(
          height: 258,
          child: PageView.builder(
            controller: _pageController,
            itemCount: count,
            onPageChanged: (idx) {
              setState(() => _currentPage = idx);
              _startTimer();
            },
            itemBuilder: (ctx, index) {
              final companion = widget.companions[index];
              return _buildSlideCard(ctx, companion);
            },
          ),
        ),
        const SizedBox(height: 12),
        // Dots Indicator + Position Pill
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                count > 6 ? 6 : count,
                (dotIndex) {
                  final isActive = (dotIndex == 5 && _currentPage >= 5) || (_currentPage == dotIndex);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 22 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.secondary
                          : Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Text(
                '${_currentPage + 1} of $count',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSlideCard(BuildContext context, DiscoveryCompanion companion) {
    final firstLetter = companion.user.fullName.isNotEmpty
        ? companion.user.fullName[0].toUpperCase()
        : 'C';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => context.push('/companion/detail/${companion.id}'),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar with purple border
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.bg,
                            child: Text(
                              firstLetter,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        if (companion.isAvailable)
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.surface, width: 2.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // Companion Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  companion.user.fullName,
                                  style: const TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (companion.verificationStatus == 'APPROVED') ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.verified, color: Colors.lightGreenAccent, size: 17),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 13, color: AppColors.muted),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  companion.user.city ?? 'India',
                                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
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
                            const SizedBox(height: 3),
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

                    // Hourly Rate & Star Rating
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${companion.hourlyRateInRupees}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          '/ hour',
                          style: TextStyle(fontSize: 11, color: AppColors.muted),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
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
                                style: const TextStyle(color: Colors.amber, fontSize: 11.5, fontWeight: FontWeight.bold),
                              ),
                              if (companion.ratingCount > 0)
                                Text(
                                  ' (${companion.ratingCount})',
                                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Bio snippet
                if (companion.bio != null && companion.bio!.isNotEmpty)
                  Text(
                    companion.bio!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.3),
                  ),

                // Activities & Book CTA
                Row(
                  children: [
                    Expanded(
                      child: companion.activities.isNotEmpty
                          ? Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: companion.activities.take(2).map((a) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.bg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                  ),
                                  child: Text(
                                    a.activity.name,
                                    style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
                                  ),
                                );
                              }).toList()
                                ..addAll(companion.activities.length > 2
                                    ? [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.bg,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '+${companion.activities.length - 2}',
                                            style: const TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ]
                                    : []),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => context.push('/companion/detail/${companion.id}'),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Book Now'),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 14),
                        ],
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
}
