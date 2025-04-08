import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../services/api_utils.dart';
import 'UserToUserChattingPage.dart';

class UserDetailsPage extends StatefulWidget {
  final String userId;
  final String myUsername;

  UserDetailsPage({required this.userId, required this.myUsername});

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
        print("❌ Failed to load user: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("❌ Error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Details')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : userDetails == null
              ? Center(child: Text("User not found"))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: userDetails!['photo'] != null
                              ? NetworkImage(userDetails!['photo'])
                              : null,
                          child: userDetails!['photo'] == null
                              ? Icon(Icons.person, size: 40)
                              : null,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        '${userDetails!['firstName']} ${userDetails!['lastName']}',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('Username: ${userDetails!['userName']}'),
                      Text('Email: ${userDetails!['email']}'),
                      Text('Phone: ${userDetails!['phoneNumber']}'),
                      if (userDetails!['description'] != null)
                        Text('Bio: ${userDetails!['description']}'),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(Icons.person_add),
                            label: Text("Add Friend"),
                            onPressed: () {
                              // TODO: Implement friend request logic
                            },
                          ),
                          ElevatedButton.icon(
                            icon: Icon(Icons.chat),
                            label: Text("Chat"),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserToUserChattingPage(
                                    itemName: widget.userId,
                                    userId: widget.myUsername,
                                    userId2: widget.userId,
                                    onSignOut: () async {},
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(Icons.call),
                            label: Text("Call"),
                            onPressed: () {
                              // TODO: Implement call logic
                            },
                          ),
                          ElevatedButton.icon(
                            icon: Icon(Icons.video_call),
                            label: Text("Video Call"),
                            onPressed: () {
                              // TODO: Implement video call logic
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}
