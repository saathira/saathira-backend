import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_user.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/bookings_repository.dart';
import '../../repositories/chat_repository.dart';
import '../../theme/app_theme.dart';
import '../safety/report_user_dialog.dart';
import 'in_app_call_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String currentUserId, String currentUserName, String? currentUserPhoto) async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    _textCtrl.clear();
    setState(() => _sending = true);

    try {
      await ref.read(chatRepositoryProvider).sendMessage(
            bookingId: widget.bookingId,
            senderId: currentUserId,
            senderName: currentUserName,
            senderPhoto: currentUserPhoto,
            text: text,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minuteStr $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(bookingDetailProvider(widget.bookingId));
    final messagesAsync = ref.watch(chatMessagesStreamProvider(widget.bookingId));
    final session = ref.watch(sessionProvider).value;
    final currentUser = session?.user;
    final isCompanion = currentUser?.role == AppRole.companion;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        titleSpacing: 0,
        title: bookingAsync.when(
          loading: () => const Text('Chat'),
          error: (_, _) => const Text('Chat'),
          data: (booking) {
            final otherUser = isCompanion ? booking.customer : booking.companionUser;
            final otherName = otherUser?.fullName ?? 'User';

            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: Text(
                    otherName.isNotEmpty ? otherName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(otherName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      Text(
                        booking.activity?.name ?? 'Meeting Chat',
                        style: const TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          bookingAsync.maybeWhen(
            data: (booking) {
              final otherUser = isCompanion ? booking.customer : booking.companionUser;
              final otherId = isCompanion ? booking.customerId : (booking.companionUser?.id ?? '');
              final otherName = otherUser?.fullName ?? 'User';

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                      }
                    },
                    itemBuilder: (ctx) => [
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
      body: Column(
        children: [
          // Privacy Shield Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              border: Border(bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.2))),
            ),
            child: Row(
              children: const [
                Icon(Icons.shield_rounded, size: 16, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '🔒 Number Masking Active: Personal phone numbers are private. Use in-app chat & calls for safety.',
                    style: TextStyle(fontSize: 11, color: Colors.white70, height: 1.2),
                  ),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Could not load messages: $e', textAlign: TextAlign.center),
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.muted.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          const Text(
                            'No messages yet',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Say hi and coordinate meeting details like arrival time and attire.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.muted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == currentUser?.id;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                          ),
                          border: isMe ? null : Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.text,
                              style: TextStyle(
                                color: isMe ? Colors.white : AppColors.text,
                                fontSize: 14.5,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(msg.createdAt),
                              style: TextStyle(
                                color: isMe ? Colors.white70 : AppColors.muted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('chat_input'),
                      controller: _textCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.bg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) {
                        if (currentUser != null) {
                          _sendMessage(currentUser.id, currentUser.fullName ?? 'User', currentUser.photoUrl);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    key: const Key('btn_send_chat'),
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 20),
                    style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                    onPressed: _sending
                        ? null
                        : () {
                            if (currentUser != null) {
                              _sendMessage(currentUser.id, currentUser.fullName ?? 'User', currentUser.photoUrl);
                            }
                          },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
