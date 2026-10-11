import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../repositories/trust_repository.dart';
import '../../theme/app_theme.dart';

class SafetyCenterScreen extends ConsumerStatefulWidget {
  const SafetyCenterScreen({super.key});

  @override
  ConsumerState<SafetyCenterScreen> createState() => _SafetyCenterScreenState();
}

class _SafetyCenterScreenState extends ConsumerState<SafetyCenterScreen> {
  final _complaintSubjectCtrl = TextEditingController();
  final _complaintMsgCtrl = TextEditingController();
  bool _submittingComplaint = false;

  @override
  void dispose() {
    _complaintSubjectCtrl.dispose();
    _complaintMsgCtrl.dispose();
    super.dispose();
  }

  void _triggerEmergencySos() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Text('Emergency Services'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'If you are in immediate physical danger, please call National Emergency Services (112) immediately.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            SizedBox(height: 12),
            Text(
              'India Emergency Number: 112\nWomen Helpline: 1091',
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

  Future<void> _submitComplaint() async {
    final subject = _complaintSubjectCtrl.text.trim();
    final message = _complaintMsgCtrl.text.trim();

    if (subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out both subject and message')),
      );
      return;
    }

    setState(() => _submittingComplaint = true);

    try {
      await ref.read(trustRepositoryProvider).submitComplaint(
            subject: subject,
            message: message,
          );

      _complaintSubjectCtrl.clear();
      _complaintMsgCtrl.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Grievance received. Our safety team will follow up within 24 hours.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${apiErrorMessage(e)}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _submittingComplaint = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final blockedAsync = ref.watch(blockedUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety & Trust Center'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Emergency SOS Banner Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF991B1B), Color(0xFF7F1D1D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.shield_outlined, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Emergency SOS Assistance',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Feel unsafe or in an emergency during a companion meeting? Get immediate help.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    key: const Key('btn_emergency_sos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red.shade900,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.call, color: Colors.red),
                    label: const Text(
                      'Emergency Assistance (112)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onPressed: _triggerEmergencySos,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text('Saathira Safety Guidelines', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // Core Rules Cards
          _buildRuleCard(
            icon: Icons.storefront_outlined,
            title: 'Always Meet in Public Spaces',
            desc: 'All activities must occur in public venues (cafes, malls, restaurants). Private residential meetings are strictly prohibited.',
          ),
          const SizedBox(height: 10),
          _buildRuleCard(
            icon: Icons.no_adult_content_outlined,
            title: 'Zero Tolerance for Adult Services',
            desc: 'Saathira is strictly for non-sexual social companionship. Any inappropriate solicitations result in an immediate lifetime ban and legal reporting.',
          ),
          const SizedBox(height: 10),
          _buildRuleCard(
            icon: Icons.payments_outlined,
            title: 'In-App Escrow Protection',
            desc: 'Never accept or send direct cash or off-platform UPI payments. Payments must remain in Saathira Escrow for your financial safety.',
          ),

          const SizedBox(height: 24),
          const Text('Submit Grievance / Complaint', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Subject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _complaintSubjectCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Account issue, companion misconduct, payment dispute',
                    filled: true,
                    fillColor: AppColors.bg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Describe the Issue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _complaintMsgCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Provide detailed information so our Trust team can assist you...',
                    filled: true,
                    fillColor: AppColors.bg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('btn_submit_complaint'),
                    onPressed: _submittingComplaint ? null : _submitComplaint,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _submittingComplaint
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Submit to Safety Team', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text('Blocked Users', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          blockedAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Could not load blocked list: $e', style: const TextStyle(color: AppColors.muted)),
            data: (blockedList) {
              if (blockedList.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('You have not blocked any users.', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                );
              }

              return Column(
                children: blockedList.map((b) {
                  return Card(
                    color: AppColors.surface,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                        child: Text(b.fullName.isNotEmpty ? b.fullName[0].toUpperCase() : 'U'),
                      ),
                      title: Text(b.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(b.city ?? 'User', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      trailing: TextButton(
                        child: const Text('Unblock', style: TextStyle(color: Colors.redAccent)),
                        onPressed: () async {
                          await ref.read(trustRepositoryProvider).unblockUser(b.id);
                          ref.invalidate(blockedUsersProvider);
                        },
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRuleCard({required IconData icon, required String title, required String desc}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
