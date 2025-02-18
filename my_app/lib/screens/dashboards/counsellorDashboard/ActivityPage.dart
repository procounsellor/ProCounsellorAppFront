import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'client_details_page.dart';

class ActivityPage extends StatefulWidget {
  final String counsellorId;
  final List<String> activityLogs;

  ActivityPage({required this.counsellorId, required this.activityLogs});

  @override
  _ActivityPageState createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  List<String> activityLogs = [];

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
            activityLogs = List<String>.from(data['activityLog']);
          });
        }
      } else {
        print('Failed to fetch activity logs');
      }
    } catch (e) {
      print('Error fetching activity logs: $e');
    }
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
    Map<String, String> photoCache = {};

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Activity Log"),
        centerTitle: true,
      ),
      body: activityLogs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: activityLogs.length,
              separatorBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: const Divider(color: Colors.grey, thickness: 0.5),
              ),
              itemBuilder: (context, index) {
                final log = activityLogs[index];
                final name = log.split('(')[0].trim();
                final activity = log.split(')')[1].trim();
                final phoneNumber = log.contains('(') && log.contains(')')
                    ? log.substring(log.indexOf('(') + 1, log.indexOf(')'))
                    : '';

                if (photoCache.containsKey(phoneNumber)) {
                  final photoUrl = photoCache[phoneNumber]!;
                  return ListTile(
                    leading: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ClientDetailsPage(
                              client: {
                                'firstName': name.split(' ')[0],
                                'lastName': name.split(' ').length > 1
                                    ? name.split(' ')[1]
                                    : '',
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
                        backgroundImage:
                            photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                        backgroundColor: Colors.blueAccent,
                        child: photoUrl.isEmpty
                            ? Text(name[0],
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold))
                            : null,
                      ),
                    ),
                    title: Text("$name - $activity",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  );
                } else {
                  return FutureBuilder<http.Response>(
                    future: http.get(Uri.parse(
                        'http://localhost:8080/api/user/$phoneNumber')),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            child: Icon(Icons.person),
                          ),
                          title: Text('Loading...'),
                        );
                      }
                      if (snapshot.hasError ||
                          snapshot.data?.statusCode != 200) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            child: Text(name[0],
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                          title: Text("$name - $activity",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        );
                      }
                      final userData = json.decode(snapshot.data!.body);
                      final photoUrl = userData['photo'] ?? '';
                      photoCache[phoneNumber] = photoUrl;

                      return ListTile(
                        leading: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ClientDetailsPage(
                                  client: {
                                    'firstName': userData['firstName'],
                                    'lastName': userData['lastName'],
                                    'email': userData['email'],
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
                            backgroundImage: photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : null,
                            backgroundColor: Colors.blueAccent,
                            child: photoUrl.isEmpty
                                ? Text(name[0],
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold))
                                : null,
                          ),
                        ),
                        title: Text(
                            "${userData['firstName']} ${userData['lastName']} has $activity",
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.normal)),
                      );
                    },
                  );
                }
              },
            ),
    );
  }
}
