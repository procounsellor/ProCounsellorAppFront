import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:my_app/screens/newCallingScreen/agora_service.dart';
import 'audio_call_screen.dart';
import 'video_call_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _getCallerId();
    _listenToCallCancellation();
  }

  void _listenToCallCancellation() {
  callRef.child(widget.receiverId).onValue.listen((event) {
    if (!event.snapshot.exists && mounted) {
      Navigator.pop(context);
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
    Navigator.pop(context);
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
                  onPressed: () {
                    _endCall;
                  },
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
