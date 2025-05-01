import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import '../../../../services/api_utils.dart';
import 'user_details_page.dart';

class UserFriendsPage extends StatefulWidget {
  final String userId;
  final String name;

  const UserFriendsPage({required this.userId, required this.name});

  @override
  _UserFriendsPageState createState() => _UserFriendsPageState();
}

class _UserFriendsPageState extends State<UserFriendsPage> {
  List<dynamic> friends = [];
  List<dynamic> filteredFriends = [];
  bool isLoading = true;
  String searchQuery = '';
  String fullName = '';

  @override
  void initState() {
    super.initState();
    fetchUserFriends();
  }

  Future<void> fetchUserFriends() async {
    final url =
        Uri.parse('${ApiUtils.baseUrl}/api/user/${widget.userId}/friends');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          friends = data;
          filteredFriends = data;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching user friends: $e');
      setState(() => isLoading = false);
    }
  }

  void updateSearchQuery(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredFriends = friends.where((user) {
        final fullName =
            ('${user['firstName'] ?? ''} ${user['lastName'] ?? ''}')
                .toLowerCase();
        final email = user['email']?.toLowerCase() ?? '';
        return fullName.contains(searchQuery) || email.contains(searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Friends of " + widget.name, style: GoogleFonts.outfit()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name or email',
                      prefixIcon: Icon(Icons.search, color: Colors.deepOrange),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.deepOrange),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.deepOrange.shade200),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    onChanged: updateSearchQuery,
                  ),
                ),
                Expanded(
                  child: filteredFriends.isEmpty
                      ? Center(
                          child: Text("No friends found.",
                              style: GoogleFonts.outfit()),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredFriends.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: Colors.grey.shade300),
                          itemBuilder: (context, index) {
                            final user = filteredFriends[index];
                            final fullName =
                                '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'
                                    .trim();
                            return ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UserDetailsPage(
                                      userId: user['userName'],
                                      myUsername: widget.userId,
                                      onSignOut: () async {},
                                    ),
                                  ),
                                );
                              },
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey[300],
                                backgroundImage: user['photo'] != null &&
                                        user['photo'].isNotEmpty
                                    ? NetworkImage(user['photo'])
                                    : null,
                                child: user['photo'] == null ||
                                        user['photo'].isEmpty
                                    ? Icon(Icons.person, color: Colors.black)
                                    : null,
                              ),
                              title: Text(
                                fullName.isNotEmpty ? fullName : 'Unnamed',
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(user['email'] ?? '',
                                  style: GoogleFonts.outfit()),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
