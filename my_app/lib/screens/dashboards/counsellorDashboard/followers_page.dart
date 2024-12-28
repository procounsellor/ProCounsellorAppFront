import 'package:flutter/material.dart';
import 'client_details_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FollowersPage extends StatefulWidget {
  final String counsellorId;

  FollowersPage({required this.counsellorId});

  @override
  _FollowersPageState createState() => _FollowersPageState();
}

class _FollowersPageState extends State<FollowersPage> {
  List<dynamic> followers = [];
  List<dynamic> filteredFollowers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFollowers();
  }

  Future<void> fetchFollowers() async {
    final url = Uri.parse(
        'http://localhost:8080/api/counsellor/${widget.counsellorId}/followers');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          followers = json.decode(response.body);
          filteredFollowers = followers; // Initially, show all followers
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch followers")),
        );
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

  void filterSubscribers(String query) {
    setState(() {
      filteredFollowers = followers
          .where((follower) =>
              "${follower['firstName']} ${follower['lastName']}"
                  .toLowerCase()
                  .contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Followers"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: "Search Followers",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: filterSubscribers,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredFollowers.length,
                    itemBuilder: (context, index) {
                      final follower = filteredFollowers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(
                            follower['photo'] ??
                                'https://via.placeholder.com/150',
                          ),
                        ),
                        title: Text(
                            "${follower['firstName']} ${follower['lastName']}"),
                        subtitle: Text("Email: ${follower['email']}"),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ClientDetailsPage(
                                client: follower,
                                counsellorId: widget.counsellorId,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
