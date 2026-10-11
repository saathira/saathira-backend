import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../repositories/companion_repository.dart';
import '../../theme/app_theme.dart';

class CompanionVerificationScreen extends ConsumerStatefulWidget {
  const CompanionVerificationScreen({super.key});

  @override
  ConsumerState<CompanionVerificationScreen> createState() => _CompanionVerificationScreenState();
}

class _CompanionVerificationScreenState extends ConsumerState<CompanionVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  String _docType = 'Aadhaar Card';
  final _docPathCtrl = TextEditingController();
  final _selfieCtrl = TextEditingController();
  bool _submitting = false;

  final List<String> _docTypes = [
    'Aadhaar Card',
    'Passport',
    'Driving License',
    'Voter ID',
  ];

  @override
  void dispose() {
    _docPathCtrl.dispose();
    _selfieCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await ref.read(companionRepositoryProvider).submitVerification(
            documentType: _docType,
            documentPath: _docPathCtrl.text.trim(),
            selfiePath: _selfieCtrl.text.trim().isNotEmpty ? _selfieCtrl.text.trim() : null,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification document submitted successfully!')),
      );
      _docPathCtrl.clear();
      _selfieCtrl.clear();
      ref.read(myCompanionProfileProvider.notifier).refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${apiErrorMessage(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myCompanionProfileProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Identity Verification'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Safety Notice Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.security, color: AppColors.primary, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Verified Companion Badge',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'To keep Saathira safe and trusted, all companions must submit Government ID verification before accepting bookings. Documents are encrypted and reviewed privately by administrators.',
                        style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text('Submit Document', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _docType,
                  decoration: const InputDecoration(labelText: 'Document Type'),
                  items: _docTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => _docType = v ?? _docType),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _docPathCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Government ID Document Reference / Path',
                    hintText: 'e.g. storage/verifications/aadhaar_front.jpg',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please provide document reference' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _selfieCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Selfie Verification Reference (Optional)',
                    hintText: 'e.g. storage/verifications/selfie.jpg',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.upload_file),
                  label: const Text('Submit for Review'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          const Text('Submission History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Could not load history: ${apiErrorMessage(e)}'),
            data: (profile) {
              final list = profile?.verifications ?? [];
              if (list.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('No verification documents submitted yet.',
                        style: TextStyle(color: AppColors.muted)),
                  ),
                );
              }

              return Column(
                children: list.map((v) {
                  Color statusColor = Colors.orange;
                  if (v.status == 'APPROVED') statusColor = Colors.greenAccent;
                  if (v.status == 'REJECTED') statusColor = Colors.redAccent;

                  return Card(
                    color: AppColors.surface,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      title: Text(v.documentType, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Submitted on ${v.createdAt.day}/${v.createdAt.month}/${v.createdAt.year}',
                              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                          if (v.reviewNote != null && v.reviewNote!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('Note: ${v.reviewNote}',
                                  style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
                            ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          v.status,
                          style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
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
}
