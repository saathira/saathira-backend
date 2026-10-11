import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../repositories/discovery_repository.dart';
import '../../theme/app_theme.dart';

class CompanionDetailScreen extends ConsumerWidget {
  const CompanionDetailScreen({super.key, required this.companionId});
  final String companionId;

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(companionDetailProvider(companionId));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Companion Profile'),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Could not load profile: ${apiErrorMessage(e)}', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(companionDetailProvider(companionId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (companion) {
          final isVerified = companion.verificationStatus == 'APPROVED';

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                children: [
                  // Profile Header Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                              child: Text(
                                companion.user?.fullName.isNotEmpty == true
                                    ? companion.user!.fullName[0].toUpperCase()
                                    : 'C',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          companion.user?.fullName ?? 'Companion',
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isVerified) ...[
                                        const SizedBox(width: 6),
                                        const Icon(Icons.verified, color: Colors.greenAccent, size: 20),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    companion.user?.city ?? 'Location flexible',
                                    style: const TextStyle(color: AppColors.muted, fontSize: 14),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        companion.ratingAvg > 0
                                            ? companion.ratingAvg.toStringAsFixed(1)
                                            : 'New',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      if (companion.ratingCount > 0)
                                        Text(
                                          ' (${companion.ratingCount} reviews)',
                                          style: const TextStyle(color: AppColors.muted, fontSize: 13),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Safety & Verification Trust Banner
                  if (isVerified)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.shield_outlined, color: Colors.greenAccent, size: 22),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'ID Verified Companion • Background checked under Saathira Safety Guidelines.',
                              style: TextStyle(color: Colors.greenAccent, fontSize: 12.5, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Bio Section
                  if (companion.bio != null && companion.bio!.isNotEmpty) ...[
                    _buildSectionHeader('About'),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        companion.bio!,
                        style: const TextStyle(color: AppColors.text, fontSize: 14.5, height: 1.5),
                      ),
                    ),
                  ],

                  // Languages Spoken
                  if (companion.languages.isNotEmpty) ...[
                    _buildSectionHeader('Languages'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: companion.languages.map((lang) {
                        return Chip(
                          backgroundColor: AppColors.surface,
                          label: Text(lang, style: const TextStyle(fontSize: 13)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide.none,
                        );
                      }).toList(),
                    ),
                  ],

                  // Permitted Activities & Rates
                  _buildSectionHeader('Available Activities'),
                  if (companion.activities.isEmpty)
                    const Text('No specific activities listed.', style: TextStyle(color: AppColors.muted))
                  else
                    Column(
                      children: companion.activities.map((item) {
                        final rate = item.customRate != null
                            ? item.customRate! ~/ 100
                            : companion.hourlyRateInRupees;

                        return Card(
                          color: AppColors.surface,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.check_circle_outline, color: AppColors.secondary, size: 22),
                            ),
                            title: Text(item.activity.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: item.activity.description != null
                                ? Text(item.activity.description!, style: const TextStyle(color: AppColors.muted, fontSize: 12))
                                : null,
                            trailing: Text(
                              '₹$rate/hr',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  // Weekly Availability Schedule
                  _buildSectionHeader('Weekly Availability'),
                  if (companion.availability.isEmpty)
                    const Text('Flexible on request.', style: TextStyle(color: AppColors.muted))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: companion.availability.map((slot) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(slot.dayName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                              const SizedBox(height: 2),
                              Text(slot.timeRangeLabel,
                                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                  // Saathira Community Policy
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Saathira is a safe companionship platform for non-sexual activities. '
                      'Any prohibited activities or harassment results in immediate permanent ban.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),

              // Sticky Bottom Action Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Starting from', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                            Text(
                              '₹${companion.hourlyRateInRupees}/hr',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: ElevatedButton(
                            key: const Key('btn_request_booking'),
                            onPressed: () {
                              context.push('/booking/request/$companionId', extra: companion);
                            },
                            child: const Text('Book Companion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
