import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'chatting_page.dart';

class ChatPage extends StatefulWidget {
  final String userId;

  ChatPage({required this.userId});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Map<String, dynamic>> counsellorsWithChats = [];
  List<Map<String, dynamic>> filteredCounsellors = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchSubscribedCounsellorsWithChats();
  }

  Future<void> fetchSubscribedCounsellorsWithChats() async {
    try {
      final subscribedUrl = Uri.parse(
          'http://localhost:8080/api/user/${widget.userId}/subscribed-counsellors');
      final subscribedResponse = await http.get(subscribedUrl);

      if (subscribedResponse.statusCode == 200) {
        final subscribedCounsellors =
            json.decode(subscribedResponse.body) as List<dynamic>;

        List<Map<String, dynamic>> counsellors = [];
        for (var counsellor in subscribedCounsellors) {
          final counsellorId = counsellor['userName'];
          final counsellorName =
              counsellor['firstName'] ?? 'Unknown Counsellor';
          final counsellorPhotoUrl =
              counsellor['photoUrl'] ?? 'https://via.placeholder.com/150';

          final chatExistsUrl = Uri.parse(
              'http://localhost:8080/api/chats/exists?userId=${widget.userId}&counsellorId=$counsellorId');
          final chatExistsResponse = await http.get(chatExistsUrl);

          if (chatExistsResponse.statusCode == 200) {
            final chatExists = json.decode(chatExistsResponse.body) as bool;
            if (chatExists) {
              counsellors.add({
                'id': counsellorId,
                'name': counsellorName,
                'photoUrl': counsellorPhotoUrl,
              });
            }
          }
        }

        setState(() {
          counsellorsWithChats = counsellors;
          filteredCounsellors = counsellors;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch subscribed counsellors");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void filterCounsellors(String query) {
    setState(() {
      searchQuery = query;
      filteredCounsellors = counsellorsWithChats
          .where((counsellor) => counsellor['name']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  Stream<String> getCounsellorState(String counsellorId) {
    final databaseReference =
        FirebaseDatabase.instance.ref('counsellorStates/$counsellorId/state');
    return databaseReference.onValue
        .map((event) => event.snapshot.value as String? ?? 'offline');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Chats"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: filterCounsellors,
              decoration: InputDecoration(
                hintText: "Search counsellors...",
                prefixIcon: Icon(Icons.search, color: Colors.orange),
                fillColor: Color(0xFFFFF3E0),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide(color: Colors.orange),
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredCounsellors.isEmpty
                    ? Center(child: Text("No chats available"))
                    : ListView.separated(
                        separatorBuilder: (context, index) => Divider(
                          color: Colors.grey.shade300,
                          thickness: 1,
                          indent: 10,
                          endIndent: 10,
                        ),
                        itemCount: filteredCounsellors.length,
                        itemBuilder: (context, index) {
                          final counsellor = filteredCounsellors[index];
                          final name =
                              counsellor['name'] ?? 'Unknown Counsellor';
                          final photoUrl = counsellor['photoUrl'] ??
                              'https://via.placeholder.com/150';
                          final counsellorId = counsellor['id'];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChattingPage(
                                    itemName: name,
                                    userId: widget.userId,
                                    counsellorId: counsellorId,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 16.0),
                              child: Row(
                                children: [
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 35,
                                        backgroundImage: NetworkImage(photoUrl),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: StreamBuilder<String>(
                                          stream:
                                              getCounsellorState(counsellorId),
                                          builder: (context, snapshot) {
                                            final state =
                                                snapshot.data ?? 'offline';
                                            return CircleAvatar(
                                              radius: 8,
                                              backgroundColor: Colors.white,
                                              child: CircleAvatar(
                                                radius: 6,
                                                backgroundColor:
                                                    state == 'online'
                                                        ? Colors.green
                                                        : Colors.grey,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
