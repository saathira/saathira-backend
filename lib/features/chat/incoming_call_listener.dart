import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/auth_repository.dart';
import '../../routing/app_router.dart';
import '../../services/webrtc_call_service.dart';
import '../../theme/app_theme.dart';
import 'in_app_call_screen.dart';

class IncomingCallListenerWrapper extends ConsumerStatefulWidget {
  const IncomingCallListenerWrapper({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<IncomingCallListenerWrapper> createState() => _IncomingCallListenerWrapperState();
}

class _IncomingCallListenerWrapperState extends ConsumerState<IncomingCallListenerWrapper> {
  StreamSubscription<QuerySnapshot>? _callSub;
  String? _activeRingingCallId;
  BuildContext? _incomingDialogContext;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupListener();
    });
  }

  void _setupListener() {
    if (!ref.read(firebaseReadyProvider)) return;
    final user = ref.read(sessionProvider).value?.user;
    if (user == null) return;

    _callSub?.cancel();
    _callSub = FirebaseFirestore.instance
        .collection('calls')
        .where('recipientId', isEqualTo: user.id)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        final callId = doc.id;

        if (_activeRingingCallId != callId) {
          _activeRingingCallId = callId;
          _showIncomingCallModal(callId, data);
        }
      } else {
        // If caller hung up or call cancelled
        if (_incomingDialogContext != null) {
          Navigator.of(_incomingDialogContext!).pop();
          _incomingDialogContext = null;
          _activeRingingCallId = null;
        }
      }
    });
  }

  void _showIncomingCallModal(String callId, Map<String, dynamic> data) {
    final callerName = data['callerName'] as String? ?? 'Client / Companion';
    final callerPhoto = data['callerPhoto'] as String?;
    final bookingId = data['bookingId'] as String? ?? callId;
    final offerData = data['offer'] as Map<String, dynamic>?;

    final targetContext = rootNavigatorKey.currentContext ?? context;

    showModalBottomSheet(
      context: targetContext,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        _incomingDialogContext = ctx;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF181528),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulse Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary,
                backgroundImage: (callerPhoto != null && callerPhoto.isNotEmpty)
                    ? NetworkImage(callerPhoto)
                    : null,
                child: (callerPhoto == null || callerPhoto.isEmpty)
                    ? Text(
                        callerName.isNotEmpty ? callerName[0].toUpperCase() : 'C',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(height: 14),

              Text(
                callerName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              const Text(
                'Incoming In-App Voice Call (Encrypted)',
                style: TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                'Booking #${bookingId.length > 8 ? bookingId.substring(0, 8) : bookingId}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 28),

              // Action Buttons: Decline and Accept
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Decline Button
                  GestureDetector(
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      _incomingDialogContext = null;
                      _activeRingingCallId = null;
                      await ref.read(webrtcCallServiceProvider).rejectCall(bookingId);
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call_end, color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 8),
                        const Text('Decline', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),

                  // Accept Button
                  GestureDetector(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _incomingDialogContext = null;
                      _activeRingingCallId = null;

                      if (offerData != null) {
                        InAppCallScreen.answer(
                          targetContext,
                          callerName: callerName,
                          callerPhoto: callerPhoto,
                          bookingId: bookingId,
                          offerData: offerData,
                          roleLabel: 'In-App Caller',
                          callerId: data['callerId'] as String?,
                        );
                      }
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call, color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 8),
                        const Text('Accept', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _callSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Re-check listener if session user changes
    ref.listen(sessionProvider, (prev, next) {
      if (next.value?.user?.id != prev?.value?.user?.id) {
        _setupListener();
      }
    });

    return widget.child;
  }
}
