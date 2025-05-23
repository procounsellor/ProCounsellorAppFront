import 'package:ProCounsellor/screens/dashboards/counsellorDashboard/counsellor_chatting_page.dart';
import 'package:flutter/material.dart';
import 'package:ProCounsellor/screens/newCallingScreen/audio_call_screen.dart';
import 'package:ProCounsellor/screens/newCallingScreen/save_fcm_token.dart';
import 'package:ProCounsellor/screens/newCallingScreen/video_call_screen.dart';
import '../../newCallingScreen/firebase_notification_service.dart';

class ClientDetailsPage extends StatelessWidget {
  final Map<String, dynamic> client;
  final String counsellorId;
  final Future<void> Function() onSignOut;

  ClientDetailsPage(
      {required this.client,
      required this.counsellorId,
      required this.onSignOut});

  void _startAudioCallAgora(BuildContext context) async{
    String receiverId = client['userName'];
    String senderName = counsellorId;
    String channelId =
        "audio_${DateTime.now().millisecondsSinceEpoch}";

    // ✅ Get Receiver's FCM Token from Firestore
    String? receiverFCMToken = await FirestoreService.getFCMTokenUser(receiverId);
    print(receiverFCMToken);

    await FirebaseNotificationService.sendCallNotification(
      receiverFCMToken: receiverFCMToken!,
      senderName: senderName,
      channelId: channelId,
      receiverId: receiverId,
      callType: "audio",
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AudioCallScreen(
          channelId: channelId,
          isCaller: true,
          callerId: senderName,
          receiverId:receiverId,
          onSignOut: onSignOut,
        ),
      ),
    );
  }

  void _startVideoCallAgora(BuildContext context) async{
    String receiverId = client['userName'];
    String senderName = counsellorId;
    String channelId =
        "video_${DateTime.now().millisecondsSinceEpoch}";

    // ✅ Get Receiver's FCM Token from Firestore
    String? receiverFCMToken = await FirestoreService.getFCMTokenUser(receiverId);
    print(receiverFCMToken);

    await FirebaseNotificationService.sendCallNotification(
      receiverFCMToken: receiverFCMToken!,
      senderName: senderName,
      channelId: channelId,
      receiverId: receiverId,
      callType: "video"
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCallScreen(
          channelId: channelId,
          isCaller: true,
          callerId: senderName,
          receiverId: receiverId,
          onSignOut: onSignOut,
        ),
      ),
    );
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
                      child:
                          client['photo'] != null && client['photo'].isNotEmpty
                              ? Image.network(
                                  client['photo'],
                                  width: double.infinity,
                                  height: 300,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/images/5857.jpg', // ✅ Asset fallback
                                      width: double.infinity,
                                      height: 300,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                              : Image.asset(
                                  'assets/images/5857.jpg', // ✅ Local Asset Image
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
                          builder: (context) => CounsellorChattingPage(
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
                      _startAudioCallAgora(context);
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
                      _startVideoCallAgora(context);
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
