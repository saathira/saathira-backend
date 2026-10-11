import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../models/app_user.dart';
import '../../models/booking.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/bookings_repository.dart';
import '../../theme/app_theme.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(myBookingsProvider(null));
    final session = ref.watch(sessionProvider).value;
    final isCompanion = session?.user?.role == AppRole.companion;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCompanion ? 'Client Bookings' : 'My Bookings'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.muted,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Requests'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Failed to load bookings: ${apiErrorMessage(e)}',
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.refresh(myBookingsProvider(null)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (allBookings) {
          final upcoming = allBookings.where((b) {
            return b.status == BookingStatus.confirmed ||
                b.status == BookingStatus.inProgress ||
                b.status == BookingStatus.paymentPending;
          }).toList();

          final requests = allBookings.where((b) {
            return b.status == BookingStatus.pending;
          }).toList();

          final past = allBookings.where((b) {
            return b.status == BookingStatus.completed ||
                b.status == BookingStatus.cancelled ||
                b.status == BookingStatus.rejected ||
                b.status == BookingStatus.expired;
          }).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _BookingListView(
                bookings: upcoming,
                emptyMessage: isCompanion
                    ? 'No upcoming bookings scheduled'
                    : 'No upcoming bookings yet',
                emptyActionText: isCompanion ? null : 'Explore Companions',
                onEmptyAction: isCompanion ? null : () => context.go('/home'),
                onRefresh: () async => ref.refresh(myBookingsProvider(null)),
                isCompanion: isCompanion,
              ),
              _BookingListView(
                bookings: requests,
                emptyMessage: 'No pending booking requests',
                onRefresh: () async => ref.refresh(myBookingsProvider(null)),
                isCompanion: isCompanion,
              ),
              _BookingListView(
                bookings: past,
                emptyMessage: 'No past booking records',
                onRefresh: () async => ref.refresh(myBookingsProvider(null)),
                isCompanion: isCompanion,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BookingListView extends StatelessWidget {
  const _BookingListView({
    required this.bookings,
    required this.emptyMessage,
    this.emptyActionText,
    this.onEmptyAction,
    required this.onRefresh,
    required this.isCompanion,
  });

  final List<Booking> bookings;
  final String emptyMessage;
  final String? emptyActionText;
  final VoidCallback? onEmptyAction;
  final Future<void> Function() onRefresh;
  final bool isCompanion;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.all(32),
          children: [
            const SizedBox(height: 80),
            Icon(Icons.calendar_today_outlined, size: 64, color: AppColors.muted.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(fontSize: 16, color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
            if (emptyActionText != null && onEmptyAction != null) ...[
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: onEmptyAction,
                  child: Text(emptyActionText!),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _BookingCard(booking: booking, isCompanion: isCompanion);
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.isCompanion});
  final Booking booking;
  final bool isCompanion;

  String _formatDateTime(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]}, $hour:$minuteStr $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final otherUser = isCompanion ? booking.customer : booking.companionUser;
    final otherName = otherUser?.fullName ?? (isCompanion ? 'Customer' : 'Companion');

    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: booking.status.color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          context.push('/bookings/${booking.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: User Info & Status Badge
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    child: Text(
                      otherName.isNotEmpty ? otherName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          otherName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          isCompanion ? 'Customer' : 'Companion',
                          style: const TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: booking.status.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: booking.status.color.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(booking.status.icon, color: booking.status.color, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          booking.status.label,
                          style: TextStyle(
                            color: booking.status.color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(height: 24, color: Colors.white10),

              // Activity & Schedule
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      booking.activity?.name ?? 'Activity',
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${booking.durationHours.toStringAsFixed(1)} hrs',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 15, color: AppColors.muted),
                  const SizedBox(width: 6),
                  Text(
                    _formatDateTime(booking.startAt),
                    style: const TextStyle(fontSize: 13, color: AppColors.text),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 15, color: AppColors.muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      booking.meetingPlace,
                      style: const TextStyle(fontSize: 13, color: AppColors.muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Footer: Price & Action CTA
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${booking.amountInRupees}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: const [
                      Text(
                        'Details',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primary),
                    ],
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
