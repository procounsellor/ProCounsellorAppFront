import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';

class ActivityPage extends StatefulWidget {
  final List<String> activityLogs;
  final String counsellorId;

  ActivityPage({required this.activityLogs, required this.counsellorId});

  @override
  _ActivityPageState createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  List<Map<String, dynamic>> userDetails = [];

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
    _markAllAsSeen();
  }

  Future<void> _fetchUserDetails() async {
    List<Map<String, dynamic>> fetchedUsers = [];
    for (String log in widget.activityLogs) {
      String userId = log.split(": ")[1];
      final response =
          await http.get(Uri.parse('http://localhost:8080/api/user/$userId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        fetchedUsers.add({
          'firstName': data['firstName'] ?? 'Unknown',
          'lastName': data['lastName'] ?? '',
          'photo': data['photo'] ?? '',
          'activity': log.split(": ")[0],
        });
      }
    }
    setState(() {
      userDetails = fetchedUsers;
    });
  }

  void _markAllAsSeen() {
    DatabaseReference subscriberRef = FirebaseDatabase.instance
        .ref('realtimeSubscribers/${widget.counsellorId}');
    DatabaseReference followerRef = FirebaseDatabase.instance
        .ref('realtimeFollowers/${widget.counsellorId}');

    subscriberRef.get().then((snapshot) {
      if (snapshot.exists) {
        Map<String, dynamic> subscribers =
            Map<String, dynamic>.from(snapshot.value as Map);
        subscribers.forEach((key, value) {
          subscriberRef.child(key).set(true);
        });
      }
    });

    followerRef.get().then((snapshot) {
      if (snapshot.exists) {
        Map<String, dynamic> followers =
            Map<String, dynamic>.from(snapshot.value as Map);
        followers.forEach((key, value) {
          followerRef.child(key).set(true);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Activity Log"),
        centerTitle: true,
      ),
      body: userDetails.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: userDetails.length,
              itemBuilder: (context, index) {
                final user = userDetails[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  elevation: 3,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user['photo'].isNotEmpty
                          ? NetworkImage(user['photo'])
                          : AssetImage('assets/default_avatar.png')
                              as ImageProvider,
                    ),
                    title: Text(
                      "${user['firstName']} ${user['lastName']}",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(user['activity']),
                  ),
                );
              },
            ),
    );
  }
}
