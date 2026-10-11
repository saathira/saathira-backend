import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/app_user.dart';
import '../../models/booking.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/bookings_repository.dart';
import '../../theme/app_theme.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsProvider(null));
    final session = ref.watch(sessionProvider).value;
    final isCompanion = session?.user?.role == AppRole.companion;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.transparent,
      ),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load messages: $e'),
          ),
        ),
        data: (allBookings) {
          final activeChatBookings = allBookings.where((b) {
            return b.status == BookingStatus.confirmed ||
                b.status == BookingStatus.inProgress ||
                b.status == BookingStatus.paymentPending ||
                b.status == BookingStatus.completed;
          }).toList();

          if (activeChatBookings.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mark_chat_unread_outlined, size: 60, color: AppColors.muted.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    const Text('No active chats', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    const SizedBox(height: 6),
                    const Text(
                      'Direct messaging opens once a booking request is accepted.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: activeChatBookings.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final booking = activeChatBookings[index];
              final otherUser = isCompanion ? booking.customer : booking.companionUser;
              final otherName = otherUser?.fullName ?? (isCompanion ? 'Customer' : 'Companion');

              return Card(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    child: Text(
                      otherName.isNotEmpty ? otherName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18),
                    ),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(otherName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: booking.status.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          booking.status.label,
                          style: TextStyle(color: booking.status.color, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${booking.activity?.name ?? "Meeting"} • Tap to open conversation',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
                  onTap: () {
                    context.push('/chat/${booking.id}');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
