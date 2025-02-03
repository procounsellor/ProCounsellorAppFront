import 'dart:ui';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class FirebaseSignalingService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child("call_signaling");
  final DatabaseReference _dbRefUserCalls = FirebaseDatabase.instance.ref().child("callsByUser");

  void listenForOffer(String callId, Function(String) onOfferReceived) {
  _dbRef.child(callId).child("offer").onValue.listen((event) {
    if (event.snapshot.value != null) {
      try {
        var offer = event.snapshot.value; 

        if (offer is String) {
          onOfferReceived(offer); // Directly pass the SDP string
        } else {
          print("Invalid offer format received: $offer");
        }
      } catch (e) {
        print("Error parsing offer: $e");
      }
    }
  });
}


  void listenForAnswer(String callId, RTCPeerConnection? peerConnection, Function(String) onAnswerReceived) {
    _dbRef.child(callId).child("answer").onValue.listen((event) async {
      if (event.snapshot.value != null) {
        try {
          String sdp = event.snapshot.value.toString();
          print("Received answer SDP: $sdp");

          RTCSessionDescription answer = RTCSessionDescription(sdp, "answer");

          if (peerConnection != null) {
            await peerConnection.setRemoteDescription(answer);
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
  
  void listenForIceCandidates(String callId, Function(Map<String, dynamic>) onCandidateReceived) {
  _dbRef.child(callId).child("ice_candidates").onChildAdded.listen((event) {
    if (event.snapshot.value != null) {
      try {
        // Parse the candidate data as a Map
        Map<String, dynamic> candidate = Map<String, dynamic>.from(event.snapshot.value as Map);
        onCandidateReceived(candidate);
      } catch (e) {
        print("Error parsing candidate: $e");
      }
    }
  });
}

void listenForIncomingCalls(String id, Function(Map<String, dynamic>) onCallReceived) {
    _dbRefUserCalls.child(id).child("incoming_calls").onValue.listen((event) {
      if (event.snapshot.value != null) {
        try {
          Map<String, dynamic> callData = Map<String, dynamic>.from(event.snapshot.value as Map);
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
        Map<dynamic, dynamic> callData = event.snapshot.value as Map<dynamic, dynamic>;
        if (callData["status"] == "completed") {
          onCallEnd();
        }
      }
    });
  }
}
