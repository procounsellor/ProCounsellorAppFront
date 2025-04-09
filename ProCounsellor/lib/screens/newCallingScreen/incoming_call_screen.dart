import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:ProCounsellor/screens/dashboards/counsellorDashboard/counsellor_base_page.dart';
import 'package:ProCounsellor/screens/dashboards/userDashboard/base_page.dart';
import 'package:ProCounsellor/screens/newCallingScreen/agora_service.dart';
import 'package:ProCounsellor/services/api_utils.dart';
import 'audio_call_screen.dart';
import 'video_call_screen.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

class IncomingCallScreen extends StatefulWidget {
  final String receiverId;
  final String channelId;
  final Future<void> Function() onSignOut;


  const IncomingCallScreen({
    Key? key,
    required this.receiverId,
    required this.channelId,
    required this.onSignOut
  }) : super(key: key);

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  final DatabaseReference callRef = FirebaseDatabase.instance.ref("agora_call_signaling");
  String callerId = "Unknown";
  String callType = "audio"; 

  String callerName = '';
  String callerPhoto = '';
  bool callerIsCounsellor = false;

  bool receiverIsCounsellor = false;

  bool _hasNavigated = false;

  StreamSubscription? _callSubscription;

  @override
  void initState() {
    super.initState();
    _getCallerId();
    _fetchCallerAndReceiverDetails();
    _listenToCallCancellation();
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    super.dispose();
  }

  void _listenToCallCancellation() {
    _callSubscription = callRef.child(widget.receiverId).onValue.listen((event) {
      if (!event.snapshot.exists && mounted) {
        navigateToBasePage();
      }
    });
  }

  Future<void> _getCallerId() async {
    final snapshot = await callRef.child(widget.receiverId).get();
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      setState(() {
        callerId = data['callerName'] ?? "Unknown";
        callType = data['callType'] ?? "audio";
      });
    }
  }

 Future<void> _acceptCall() async {
  try {
    await callRef.child(widget.receiverId).remove();

    final Widget callScreen = callType == "video"
        ? VideoCallScreen(
            channelId: widget.channelId,
            isCaller: false,
            receiverId: widget.receiverId,
            callerId: callerId,
            onSignOut: widget.onSignOut,
          )
        : AudioCallScreen(
            channelId: widget.channelId,
            isCaller: false,
            receiverId: widget.receiverId,
            callerId: callerId,
            onSignOut: widget.onSignOut,
          );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => callScreen),
    );
  } catch (e) {
    print("Error accepting call: $e");
  }
}

  void _endCall(){
    callRef.child(widget.receiverId).remove();
    AgoraService.declinedCall(widget.channelId);
    navigateToBasePage();
  }

  void navigateToBasePage(){
      if (_hasNavigated || !mounted) return;
        _hasNavigated = true;

      if(receiverIsCounsellor){
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => CounsellorBasePage(
                      counsellorId: widget.receiverId,
                      onSignOut: widget.onSignOut,
                    )
                    ),
                    (route) => false,
                    );
      }
      else{
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => BasePage(
                      username: widget.receiverId,
                      onSignOut: widget.onSignOut,
                    )
                    ),
                    (route) => false,
                    );
      }
  }

   Future<void> _fetchCallerAndReceiverDetails() async {
    String baseUrl = "${ApiUtils.baseUrl}/api";

    try {
      final callerUserRes = await http.get(Uri.parse('$baseUrl/user/${callerId}'));
      if (callerUserRes.statusCode == 200 && callerUserRes.body.isNotEmpty) {
        final data = json.decode(callerUserRes.body);
        setState(() {
          callerName = "${data['firstName']} ${data['lastName']}";
          callerPhoto = data['photo'];
          callerIsCounsellor = false;
        });
      } else {
        final callerCounsellorRes = await http.get(Uri.parse('$baseUrl/counsellor/${callerId}'));
        if (callerCounsellorRes.statusCode == 200 && callerCounsellorRes.body.isNotEmpty) {
          final data = json.decode(callerCounsellorRes.body);
          setState(() {
            callerName = "${data['firstName']} ${data['lastName']}";
            callerPhoto = data['photoUrl'];
            callerIsCounsellor = true;
          });
        }
      }

      final receiverUserRes = await http.get(Uri.parse('$baseUrl/user/${widget.receiverId}'));
      if (receiverUserRes.statusCode == 200 && receiverUserRes.body.isNotEmpty) {
        setState(() {
          receiverIsCounsellor = false;
        });
      } else {
        final receiverCounsellorRes = await http.get(Uri.parse('$baseUrl/counsellor/${widget.receiverId}'));
        if (receiverCounsellorRes.statusCode == 200 && receiverCounsellorRes.body.isNotEmpty) {
          setState(() {
            receiverIsCounsellor = true;
          });
        }
      }
    } catch (e) {
      print("❌ Error fetching caller/receiver details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Icon(
                  callType == "video" ? Icons.videocam : Icons.call,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(height: 10),
                Text(
                  callType == "video"
                      ? "Incoming Video Call from $callerId"
                      : "Incoming Audio Call from $callerId",
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ❌ Reject Call
                ElevatedButton(
                  onPressed: _endCall,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Icon(Icons.call_end, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 20),
                // ✅ Accept Call
                ElevatedButton(
                  onPressed: _acceptCall,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Icon(Icons.call, color: Colors.white, size: 30),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}