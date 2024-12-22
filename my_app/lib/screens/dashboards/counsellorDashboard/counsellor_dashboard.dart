import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'client_details_page.dart';

class CounsellorDashboard extends StatefulWidget {
  final VoidCallback onSignOut;
  final String counsellorId;

  CounsellorDashboard({required this.onSignOut, required this.counsellorId});

  @override
  _CounsellorDashboardState createState() => _CounsellorDashboardState();
}

class _CounsellorDashboardState extends State<CounsellorDashboard> {
  bool isLoading = true; // To track the loading state
  List<dynamic> clients = []; // To store the list of subscribed clients

  @override
  void initState() {
    super.initState();
    fetchClients(); // Fetch clients when the page loads
  }

  // Function to fetch the list of subscribed clients
  Future<void> fetchClients() async {
    final url = Uri.parse(
        'http://localhost:8080/api/counsellor/${widget.counsellorId}/clients');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          clients = json.decode(response.body); // Parse the response body
          isLoading = false; // Stop loading
        });
      } else {
        setState(() {
          isLoading = false; // Stop loading in case of an error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch clients")),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false; // Stop loading if an exception occurs
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
        title: Text("Counsellor Dashboard"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: widget.onSignOut, // Call the onSignOut method
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(), // Show loader while loading
            )
          : clients.isEmpty
              ? Center(
                  child: Text("No subscribed clients found."),
                )
              : ListView.builder(
                  itemCount: clients.length,
                  itemBuilder: (context, index) {
                    final client = clients[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                          client['photoUrl'] ??
                              'https://via.placeholder.com/150', // Placeholder image
                        ),
                      ),
                      title:
                          Text("${client['firstName']} ${client['lastName']}"),
                      subtitle: Text("Email: ${client['email']}"),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ClientDetailsPage(
                              client: client,
                              counsellorId: widget.counsellorId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
