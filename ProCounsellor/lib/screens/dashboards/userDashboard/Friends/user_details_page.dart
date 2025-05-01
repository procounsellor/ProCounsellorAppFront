import 'dart:convert';
import 'package:ProCounsellor/screens/dashboards/userDashboard/Friends/UserFriendsPage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../services/api_utils.dart';
import '../../../newCallingScreen/audio_call_screen.dart';
import '../../../newCallingScreen/firebase_notification_service.dart';
import '../../../newCallingScreen/save_fcm_token.dart';
import '../../../newCallingScreen/video_call_screen.dart';
import 'UserToUserChattingPage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../userDashboard/details_page.dart';
import '../../userDashboard/my_reviews.dart';

class UserDetailsPage extends StatefulWidget {
  final String userId;
  final String myUsername;
  final Future<void> Function() onSignOut;

  const UserDetailsPage({
    required this.userId,
    required this.myUsername,
    required this.onSignOut,
  });

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  Map<String, dynamic>? userDetails;
  bool isLoading = true;
  bool isFriend = false;
  bool checkingFriendStatus = true;
  bool friendAdded = false;
  List<dynamic> subscribedCounsellors = [];
  bool loadingSubscribed = true;
  String reviewCount = "";
  String friendCount = "";
  String fullName = '';

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
    _checkIfFriend();
    _fetchSubscribedCounsellors();
  }

  Future<void> _fetchSubscribedCounsellors() async {
    final url = Uri.parse(
        '${ApiUtils.baseUrl}/api/user/${widget.userId}/subscribed-counsellors');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          subscribedCounsellors = json.decode(response.body);
          loadingSubscribed = false;
        });
      } else {
        setState(() => loadingSubscribed = false);
      }
    } catch (e) {
      print('Error fetching subscribed counsellors: $e');
      setState(() => loadingSubscribed = false);
    }
  }

  Future<void> _checkIfFriend() async {
    final url = Uri.parse(
        '${ApiUtils.baseUrl}/api/user/${widget.myUsername}/is-friend/${widget.userId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() {
          isFriend = result == true;
        });
      }
    } catch (e) {
      print('Error checking friend status: $e');
    } finally {
      setState(() => checkingFriendStatus = false);
    }
  }

  Future<void> _fetchUserDetails() async {
    final url = Uri.parse('${ApiUtils.baseUrl}/api/user/${widget.userId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userDetails = data;
          reviewCount =
              (userDetails?['userReviewIds'] as List?)?.length.toString() ??
                  '0';
          friendCount = userDetails?['friendIds'] != null
              ? (userDetails!['friendIds'] as List).length.toString()
              : '0';
          fullName = userDetails?['firstName'] + " " + userDetails?['lastName'];
        });
      }
    } catch (_) {}
    setState(() => isLoading = false);
  }

  void _startAudioCallAgora(BuildContext context) async {
    String receiverId = widget.userId;
    String senderName = widget.myUsername;
    String channelId = "audio_${DateTime.now().millisecondsSinceEpoch}";

    String? receiverFCMToken =
        await FirestoreService.getFCMTokenUser(receiverId);

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
        builder: (_) => AudioCallScreen(
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

    String? receiverFCMToken =
        await FirestoreService.getFCMTokenUser(receiverId);

    await FirebaseNotificationService.sendCallNotification(
      receiverFCMToken: receiverFCMToken!,
      senderName: senderName,
      channelId: channelId,
      receiverId: receiverId,
      callType: "video",
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoCallScreen(
          channelId: channelId,
          isCaller: true,
          callerId: senderName,
          receiverId: receiverId,
          onSignOut: widget.onSignOut,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // 🛡 Only set result if user initiated back (not via system pop)
        if (!didPop && context.mounted) {
          Navigator.pop(context, friendAdded ? 'friendAdded' : result);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('User Details', style: GoogleFonts.outfit()),
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
                        // PROFILE HEADER
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${userDetails!['firstName']} ${userDetails!['lastName']}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(userDetails!['email'] ?? '',
                                      style: GoogleFonts.outfit(
                                          color: Colors.grey[700])),
                                  SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => MyReviewPage(
                                                  username: widget.userId),
                                            ),
                                          );
                                        },
                                        child: _buildStatItem(
                                            "Reviews", reviewCount),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => UserFriendsPage(
                                                  userId: widget.userId,
                                                  name: fullName),
                                            ),
                                          );
                                        },
                                        child: _buildStatItem("Friends",
                                            friendCount), // replace "56" with actual value if needed
                                      ),
                                      _buildStatItem("Posts", "18"),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),

                        SizedBox(height: 30),

                        if (loadingSubscribed)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (subscribedCounsellors.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Subscribed Counsellors",
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  )),
                              SizedBox(height: 8),
                              SizedBox(
                                height: 90,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: subscribedCounsellors.length,
                                  itemBuilder: (context, index) {
                                    final counsellor =
                                        subscribedCounsellors[index];
                                    final name =
                                        '${counsellor['firstName'] ?? ''} ${counsellor['lastName'] ?? ''}';
                                    final photo = counsellor['photoUrl'];

                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(right: 12.0),
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => DetailsPage(
                                                itemName:
                                                    counsellor['userName'],
                                                userId: widget.myUsername,
                                                counsellorId:
                                                    counsellor['userName'],
                                                counsellor: counsellor,
                                                isNews: false,
                                                onSignOut: widget.onSignOut,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Column(
                                          children: [
                                            CircleAvatar(
                                              radius: 30,
                                              backgroundImage: (photo != null &&
                                                      photo.isNotEmpty)
                                                  ? NetworkImage(photo)
                                                  : null,
                                              backgroundColor:
                                                  Colors.grey.shade300,
                                              child: (photo == null ||
                                                      photo.isEmpty)
                                                  ? Icon(Icons.person,
                                                      color: Colors.black)
                                                  : null,
                                            ),
                                            SizedBox(height: 6),
                                            SizedBox(
                                              width: 60,
                                              child: Text(
                                                name,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.outfit(
                                                    fontSize: 12),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text("No subscribed counsellors.",
                                style: GoogleFonts.outfit(
                                    fontSize: 14, color: Colors.grey)),
                          ),

                        _buildUserInterests(userDetails!),
                        SizedBox(height: 24),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            final buttonCount = 4;
                            final spacing = 12.0;
                            final totalSpacing = (buttonCount - 1) * spacing;
                            final itemSize =
                                (constraints.maxWidth - totalSpacing) /
                                    buttonCount;

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSquareActionButton(
                                  icon: isFriend
                                      ? Icons.person_remove
                                      : Icons.person_add,
                                  label: isFriend ? "Remove" : "Add",
                                  onPressed: () async {
                                    if (!isFriend) {
                                      // Add Friend
                                      final url = Uri.parse(
                                          '${ApiUtils.baseUrl}/api/user/${widget.myUsername}/add-friend/${widget.userId}');
                                      try {
                                        final response = await http.post(
                                          url,
                                          headers: {
                                            'Content-Type': 'application/json'
                                          },
                                          body: json.encode({}),
                                        );
                                        if (response.statusCode == 200 &&
                                            response.body.contains(
                                                'Successfully added')) {
                                          setState(() {
                                            isFriend = true;
                                            friendAdded = true;
                                          });
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'Friend added successfully')),
                                          );
                                        } else if (response.body
                                            .contains('Already friends')) {
                                          setState(() => isFriend = true);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content:
                                                    Text('Already friends')),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'Failed: ${response.body}')),
                                          );
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    } else {
                                      // Remove Friend
                                      final url = Uri.parse(
                                          '${ApiUtils.baseUrl}/api/user/${widget.myUsername}/unfriend/${widget.userId}');
                                      try {
                                        final response = await http.delete(url);
                                        if (response.statusCode == 200) {
                                          setState(() {
                                            isFriend = false;
                                            friendAdded = false;
                                          });
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content:
                                                    Text('Friend removed')),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'Failed to remove: ${response.body}')),
                                          );
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    }
                                  },
                                  size: itemSize,
                                ),
                                _buildSquareActionButton(
                                  icon: Icons.chat,
                                  label: "Chat",
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => UserToUserChattingPage(
                                          itemName: widget.userId,
                                          userId: widget.myUsername,
                                          userId2: widget.userId,
                                          onSignOut: () async {},
                                          role: "user",
                                        ),
                                      ),
                                    );
                                  },
                                  enabled: isFriend,
                                  size: itemSize,
                                ),
                                _buildSquareActionButton(
                                  icon: Icons.call,
                                  label: "Call",
                                  onPressed: () {
                                    _startAudioCallAgora(context);
                                  },
                                  enabled: isFriend,
                                  size: itemSize,
                                ),
                                _buildSquareActionButton(
                                  icon: Icons.video_call,
                                  label: "Video",
                                  onPressed: () {
                                    _startVideoCallAgora(context);
                                  },
                                  enabled: isFriend,
                                  size: itemSize,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
      ),
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
                  style: GoogleFonts.outfit(fontSize: 14),
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
                  style: GoogleFonts.outfit(fontSize: 14),
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

  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed,
      {bool enabled = true}) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label, style: GoogleFonts.outfit()),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: enabled
            ? Colors.orangeAccent
            : Colors.orangeAccent.withOpacity(0.5),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: enabled ? onPressed : null,
    );
  }

  Widget _buildSquareActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required double size,
    bool enabled = true,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          elevation: 2,
          disabledBackgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(
            color: enabled ? Colors.black : Colors.grey.shade400,
            width: 1,
          ),
          padding: EdgeInsets.zero,
        ),
        onPressed: enabled ? onPressed : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: enabled ? Colors.black : Colors.grey),
            SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: enabled ? Colors.black : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
