import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

enum WebRtcCallStatus {
  idle,
  connecting,
  ringing,
  connected,
  ended,
  rejected,
  error,
}

class WebRtcCallService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  StreamSubscription<DocumentSnapshot>? _callDocSub;
  StreamSubscription<QuerySnapshot>? _candidatesSub;

  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  final Map<String, dynamic> _mediaConstraints = {
    'audio': true,
    'video': false,
  };

  /// Call state change callback
  void Function(WebRtcCallStatus status)? onStatusChanged;
  void Function(String errorMessage)? onError;

  /// Start outgoing audio call to recipient
  Future<void> startCall({
    required String bookingId,
    required String callerId,
    required String callerName,
    String? callerPhoto,
    required String recipientId,
  }) async {
    try {
      onStatusChanged?.call(WebRtcCallStatus.connecting);

      // 1. Acquire local audio stream
      _localStream = await navigator.mediaDevices.getUserMedia(_mediaConstraints);

      // 2. Initialize RTCPeerConnection
      _peerConnection = await createPeerConnection(_iceServers);

      // 3. Register audio tracks
      for (final track in _localStream!.getAudioTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }

      // 4. Remote track listener
      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams[0];
          debugPrint('WebRTC: Remote audio track received!');
        }
      };

      final callDoc = _firestore.collection('calls').doc(bookingId);
      final callerCandidatesCol = callDoc.collection('callerCandidates');

      // 5. Send ICE candidates to Firestore
      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        if (candidate.candidate == null || candidate.candidate!.isEmpty) return;
        callerCandidatesCol.add({
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      };

      // 6. Generate SDP Offer
      final offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': 0,
      });
      await _peerConnection!.setLocalDescription(offer);

      // 7. Write Call record to Firestore
      await callDoc.set({
        'bookingId': bookingId,
        'callerId': callerId,
        'callerName': callerName,
        'callerPhoto': callerPhoto,
        'recipientId': recipientId,
        'status': 'ringing',
        'offer': {
          'sdp': offer.sdp,
          'type': offer.type,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      onStatusChanged?.call(WebRtcCallStatus.ringing);

      // 8. Listen for Recipient's Answer and Status updates
      _callDocSub = callDoc.snapshots().listen((snapshot) async {
        if (!snapshot.exists) return;
        final data = snapshot.data();
        if (data == null) return;

        final status = data['status'] as String?;

        if (status == 'connected' && data['answer'] != null) {
          if (_peerConnection?.getRemoteDescription() == null) {
            final answer = data['answer'] as Map<String, dynamic>;
            final rtcAnswer = RTCSessionDescription(
              answer['sdp'] as String,
              answer['type'] as String,
            );
            await _peerConnection!.setRemoteDescription(rtcAnswer);
            onStatusChanged?.call(WebRtcCallStatus.connected);

            // Listen for Recipient's ICE candidates
            _candidatesSub = callDoc
                .collection('recipientCandidates')
                .snapshots()
                .listen((candSnap) {
              for (final change in candSnap.docChanges) {
                if (change.type == DocumentChangeType.added) {
                  final cData = change.doc.data();
                  if (cData == null) continue;
                  final candStr = cData['candidate'] as String?;
                  if (candStr == null || candStr.isEmpty) continue;
                  final candidate = RTCIceCandidate(
                    candStr,
                    cData['sdpMid'] as String?,
                    cData['sdpMLineIndex'] as int?,
                  );
                  _peerConnection?.addCandidate(candidate);
                }
              }
            });
          }
        } else if (status == 'rejected') {
          onStatusChanged?.call(WebRtcCallStatus.rejected);
          await endCall(bookingId);
        } else if (status == 'ended') {
          onStatusChanged?.call(WebRtcCallStatus.ended);
          await endCall(bookingId);
        }
      });
    } catch (e) {
      debugPrint('WebRTC Call Error: $e');
      onError?.call('Call initialization failed: $e');
      onStatusChanged?.call(WebRtcCallStatus.error);
      await endCall(bookingId);
    }
  }

  /// Answer incoming call from caller
  Future<void> answerCall({
    required String bookingId,
    required Map<String, dynamic> offerData,
  }) async {
    try {
      onStatusChanged?.call(WebRtcCallStatus.connecting);

      final callDoc = _firestore.collection('calls').doc(bookingId);

      // 1. Acquire local audio stream
      _localStream = await navigator.mediaDevices.getUserMedia(_mediaConstraints);

      // 2. Initialize RTCPeerConnection
      _peerConnection = await createPeerConnection(_iceServers);

      // 3. Register audio tracks
      for (final track in _localStream!.getAudioTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }

      // 4. Remote track listener
      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams[0];
          debugPrint('WebRTC: Remote audio track connected!');
        }
      };

      // 5. Send recipient ICE candidates to Firestore
      final recipientCandidatesCol = callDoc.collection('recipientCandidates');
      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        if (candidate.candidate == null || candidate.candidate!.isEmpty) return;
        recipientCandidatesCol.add({
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      };

      // 6. Set caller's remote offer description
      final rtcOffer = RTCSessionDescription(
        offerData['sdp'] as String,
        offerData['type'] as String,
      );
      await _peerConnection!.setRemoteDescription(rtcOffer);

      // 7. Add caller ICE candidates
      _candidatesSub = callDoc.collection('callerCandidates').snapshots().listen((snap) {
        for (final change in snap.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final cData = change.doc.data();
            if (cData == null) continue;
            final candStr = cData['candidate'] as String?;
            if (candStr == null || candStr.isEmpty) continue;
            final candidate = RTCIceCandidate(
              candStr,
              cData['sdpMid'] as String?,
              cData['sdpMLineIndex'] as int?,
            );
            _peerConnection?.addCandidate(candidate);
          }
        }
      });

      // 8. Generate SDP Answer
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      // 9. Update Firestore call document
      await callDoc.update({
        'answer': {
          'sdp': answer.sdp,
          'type': answer.type,
        },
        'status': 'connected',
        'connectedAt': FieldValue.serverTimestamp(),
      });

      onStatusChanged?.call(WebRtcCallStatus.connected);

      // 10. Listen for hang up
      _callDocSub = callDoc.snapshots().listen((snapshot) async {
        if (!snapshot.exists) return;
        final data = snapshot.data();
        if (data?['status'] == 'ended') {
          onStatusChanged?.call(WebRtcCallStatus.ended);
          await endCall(bookingId);
        }
      });
    } catch (e) {
      debugPrint('WebRTC Answer Error: $e');
      onError?.call('Failed to answer call: $e');
      onStatusChanged?.call(WebRtcCallStatus.error);
      await endCall(bookingId);
    }
  }

  /// Reject an incoming call
  Future<void> rejectCall(String bookingId) async {
    try {
      await _firestore.collection('calls').doc(bookingId).update({
        'status': 'rejected',
        'endedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
    onStatusChanged?.call(WebRtcCallStatus.rejected);
    await endCall(bookingId);
  }

  /// Terminate call and release media resources
  Future<void> endCall(String bookingId) async {
    try {
      await _firestore.collection('calls').doc(bookingId).update({
        'status': 'ended',
        'endedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    await _callDocSub?.cancel();
    _callDocSub = null;

    await _candidatesSub?.cancel();
    _candidatesSub = null;

    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        track.stop();
      }
      await _localStream?.dispose();
      _localStream = null;
    }

    if (_remoteStream != null) {
      for (final track in _remoteStream!.getTracks()) {
        track.stop();
      }
      await _remoteStream?.dispose();
      _remoteStream = null;
    }

    if (_peerConnection != null) {
      await _peerConnection?.close();
      await _peerConnection?.dispose();
      _peerConnection = null;
    }

    onStatusChanged?.call(WebRtcCallStatus.ended);
  }

  /// Mute / Unmute microphone
  void setMuted(bool isMuted) {
    if (_localStream != null) {
      for (final track in _localStream!.getAudioTracks()) {
        track.enabled = !isMuted;
      }
    }
  }

  /// Toggle speakerphone / earpiece
  void setSpeakerphone(bool isSpeakerOn) {
    Helper.setSpeakerphoneOn(isSpeakerOn);
  }
}

final webrtcCallServiceProvider = Provider<WebRtcCallService>((ref) {
  return WebRtcCallService();
});
