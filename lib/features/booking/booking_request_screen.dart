import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../models/companion_profile.dart';
import '../../repositories/bookings_repository.dart';
import '../../repositories/discovery_repository.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';

class BookingRequestScreen extends ConsumerStatefulWidget {
  const BookingRequestScreen({
    super.key,
    required this.companionId,
    this.companionInitial,
  });

  final String companionId;
  final CompanionProfile? companionInitial;

  @override
  ConsumerState<BookingRequestScreen> createState() => _BookingRequestScreenState();
}

class _BookingRequestScreenState extends ConsumerState<BookingRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _meetingPlaceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _detectingLocation = false;

  Future<void> _autoDetectMeetingLocation() async {
    setState(() => _detectingLocation = true);
    try {
      final loc = await ref.read(currentLocationProvider.notifier).autoDetectLocation();
      final suggestedPlace = 'Starbucks / Cafe, ${loc.displayName}';
      setState(() {
        _meetingPlaceCtrl.text = suggestedPlace;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Set meeting area to ${loc.displayName}'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not detect location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _detectingLocation = false);
    }
  }

  String? _selectedActivityId;
  int? _selectedActivityRatePaise;

  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Default to tomorrow 2:00 PM - 4:00 PM
    _selectedDate = now.add(const Duration(days: 1));
    _startTime = const TimeOfDay(hour: 14, minute: 0);
    _endTime = const TimeOfDay(hour: 16, minute: 0);

    if (widget.companionInitial != null && widget.companionInitial!.activities.isNotEmpty) {
      final first = widget.companionInitial!.activities.first;
      _selectedActivityId = first.activityId;
      _selectedActivityRatePaise = first.customRate ?? widget.companionInitial!.hourlyRate;
    }
  }

  @override
  void dispose() {
    _meetingPlaceCtrl.dispose;
    _notesCtrl.dispose();
    super.dispose();
  }

  DateTime get _startDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
  }

  DateTime get _endDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );
  }

  int get _durationMinutes {
    final diff = _endDateTime.difference(_startDateTime).inMinutes;
    return diff > 0 ? diff : 0;
  }

  int _calculateTotalPaise(int baseRatePaise) {
    final rate = _selectedActivityRatePaise ?? baseRatePaise;
    if (_durationMinutes <= 0) return 0;
    return (rate * _durationMinutes / 60.0).round();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        // Adjust end time to be at least 1 hour later
        final newEndHour = (picked.hour + 2) % 24;
        _endTime = TimeOfDay(hour: newEndHour, minute: picked.minute);
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _submitRequest(int baseRatePaise) async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedActivityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an activity')),
      );
      return;
    }

    if (_startDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start time must be in the future')),
      );
      return;
    }

    if (_durationMinutes < 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking duration must be at least 1 hour (60 mins)')),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final booking = await ref.read(bookingsRepositoryProvider).createBooking(
            companionId: widget.companionId,
            activityId: _selectedActivityId!,
            startAt: _startDateTime,
            endAt: _endDateTime,
            meetingPlace: _meetingPlaceCtrl.text.trim(),
            notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
          );

      if (!mounted) return;
      ref.invalidate(myBookingsProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Booking request sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to booking detail screen
      context.go('/bookings/${booking.id}');
    } catch (e) {
      setState(() {
        _errorMessage = apiErrorMessage(e);
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(companionDetailProvider(widget.companionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Booking'),
        backgroundColor: Colors.transparent,
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Could not load companion: ${apiErrorMessage(e)}', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.refresh(companionDetailProvider(widget.companionId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (companion) {
          if (_selectedActivityId == null && companion.activities.isNotEmpty) {
            _selectedActivityId = companion.activities.first.activityId;
            _selectedActivityRatePaise =
                companion.activities.first.customRate ?? companion.hourlyRate;
          }

          final totalPaise = _calculateTotalPaise(companion.hourlyRate);
          final totalRupees = totalPaise ~/ 100;
          final currentRateRupees = (_selectedActivityRatePaise ?? companion.hourlyRate) ~/ 100;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
              children: [
                // Companion Mini Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                        child: Text(
                          companion.user?.fullName.isNotEmpty == true
                              ? companion.user!.fullName[0].toUpperCase()
                              : 'C',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              companion.user?.fullName ?? 'Companion',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              companion.user?.city ?? 'Location flexible',
                              style: const TextStyle(color: AppColors.muted, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 15),
                                const SizedBox(width: 4),
                                Text(
                                  companion.ratingAvg > 0
                                      ? companion.ratingAvg.toStringAsFixed(1)
                                      : 'New',
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                const Text(
                  '1. Select Activity',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (companion.activities.isEmpty)
                  const Text('Companion has not configured any activities.',
                      style: TextStyle(color: AppColors.muted))
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: companion.activities.map((item) {
                      final isSelected = _selectedActivityId == item.activityId;
                      final rate = (item.customRate ?? companion.hourlyRate) ~/ 100;

                      return ChoiceChip(
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedActivityId = item.activityId;
                              _selectedActivityRatePaise =
                                  item.customRate ?? companion.hourlyRate;
                            });
                          }
                        },
                        label: Text('${item.activity.name} (₹$rate/hr)'),
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.text,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.08),
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 24),
                const Text(
                  '2. Date & Time Window',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Date Picker Button
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Meeting Date',
                                style: TextStyle(color: AppColors.muted, fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.edit, size: 18, color: AppColors.muted),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Time Pickers Row
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickStartTime,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Start Time',
                                  style: TextStyle(color: AppColors.muted, fontSize: 11)),
                              const SizedBox(height: 4),
                              Text(
                                _startTime.format(context),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _pickEndTime,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('End Time',
                                  style: TextStyle(color: AppColors.muted, fontSize: 11)),
                              const SizedBox(height: 4),
                              Text(
                                _endTime.format(context),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '3. Public Meeting Location',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      icon: _detectingLocation
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location, size: 14, color: AppColors.secondary),
                      label: const Text(
                        'Auto-Detect Location',
                        style: TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _detectingLocation ? null : _autoDetectMeetingLocation,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'For your safety, meetings must take place in public places (cafes, malls, parks).',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _meetingPlaceCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                    suffixIcon: _detectingLocation
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
                            tooltip: 'Auto-detect location',
                            onPressed: _autoDetectMeetingLocation,
                          ),
                    hintText: 'e.g. Starbucks, Indiranagar 100ft Rd',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please specify a public meeting location';
                    }
                    if (val.trim().length < 5) {
                      return 'Please enter a more descriptive location';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),
                const Text(
                  '4. Special Notes (Optional)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Any specific agenda, dress code preference, or topics to discuss...',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Cost Breakdown Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Hourly Rate', style: TextStyle(color: AppColors.muted)),
                          Text('₹$currentRateRupees/hr',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Duration', style: TextStyle(color: AppColors.muted)),
                          Text(
                            '${(_durationMinutes / 60.0).toStringAsFixed(1)} hrs ($_durationMinutes mins)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: Colors.white12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Estimated Total',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '₹$totalRupees',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Payment is only required after the companion accepts your request.',
                        style: TextStyle(fontSize: 11.5, color: AppColors.muted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bg,
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        ),
        child: SafeArea(
          child: ElevatedButton(
            key: const Key('btn_submit_booking_request'),
            onPressed: _submitting
                ? null
                : () {
                    final detail = ref.read(companionDetailProvider(widget.companionId)).value;
                    if (detail != null) {
                      _submitRequest(detail.hourlyRate);
                    }
                  },
            child: _submitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Confirm & Send Request',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}
