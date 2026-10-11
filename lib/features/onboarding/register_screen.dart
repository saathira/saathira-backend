import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../models/app_user.dart';
import '../../repositories/auth_repository.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';

/// Customer & companion onboarding (creates the backend user record).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _city = TextEditingController();
  String? _gender;
  DateTime? _dob;
  bool _agreed = false;
  bool _loading = false;
  bool _detectingCity = false;

  Future<void> _autoDetectCity() async {
    setState(() => _detectingCity = true);
    try {
      final loc = await ref.read(currentLocationProvider.notifier).autoDetectLocation();
      setState(() {
        _city.text = loc.city;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 City detected: ${loc.displayName}'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not detect city: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _detectingCity = false);
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final adult = DateTime(now.year - 18, now.month, now.day);
    final d = await showDatePicker(
      context: context,
      initialDate: adult,
      firstDate: DateTime(1940),
      lastDate: adult,
    );
    if (d != null) setState(() => _dob = d);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate() || _dob == null || !_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields and accept the guidelines')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).register(
            role: ref.read(selectedRoleProvider),
            fullName: _name.text.trim(),
            email: _email.text.trim(),
            gender: _gender,
            dateOfBirth: _dob,
            city: _city.text.trim(),
          );
      ref.invalidate(sessionProvider); // router redirects to home/dashboard
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _city.dispose();
    super.dispose();
  }

  Widget _buildRoleSlider(AppRole currentRole) {
    final isCustomer = currentRole == AppRole.customer;

    return Container(
      height: 54,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final halfWidth = (constraints.maxWidth) / 2;
          return Stack(
            children: [
              // Animated sliding indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                left: isCustomer ? 0 : halfWidth,
                top: 0,
                bottom: 0,
                width: halfWidth,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),

              // Tap Targets & Labels
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      key: const Key('tab_find_companion'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => ref.read(selectedRoleProvider.notifier).set(AppRole.customer),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_search_outlined,
                              size: 19,
                              color: isCustomer ? Colors.white : AppColors.muted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Find Companion',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isCustomer ? FontWeight.bold : FontWeight.w500,
                                color: isCustomer ? Colors.white : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      key: const Key('tab_become_companion'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => ref.read(selectedRoleProvider.notifier).set(AppRole.companion),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.handshake_outlined,
                              size: 19,
                              color: !isCustomer ? Colors.white : AppColors.muted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Be a Companion',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: !isCustomer ? FontWeight.bold : FontWeight.w500,
                                color: !isCustomer ? Colors.white : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final role = ref.watch(selectedRoleProvider);
    final isCustomer = role == AppRole.customer;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Setup Your Account'),
        actions: [
          IconButton(
            tooltip: 'Sign out / Change number',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Top Role Slider Switch
            _buildRoleSlider(role),
            const SizedBox(height: 16),

            // Dynamic Role Explanation Banner
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isCustomer
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCustomer
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : AppColors.secondary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isCustomer ? Icons.info_outline : Icons.stars,
                    color: isCustomer ? AppColors.primary : AppColors.secondary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isCustomer
                          ? 'Customer Account: Browse, search and book verified companions for shopping, doctor visits, cinema & outings.'
                          : 'Companion Account: Accompany clients for permitted activities, set your hourly pricing & receive payouts.',
                      style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Personal Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),

            TextFormField(
              key: const Key('input_name'),
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your full name' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              key: const Key('input_gender'),
              initialValue: _gender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                prefixIcon: Icon(Icons.wc_outlined),
              ),
              dropdownColor: AppColors.surface,
              items: const ['Female', 'Male', 'Non-binary', 'Prefer not to say']
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => setState(() => _gender = v),
              validator: (v) => v == null ? 'Select gender' : null,
            ),
            const SizedBox(height: 14),
            InkWell(
              key: const Key('input_dob'),
              onTap: _pickDob,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date of birth (18+)',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(_dob == null ? 'Select Date of Birth' : '${_dob!.day}/${_dob!.month}/${_dob!.year}'),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('input_city'),
              controller: _city,
              decoration: InputDecoration(
                labelText: 'City / Location',
                prefixIcon: const Icon(Icons.location_city_outlined),
                suffixIcon: _detectingCity
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
                        tooltip: 'Auto-detect city',
                        onPressed: _autoDetectCity,
                      ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your city' : null,
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: const Icon(Icons.my_location, size: 14, color: AppColors.secondary),
                label: const Text('Auto-Detect Current City 🎯', style: TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.bold)),
                backgroundColor: AppColors.secondary.withValues(alpha: 0.12),
                side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.3)),
                onPressed: _detectingCity ? null : _autoDetectCity,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('input_email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email (optional)',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 18),
            CheckboxListTile(
              key: const Key('chk_guidelines'),
              contentPadding: EdgeInsets.zero,
              value: _agreed,
              onChanged: (v) => setState(() => _agreed = v ?? false),
              title: Text(
                'I am 18+ and agree to the Terms, Community Guidelines and Safety Policy. '
                'Saathira strictly prohibits sexual services, illegal activities, and off-platform cash.',
                style: t.bodySmall?.copyWith(color: AppColors.muted, height: 1.3),
              ),
            ),
            if (role == AppRole.companion)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: AppColors.secondary, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'After profile setup, you will complete ID verification before receiving bookings.',
                          style: TextStyle(color: AppColors.secondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              key: const Key('btn_register'),
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(role == AppRole.companion ? 'Continue to Companion Setup' : 'Start Finding Companions'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
