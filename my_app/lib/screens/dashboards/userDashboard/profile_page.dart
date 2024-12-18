import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import http package
import 'dart:convert'; // For decoding the JSON response

class ProfilePage extends StatefulWidget {
  final String username;

  ProfilePage({required this.username});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<Map<String, dynamic>> subscribedCounsellors = [];
  bool isLoading = true; // To show a loading indicator while fetching data

  @override
  void initState() {
    super.initState();
    fetchSubscribedCounsellors();
  }

  // Fetch the list of subscribed counsellors from the API
  Future<void> fetchSubscribedCounsellors() async {
    final url = Uri.parse(
        'http://localhost:8080/api/user/${widget.username}/subscribed-counsellors');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> counsellorsData = json.decode(response.body);
        setState(() {
          subscribedCounsellors =
              List<Map<String, dynamic>>.from(counsellorsData);
          isLoading = false;
        });
      } else {
        // Handle error response
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
        title: Text("Profile"),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture and User Info
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            SizedBox(height: 16),
            Text("Username: ${widget.username}",
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text("Email: user@example.com", style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text("Membership: Premium", style: TextStyle(fontSize: 18)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Edit Profile Coming Soon!")),
                );
              },
              child: Text("Edit Profile"),
            ),
            SizedBox(height: 20),

            // Heading for Subscribed Counsellors
            Text(
              "Subscribed Counsellors",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            // Loading indicator while data is being fetched
            if (isLoading) Center(child: CircularProgressIndicator()),

            // List of subscribed counsellors
            if (!isLoading && subscribedCounsellors.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: subscribedCounsellors.length,
                  itemBuilder: (context, index) {
                    final counsellor = subscribedCounsellors[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundImage: NetworkImage(
                              counsellor['photoUrl'] ??
                                  'https://via.placeholder.com/100'),
                        ),
                        title: Text(counsellor['firstName'] ?? 'No Name'),
                        subtitle: Text(counsellor['rating'] != null
                            ? 'Rating: ${counsellor['rating']}'
                            : 'No Rating'),
                        trailing: Icon(Icons.arrow_forward),
                        onTap: () {
                          // Navigate to counsellor details page or chat
                        },
                      ),
                    );
                  },
                ),
              ),
            // Message if no counsellors are found
            if (!isLoading && subscribedCounsellors.isEmpty)
              Center(child: Text("No subscribed counsellors")),
          ],
        ),
      ),
    );
  }
}
