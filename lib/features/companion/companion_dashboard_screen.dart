import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/network/api_client.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/companion_repository.dart';
import '../../repositories/storage_repository.dart';
import '../../theme/app_theme.dart';

class CompanionDashboardScreen extends ConsumerStatefulWidget {
  const CompanionDashboardScreen({super.key});

  @override
  ConsumerState<CompanionDashboardScreen> createState() => _CompanionDashboardScreenState();
}

class _CompanionDashboardScreenState extends ConsumerState<CompanionDashboardScreen> {
  bool _uploadingAvatar = false;
  String? _localPhotoUrl;

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked == null) return;

      setState(() => _uploadingAvatar = true);
      final newPhotoUrl = await ref.read(storageRepositoryProvider).uploadAvatar(File(picked.path));

      // 1. Immediately reflect the photo locally
      if (mounted) {
        setState(() {
          _localPhotoUrl = newPhotoUrl;
        });
      }

      // 2. Hot-load image into global sessionProvider with zero reload or redirect
      ref.read(sessionProvider.notifier).updatePhotoUrl(newPhotoUrl);
      ref.read(myCompanionProfileProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Companion profile photo updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update avatar: ${apiErrorMessage(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  void _showAvatarPickerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Change Profile Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 6),
              const Text('Your photo will be showcased to clients in the companion directory.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 18),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
                title: const Text('Take Photo with Camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadAvatar(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.photo_library, color: Colors.white, size: 20),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadAvatar(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case 'APPROVED':
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.greenAccent;
        label = 'Verified Companion';
        icon = Icons.verified;
        break;
      case 'PENDING':
        bg = Colors.amber.withValues(alpha: 0.15);
        fg = Colors.amberAccent;
        label = 'Verification Pending';
        icon = Icons.hourglass_top;
        break;
      case 'REJECTED':
        bg = Colors.red.withValues(alpha: 0.15);
        fg = Colors.redAccent;
        label = 'Verification Rejected';
        icon = Icons.cancel;
        break;
      default:
        bg = Colors.orange.withValues(alpha: 0.15);
        fg = Colors.orangeAccent;
        label = 'Action Required: Submit ID';
        icon = Icons.shield_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailingBadge,
  }) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        ),
        trailing: trailingBadge ?? const Icon(Icons.chevron_right, color: AppColors.muted),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myCompanionProfileProvider);
    final user = ref.watch(sessionProvider).value?.user;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Companion Hub', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.read(myCompanionProfileProvider.notifier).refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Failed to load companion profile: ${apiErrorMessage(e)}', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.read(myCompanionProfileProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (profile) {
          final isVerified = profile?.verificationStatus == 'APPROVED';

          return RefreshIndicator(
            onRefresh: () => ref.read(myCompanionProfileProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Top Profile Summary Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: () => _showAvatarPickerModal(context),
                                child: CircleAvatar(
                                  radius: 32,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                                  backgroundImage: ((_localPhotoUrl ?? user?.photoUrl) != null &&
                                          (_localPhotoUrl ?? user!.photoUrl)!.isNotEmpty)
                                      ? NetworkImage((_localPhotoUrl ?? user!.photoUrl)!)
                                      : null,
                                  child: _uploadingAvatar
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : ((_localPhotoUrl ?? user?.photoUrl) == null ||
                                              (_localPhotoUrl ?? user!.photoUrl)!.isEmpty)
                                          ? Text(
                                              (user?.fullName?.isNotEmpty == true) ? user!.fullName![0].toUpperCase() : 'C',
                                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                                            )
                                          : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => _showAvatarPickerModal(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.camera_alt, size: 13, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.fullName ?? 'Companion',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.city ?? 'Location not set',
                                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatusChip(profile?.verificationStatus ?? 'NOT_SUBMITTED'),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${profile?.ratingAvg.toStringAsFixed(1) ?? '5.0'} (${profile?.ratingCount ?? 0})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Text('Management & Availability', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),

                // 1. Identity Verification Menu Card
                _buildMenuCard(
                  context: context,
                  icon: Icons.verified_user_outlined,
                  title: 'Identity Verification (KYC)',
                  subtitle: isVerified
                      ? 'Government ID verified by admin team'
                      : 'Upload Government ID & Selfie to unlock bookings',
                  trailingBadge: isVerified
                      ? const Icon(Icons.check_circle, color: Colors.greenAccent)
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('Required', style: TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                  onTap: () => context.push('/companion-verification'),
                ),

                // 2. Activities & Custom Rates Menu Card
                _buildMenuCard(
                  context: context,
                  icon: Icons.checklist_rtl_rounded,
                  title: 'Offered Activities & Pricing',
                  subtitle: 'Select activities you offer and configure custom rates',
                  onTap: () => context.push('/companion-activities'),
                ),

                // 3. Weekly Availability Slots
                _buildMenuCard(
                  context: context,
                  icon: Icons.calendar_month_outlined,
                  title: 'Weekly Working Hours',
                  subtitle: 'Manage your active days and booking time slots',
                  onTap: () => context.push('/companion-availability'),
                ),

                // 4. Hourly Base Rate & Bio Settings
                _buildMenuCard(
                  context: context,
                  icon: Icons.currency_rupee_rounded,
                  title: 'Profile, Bio & Base Rate',
                  subtitle: '₹${((profile?.hourlyRate ?? 100000) / 100).toStringAsFixed(0)}/hr • Radius: ${profile?.serviceRadiusKm ?? 10} km',
                  onTap: () => context.push('/companion-settings'),
                ),

                const SizedBox(height: 20),
                const Text('Earnings & Trust', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),

                // 5. UPI Payout Configuration
                _buildMenuCard(
                  context: context,
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Payout Settings (UPI)',
                  subtitle: profile?.payoutUpi != null
                      ? 'Payouts sent to: ${profile!.payoutUpi}'
                      : 'Link UPI VPA to receive booking payments automatically',
                  onTap: () => context.push('/companion-settings'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
