import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../services/api_utils.dart';
import 'Friends/user_details_page.dart';
import 'details_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

class CallHistoryPage extends StatefulWidget {
  final String userId;
  final Future<void> Function() onSignOut;
  final VoidCallback? onMissedCallUpdated;

  const CallHistoryPage(
      {required this.userId,
      required this.onSignOut,
      this.onMissedCallUpdated,
      Key? key})
      : super(key: key);

  @override
  _CallHistoryPageState createState() => _CallHistoryPageState();
}

class _CallHistoryPageState extends State<CallHistoryPage> {
  List<dynamic> callHistory = [];
  Map<String, String> profilePhotos = {}; // Store profile pictures
  Map<String, String> contactNames = {}; // Store fetched contact names
  bool isLoading = true;
  bool hasError = false;
  int missedCallNotificationCount = 0; // ✅ Initialize variable

  @override
  void initState() {
    super.initState();
    fetchCallHistory();
  }

  void markMissedCallsAsSeen() async {
    DatabaseReference callRef = FirebaseDatabase.instance.ref('calls');

    try {
      // ✅ Fetch all calls from Firebase
      DataSnapshot snapshot = await callRef.get();

      if (snapshot.exists && snapshot.value != null) {
        Map<dynamic, dynamic> calls = snapshot.value as Map<dynamic, dynamic>;

        calls.forEach((callId, callData) {
          if (callData["receiverId"] == widget.userId &&
              callData["status"] == "Missed Call" &&
              callData["missedCallStatusSeen"] == false) {
            print("🔹 Marking call $callId as seen..."); // ✅ Debug Log

            // ✅ Update the missed call status in Firebase
            callRef
                .child(callId)
                .update({"missedCallStatusSeen": true}).then((_) {
              print("✅ Successfully marked missed call $callId as seen.");
            }).catchError((error) {
              print("❌ Error updating missed call status: $error");
            });
          }
        });
      }
    } catch (error) {
      print("❌ Error fetching calls from Firebase: $error");
    }

    // ✅ Update UI after marking calls as seen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          missedCallNotificationCount = 0;
        });

        widget.onMissedCallUpdated?.call();
      }
    });
  }

  Future<void> fetchCallHistory() async {
    try {
      String apiUrl = "${ApiUtils.baseUrl}/api/user/${widget.userId}";

      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> calls = (data['callHistory'] ?? [])
            .map((call) => Map<String, dynamic>.from(call))
            .toList();

        // Sort calls (newest first)
        calls.sort((a, b) => b["startTime"].compareTo(a["startTime"]));

        // ✅ Step 5: Update UI with Fresh Data
        _updateCallHistory(calls);

        // ✅ Step 6: Mark Missed Calls as Seen
        markMissedCallsAsSeen();

        fetchContactDetails();
      } else {
        throw Exception("Failed to load call history");
      }
    } catch (e) {
      print("Error fetching call history: $e");
      if (mounted) {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    }
  }

  void _updateCallHistory(List<dynamic> calls) {
    if (mounted) {
      setState(() {
        callHistory = calls;
        missedCallNotificationCount = calls
            .where((call) =>
                call["receiverId"] == widget.userId &&
                call["status"] == "Missed Call" &&
                call["missedCallStatusSeen"] == false)
            .length;
        isLoading = false;
      });
    }
  }

  Future<void> fetchContactDetails() async {
    for (var call in callHistory) {
      String contactId = call["callerId"] == widget.userId
          ? call["receiverId"]
          : call["callerId"];

      try {
        String apiUrl = "${ApiUtils.baseUrl}/api/counsellor/$contactId";
        final response = await http.get(Uri.parse(apiUrl));

        if (response.statusCode == 200 && response.body.isNotEmpty) {
          final data = json.decode(response.body);
          if (mounted) {
            setState(() {
              profilePhotos[contactId] = data["photoUrl"] ?? "";
              contactNames[contactId] =
                  "${data["firstName"]} ${data["lastName"]}";
            });
          }
        }
        else{
          String apiUrl = "${ApiUtils.baseUrl}/api/user/$contactId";
          final response = await http.get(Uri.parse(apiUrl));

          if (response.statusCode == 200 && response.body.isNotEmpty) {
            final data = json.decode(response.body);
            if (mounted) {
            setState(() {
              profilePhotos[contactId] = data["photo"] ?? "";
              contactNames[contactId] =
                  "${data["firstName"]} ${data["lastName"]}";
            });
            }
          }
        }
      } catch (e) {
        print("Error fetching details for $contactId: $e");
      }
    }
  }

  String formatTimestamp(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('hh:mm a').format(dateTime);
    } else if (difference.inDays == 1) {
      return "Yesterday";
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE')
          .format(dateTime); // Show day name (e.g., Friday)
    } else {
      return DateFormat('dd MMM').format(dateTime); // Show date (e.g., 15 Feb)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Call History",
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: widget.onSignOut,
            tooltip: "Sign Out",
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : hasError
              ? Center(
                  child: Text("Failed to load call history",
                      style: GoogleFonts.outfit(color: Colors.white)))
              : callHistory.isEmpty
                  ? Center(
                      child: Text("No call history available",
                          style: GoogleFonts.outfit(color: Colors.white)))
                  : _buildCallHistoryList(),
    );
  }

  Widget _buildCallHistoryList() {
    return ListView.builder(
      itemCount: callHistory.length,
      itemBuilder: (context, index) {
        return _buildCallCard(callHistory[index]);
      },
    );
  }

  Widget _buildCallCard(Map<String, dynamic> call) {
    bool isOutgoing = call["callerId"] == widget.userId;
    String status = call["status"];
    String formattedTime = formatTimestamp(call["startTime"]);
    String contactId = isOutgoing ? call["receiverId"] : call["callerId"];
    String photoUrl = profilePhotos[contactId] ?? "";
    String contactName = contactNames[contactId] ?? "Name ";

    Icon callStatusIcon;
    if (status == "Missed Call") {
      callStatusIcon = isOutgoing
          ? const Icon(Icons.call_made,
              color: Colors.grey, size: 16) // Outgoing missed → No Response
          : const Icon(Icons.call_received,
              color: Colors.red, size: 16); // Incoming missed → Missed Call
    } else if (status == "Declined") {
      callStatusIcon = isOutgoing
          ? const Icon(Icons.call_made,
              color: Colors.grey, size: 16) // Outgoing missed → No Response
          : const Icon(Icons.call_received,
              color: Colors.red, size: 16); // Incoming missed → Missed Call
    } else {
      callStatusIcon = Icon(
        isOutgoing ? Icons.call_made : Icons.call_received,
        color:
            isOutgoing ? Colors.green : const Color.fromARGB(255, 89, 244, 54),
        size: 16,
      );
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      leading: GestureDetector(
        onTap: () => _navigateToUserOrCounsellorDetails(context, contactId),
        child: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey[800],
          backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
          child: photoUrl.isEmpty
              ? const Icon(Icons.person, color: Colors.white, size: 30)
              : null,
        ),
      ),
      title: Text(
        contactName,
        style: GoogleFonts.outfit(
            color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      subtitle: Row(
        children: [
          callStatusIcon, // ✅ Shows different icons for missed call / no response
          const SizedBox(width: 5),
          Text(
            status == "Declined"
                ? "Declined" // ✅ If call was declined, show "Declined" on both sides
                : status == "Missed Call"
                    ? (isOutgoing
                        ? "No Response"
                        : "Missed Call") // ✅ Handle missed calls
                    : (isOutgoing
                        ? "Outgoing"
                        : "Incoming"), // ✅ Default: Incoming/Outgoing
            style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
          ),

          const SizedBox(width: 5),
          Icon(
            call["callType"] == "video" ? Icons.videocam : Icons.call,
            color: Colors.grey,
            size: 16,
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formattedTime,
            style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.grey, size: 20),
            onPressed: () => _showCallDetailsModal(
                context, call, contactName, photoUrl, contactId),
          ),
        ],
      ),
    );
  }

  void _navigateToUserOrCounsellorDetails(BuildContext context, String userId) async {
    try {
      String apiUrl = "${ApiUtils.baseUrl}/api/counsellor/$userId";
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final counsellorData = json.decode(response.body);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsPage(
              counsellorId: userId,
              userId: widget.userId,
              itemName: userId,
              onSignOut: widget.onSignOut,
            ),
          ),
        );
      }
      else{
        String apiUrl = "${ApiUtils.baseUrl}/api/user/$userId";
        final response = await http.get(Uri.parse(apiUrl));

        if (response.statusCode == 200 && response.body.isNotEmpty) {
          final userData = json.decode(response.body);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserDetailsPage(
                userId: userId,
                myUsername: widget.userId,
                onSignOut: widget.onSignOut,
              ),
            ),
          );
        }
        else {
          ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load details")));
        }
      }
    } catch (e) {
      print("Error fetching client details: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error fetching client details")));
    }
  }

  void _showCallDetailsModal(BuildContext context, Map<String, dynamic> call,
      String contactName, String photoUrl, String contactId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
      builder: (context) {
        return GestureDetector(
          onTap: () {
            Navigator.pop(context); // Close modal before navigation
            _navigateToUserOrCounsellorDetails(context, contactId);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                    radius: 40, backgroundImage: NetworkImage(photoUrl)),
                const SizedBox(height: 10),
                Text(contactName,
                    style: GoogleFonts.outfit(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const Divider(color: Colors.grey),
                ListTile(
                  leading: const Icon(Icons.call, color: Colors.green),
                  title: Text("Call Type: ${call["callType"]}",
                      style: GoogleFonts.outfit(color: Colors.black)),
                ),
                ListTile(
                  leading: const Icon(Icons.timer, color: Colors.blue),
                  title: Text("Duration: ${call["duration"] ?? "0 sec"}",
                      style: GoogleFonts.outfit(color: Colors.black)),
                ),
                ListTile(
                  leading: const Icon(Icons.access_time, color: Colors.orange),
                  title: Text("Time: ${formatTimestamp(call["startTime"])}",
                      style: GoogleFonts.outfit(color: Colors.black)),
                ),
                const SizedBox(height: 10),
                Text(
                  "Tap anywhere to view full details",
                  style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}
