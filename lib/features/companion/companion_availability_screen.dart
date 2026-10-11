import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../models/companion_profile.dart';
import '../../repositories/companion_repository.dart';
import '../../theme/app_theme.dart';

class CompanionAvailabilityScreen extends ConsumerStatefulWidget {
  const CompanionAvailabilityScreen({super.key});

  @override
  ConsumerState<CompanionAvailabilityScreen> createState() => _CompanionAvailabilityScreenState();
}

class _CompanionAvailabilityScreenState extends ConsumerState<CompanionAvailabilityScreen> {
  int _selectedDay = 1; // Default Monday (1)
  final List<AvailabilitySlot> _slots = [];
  bool _initialized = false;
  bool _saving = false;

  final List<String> _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  void _initSlots(List<AvailabilitySlot> current) {
    if (_initialized) return;
    _slots.clear();
    _slots.addAll(current);
    _initialized = true;
  }

  Future<void> _addSlot() async {
    final start = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (start == null || !mounted) return;

    final end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (start.hour + 2) % 24, minute: start.minute),
    );
    if (end == null || !mounted) return;

    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes >= endMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be later than start time')),
      );
      return;
    }

    setState(() {
      _slots.add(AvailabilitySlot(
        dayOfWeek: _selectedDay,
        startMinute: startMinutes,
        endMinute: endMinutes,
      ));
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(companionRepositoryProvider).syncAvailability(_slots);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weekly availability updated successfully!')),
      );
      ref.read(myCompanionProfileProvider.notifier).refresh();
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update availability: ${apiErrorMessage(e)}')),
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
        title: const Text('Weekly Availability'),
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
        error: (e, _) => Center(child: Text('Error loading profile: ${apiErrorMessage(e)}')),
        data: (profile) {
          if (profile != null) _initSlots(profile.availability);

          final currentDaySlots = _slots.where((s) => s.dayOfWeek == _selectedDay).toList()
            ..sort((a, b) => a.startMinute.compareTo(b.startMinute));

          return Column(
            children: [
              // Day Tabs
              Container(
                height: 70,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedDay == index;
                    final slotCount = _slots.where((s) => s.dayOfWeek == index).length;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => setState(() => _selectedDay = index),
                        child: Container(
                          width: 58,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _dayNames[index],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : AppColors.muted,
                                ),
                              ),
                              if (slotCount > 0)
                                Text(
                                  '$slotCount slots',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isSelected ? Colors.white70 : AppColors.secondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const Divider(height: 1),

              // Slots list for selected day
              Expanded(
                child: currentDaySlots.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.event_busy, size: 48, color: AppColors.muted),
                            const SizedBox(height: 12),
                            Text(
                              'No slots configured for ${_dayNames[_selectedDay]}',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _addSlot,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Time Slot'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: currentDaySlots.length,
                        itemBuilder: (context, index) {
                          final slot = currentDaySlots[index];
                          return Card(
                            color: AppColors.surface,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            child: ListTile(
                              leading: const Icon(Icons.access_time, color: AppColors.primary),
                              title: Text(slot.timeRangeLabel,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              subtitle: Text(slot.dayName, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () {
                                  setState(() {
                                    _slots.remove(slot);
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Bottom add slot bar
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton.icon(
                  onPressed: _addSlot,
                  icon: const Icon(Icons.add),
                  label: Text('Add Slot for ${_dayNames[_selectedDay]}'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
