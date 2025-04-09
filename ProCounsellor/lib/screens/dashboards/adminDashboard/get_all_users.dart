import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ProCounsellor/screens/dashboards/adminDashboard/get_user_details.dart';
import 'dart:convert';

import 'package:ProCounsellor/services/api_utils.dart';

class AllUsersPage extends StatefulWidget {
  @override
  _AllUsersPageState createState() => _AllUsersPageState();
}

class _AllUsersPageState extends State<AllUsersPage> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiUtils.baseUrl}/api/user/all-users'),
      );

      if (response.statusCode == 200) {
        List<dynamic> usersData = json.decode(response.body);
        setState(() {
          _users = usersData.map((user) {
            return {
              'userName': user['userName'],
              'fullName': '${user['firstName']} ${user['lastName']}',
              'photo': user['photo'] ?? '',
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("All Users")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: _users.length,
              separatorBuilder: (context, index) => Divider(),  // Add divider after each user
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: _users[index]['photo'].isNotEmpty
                        ? NetworkImage(_users[index]['photo'])
                        : AssetImage('assets/images/default_profile.png') as ImageProvider,
                    radius: 25,
                  ),
                  title: Text(
                    _users[index]['fullName'],
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Username: ${_users[index]['userName']}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserDetailsPage(userName: _users[index]['userName']),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
