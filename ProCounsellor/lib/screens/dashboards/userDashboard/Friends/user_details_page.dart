//// user details page

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../services/api_utils.dart';
import '../../../newCallingScreen/audio_call_screen.dart';
import '../../../newCallingScreen/firebase_notification_service.dart';
import '../../../newCallingScreen/save_fcm_token.dart';
import '../../../newCallingScreen/video_call_screen.dart';
import 'UserToUserChattingPage.dart';
import 'package:google_fonts/google_fonts.dart';

class UserDetailsPage extends StatefulWidget {
  final String userId;
  final String myUsername;
  final Future<void> Function() onSignOut;

  const UserDetailsPage(
      {required this.userId,
      required this.myUsername,
      required this.onSignOut});

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  Map<String, dynamic>? userDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    final url = Uri.parse('${ApiUtils.baseUrl}/api/user/${widget.userId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userDetails = data;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _startAudioCallAgora(BuildContext context) async {
    String receiverId = widget.userId;
    String senderName = widget.myUsername;
    String channelId = "audio_${DateTime.now().millisecondsSinceEpoch}";
    print("Channel ID:"+ channelId);

    // ✅ Get Receiver's FCM Token from Firestore
    String? receiverFCMToken =
        await FirestoreService.getFCMTokenUser(receiverId);
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
          receiverId: receiverId,
          onSignOut: widget.onSignOut,
        ),
      ),
    );
  }

  void _startVideoCallAgora(BuildContext context) async {
    String receiverId = widget.userId;
    String senderName = widget.myUsername;
    String channelId = "video_${DateTime.now().millisecondsSinceEpoch}";

    // ✅ Get Receiver's FCM Token from Firestore
    String? receiverFCMToken =
        await FirestoreService.getFCMTokenUser(receiverId);
    print(receiverFCMToken);

    await FirebaseNotificationService.sendCallNotification(
        receiverFCMToken: receiverFCMToken!,
        senderName: senderName,
        channelId: channelId,
        receiverId: receiverId,
        callType: "video");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCallScreen(
          channelId: channelId,
          isCaller: true,
          callerId: senderName,
          receiverId: receiverId,
          onSignOut: widget.onSignOut,
        ),
      ),
    );
  }

  Widget _buildUserInfo(String label, String? value) {
    if (value == null || value.trim().isEmpty) return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style:
                GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.outfit(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInterests(Map<String, dynamic> data) {
    final stateInterest = data['userInterestedStateOfCounsellors'];
    final courseInterest = data['interestedCourse'];

    List<Widget> interestWidgets = [];

    if (courseInterest != null && courseInterest.toString().trim().isNotEmpty) {
      final List<String> courses = courseInterest
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .split(',')
          .map((e) => e.trim())
          .toList();

      interestWidgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 12.0, bottom: 6),
          child: Text("Interested Courses",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ),
      );
      interestWidgets.add(Wrap(
        spacing: 12,
        runSpacing: 6,
        children: courses
            .map((course) => Text(
                  course,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ))
            .toList(),
      ));
    }

    if (stateInterest != null && stateInterest.toString().trim().isNotEmpty) {
      final List<String> states = stateInterest
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .split(',')
          .map((e) => e.trim())
          .toList();

      interestWidgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 6),
          child: Text("Preferred Counsellor States",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ),
      );
      interestWidgets.add(Wrap(
        spacing: 12,
        runSpacing: 6,
        children: states
            .map((state) => Text(
                  state,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ))
            .toList(),
      ));
    }

    if (interestWidgets.isEmpty) {
      interestWidgets.add(Text("No interests specified"));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: interestWidgets,
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style:
                GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text(label, style: GoogleFonts.outfit(color: Colors.grey[600])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('User Details'),
          titleTextStyle: GoogleFonts.outfit(),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : userDetails == null
                ? Center(child: Text("User not found"))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TOP SECTION: Photo + Name/Email + Stats
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile photo
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 130,
                                height: 180,
                                color: Colors.grey[200],
                                child: userDetails!['photo'] != null
                                    ? Image.network(userDetails!['photo'],
                                        fit: BoxFit.cover)
                                    : Icon(Icons.person,
                                        size: 80, color: Colors.grey),
                              ),
                            ),
                            SizedBox(width: 20),

                            // Name, Email, and Stats
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${userDetails!['firstName']} ${userDetails!['lastName']}',
                                    style: GoogleFonts.outfit(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 8),
                                  Text(userDetails!['email'] ?? '',
                                      style: GoogleFonts.outfit(
                                          color: Colors.grey[700])),
                                  SizedBox(height: 20),

                                  // Stats Row
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildStatItem("Reviews", "24"),
                                      _buildStatItem("Friends", "56"),
                                      _buildStatItem("Posts", "18"),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),

                        // BELOW SECTION: Interests + Buttons
                        SizedBox(height: 30),
                        _buildUserInterests(userDetails!),
                        SizedBox(height: 24),

                        // Action Buttons (Centered)
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildActionButton(Icons.person_add, "Add Friend",
                                () {
                              // TODO
                            }),
                            _buildActionButton(Icons.chat, "Chat", () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserToUserChattingPage(
                                    itemName: widget.userId,
                                    userId: widget.myUsername,
                                    userId2: widget.userId,
                                    onSignOut: () async {},
                                  ),
                                ),
                              );
                            }),
                            _buildActionButton(Icons.call, "Call", () {
                              _startAudioCallAgora(context);
                            }),
                            _buildActionButton(Icons.video_call, "Video Call",
                                () {
                              _startVideoCallAgora(context);
                            }),
                          ],
                        ),
                      ],
                    ),
                  ));
  }

  Widget _buildActionButton(
      IconData icon, String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label, style: GoogleFonts.outfit()),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.orangeAccent,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
    );
  }
}
