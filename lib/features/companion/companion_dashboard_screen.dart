import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/companion_repository.dart';
import '../../theme/app_theme.dart';

class CompanionDashboardScreen extends ConsumerWidget {
  const CompanionDashboardScreen({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
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
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                            child: Text(
                              (user?.fullName?.isNotEmpty == true) ? user!.fullName![0].toUpperCase() : 'C',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
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
                      _buildStatusChip(profile?.verificationStatus ?? 'NOT_SUBMITTED'),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Active & Accepting Bookings',
                            style: TextStyle(
                              color: isVerified ? Colors.white : AppColors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Switch(
                            value: profile?.isAvailable ?? false,
                            onChanged: isVerified
                                ? (val) async {
                                    await ref.read(companionRepositoryProvider).updateProfile(isAvailable: val);
                                    ref.read(myCompanionProfileProvider.notifier).refresh();
                                  }
                                : null,
                          ),
                        ],
                      ),
                      if (!isVerified)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Bookings will open once your identity verification is approved.',
                            style: TextStyle(color: AppColors.secondary, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Text('Management & Settings',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.muted)),
                const SizedBox(height: 14),

                // 0. Bookings & Client Requests
                _buildMenuCard(
                  context: context,
                  icon: Icons.calendar_today_outlined,
                  title: 'Bookings & Client Requests',
                  subtitle: 'Manage upcoming meetings, accept & complete requests',
                  onTap: () => context.push('/bookings'),
                ),

                // 1. Direct Client Chat
                _buildMenuCard(
                  context: context,
                  icon: Icons.chat_bubble_outline,
                  title: 'Messages & Client Chat',
                  subtitle: 'Communicate with clients for confirmed meetings',
                  onTap: () => context.push('/chat'),
                ),

                // 2. Identity Verification
                _buildMenuCard(
                  context: context,
                  icon: Icons.verified_user_outlined,
                  title: 'Identity Verification',
                  subtitle: profile?.verificationStatus == 'APPROVED'
                      ? 'Government ID verified'
                      : 'Upload Government ID & Selfie for safety check',
                  onTap: () => context.push('/companion/verification'),
                ),

                // 3. Activities & Custom Pricing
                _buildMenuCard(
                  context: context,
                  icon: Icons.category_outlined,
                  title: 'My Permitted Activities',
                  subtitle: '${profile?.activities.length ?? 0} activities enabled',
                  onTap: () => context.push('/companion/activities'),
                ),

                // 4. Weekly Availability
                _buildMenuCard(
                  context: context,
                  icon: Icons.calendar_month_outlined,
                  title: 'Availability & Slots',
                  subtitle: '${profile?.availability.length ?? 0} weekly time windows configured',
                  onTap: () => context.push('/companion/availability'),
                ),

                // 5. Bio, Rates & Payout UPI
                _buildMenuCard(
                  context: context,
                  icon: Icons.account_circle_outlined,
                  title: 'Profile, Rates & Payouts',
                  subtitle: 'Base rate: ₹${profile?.hourlyRateInRupees ?? 0}/hr • UPI: ${profile?.payoutUpi ?? "Not set"}',
                  onTap: () => context.push('/companion/profile-edit'),
                ),

                // 6. Safety & SOS Center
                _buildMenuCard(
                  context: context,
                  icon: Icons.shield_outlined,
                  title: 'Safety, SOS & Incident Reporting',
                  subtitle: 'Emergency assistance, guidelines & blocked users',
                  onTap: () => context.push('/safety'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
