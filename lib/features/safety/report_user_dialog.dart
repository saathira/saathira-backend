import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../repositories/trust_repository.dart';
import '../../theme/app_theme.dart';

class ReportUserDialog extends ConsumerStatefulWidget {
  const ReportUserDialog({
    super.key,
    required this.reportedUserId,
    required this.reportedUserName,
    this.bookingId,
  });

  final String reportedUserId;
  final String reportedUserName;
  final String? bookingId;

  static Future<bool?> show(
    BuildContext context, {
    required String reportedUserId,
    required String reportedUserName,
    String? bookingId,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => ReportUserDialog(
        reportedUserId: reportedUserId,
        reportedUserName: reportedUserName,
        bookingId: bookingId,
      ),
    );
  }

  @override
  ConsumerState<ReportUserDialog> createState() => _ReportUserDialogState();
}

class _ReportUserDialogState extends ConsumerState<ReportUserDialog> {
  String? _selectedReason;
  final _detailsCtrl = TextEditingController();
  bool _submitting = false;
  bool _alsoBlock = false;

  final List<String> _reasons = [
    'Inappropriate Behavior / Harassment',
    'Solicitation or Prohibited Services',
    'Off-platform Payment Request',
    'No-show / Abandoned Meeting',
    'Safety & Security Concern',
    'Fake Profile or Misleading Information',
  ];

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason for the report')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await ref.read(trustRepositoryProvider).reportUser(
            reportedUserId: widget.reportedUserId,
            bookingId: widget.bookingId,
            reason: _selectedReason!,
            details: _detailsCtrl.text.trim().isNotEmpty ? _detailsCtrl.text.trim() : null,
          );

      if (_alsoBlock) {
        await ref.read(trustRepositoryProvider).blockUser(widget.reportedUserId);
        ref.invalidate(blockedUsersProvider);
      }

      if (!mounted) return;
      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🛡️ Report submitted. Our Trust & Safety team will investigate immediately.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit report: ${apiErrorMessage(e)}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.flag, color: Colors.redAccent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Report ${widget.reportedUserName}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Reports are strictly confidential. Saathira takes safety violations very seriously.',
                style: TextStyle(color: AppColors.muted, fontSize: 12.5),
              ),
              const SizedBox(height: 18),

              const Text('Select Violation Reason', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),

              ..._reasons.map((reason) {
                final isSelected = _selectedReason == reason;
                return InkWell(
                  onTap: () => setState(() => _selectedReason = reason),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          color: isSelected ? AppColors.primary : AppColors.muted,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            reason,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected ? Colors.white : AppColors.text,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),
              const Text('Additional Details (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _detailsCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe what happened...',
                  filled: true,
                  fillColor: AppColors.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _alsoBlock,
                activeColor: AppColors.primary,
                title: Text(
                  'Also block ${widget.reportedUserName} from contacting me',
                  style: const TextStyle(fontSize: 13),
                ),
                onChanged: (val) => setState(() => _alsoBlock = val ?? false),
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _submitting ? null : () => Navigator.pop(context, false),
                      child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      key: const Key('btn_submit_report'),
                      onPressed: _submitting ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Submit Report', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
