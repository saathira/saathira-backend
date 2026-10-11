import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/auth_repository.dart';
import '../../services/webrtc_call_service.dart';
import '../../theme/app_theme.dart';
import '../safety/report_user_dialog.dart';

enum CallState {
  connecting,
  ringing,
  connected,
  ended,
}

class InAppCallScreen extends ConsumerStatefulWidget {
  const InAppCallScreen({
    super.key,
    required this.recipientName,
    this.recipientPhoto,
    required this.bookingId,
    this.roleLabel = 'Companion',
    this.recipientId,
    this.isIncoming = false,
    this.offerData,
  });

  final String recipientName;
  final String? recipientPhoto;
  final String bookingId;
  final String roleLabel;
  final String? recipientId;
  final bool isIncoming;
  final Map<String, dynamic>? offerData;

  /// Start an outgoing call to the recipient
  static Future<void> start(
    BuildContext context, {
    required String recipientName,
    String? recipientPhoto,
    required String bookingId,
    String roleLabel = 'Companion',
    String? recipientId,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.85),
        pageBuilder: (context, anim1, anim2) => InAppCallScreen(
          recipientName: recipientName,
          recipientPhoto: recipientPhoto,
          bookingId: bookingId,
          roleLabel: roleLabel,
          recipientId: recipientId,
          isIncoming: false,
        ),
        transitionsBuilder: (context, anim1, anim2, child) {
          return FadeTransition(
            opacity: anim1,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
      ),
    );
  }

  /// Answer an incoming call
  static Future<void> answer(
    BuildContext context, {
    required String callerName,
    String? callerPhoto,
    required String bookingId,
    required Map<String, dynamic> offerData,
    String roleLabel = 'Caller',
    String? callerId,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.85),
        pageBuilder: (context, anim1, anim2) => InAppCallScreen(
          recipientName: callerName,
          recipientPhoto: callerPhoto,
          bookingId: bookingId,
          roleLabel: roleLabel,
          recipientId: callerId,
          isIncoming: true,
          offerData: offerData,
        ),
        transitionsBuilder: (context, anim1, anim2, child) {
          return FadeTransition(
            opacity: anim1,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  ConsumerState<InAppCallScreen> createState() => _InAppCallScreenState();
}

class _InAppCallScreenState extends ConsumerState<InAppCallScreen>
    with SingleTickerProviderStateMixin {
  CallState _callState = CallState.connecting;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  int _callDurationSeconds = 0;
  Timer? _callTimer;
  String _statusText = 'Securing private connection...';

  late AnimationController _pulseCtrl;
  late WebRtcCallService _callService;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _callService = ref.read(webrtcCallServiceProvider);
    _setupCallListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCall();
    });
  }

