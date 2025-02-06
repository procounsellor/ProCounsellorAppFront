import 'dart:ui';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class FirebaseSignalingService {
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref().child("call_signaling");
  final DatabaseReference _dbRefUserCalls =
      FirebaseDatabase.instance.ref().child("callsByUser");

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  Function(MediaStream)? onRemoteStream;

  Future<void> initialize() async {
    Map<String, dynamic> config = {
      "iceServers": [
        {"urls": "stun:stun.l.google.com:19302"},
      ]
    };

    _peerConnection = await createPeerConnection(config);

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        onRemoteStream?.call(event.streams[0]);
      }
    };

    _localStream = await navigator.mediaDevices.getUserMedia({
      "video": true,
      "audio": true,
    });

    for (var track in _localStream!.getTracks()) {
      _peerConnection!.addTrack(track, _localStream!);
    }
  }

  void listenForOffer(String callId, Function(String) onOfferReceived) {
    _dbRef.child(callId).child("offer").onValue.listen((event) {
      if (event.snapshot.value != null) {
        try {
          var offer = event.snapshot.value;

          if (offer is String) {
            onOfferReceived(offer);
          } else {
            print("Invalid offer format received: $offer");
          }
        } catch (e) {
          print("Error parsing offer: $e");
        }
      }
    });
  }

  void listenForAnswer(String callId, Function(String) onAnswerReceived) {
    _dbRef.child(callId).child("answer").onValue.listen((event) async {
      if (event.snapshot.value != null) {
        try {
          String sdp = event.snapshot.value.toString();
          print("Received answer SDP: $sdp");

          RTCSessionDescription answer = RTCSessionDescription(sdp, "answer");

          if (_peerConnection != null) {
            await _peerConnection!.setRemoteDescription(answer);
            print("Remote description set successfully.");
          } else {
            print("Peer connection is null when setting remote description.");
          }

          onAnswerReceived(sdp);
        } catch (e) {
          print("Error parsing answer: $e");
        }
      }
    });
  }

  void listenForIceCandidates(String callId) {
    _dbRef.child(callId).child("ice_candidates").onChildAdded.listen((event) {
      if (event.snapshot.value != null) {
        try {
          Map<String, dynamic> candidateData =
              Map<String, dynamic>.from(event.snapshot.value as Map);

          RTCIceCandidate candidate = RTCIceCandidate(
            candidateData["candidate"],
            candidateData["sdpMid"],
            candidateData["sdpMLineIndex"],
          );

          _peerConnection!.addCandidate(candidate);
        } catch (e) {
          print("Error parsing ICE candidate: $e");
        }
      }
    });
  }

  void listenForIncomingCalls(
      String id, Function(Map<String, dynamic>) onCallReceived) {
    _dbRefUserCalls.child(id).child("incoming_calls").onValue.listen((event) {
      if (event.snapshot.value != null) {
        try {
          Map<String, dynamic> callData =
              Map<String, dynamic>.from(event.snapshot.value as Map);
          onCallReceived(callData);
        } catch (e) {
          print("Error parsing incoming call: $e");
        }
      }
    });
  }

  void clearIncomingCall(String counsellorId) {
    _dbRefUserCalls.child(counsellorId).child("incoming_calls").remove();
  }

  // Listen for Call End Events
  void listenForCallEnd(String callId, VoidCallback onCallEnd) {
    _dbRef.child(callId).onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> callData =
            event.snapshot.value as Map<dynamic, dynamic>;
        if (callData["status"] == "completed") {
          onCallEnd();
        }
      }
    });
  }
}
