import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../models/companion_profile.dart';
import '../../repositories/companion_repository.dart';
import '../../theme/app_theme.dart';

class CompanionProfileEditScreen extends ConsumerStatefulWidget {
  const CompanionProfileEditScreen({super.key});

  @override
  ConsumerState<CompanionProfileEditScreen> createState() => _CompanionProfileEditScreenState();
}

class _CompanionProfileEditScreenState extends ConsumerState<CompanionProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioCtrl = TextEditingController();
  final _languagesCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();
  double _radiusKm = 10;
  bool _initialized = false;
  bool _saving = false;

  void _initFromProfile(CompanionProfile profile) {
    if (_initialized) return;
    _bioCtrl.text = profile.bio ?? '';
    _languagesCtrl.text = profile.languages.join(', ');
    _rateCtrl.text = profile.hourlyRate > 0 ? (profile.hourlyRate ~/ 100).toString() : '';
    _upiCtrl.text = profile.payoutUpi ?? '';
    _radiusKm = profile.serviceRadiusKm.toDouble().clamp(1.0, 100.0);
    _initialized = true;
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _languagesCtrl.dispose();
    _rateCtrl.dispose();
    _upiCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final rateRupees = int.tryParse(_rateCtrl.text.trim()) ?? 0;
      final languages = _languagesCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      await ref.read(companionRepositoryProvider).updateProfile(
            bio: _bioCtrl.text.trim(),
            languages: languages,
            hourlyRate: rateRupees * 100, // convert ₹ to paise
            payoutUpi: _upiCtrl.text.trim().isNotEmpty ? _upiCtrl.text.trim() : null,
            serviceRadiusKm: _radiusKm.round(),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Companion details saved successfully!')),
      );
      ref.read(myCompanionProfileProvider.notifier).refresh();
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: ${apiErrorMessage(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myCompanionProfileProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Profile, Rates & Payouts'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: ${apiErrorMessage(e)}')),
        data: (profile) {
          if (profile != null) _initFromProfile(profile);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Bio
                TextFormField(
                  controller: _bioCtrl,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'About You (Bio)',
                    hintText: 'Share your background, interests, conversation topics and companionship style...',
                  ),
                  validator: (v) => (v != null && v.trim().length > 500) ? 'Bio cannot exceed 500 characters' : null,
                ),
                const SizedBox(height: 16),

                // Languages
                TextFormField(
                  controller: _languagesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Languages Spoken (comma separated)',
                    hintText: 'e.g. English, Hindi, Bengali',
                  ),
                ),
                const SizedBox(height: 16),

                // Base Hourly Rate
                TextFormField(
                  controller: _rateCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Default Base Hourly Rate (₹)',
                    hintText: 'e.g. 500',
                    prefixText: '₹ ',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter hourly rate';
                    final num = int.tryParse(v.trim());
                    if (num == null || num < 0) return 'Enter a valid rate';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Payout UPI
                TextFormField(
                  controller: _upiCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Payout UPI ID',
                    hintText: 'e.g. yourname@okaxis or yourname@paytm',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  validator: (v) {
                    if (v != null && v.isNotEmpty && !v.contains('@')) {
                      return 'Enter a valid UPI ID (e.g. name@bank)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Service Radius
                Text('Service Radius: ${_radiusKm.round()} km',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                const Text('How far you are willing to travel for companion activities from your city center.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13)),
                Slider(
                  value: _radiusKm,
                  min: 1,
                  max: 50,
                  divisions: 49,
                  label: '${_radiusKm.round()} km',
                  onChanged: (v) => setState(() => _radiusKm = v),
                ),

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save Profile Details'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