  void _setupCallListeners() {
    _callService.onStatusChanged = (status) {
      if (!mounted) return;
      switch (status) {
        case WebRtcCallStatus.connecting:
          setState(() {
            _callState = CallState.connecting;
            _statusText = 'Connecting encrypted audio...';
          });
          break;
        case WebRtcCallStatus.ringing:
          setState(() {
            _callState = CallState.ringing;
            _statusText = 'Ringing...';
          });
          break;
        case WebRtcCallStatus.connected:
          setState(() {
            _callState = CallState.connected;
          });
          _startTimer();
          break;
        case WebRtcCallStatus.rejected:
          setState(() {
            _callState = CallState.ended;
            _statusText = 'Call declined';
          });
          _autoCloseAfterDelay();
          break;
        case WebRtcCallStatus.ended:
          setState(() {
            _callState = CallState.ended;
            _statusText = 'Call ended';
          });
          _autoCloseAfterDelay();
          break;
        case WebRtcCallStatus.error:
          setState(() {
            _callState = CallState.ended;
            _statusText = 'Connection failed';
          });
          _autoCloseAfterDelay();
          break;
        default:
          break;
      }
    };

    _callService.onError = (msg) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
        );
      }
    };
  }

  Future<void> _initializeCall() async {
    if (widget.isIncoming) {
      if (widget.offerData != null) {
        await _callService.answerCall(
          bookingId: widget.bookingId,
          offerData: widget.offerData!,
        );
      }
    } else {
      final currentUser = ref.read(sessionProvider).value?.user;
      final callerId = currentUser?.id ?? 'anonymous';
      final callerName = currentUser?.fullName ?? 'User';
      final callerPhoto = currentUser?.photoUrl;

      await _callService.startCall(
        bookingId: widget.bookingId,
        callerId: callerId,
        callerName: callerName,
        callerPhoto: callerPhoto,
        recipientId: widget.recipientId ?? '',
      );
    }
  }

  void _startTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _callDurationSeconds++;
      });
    });
  }

  void _autoCloseAfterDelay() {
    _callTimer?.cancel();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _handleEndCall() async {
    _callTimer?.cancel();
    setState(() => _callState = CallState.ended);
    await _callService.endCall(widget.bookingId);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _callService.setMuted(_isMuted);
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    _callService.setSpeakerphone(_isSpeakerOn);
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF10B981)),
                                const SizedBox(width: 6),
                                Text(
                                  'WebRTC Encrypted',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.report_problem_outlined, color: Colors.white70),
                            tooltip: 'Safety & Report',
                            onPressed: () {
                              ReportUserDialog.show(
                                context,
                                reportedUserId: widget.recipientId ?? 'unknown',
                                reportedUserName: widget.recipientName,
                                bookingId: widget.bookingId,
                              );
                            },
                          ),
                        ],
                      ),

                      // Center Profile & Call Status
                      Column(
                        children: [
                          const SizedBox(height: 12),
                          // Pulse Ring Avatar
                          AnimatedBuilder(
                            animation: _pulseCtrl,
                            builder: (context, child) {
                              final wave = _callState == CallState.connected
                                  ? (1.0 + 0.08 * _pulseCtrl.value)
                                  : 1.0;
                              return Transform.scale(
                                scale: wave,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (_callState == CallState.connected)
                                      Container(
                                        width: 140,
                                        height: 140,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.primary.withValues(
                                              alpha: (1.0 - _pulseCtrl.value) * 0.5,
                                            ),
                                            width: 3,
                                          ),
                                        ),
                                      ),
                                    CircleAvatar(
                                      radius: 54,
                                      backgroundColor: AppColors.primary,
                                      backgroundImage: (widget.recipientPhoto != null &&
                                              widget.recipientPhoto!.isNotEmpty)
                                          ? NetworkImage(widget.recipientPhoto!)
                                          : null,
                                      child: (widget.recipientPhoto == null ||
                                              widget.recipientPhoto!.isEmpty)
                                          ? Text(
                                              widget.recipientName.isNotEmpty
                                                  ? widget.recipientName[0].toUpperCase()
                                                  : 'C',
                                              style: const TextStyle(
                                                fontSize: 42,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          Text(
                            widget.recipientName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.roleLabel,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildStatusIndicator(),
                        ],
                      ),

                      // Bottom Call Controls
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Mute Toggle
                              _buildControlButton(
                                icon: _isMuted ? Icons.mic_off : Icons.mic,
                                label: _isMuted ? 'Muted' : 'Mute',
                                isActive: _isMuted,
                                onTap: _callState == CallState.connected ? _toggleMute : () {},
                              ),
                              // Speaker Toggle
                              _buildControlButton(
                                icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                                label: _isSpeakerOn ? 'Speaker' : 'Earpiece',
                                isActive: _isSpeakerOn,
                                onTap: _callState == CallState.connected ? _toggleSpeaker : () {},
                              ),
                              // Safety Info
                              _buildControlButton(
                                icon: Icons.privacy_tip_outlined,
                                label: 'Private',
                                isActive: false,
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('🔒 Phone numbers are masked and hidden for privacy.'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 36),

                          // End Call Button
                          GestureDetector(
                            onTap: _handleEndCall,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.redAccent.shade700,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.call_end,
                                color: Colors.white,
                                size: 34,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'End Call',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    switch (_callState) {
      case CallState.connecting:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _statusText,
              style: const TextStyle(color: AppColors.muted, fontSize: 14),
            ),
          ],
        );
      case CallState.ringing:
        return Text(
          _statusText,
          style: const TextStyle(
            color: AppColors.secondary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        );
      case CallState.connected:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDuration(_callDurationSeconds),
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ],
        );
      case CallState.ended:
        return Text(
          _statusText,
          style: const TextStyle(
            color: Colors.redAccent,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        );
    }
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? Colors.white70 : Colors.white12,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                color: isActive ? Colors.white : Colors.white70,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
