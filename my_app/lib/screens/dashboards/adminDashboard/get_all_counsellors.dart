import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:my_app/screens/dashboards/adminDashboard/get_counsellor_details.dart';

class AllCounsellorsPage extends StatefulWidget {
  @override
  _AllCounsellorsPageState createState() => _AllCounsellorsPageState();
}

class _AllCounsellorsPageState extends State<AllCounsellorsPage> {
  List<Map<String, dynamic>> _counsellors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCounsellors();
  }

  Future<void> fetchCounsellors() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/counsellor/all-counsellors'),
      );

      if (response.statusCode == 200) {
        List<dynamic> usersData = json.decode(response.body);
        setState(() {
          _counsellors = usersData.map((user) {
            return {
              'userName': user['userName'],
              'fullName': '${user['firstName']} ${user['lastName']}',
              'photoUrl': user['photoUrl'] ?? '',
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
      appBar: AppBar(title: Text("All Counsellors")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: _counsellors.length,
              separatorBuilder: (context, index) => Divider(),  // Add divider after each user
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: _counsellors[index]['photoUrl'].isNotEmpty
                        ? NetworkImage(_counsellors[index]['photoUrl'])
                        : AssetImage('assets/images/default_profile.png') as ImageProvider,
                    radius: 25,
                  ),
                  title: Text(
                    _counsellors[index]['fullName'],
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Username: ${_counsellors[index]['userName']}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CounsellorDetailsPage(userName: _counsellors[index]['userName']),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
