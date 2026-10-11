import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../safety/report_user_dialog.dart';

enum CallState {
  connecting,
  ringing,
  connected,
  ended,
}

class InAppCallScreen extends StatefulWidget {
  const InAppCallScreen({
    super.key,
    required this.recipientName,
    this.recipientPhoto,
    required this.bookingId,
    this.roleLabel = 'Companion',
    this.recipientId,
  });

  final String recipientName;
  final String? recipientPhoto;
  final String bookingId;
  final String roleLabel;
  final String? recipientId;

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
  State<InAppCallScreen> createState() => _InAppCallScreenState();
}

class _InAppCallScreenState extends State<InAppCallScreen>
    with SingleTickerProviderStateMixin {
  CallState _callState = CallState.connecting;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  int _callDurationSeconds = 0;
  Timer? _callTimer;
  Timer? _stateTimer;

  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _simulateCallFlow();
  }

  void _simulateCallFlow() {
    // 1.5s -> Ringing
    _stateTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted || _callState == CallState.ended) return;
      setState(() => _callState = CallState.ringing);

      // 3.5s -> Connected
      _stateTimer = Timer(const Duration(milliseconds: 2200), () {
        if (!mounted || _callState == CallState.ended) return;
        setState(() => _callState = CallState.connected);
        _startTimer();
      });
    });
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

  void _endCall() {
    _callTimer?.cancel();
    _stateTimer?.cancel();
    setState(() => _callState = CallState.ended);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _stateTimer?.cancel();
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
    final initialLetter = widget.recipientName.isNotEmpty
        ? widget.recipientName[0].toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Top Privacy Shield Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.shield_rounded, color: AppColors.primary, size: 16),
                              SizedBox(width: 8),
                              Text(
                                '🔒 Number Masked • Encrypted Private Call',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Caller Info & Pulse Animation
                      Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer ripple pulse rings when ringing/connected
                              if (_callState != CallState.ended)
                                AnimatedBuilder(
                                  animation: _pulseCtrl,
                                  builder: (context, child) {
                                    final val = _pulseCtrl.value;
                                    return Container(
                                      width: 130 + (val * 34),
                                      height: 130 + (val * 34),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: (_callState == CallState.connected
                                                  ? const Color(0xFF10B981)
                                                  : AppColors.primary)
                                              .withValues(alpha: (1 - val) * 0.5),
                                          width: 2,
                                        ),
                                      ),
                                    );
                                  },
                                ),

                              // Avatar Circle
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.35),
                                      blurRadius: 24,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    initialLetter,
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          Text(
                            widget.recipientName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 6),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.roleLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Status Indicator
                          _buildStatusIndicator(),
                        ],
                      ),

                      const Spacer(),

                      // Sound Wave Equalizer Bars when connected
                      if (_callState == CallState.connected)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              return AnimatedBuilder(
                                animation: _pulseCtrl,
                                builder: (context, child) {
                                  final wave = ((_pulseCtrl.value * 2 + (index * 0.25)) % 1.0);
                                  final height = 10.0 + (wave * 18.0);
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    width: 4,
                                    height: height,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  );
                                },
                              );
                            }),
                          ),
                        ),

                      // Call Controls
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Mute Button
                                _buildControlButton(
                                  icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                                  label: _isMuted ? 'Unmute' : 'Mute',
                                  isActive: _isMuted,
                                  onTap: () => setState(() => _isMuted = !_isMuted),
                                ),

                                // Speaker Button
                                _buildControlButton(
                                  icon: _isSpeakerOn
                                      ? Icons.volume_up_rounded
                                      : Icons.volume_down_rounded,
                                  label: _isSpeakerOn ? 'Speaker' : 'Earpiece',
                                  isActive: _isSpeakerOn,
                                  onTap: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                                ),

                                // Safety / Report
                                _buildControlButton(
                                  icon: Icons.flag_outlined,
                                  label: 'Report',
                                  isActive: false,
                                  iconColor: Colors.redAccent,
                                  onTap: () {
                                    if (widget.recipientId != null) {
                                      ReportUserDialog.show(
                                        context,
                                        reportedUserId: widget.recipientId!,
                                        reportedUserName: widget.recipientName,
                                        bookingId: widget.bookingId,
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Safety report available in chat menu.')),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 28),

                            // End Call Action Button
                            GestureDetector(
                              onTap: _endCall,
                              child: Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.redAccent.withValues(alpha: 0.4),
                                      blurRadius: 18,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.call_end_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),
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
                      ),

                      const SizedBox(height: 10),
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
          children: const [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Securing private connection...',
              style: TextStyle(color: AppColors.muted, fontSize: 14),
            ),
          ],
        );
      case CallState.ringing:
        return const Text(
          'Ringing...',
          style: TextStyle(
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
        return const Text(
          'Call Ended',
          style: TextStyle(
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
    Color? iconColor,
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
                color: iconColor ?? (isActive ? Colors.white : Colors.white70),
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
