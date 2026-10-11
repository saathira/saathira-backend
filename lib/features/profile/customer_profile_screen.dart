import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../models/app_user.dart';
import '../../repositories/auth_repository.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  String _maskPhone(String? phone) {
    if (phone == null || phone.isEmpty) return 'No contact info';
    final cleaned = phone.trim();
    final digits = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 10) {
      final last3 = digits.substring(digits.length - 3);
      final first2 = digits.substring(0, 2);
      final prefix = cleaned.startsWith('+91') ? '+91 ' : '';
      return '$prefix$first2••••••$last3 (🔒 Masked)';
    }
    return '$phone (🔒 Masked)';
  }

  void _openEditProfileModal(BuildContext context, AppUser user) {
    final nameCtrl = TextEditingController(text: user.fullName ?? '');
    final emailCtrl = TextEditingController(text: user.email ?? '');
    final cityCtrl = TextEditingController(text: user.city ?? '');
    String? selectedGender;
    bool saving = false;

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
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
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
                          'Edit Profile',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cityCtrl,
                      decoration: InputDecoration(
                        labelText: 'City / Location',
                        prefixIcon: const Icon(Icons.location_city_outlined),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.my_location, color: AppColors.secondary),
                          tooltip: 'Auto-detect city',
                          onPressed: () async {
                            try {
                              final loc = await ref.read(currentLocationProvider.notifier).autoDetectLocation();
                              setModalState(() {
                                cityCtrl.text = loc.city;
                              });
                            } catch (_) {}
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: Icon(Icons.wc_outlined),
                      ),
                      dropdownColor: AppColors.surface,
                      items: const [
                        DropdownMenuItem(value: 'MALE', child: Text('Male')),
                        DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                        DropdownMenuItem(value: 'NON_BINARY', child: Text('Non-Binary')),
                        DropdownMenuItem(value: 'PREFER_NOT_TO_SAY', child: Text('Prefer not to say')),
                      ],
                      onChanged: (v) => setModalState(() => selectedGender = v),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saving
                            ? null
                            : () async {
                                if (nameCtrl.text.trim().isEmpty) return;
                                setModalState(() => saving = true);
                                try {
                                  await ref.read(authRepositoryProvider).updateProfile(
                                        fullName: nameCtrl.text.trim(),
                                        email: emailCtrl.text.trim(),
                                        city: cityCtrl.text.trim(),
                                        gender: selectedGender,
                                      );
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Profile updated successfully!')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Update failed: ${apiErrorMessage(e)}')),
                                    );
                                  }
                                } finally {
                                  setModalState(() => saving = false);
                                }
                              },
                        child: saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Save Changes'),
                      ),
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

  void _triggerEmergencySos() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Text('Emergency Services'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'If you are in immediate danger or need police/ambulance assistance, please dial National Emergency Services.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            SizedBox(height: 12),
            Text(
              'India National Emergency: 112\nWomen Helpline: 1091',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 15),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showSafetyPolicyModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.92,
          builder: (_, scrollCtrl) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: ListView(
                controller: scrollCtrl,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: AppColors.primary, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Community Guidelines',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Permitted Activities Only',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amberAccent),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Saathira is an activity-based companionship platform. Permitted bookings include Shopping assistance, Doctor appointments, Movies/theatre, Cafe & dining, City walks, and Social conversation in public spaces.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Strictly Prohibited Activities',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '• Any form of sexual services or physical exploitation is strictly illegal and results in immediate permanent bans and police referral.\n• Substance abuse, intoxication, or illegal activities.\n• Demanding unrecorded off-platform cash transactions.\n• Harassment, hate speech, or sharing private photos.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Safety Protocols & SOS',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.greenAccent),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Always meet in public places. If you feel unsafe at any moment, use the Emergency SOS 112 button or leave the venue immediately. Our 24/7 Trust & Safety mediation team investigates all incident reports.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('I Understand & Agree'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionProvider);
    final user = sessionAsync.value?.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final displayName = user.fullName ?? 'User';
    final initialLetter = (user.fullName != null && user.fullName!.isNotEmpty)
        ? user.fullName![0].toUpperCase()
        : 'U';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () => _openEditProfileModal(context, user),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Card Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.3),
                  child: Text(
                    initialLetter,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _maskPhone(user.phone ?? user.email),
                        style: const TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.role == AppRole.companion ? 'Verified Companion' : 'Customer Account',
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick Action Cards
          Row(
            children: [
              Expanded(
                child: _buildTileCard(
                  icon: Icons.calendar_month_outlined,
                  title: 'Bookings',
                  subtitle: 'Active & History',
                  onTap: () => context.push('/bookings'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTileCard(
                  icon: Icons.chat_bubble_outline,
                  title: 'Messages',
                  subtitle: 'Chat with companions',
                  onTap: () => context.push('/chat'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Safety & Emergency Contact Section
          const Text('Safety & Emergency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.shield_outlined, color: Colors.greenAccent),
                  title: const Text('Safety Center & SOS', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Emergency 112, Safety Guidelines & Grievances', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
                  onTap: () => context.push('/safety'),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.emergency_outlined, color: Colors.redAccent),
                  title: const Text('Emergency SOS 112', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.redAccent)),
                  subtitle: const Text('Direct dial national emergency police/ambulance', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  trailing: const Icon(Icons.call, color: Colors.redAccent),
                  onTap: _triggerEmergencySos,
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.gavel_outlined, color: Colors.amberAccent),
                  title: const Text('Community Guidelines & Policies', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Permitted activities and zero-tolerance safety rules', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
                  onTap: () => _showSafetyPolicyModal(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Companion Switch (if user is customer)
          if (user.role == AppRole.customer) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: AppColors.primary, size: 32),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Become a Saathira Companion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        SizedBox(height: 2),
                        Text(
                          'Accompany users for permitted activities & earn on your schedule.',
                          style: TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => context.push('/companion/dashboard'),
                    child: const Text('Join Hub'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // App Settings & Info
          const Text('Account & Preferences', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_none_outlined, color: AppColors.secondary),
                  title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
                  onTap: () => context.push('/notifications'),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.lock_outline, color: AppColors.muted),
                  title: const Text('Privacy & Security', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
                  onTap: () => _showSafetyPolicyModal(context),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.redAccent)),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: const Text('Sign Out'),
                        content: const Text('Are you sure you want to sign out of Saathira?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size(0, 36)),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(authRepositoryProvider).signOut();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTileCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.secondary, size: 24),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
