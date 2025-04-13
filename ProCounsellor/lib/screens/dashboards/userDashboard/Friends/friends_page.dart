import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/api_utils.dart';
import 'user_details_page.dart';
import 'UserToUserChattingPage.dart';
import 'dart:async';

class FriendsPage extends StatefulWidget {
  final String username;
  final Future<void> Function() onSignOut;

  FriendsPage({required this.username, required this.onSignOut});

  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  List<dynamic> users = [];
  List<dynamic> filteredUsers = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadCachedUsers();
    fetchAllUsers();
  }

  Future<void> loadCachedUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cached_users');
    if (cachedData != null) {
      final decodedData = json.decode(cachedData);
      setState(() {
        users = decodedData;
        filteredUsers = decodedData;
        isLoading = false;
      });
    }
  }

  Future<void> fetchAllUsers() async {
    final url = Uri.parse('${ApiUtils.baseUrl}/api/user/all-users');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // 🔥 Remove current user
        final filteredData = (data as List).where((user) {
          return user['userName'] != widget.username;
        }).toList();

        // ✅ Cache and update state
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('cached_users', json.encode(filteredData));

        setState(() {
          users = filteredData;
          filteredUsers = filteredData;
          isLoading = false;
        });
      } else {
        print("❌ Failed to fetch users: ${response.body}");
      }
    } catch (e) {
      print("❌ Error fetching users: $e");
    }
  }

  void updateSearchQuery(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredUsers = users.where((user) {
        final fullName =
            ('${user['firstName'] ?? ''} ${user['lastName'] ?? ''}')
                .toLowerCase();
        final email = user['email']?.toLowerCase() ?? '';
        return fullName.contains(searchQuery) || email.contains(searchQuery);
      }).toList();
    });
  }

  Future<void> handleRefresh() async {
    await fetchAllUsers();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Friends', style: GoogleFonts.outfit()),
        centerTitle: true,
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
                  child: RefreshIndicator(
                    onRefresh: handleRefresh,
                    child: filteredUsers.isEmpty
                        ? ListView(
                            children: [
                              Center(
                                  child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text('No users found',
                                    style: GoogleFonts.outfit()),
                              ))
                            ],
                          )
                        : ListView.separated(
                            itemCount: filteredUsers.length,
                            separatorBuilder: (context, index) =>
                                Divider(indent: 16, endIndent: 16),
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              final fullName =
                                  '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'
                                      .trim();
                              return ListTile(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UserDetailsPage(
                                          userId: user['userName'],
                                          myUsername: widget.username,
                                          onSignOut: widget.onSignOut),
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
                                subtitle: Text(
                                  user['email'] ?? '',
                                  style: GoogleFonts.outfit(),
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.message,
                                      color: Colors.deepOrange),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            UserToUserChattingPage(
                                          itemName: user['userName'],
                                          userId: widget.username,
                                          userId2: user['userName'],
                                          onSignOut: () async {},
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}
