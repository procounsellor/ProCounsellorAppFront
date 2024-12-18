import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import the http package
import 'dart:convert'; // For encoding/decoding JSON
import 'chatting_page.dart';

class DetailsPage extends StatefulWidget {
  final String itemName;
  final String userId;
  final String counsellorId;
  final bool isNews;
  final Map<String, dynamic>? counsellor;

  DetailsPage({
    required this.itemName,
    required this.userId,
    required this.counsellorId,
    this.counsellor,
    this.isNews = false,
  });

  @override
  _DetailsPageState createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  bool isSubscribed = false; // Track subscription status
  bool isLoading = true; // Track loading status for API calls

  @override
  void initState() {
    super.initState();
    checkSubscriptionStatus(); // Check subscription status on page load
  }

  // Function to check if the user is already subscribed to the counsellor
  Future<void> checkSubscriptionStatus() async {
    final url = Uri.parse(
        'http://localhost:8080/api/user/${widget.userId}/is-subscribed/${widget.counsellorId}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final bool status = json.decode(response.body);
        setState(() {
          isSubscribed = status;
          isLoading = false; // Stop loading once the status is fetched
        });
      } else {
        setState(() {
          isLoading = false; // Stop loading even if there's an error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch subscription status")),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false; // Stop loading if there's an error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // Function to call the subscribe API
  Future<void> subscribe() async {
    final url = Uri.parse(
        'http://localhost:8080/api/user/${widget.userId}/subscribe/${widget.counsellorId}');

    try {
      final response = await http.post(url);

      if (response.statusCode == 200) {
        setState(() {
          isSubscribed = true; // Update subscription status
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Subscribed to ${widget.itemName}!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to subscribe")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemName),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(
                child:
                    CircularProgressIndicator()) // Show loader while fetching status
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Details about ${widget.itemName}",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),

                  if (!widget.isNews) ...[
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(
                        widget.counsellor?['photoUrl'] ??
                            'https://via.placeholder.com/100',
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Rating: ${widget.counsellor?['rating'] ?? 'No rating'}",
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 20),
                  ] else ...[
                    Icon(Icons.new_releases, size: 50, color: Colors.blue),
                    SizedBox(height: 10),
                    Text("Top News Item", style: TextStyle(fontSize: 16)),
                    SizedBox(height: 20),
                  ],

                  // Disable other buttons if not subscribed
                  ElevatedButton.icon(
                    onPressed: isSubscribed
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      "Calling ${widget.counsellor?['firstName']}...")),
                            );
                          }
                        : null, // Disable button if not subscribed
                    icon: Icon(Icons.call),
                    label: Text("Call"),
                  ),
                  SizedBox(height: 10),

                  ElevatedButton.icon(
                    onPressed: isSubscribed
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChattingPage(
                                  itemName: widget.itemName,
                                  userId: widget.userId,
                                  counsellorId: widget.counsellorId,
                                ),
                              ),
                            );
                          }
                        : null, // Disable button if not subscribed
                    icon: Icon(Icons.chat),
                    label: Text("Chat"),
                  ),
                  SizedBox(height: 10),

                  ElevatedButton.icon(
                    onPressed: isSubscribed
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      "Video calling ${widget.counsellor?['firstName']}...")),
                            );
                          }
                        : null, // Disable button if not subscribed
                    icon: Icon(Icons.video_call),
                    label: Text("Video Call"),
                  ),
                  SizedBox(height: 20),

                  // Subscribe Button
                  ElevatedButton.icon(
                    onPressed: isSubscribed
                        ? null // Disable button if already subscribed
                        : subscribe,
                    icon:
                        Icon(isSubscribed ? Icons.check : Icons.subscriptions),
                    label: Text(isSubscribed ? "Subscribed" : "Subscribe"),
                  ),
                  SizedBox(height: 20),

                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Add a note...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note_add),
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ],
              ),
      ),
    );
  }
}
