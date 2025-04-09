import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../services/api_utils.dart';
import 'user_details_page.dart';

class FriendsPage extends StatefulWidget {
  final String username;

  FriendsPage({required this.username});

  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  List<dynamic> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAllUsers();
  }

  Future<void> fetchAllUsers() async {
    final url = Uri.parse('${ApiUtils.baseUrl}/api/user/all-users');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          users = data;
          isLoading = false;
        });
      } else {
        print("❌ Failed to fetch users: ${response.body}");
      }
    } catch (e) {
      print("❌ Error fetching users: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Friends'),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? Center(child: Text('No users found'))
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserDetailsPage(
                              userId: user[
                                  'userName'], // or user['id'] based on your API
                              myUsername: widget.username,
                            ),
                          ),
                        );
                      },
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: Icon(Icons.person, color: Colors.black),
                      ),
                      title: Text(user['userName'] ?? 'Unnamed'),
                      subtitle: Text(user['email'] ?? ''),
                    );
                  },
                ),
    );
  }
}
