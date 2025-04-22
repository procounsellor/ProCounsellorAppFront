// import 'dart:convert';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:http/http.dart' as http;
// import 'package:ProCounsellor/services/api_utils.dart';

// class VideoCallService {
//   static const String baseUrl = "${ApiUtils.baseUrl}/calls";

//   // Start a Video or Audio Call
//   Future<String?> startCall(
//       String callerId, String receiverId, String callType) async {
//     final response = await http.post(
//       Uri.parse("$baseUrl/start"),
//       body: {
//         "callerId": callerId,
//         "receiverId": receiverId,
//         "callType": callType
//       },
//     );

//     if (response.statusCode == 200) {
//       return response.body; // Returns callId
//     } else {
//       return null;
//     }
//   }

//   // End the Call
//   Future<void> endCall(String callId) async {
//     final response = await http.post(Uri.parse("$baseUrl/$callId/end"));

//     if (response.statusCode == 200) {
//       print("Call ended successfully.");
//     } else {
//       print("Failed to end call: ${response.body}");
//     }
//   }

//   // Send Offer SDP to Backend
//   Future<void> sendOffer(String callId, RTCSessionDescription offer) async {
//     print('Sending Offer SDP...');
//     final response = await http.post(
//       Uri.parse("$baseUrl/$callId/offer"),
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode({
//         "sdp": offer.sdp,
//         "type": offer.type, // Ensuring we send SDP type
//       }),
//     );

//     if (response.statusCode == 200) {
//       print("Offer SDP sent successfully.");
//     } else {
//       print("Failed to send Offer SDP: ${response.body}");
//     }
//   }

//   // Send Answer SDP to Backend
//   Future<void> sendAnswer(String callId, RTCSessionDescription answer) async {
//     print('Sending Answer SDP...');
//     final response = await http.post(
//       Uri.parse("$baseUrl/$callId/answer"),
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode({
//         "sdp": answer.sdp,
//         "type": answer.type, // Ensuring we send SDP type
//       }),
//     );

//     if (response.statusCode == 200) {
//       print("Answer SDP sent successfully.");
//     } else {
//       print("Failed to send Answer SDP: ${response.body}");
//     }
//   }

//   // Send ICE Candidate to Backend
//   Future<void> sendIceCandidate(
//       String callId, RTCIceCandidate candidate, String senderId) async {
//     print("Sending ICE candidate from $senderId: ${candidate.toMap()}");

//     final response = await http.post(
//       Uri.parse("$baseUrl/$callId/candidate"),
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode({
//         "candidate": {
//           "candidate": candidate.candidate,
//           "sdpMid": candidate.sdpMid,
//           "sdpMLineIndex": candidate.sdpMLineIndex,
//         },
//         "senderId": senderId,
//       }),
//     );

//     if (response.statusCode == 200) {
//       print("ICE candidate sent successfully.");
//     } else {
//       print("Failed to send ICE candidate: ${response.body}");
//     }
//   }
// }
