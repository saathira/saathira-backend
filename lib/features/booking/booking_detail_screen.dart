import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../models/app_user.dart';
import '../../models/booking.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/bookings_repository.dart';
import '../../repositories/payments_repository.dart';
import '../../theme/app_theme.dart';
import '../chat/in_app_call_screen.dart';
import '../reviews/leave_review_dialog.dart';
import '../safety/report_user_dialog.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  const BookingDetailScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  ConsumerState<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  bool _actionLoading = false;

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minuteStr $ampm';
  }

  Future<void> _handleAccept() async {
    setState(() => _actionLoading = true);
    try {
      await ref.read(bookingsRepositoryProvider).acceptBooking(widget.bookingId);
      ref.invalidate(bookingDetailProvider(widget.bookingId));
      ref.invalidate(myBookingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking request accepted! Customer has been notified to complete payment.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${apiErrorMessage(e)}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _handleReject() async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Decline Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to decline this booking request?', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                hintText: 'Reason for declining (optional)...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _actionLoading = true);
    try {
      await ref.read(bookingsRepositoryProvider).rejectBooking(
            widget.bookingId,
            reason: reasonCtrl.text.trim().isNotEmpty ? reasonCtrl.text.trim() : null,
          );
      ref.invalidate(bookingDetailProvider(widget.bookingId));
      ref.invalidate(myBookingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking request declined')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${apiErrorMessage(e)}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _handleCancel() async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Cancel Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for cancellation:', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Personal emergency, scheduling conflict',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Booking')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a cancellation reason')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _actionLoading = true);
    try {
      await ref.read(bookingsRepositoryProvider).cancelBooking(
            widget.bookingId,
            reason: reasonCtrl.text.trim(),
          );
      ref.invalidate(bookingDetailProvider(widget.bookingId));
      ref.invalidate(myBookingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${apiErrorMessage(e)}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _handleStart() async {
    setState(() => _actionLoading = true);
    try {
      await ref.read(bookingsRepositoryProvider).startBooking(widget.bookingId);
      ref.invalidate(bookingDetailProvider(widget.bookingId));
      ref.invalidate(myBookingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚀 Meeting started! Have a great and safe companion experience.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${apiErrorMessage(e)}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _handlePaymentCheckout(Booking booking) async {
    setState(() => _actionLoading = true);
    try {
      // 1. Create order on backend
      final order = await ref.read(paymentsRepositoryProvider).createOrder(booking.id);

      if (!mounted) return;

      // 2. Open Payment Sheet modal
      final bool? proceed = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: AppColors.surface,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (ctx) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.security, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Secure Escrow Checkout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Powered by Razorpay', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Companion', style: TextStyle(color: AppColors.muted)),
                          Text(order.companionName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Activity', style: TextStyle(color: AppColors.muted)),
                          Text(order.activityName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(height: 20, color: Colors.white10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(
                            '₹${order.amountInRupees}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.secondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: const [
                    Icon(Icons.shield_outlined, color: Colors.greenAccent, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '100% Escrow Protection: Payment is held safely and released to companion only after meeting is completed.',
                        style: TextStyle(fontSize: 11.5, color: Colors.greenAccent, height: 1.3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('btn_confirm_razorpay_payment'),
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Pay ₹${order.amountInRupees} (UPI / Card / NetBanking)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (proceed != true) return;

      // 3. Verify Payment
      final paymentId = 'pay_${DateTime.now().millisecondsSinceEpoch}';
      await ref.read(paymentsRepositoryProvider).verifyPayment(
            bookingId: booking.id,
            razorpayOrderId: order.orderId,
            razorpayPaymentId: paymentId,
          );

      ref.invalidate(bookingDetailProvider(widget.bookingId));
      ref.invalidate(myBookingsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Payment successful! Meeting confirmed.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${apiErrorMessage(e)}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _handleComplete() async {
    setState(() => _actionLoading = true);
    try {
      await ref.read(bookingsRepositoryProvider).completeBooking(widget.bookingId);
      ref.invalidate(bookingDetailProvider(widget.bookingId));
      ref.invalidate(myBookingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ Meeting marked completed! Payout will be processed.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${apiErrorMessage(e)}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(bookingDetailProvider(widget.bookingId));
    final session = ref.watch(sessionProvider).value;
    final currentUserId = session?.user?.id;
    final isCompanion = session?.user?.role == AppRole.companion;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.transparent,
        actions: [
          bookingAsync.maybeWhen(
            data: (booking) {
              final otherUser = isCompanion ? booking.customer : booking.companionUser;
              final otherId = isCompanion ? booking.customerId : (booking.companionUser?.id ?? '');
              final otherName = otherUser?.fullName ?? (isCompanion ? 'Customer' : 'Companion');

              final canChat = booking.status == BookingStatus.confirmed ||
                  booking.status == BookingStatus.inProgress ||
                  booking.status == BookingStatus.paymentPending ||
                  booking.status == BookingStatus.completed;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canChat) ...[
                    IconButton(
                      icon: const Icon(Icons.phone_in_talk_rounded, color: AppColors.primary),
                      tooltip: 'In-App Voice Call (Private)',
                      onPressed: () {
                        InAppCallScreen.start(
                          context,
                          recipientName: otherName,
                          recipientPhoto: otherUser?.photoUrl,
                          bookingId: booking.id,
                          roleLabel: isCompanion ? 'Customer' : 'Companion',
                          recipientId: otherId,
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline),
                      tooltip: 'Open Chat',
                      onPressed: () => context.push('/chat/${booking.id}'),
                    ),
                  ],
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (val) {
                      if (val == 'report') {
                        ReportUserDialog.show(
                          context,
                          reportedUserId: otherId,
                          reportedUserName: otherName,
                          bookingId: booking.id,
                        );
                      } else if (val == 'safety') {
                        context.push('/safety');
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'safety',
                        child: Row(
                          children: [
                            Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text('Safety & SOS'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(Icons.flag_outlined, size: 18, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text('Report User', style: TextStyle(color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: bookingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Could not load booking: ${apiErrorMessage(e)}', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.refresh(bookingDetailProvider(widget.bookingId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (booking) {
          final otherUser = isCompanion ? booking.customer : booking.companionUser;
          final otherId = isCompanion ? booking.customerId : (booking.companionUser?.id ?? '');
          final otherName = otherUser?.fullName ?? (isCompanion ? 'Customer' : 'Companion');

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 130),
                children: [
                  // Status Header Banner Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: booking.status.color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: booking.status.color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(booking.status.icon, color: booking.status.color, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.status.label,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: booking.status.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getStatusHelpText(booking.status, isCompanion),
                                style: const TextStyle(fontSize: 13, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Cancellation / Rejection info banner if applicable
                  if (booking.cancelReason != null && booking.cancelReason!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.cancelledBy != null
                                      ? 'Cancelled by ${booking.cancelledBy}'
                                      : 'Decline / Cancellation Reason:',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.redAccent),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  booking.cancelReason!,
                                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Participant Profile Card
                  const Text('Participant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                          child: Text(
                            otherName.isNotEmpty ? otherName[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(otherName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(
                                '${isCompanion ? "Customer" : "Companion"} • ${otherUser?.city ?? "India"}',
                                style: const TextStyle(fontSize: 13, color: AppColors.muted),
                              ),
                              if (booking.status == BookingStatus.confirmed ||
                                  booking.status == BookingStatus.inProgress ||
                                  booking.status == BookingStatus.paymentPending) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.shield_rounded, size: 12, color: AppColors.primary),
                                      SizedBox(width: 4),
                                      Text(
                                        '🔒 Number Masked (Private)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.chat_bubble_outline, size: 15),
                                        label: const Text('Chat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          side: const BorderSide(color: AppColors.primary),
                                          foregroundColor: AppColors.primary,
                                          minimumSize: const Size(0, 34),
                                        ),
                                        onPressed: () => context.push('/chat/${booking.id}'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.phone_in_talk_rounded, size: 15),
                                        label: const Text('In-App Call', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          minimumSize: const Size(0, 34),
                                        ),
                                        onPressed: () {
                                          InAppCallScreen.start(
                                            context,
                                            recipientName: otherName,
                                            recipientPhoto: otherUser?.photoUrl,
                                            bookingId: booking.id,
                                            roleLabel: isCompanion ? 'Customer' : 'Companion',
                                            recipientId: otherId,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Meeting Details Card
                  const Text('Meeting Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          icon: Icons.local_activity_outlined,
                          title: 'Activity',
                          value: booking.activity?.name ?? 'Standard Companionship',
                        ),
                        const Divider(height: 20, color: Colors.white10),
                        _buildDetailRow(
                          icon: Icons.calendar_today_outlined,
                          title: 'Date & Time',
                          value: '${_formatDateTime(booking.startAt)}\nDuration: ${booking.durationHours.toStringAsFixed(1)} hrs',
                        ),
                        const Divider(height: 20, color: Colors.white10),
                        _buildDetailRow(
                          icon: Icons.location_on_outlined,
                          title: 'Meeting Location',
                          value: booking.meetingPlace,
                        ),
                        if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                          const Divider(height: 20, color: Colors.white10),
                          _buildDetailRow(
                            icon: Icons.notes_outlined,
                            title: 'Customer Notes',
                            value: booking.notes!,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Financial Details Card
                  const Text('Payment Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Booking Fee', style: TextStyle(color: AppColors.muted)),
                            Text(
                              '₹${booking.amountInRupees}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        if (isCompanion) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Platform Fee (20%)', style: TextStyle(color: AppColors.muted)),
                              Text(
                                '-₹${booking.commissionInRupees}',
                                style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                              ),
                            ],
                          ),
                          const Divider(height: 20, color: Colors.white10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Your Net Earnings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text(
                                '₹${booking.amountInRupees - booking.commissionInRupees}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.greenAccent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Safety Advice Banner
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Always stay in designated public spaces. Never agree to private residences or unverified locations.',
                            style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Bottom Action Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                  ),
                  child: SafeArea(
                    child: _buildActionButtons(booking, isCompanion, currentUserId),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getStatusHelpText(BookingStatus status, bool isCompanion) {
    switch (status) {
      case BookingStatus.pending:
        return isCompanion
            ? 'Review and accept or decline this request.'
            : 'Waiting for companion to review and accept.';
      case BookingStatus.paymentPending:
        return isCompanion
            ? 'Accepted! Waiting for customer to complete payment.'
            : 'Request accepted! Complete payment to confirm meeting.';
      case BookingStatus.confirmed:
        return 'Meeting is confirmed! Coordinate meeting at scheduled time.';
      case BookingStatus.inProgress:
        return 'Meeting is currently in progress.';
      case BookingStatus.completed:
        return 'Meeting has been successfully completed.';
      case BookingStatus.cancelled:
        return 'This booking was cancelled.';
      case BookingStatus.rejected:
        return 'This booking request was declined.';
      case BookingStatus.expired:
        return 'This booking expired before confirmation.';
      case BookingStatus.disputed:
        return 'Under safety investigation.';
    }
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Booking booking, bool isCompanion, String? currentUserId) {
    if (_actionLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Companion Actions
    if (isCompanion) {
      if (booking.status == BookingStatus.pending) {
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('btn_reject_booking'),
                onPressed: _handleReject,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Decline'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                key: const Key('btn_accept_booking'),
                onPressed: _handleAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Accept Request', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      }

      if (booking.status == BookingStatus.confirmed) {
        return ElevatedButton(
          key: const Key('btn_start_meeting'),
          onPressed: _handleStart,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Start Meeting Now 🚀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        );
      }

      if (booking.status == BookingStatus.inProgress) {
        return ElevatedButton(
          key: const Key('btn_complete_meeting'),
          onPressed: _handleComplete,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Mark Meeting Complete ✨', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        );
      }

      if (booking.status == BookingStatus.paymentPending) {
        return const Center(
          child: Text('Awaiting Client Payment...', style: TextStyle(color: AppColors.muted, fontStyle: FontStyle.italic)),
        );
      }

      return const SizedBox.shrink();
    }

    // Customer Actions
    if (booking.status == BookingStatus.paymentPending) {
      return ElevatedButton(
        key: const Key('btn_pay_booking'),
        onPressed: () => _handlePaymentCheckout(booking),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          'Pay ₹${booking.amountInRupees} & Confirm',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      );
    }

    if (booking.status == BookingStatus.inProgress) {
      return ElevatedButton(
        key: const Key('btn_customer_complete'),
        onPressed: _handleComplete,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('Mark Meeting Completed ✨', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      );
    }

    if (booking.status == BookingStatus.completed) {
      final companionName = booking.companionUser?.fullName ?? 'Companion';

      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          key: const Key('btn_leave_review'),
          icon: const Icon(Icons.star_rounded, color: Colors.amber),
          label: const Text('Leave a Review & Rating ⭐', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () {
            LeaveReviewDialog.show(
              context,
              bookingId: booking.id,
              companionName: companionName,
            );
          },
        ),
      );
    }

    if (booking.status == BookingStatus.pending || booking.status == BookingStatus.confirmed) {
      return OutlinedButton(
        key: const Key('btn_customer_cancel'),
        onPressed: _handleCancel,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: const BorderSide(color: Colors.redAccent),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: const Text('Cancel Booking'),
      );
    }

    return const SizedBox.shrink();
  }
}
