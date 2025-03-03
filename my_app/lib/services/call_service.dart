import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;

class CallService {
  static const String baseUrl = "http://localhost:8080/calls";

  Future<String?> startCall(
      String callerId, String receiverId, String callType) async {
    final response = await http.post(
      Uri.parse("$baseUrl/start"),
      body: {
        "callerId": callerId,
        "receiverId": receiverId,
        "callType": callType
      },
    );

    if (response.statusCode == 200) {
      return response.body; // Returns callId
    } else {
      return null;
    }
  }

  Future<void> endCall(String callId) async {
    await http.post(Uri.parse("$baseUrl/$callId/end"));
  }

  Future<void> sendOffer(String callId, RTCSessionDescription offer) async {
    print('offer service called');
    await http.post(
      Uri.parse("$baseUrl/$callId/offer"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"sdp": offer.sdp}), // Send only the "sdp" field as JSON
    );
  }

  Future<void> declinedCall(String callId) async {
    await http.post(Uri.parse("$baseUrl/$callId/declined"));
  }

  Future<void> sendAnswer(String callId, String? sdp) async {
    if (sdp == null || sdp.isEmpty) {
      print("SDP is null or empty, skipping sendAnswer.");
      return;
    }

    final response = await http.post(
      Uri.parse("$baseUrl/$callId/answer"),
      headers: {
        "Content-Type": "application/json", // Ensure JSON is correctly sent
      },
      body: jsonEncode({"sdp": sdp}), // Send as a JSON object
    );

    if (response.statusCode == 200) {
      print("SDP Answer sent successfully.");
    } else {
      print("Failed to send SDP answer: ${response.body}");
    }
  }

  Future<void> sendIceCandidate(
      String callId, Map<String, dynamic> candidate, String senderId) async {
    print("Sending ICE candidate: $candidate from $senderId");

    await http.post(
      Uri.parse("$baseUrl/$callId/candidate"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "candidate": candidate,
        "senderId": senderId,
      }),
    );
  }
}
