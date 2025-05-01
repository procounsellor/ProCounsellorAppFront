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
  List<dynamic> myFriends = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadCachedUsers();
    fetchAllUsers();
    fetchMyFriends();
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
        final filteredData = (data as List).where((user) {
          return user['userName'] != widget.username;
        }).toList();

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

  Future<void> fetchMyFriends() async {
    final url =
        Uri.parse('${ApiUtils.baseUrl}/api/user/${widget.username}/friends');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          myFriends = data;
        });
      } else {
        print("⚠️ No friends found or failed to fetch.");
      }
    } catch (e) {
      print("❌ Error fetching friends: $e");
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
    await fetchMyFriends();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text('Friends', style: GoogleFonts.outfit()),
          centerTitle: true,
          bottom: TabBar(
            labelColor: Colors.deepOrange,
            unselectedLabelColor: Colors.black54,
            tabs: [
              Tab(text: 'My Friends'),
              Tab(text: 'Explore Friends'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMyFriendsTab(),
            _buildExploreFriendsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildMyFriendsTab() {
    final filteredFriends = myFriends.where((user) {
      final fullName = ('${user['firstName'] ?? ''} ${user['lastName'] ?? ''}')
          .toLowerCase();
      final email = user['email']?.toLowerCase() ?? '';
      return fullName.contains(searchQuery) || email.contains(searchQuery);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name or email',
                    prefixIcon: Icon(Icons.search, color: Colors.deepOrange),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.deepOrange),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.deepOrange.shade200),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  onChanged: (query) {
                    setState(() {
                      searchQuery = query.toLowerCase();
                    });
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.deepOrange),
                onPressed: () async {
                  await fetchMyFriends();
                  setState(() {});
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await fetchMyFriends();
              setState(() {});
            },
            child: filteredFriends.isEmpty
                ? ListView(
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text('You have no friends yet.',
                              style: GoogleFonts.outfit(fontSize: 16)),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    itemCount: filteredFriends.length,
                    separatorBuilder: (context, index) =>
                        Divider(indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final user = filteredFriends[index];
                      final fullName =
                          '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'
                              .trim();
                      return _buildUserTile(user, fullName, showChat: true);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildExploreFriendsTab() {
    return isLoading
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
                      borderSide: BorderSide(color: Colors.deepOrange.shade200),
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
                            return _buildUserTile(user, fullName,
                                showChat: false);
                          },
                        ),
                ),
              ),
            ],
          );
  }

  Widget _buildUserTile(Map<String, dynamic> user, String fullName,
      {bool showChat = true}) {
    return ListTile(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserDetailsPage(
              userId: user['userName'],
              myUsername: widget.username,
              onSignOut: widget.onSignOut,
            ),
          ),
        );

        if (result == 'friendAdded') {
          await fetchMyFriends();
          setState(() {});
        }
      },
      leading: CircleAvatar(
        backgroundColor: Colors.grey[300],
        backgroundImage: user['photo'] != null && user['photo'].isNotEmpty
            ? NetworkImage(user['photo'])
            : null,
        child: user['photo'] == null || user['photo'].isEmpty
            ? Icon(Icons.person, color: Colors.black)
            : null,
      ),
      title: Text(
        fullName.isNotEmpty ? fullName : 'Unnamed',
        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(user['email'] ?? '', style: GoogleFonts.outfit()),
      trailing: showChat
          ? IconButton(
              icon: Icon(Icons.message, color: Colors.deepOrange),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserToUserChattingPage(
                      itemName: user['userName'],
                      userId: widget.username,
                      userId2: user['userName'],
                      onSignOut: () async {},
                      role: "user",
                    ),
                  ),
                );
              },
            )
          : null,
    );
  }
}
