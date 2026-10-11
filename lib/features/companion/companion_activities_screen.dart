import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../repositories/companion_repository.dart';
import '../../theme/app_theme.dart';

class CompanionActivitiesScreen extends ConsumerStatefulWidget {
  const CompanionActivitiesScreen({super.key});

  @override
  ConsumerState<CompanionActivitiesScreen> createState() => _CompanionActivitiesScreenState();
}

class _CompanionActivitiesScreenState extends ConsumerState<CompanionActivitiesScreen> {
  // Map of activityId -> custom rate in Rupees (or null for default)
  final Map<String, int?> _selectedActivities = {};
  bool _initialized = false;
  bool _saving = false;

  void _initSelected(List<dynamic> current) {
    if (_initialized) return;
    for (final item in current) {
      final actId = item.activityId as String;
      final ratePaise = item.customRate as int?;
      _selectedActivities[actId] = ratePaise != null ? (ratePaise ~/ 100) : null;
    }
    _initialized = true;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final payload = _selectedActivities.entries.map((e) {
        return {
          'activityId': e.key,
          if (e.value != null) 'customRate': e.value! * 100, // convert ₹ to paise
        };
      }).toList();

      await ref.read(companionRepositoryProvider).syncActivities(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activities updated successfully!')),
      );
      ref.read(myCompanionProfileProvider.notifier).refresh();
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save activities: ${apiErrorMessage(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(activitiesListProvider);
    final profileAsync = ref.watch(myCompanionProfileProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('My Activities & Rates'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: activitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading activities: ${apiErrorMessage(e)}')),
        data: (activities) {
          return profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading profile: ${apiErrorMessage(e)}')),
            data: (profile) {
              if (profile != null) _initSelected(profile.activities);

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Choose which activities you are willing to accompany clients for. '
                      'You can leave custom rate blank to use your default base hourly rate.',
                      style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...activities.map((act) {
                    final isChecked = _selectedActivities.containsKey(act.id);
                    final customRate = _selectedActivities[act.id];

                    return Card(
                      color: AppColors.surface,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isChecked ? AppColors.primary : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(act.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              subtitle: act.description != null
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(act.description!, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                                    )
                                  : null,
                              value: isChecked,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedActivities[act.id] = null;
                                  } else {
                                    _selectedActivities.remove(act.id);
                                  }
                                });
                              },
                            ),
                            if (isChecked) ...[
                              const Divider(height: 16),
                              Row(
                                children: [
                                  const Text('Custom Rate (₹/hr):',
                                      style: TextStyle(fontSize: 13, color: AppColors.muted)),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: customRate != null ? customRate.toString() : '',
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      decoration: InputDecoration(
                                        hintText: 'Default: ₹${profile?.hourlyRateInRupees ?? 0}/hr',
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      ),
                                      onChanged: (val) {
                                        final parsed = int.tryParse(val.trim());
                                        _selectedActivities[act.id] = parsed;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save Activities'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
