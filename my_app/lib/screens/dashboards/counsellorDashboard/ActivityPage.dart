import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'client_details_page.dart';
import 'package:intl/intl.dart';

class ActivityPage extends StatefulWidget {
  final String counsellorId;
  final List<String> activityLogs;

  ActivityPage({required this.counsellorId, required this.activityLogs});

  @override
  _ActivityPageState createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  List<Map<String, dynamic>> activityLogs = [];

  @override
  void initState() {
    super.initState();
    _fetchActivityLogs();
    _markAllAsSeen();
  }

  Future<void> _fetchActivityLogs() async {
    final url = Uri.parse(
        'http://localhost:8080/api/counsellor/${widget.counsellorId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['activityLog'] != null) {
          setState(() {
            activityLogs = List<Map<String, dynamic>>.from(data['activityLog'])
                .map((log) => {
                      "activity": log["activity"],
                      "timestamp": DateTime.fromMillisecondsSinceEpoch(
                          log["timestamp"]["seconds"] * 1000),
                    })
                .toList();

            activityLogs
                .sort((a, b) => b["timestamp"].compareTo(a["timestamp"]));
          });
        }
      } else {
        print('Failed to fetch activity logs');
      }
    } catch (e) {
      print('Error fetching activity logs: $e');
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupActivitiesByDate() {
    Map<String, List<Map<String, dynamic>>> groupedActivities = {
      "Today": [],
      "Yesterday": [],
      "Last 7 Days": [],
      "Older": []
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final weekAgo = today.subtract(Duration(days: 7));

    for (var log in activityLogs) {
      DateTime logDate = log["timestamp"];
      if (logDate.isAfter(today)) {
        groupedActivities["Today"]!.add(log);
      } else if (logDate.isAfter(yesterday)) {
        groupedActivities["Yesterday"]!.add(log);
      } else if (logDate.isAfter(weekAgo)) {
        groupedActivities["Last 7 Days"]!.add(log);
      } else {
        groupedActivities["Older"]!.add(log);
      }
    }

    return groupedActivities;
  }

  void _markAllAsSeen() {
    DatabaseReference subscriberRef = FirebaseDatabase.instance
        .ref('realtimeSubscribers/${widget.counsellorId}');
    DatabaseReference followerRef = FirebaseDatabase.instance
        .ref('realtimeFollowers/${widget.counsellorId}');
    DatabaseReference reviewsRef = FirebaseDatabase.instance
        .ref('counsellorRealtimeReview/${widget.counsellorId}');

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

    reviewsRef.get().then((snapshot) {
      if (snapshot.exists) {
        Map<String, dynamic> followers =
            Map<String, dynamic>.from(snapshot.value as Map);
        followers.forEach((key, value) {
          reviewsRef.child(key).set(true);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Map<String, String> photoCache = {};
    Map<String, List<Map<String, dynamic>>> groupedLogs =
        _groupActivitiesByDate();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Activity Log"),
        centerTitle: true,
      ),
      body: activityLogs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: groupedLogs.entries
                  .where((entry) => entry.value.isNotEmpty)
                  .map((entry) => _buildActivitySection(entry.key, entry.value))
                  .toList(),
            ),
    );
  }

  Widget _buildActivitySection(String title, List<Map<String, dynamic>> logs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title, // "Today", "Yesterday", etc.
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black54),
          ),
        ),
        Column(
          children: logs
              .map((log) => _buildActivityTile(
                  log["activity"], log["timestamp"], log["phoneNumber"]))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildActivityTile(
      String activityMessage, DateTime timestamp, String? phoneNumber) {
    final String formattedTime =
        DateFormat('hh:mm a').format(timestamp); // Only show time

    final String name = activityMessage.split('(')[0].trim();
    final String activity = activityMessage.split(')')[1].trim();
    phoneNumber ??=
        activityMessage.contains('(') && activityMessage.contains(')')
            ? activityMessage.substring(
                activityMessage.indexOf('(') + 1, activityMessage.indexOf(')'))
            : '';

    return FutureBuilder<http.Response>(
      future:
          http.get(Uri.parse('http://localhost:8080/api/user/$phoneNumber')),
      builder: (context, snapshot) {
        String photoUrl = "";
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildListTile(
              name, activity, formattedTime, photoUrl, phoneNumber,
              isLoading: true);
        }
        if (snapshot.hasError || snapshot.data?.statusCode != 200) {
          return _buildListTile(
              name, activity, formattedTime, photoUrl, phoneNumber);
        }
        final userData = json.decode(snapshot.data!.body);
        photoUrl = userData['photo'] ?? '';

        return _buildListTile(
            userData['firstName'] + " " + userData['lastName'],
            activity,
            formattedTime,
            photoUrl,
            phoneNumber);
      },
    );
  }

  Widget _buildListTile(String name, String activity, String time,
      String photoUrl, String? phoneNumber,
      {bool isLoading = false}) {
    return ListTile(
      leading: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClientDetailsPage(
                client: {
                  'firstName': name.split(' ')[0],
                  'lastName':
                      name.split(' ').length > 1 ? name.split(' ')[1] : '',
                  'email': name,
                  'phone': phoneNumber,
                  'photo': photoUrl,
                  'userName': phoneNumber,
                },
                counsellorId: widget.counsellorId,
              ),
            ),
          );
        },
        child: CircleAvatar(
          backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
          backgroundColor: Colors.blueAccent,
          child: photoUrl.isEmpty
              ? Text(name[0],
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))
              : null,
        ),
      ),
      title: Text(
        "$name - $activity",
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        time,
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }
}
