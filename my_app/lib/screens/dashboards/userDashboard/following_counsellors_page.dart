import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'details_page.dart'; // Import the DetailsPage

class FollowingCounsellorsPage extends StatefulWidget {
  final String username;

  FollowingCounsellorsPage({required this.username});

  @override
  _FollowingCounsellorsPageState createState() =>
      _FollowingCounsellorsPageState();
}

class _FollowingCounsellorsPageState extends State<FollowingCounsellorsPage> {
  List<dynamic> counsellors = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchFollowedCounsellors();
  }

  Future<void> fetchFollowedCounsellors() async {
    final url = Uri.parse(
        'http://localhost:8080/api/user/${widget.username}/followed-counsellors');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          counsellors = json.decode(response.body) ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load subscribed counsellors")),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Followed Counsellors"),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Search',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                  SizedBox(height: 16.0),
                  Expanded(
                    child: ListView.builder(
                      itemCount: counsellors.length,
                      itemBuilder: (context, index) {
                        final counsellor = counsellors[index];
                        final name = counsellor['firstName'] ?? 'Unknown';

                        if (searchQuery.isNotEmpty &&
                            !name.toLowerCase().contains(searchQuery)) {
                          return SizedBox.shrink();
                        }

                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                counsellor['photoUrl'] ??
                                    'https://via.placeholder.com/150/0000FF/808080 ?Text=PAKAINFO.com',
                              ),
                            ),
                            title: Text(name),
                            onTap: () {
                              // Navigate to the DetailsPage when tapped
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailsPage(
                                    itemName: counsellor['firstName'] ??
                                        counsellor[
                                            'userName'], // Pass the counsellor's name
                                    userId: widget.username, // Pass the userId
                                    counsellorId: counsellor['userName'] ??
                                        '', // Pass the counsellorId
                                    isNews:
                                        false, // This is a counsellor, so isNews is false
                                    counsellor:
                                        counsellor, // Pass the full counsellor object
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
