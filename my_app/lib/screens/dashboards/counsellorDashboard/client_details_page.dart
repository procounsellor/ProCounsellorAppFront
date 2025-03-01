import 'package:flutter/material.dart';
import 'package:my_app/screens/callingScreens/call_page.dart';
import 'package:my_app/services/call_service.dart';
import 'counsellor_chatting_page.dart';
import '../../callingScreens/video_call_page.dart';
import '../../../services/video_call_service.dart';

class ClientDetailsPage extends StatelessWidget {
  final Map<String, dynamic> client;
  final String counsellorId;
  final Future<void> Function() onSignOut;

  ClientDetailsPage({required this.client, required this.counsellorId, required this.onSignOut});

  void _startCall(BuildContext context) async {
    final CallService _callService = CallService();
    String callerId = counsellorId;
    String receiverId = client['userName'];

    if (callerId.isEmpty || receiverId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Enter both IDs")));
      return;
    }

    String? callId =
        await _callService.startCall(callerId, receiverId, "audio");
    if (callId != null) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CallPage(
                  callId: callId,
                  id: counsellorId,
                  callInitiatorId: receiverId,
                  isCaller: true,
                  onSignOut: onSignOut)));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Call failed")));
    }
  }

  void _startVideoCall(BuildContext context) async {
    final VideoCallService _callService = VideoCallService();
    String callerId = counsellorId;
    String receiverId = client['userName'];

    if (callerId.isEmpty || receiverId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Enter both IDs")));
      return;
    }

    String? callId =
        await _callService.startCall(callerId, receiverId, "video");
    if (callId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoCallPage(
            callId: callId,
            id: counsellorId,
            isCaller: true,
            callInitiatorId: receiverId,
            onSignOut: onSignOut,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Call failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Client Details",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Card(
                color: Colors.white,
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(15),
                        bottom: Radius.circular(15),
                      ),
                      child: Image.network(
                        client['photo'] ?? 'https://via.placeholder.com/150',
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "${client['firstName'] ?? 'Unknown'} ${client['lastName'] ?? ''}"
                          .trim(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[300],
                      foregroundColor: Colors.black,
                      padding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(Icons.chat, color: Colors.black, size: 18),
                    label: Text(
                      "Chat",
                      style: TextStyle(color: Colors.black, fontSize: 14),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChattingPage(
                            itemName:
                                "${client['firstName'] ?? 'Unknown'} ${client['lastName'] ?? ''}"
                                    .trim(),
                            userId: client['userName'] ?? 'unknown_user',
                            counsellorId: counsellorId,
                            photo: client['photo'] ?? '',
                            onSignOut: onSignOut,
                          ),
                        ),
                      );
                    },
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[300],
                      foregroundColor: Colors.black,
                      padding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(Icons.call, color: Colors.black, size: 18),
                    label: Text(
                      "Call",
                      style: TextStyle(color: Colors.black, fontSize: 14),
                    ),
                    onPressed: () {
                      _startCall(context);
                    },
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[300],
                      foregroundColor: Colors.black,
                      padding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(Icons.videocam, color: Colors.black, size: 18),
                    label: Text(
                      "Video Call",
                      style: TextStyle(color: Colors.black, fontSize: 14),
                    ),
                    onPressed: () {
                      _startVideoCall(context);
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),
              Card(
                color: Colors.white,
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildDetailRow(Icons.menu_book,
                          client['interestedCourse'] ?? 'Not Provided',
                          isBold: false),
                      buildDetailRow(
                          Icons.location_pin,
                          client['userInterestedStateOfCounsellors']
                                  ?.join(", ") ??
                              'Not Provided',
                          isBold: false),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDetailRow(IconData icon, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '$value',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
