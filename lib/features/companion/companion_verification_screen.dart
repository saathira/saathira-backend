import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/network/api_client.dart';
import '../../repositories/companion_repository.dart';
import '../../repositories/storage_repository.dart';
import '../../theme/app_theme.dart';

class CompanionVerificationScreen extends ConsumerStatefulWidget {
  const CompanionVerificationScreen({super.key});

  @override
  ConsumerState<CompanionVerificationScreen> createState() => _CompanionVerificationScreenState();
}

class _CompanionVerificationScreenState extends ConsumerState<CompanionVerificationScreen> {
  final _picker = ImagePicker();
  String _docType = 'Aadhaar Card';
  File? _docFile;
  File? _selfieFile;
  bool _submitting = false;
  String _submitProgress = '';

  final List<String> _docTypes = [
    'Aadhaar Card',
    'Passport',
    'Driving License',
    'Voter ID',
  ];

  Future<void> _pickDocument(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _docFile = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _pickSelfie() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _selfieFile = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to take selfie: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_docFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload or take a photo of your Government ID')),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _submitProgress = 'Uploading Government ID to secure storage...';
    });

    try {
      final storageRepo = ref.read(storageRepositoryProvider);

      // 1. Upload ID Document to private bucket
      final docPath = await storageRepo.uploadVerificationDocument(_docFile!, type: 'document');

      // 2. Upload Selfie if provided
      String? selfiePath;
      if (_selfieFile != null) {
        setState(() => _submitProgress = 'Uploading verification selfie...');
        selfiePath = await storageRepo.uploadVerificationDocument(_selfieFile!, type: 'selfie');
      }

      // 3. Submit verification request to backend
      setState(() => _submitProgress = 'Submitting for review...');
      await ref.read(companionRepositoryProvider).submitVerification(
            documentType: _docType,
            documentPath: docPath,
            selfiePath: selfiePath,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification submitted successfully! Our safety team will review it shortly.')),
      );
      setState(() {
        _docFile = null;
        _selfieFile = null;
      });
      ref.read(myCompanionProfileProvider.notifier).refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: ${apiErrorMessage(e)}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          _submitProgress = '';
        });
      }
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
                        'To keep Saathira safe and trusted, all companions must submit Government ID verification before accepting bookings. Documents are stored in encrypted private buckets and reviewed securely by administrators.',
                        style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text('Upload Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          // Document Type Selector
          DropdownButtonFormField<String>(
            initialValue: _docType,
            decoration: const InputDecoration(labelText: 'Government Document Type'),
            items: _docTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _docType = v ?? _docType),
          ),

          const SizedBox(height: 18),

          // 1. Document Upload Card
          const Text('1. Government ID Document (Required)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted)),
          const SizedBox(height: 8),

          if (_docFile == null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1), style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  const Icon(Icons.badge_outlined, size: 40, color: AppColors.primary),
                  const SizedBox(height: 10),
                  Text(
                    'Upload clear photo of your $_docType',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Make sure your full name, photo, and ID number are clearly visible.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickDocument(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: const Text('Take Photo'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _pickDocument(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library, size: 18),
                        label: const Text('Gallery'),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _docFile!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
                          SizedBox(width: 6),
                          Text('ID Document Selected', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () => _pickDocument(ImageSource.camera),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Change'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // 2. Selfie Upload Card
          const Text('2. Live Selfie for Face Match (Recommended)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted)),
          const SizedBox(height: 8),

          if (_selfieFile == null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.face_retouching_natural, size: 36, color: Colors.tealAccent),
                  const SizedBox(height: 8),
                  const Text(
                    'Take a quick selfie to verify identity',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ensures the applicant matches the uploaded ID card for high trust.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _pickSelfie,
                    icon: const Icon(Icons.camera_front, size: 18),
                    label: const Text('Take Live Selfie'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selfieFile!,
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.tealAccent, size: 16),
                            SizedBox(width: 6),
                            Text('Selfie Captured', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text('Ready to match with ID document', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.muted),
                    tooltip: 'Retake',
                    onPressed: _pickSelfie,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Submit Button
          if (_submitting)
            Column(
              children: [
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
                const SizedBox(height: 10),
                Text(_submitProgress, style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
              ],
            )
          else
            ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.lock_outline),
              label: const Text('Submit Verification for Review'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
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
