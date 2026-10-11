import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/discovery_repository.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';

class DiscoveryFilterSheet extends ConsumerStatefulWidget {
  const DiscoveryFilterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const DiscoveryFilterSheet(),
    );
  }

  @override
  ConsumerState<DiscoveryFilterSheet> createState() => _DiscoveryFilterSheetState();
}

class _DiscoveryFilterSheetState extends ConsumerState<DiscoveryFilterSheet> {
  final _cityCtrl = TextEditingController();
  RangeValues _priceRange = const RangeValues(0, 3000);
  double? _minRating;
  String? _sort;
  int? _selectedRadius;
  UserLocation? _detectedLoc;
  bool _initialized = false;
  bool _detectingLocation = false;

  void _init() {
    if (_initialized) return;
    final f = ref.read(discoveryFilterProvider);
    _cityCtrl.text = f.city ?? '';
    _priceRange = RangeValues(
      (f.minPrice ?? 0).toDouble(),
      (f.maxPrice ?? 3000).toDouble(),
    );
    _minRating = f.minRating;
    _sort = f.sort;
    _selectedRadius = f.radiusKm;
    _initialized = true;
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _autoDetectCity() async {
    setState(() => _detectingLocation = true);
    try {
      final loc = await ref.read(currentLocationProvider.notifier).autoDetectLocation();
      setState(() {
        _detectedLoc = loc;
        _cityCtrl.text = loc.city;
        _sort ??= 'distance'; // Suggest nearest sort when GPS is detected
      });
      if (mounted) {
        final accuracy = loc.isGpsPrecise ? ' (🎯 High-Accuracy GPS)' : ' (Network)';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Location detected: ${loc.displayName}$accuracy'),
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

  void _apply() {
    final notifier = ref.read(discoveryFilterProvider.notifier);
    final f = ref.read(discoveryFilterProvider);

    notifier.setLocation(
      city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
      lat: _detectedLoc?.latitude ?? f.lat,
      lng: _detectedLoc?.longitude ?? f.lng,
      radiusKm: _selectedRadius,
    );

    notifier.setPriceRange(
      _priceRange.start > 0 ? _priceRange.start.round() : null,
      _priceRange.end < 3000 ? _priceRange.end.round() : null,
    );
    notifier.setMinRating(_minRating);
    notifier.setSort(_sort);
    Navigator.pop(context);
  }

  void _reset() {
    ref.read(discoveryFilterProvider.notifier).reset();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    _init();

    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filter Companions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(onPressed: _reset, child: const Text('Reset', style: TextStyle(color: AppColors.secondary))),
              ],
            ),
            const SizedBox(height: 16),

            // City Filter with Auto-Detect Suffix
            TextField(
              controller: _cityCtrl,
              decoration: InputDecoration(
                labelText: 'City / Location',
                prefixIcon: const Icon(Icons.location_on_outlined),
                hintText: 'e.g. Mumbai, Delhi, Bengaluru',
                suffixIcon: _detectingLocation
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.my_location, color: AppColors.secondary),
                        tooltip: 'Auto-detect location',
                        onPressed: _autoDetectCity,
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: const Icon(Icons.my_location, size: 14, color: AppColors.secondary),
                label: const Text('Auto-Detect Current GPS 🎯', style: TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.bold)),
                backgroundColor: AppColors.secondary.withValues(alpha: 0.12),
                side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.3)),
                onPressed: _detectingLocation ? null : _autoDetectCity,
              ),
            ),
            const SizedBox(height: 16),

            // Distance Radius Filter
            const Text('Search Radius', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final r in [null, 5, 15, 25, 50, 100])
                  ChoiceChip(
                    label: Text(r == null ? 'Any Distance' : '$r km'),
                    selected: _selectedRadius == r,
                    onSelected: (val) => setState(() => _selectedRadius = val ? r : null),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Hourly Price Range
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Hourly Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                  '₹${_priceRange.start.round()} - ₹${_priceRange.end >= 3000 ? "3000+" : _priceRange.end.round()}/hr',
                  style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            RangeSlider(
              values: _priceRange,
              min: 0,
              max: 3000,
              divisions: 30,
              onChanged: (v) => setState(() => _priceRange = v),
            ),
            const SizedBox(height: 16),

            // Minimum Rating
            const Text('Minimum Rating', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final r in [null, 4.0, 4.5, 4.8])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(r == null ? 'Any' : '$r★'),
                      selected: _minRating == r,
                      onSelected: (val) => setState(() => _minRating = val ? r : null),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Sort Option (including Nearest First)
            const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Top Rated'),
                  selected: _sort == null || _sort == 'rating',
                  onSelected: (_) => setState(() => _sort = 'rating'),
                ),
                ChoiceChip(
                  label: const Text('Nearest First 📍'),
                  selected: _sort == 'distance',
                  onSelected: (_) => setState(() => _sort = 'distance'),
                ),
                ChoiceChip(
                  label: const Text('Price: Low to High'),
                  selected: _sort == 'price_asc',
                  onSelected: (_) => setState(() => _sort = 'price_asc'),
                ),
                ChoiceChip(
                  label: const Text('Price: High to Low'),
                  selected: _sort == 'price_desc',
                  onSelected: (_) => setState(() => _sort = 'price_desc'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _apply,
                child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
