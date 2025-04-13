import 'dart:async'; // Import Timer
import 'dart:convert'; // For JSON decoding
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import http for API calls
import 'package:ProCounsellor/screens/dashboards/userDashboard/call_history_page.dart';
import '../../../services/api_utils.dart';
import 'user_dashboard.dart';
import 'learnwithus/learn_with_us_page.dart';
import 'communities/communities_home_page.dart';
import 'profile_page.dart';
import 'user_state_notifier.dart'; // Import UserStateNotifier
import 'package:firebase_database/firebase_database.dart';
import 'chat_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Friends/friends_page.dart';
import 'components/message_notifier_service.dart';

class BasePage extends StatefulWidget {
  final Future<void> Function() onSignOut;
  final String username;

  BasePage({required this.onSignOut, required this.username});

  @override
  _BasePageState createState() => _BasePageState();
}

class _BasePageState extends State<BasePage> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  late UserStateNotifier _userStateNotifier;

  final List<Widget> _pages = [];
  Timer? _stateChangeTimer; // Timer for debouncing state changes

  String? _photoUrl;
  String _fullName = ""; // To store the user's photo URL
  bool _isLoadingPhoto = true; // To track photo loading state
  int notificationCount = 0;
  late DatabaseReference chatRef;
  int missedCallNotificationCount = 0;
  MessageNotifierService? _messageNotifier;

  @override
  void initState() {
    super.initState();
    _fullName = widget.username;

    // Add WidgetsBindingObserver to listen for app lifecycle events
    WidgetsBinding.instance.addObserver(this);

    // Initialize UserStateNotifier
    _userStateNotifier = UserStateNotifier(widget.username);

    // Fetch user details
    _fetchUserDetails();
    _listenToMissedCalls();

    // Set user state to "online" when BasePage is created
    _setOnlineWithDebounce();

    // Initialize pages
    _pages.add(
        UserDashboard(onSignOut: widget.onSignOut, username: widget.username));
    _pages.add(LearnWithUsPage());
    _pages.add(CommunitiesHomePage());
    //_pages.add(MyActivitiesPage(username: widget.username, onSignOut: widget.onSignOut,));
    _pages.add(CallHistoryPage(
      userId: widget.username,
      onSignOut: widget.onSignOut,
      onMissedCallUpdated: _resetMissedCallCount,
    ));
    _pages.add(ProfilePage(username: widget.username));
  }

  void _listenToMissedCalls() {
    DatabaseReference callRef = FirebaseDatabase.instance.ref('calls');

    callRef.onValue.listen((event) {
      int newMissedCalls = 0;
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> calls =
            event.snapshot.value as Map<dynamic, dynamic>;

        calls.forEach((key, callData) {
          if (callData["receiverId"] == widget.username &&
              callData["status"] == "Missed Call" &&
              callData["missedCallStatusSeen"] == false) {
            newMissedCalls++;
          }
        });
      }

      // ✅ Delay setState() until after the build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            missedCallNotificationCount = newMissedCalls;
          });
        }
      });
    });
  }

  void _resetMissedCallCount() {
    setState(() {
      missedCallNotificationCount = 0;
    });
  }

  Future<void> _fetchUserDetails() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiUtils.baseUrl}/api/user/${widget.username}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> chatObjects = data['chatIdsCreatedForUser'] ?? [];
        print(chatObjects);
        final List<String> chatIds = chatObjects
            .map<String>((chat) => chat['chatId'] as String)
            .toList();

        _messageNotifier = MessageNotifierService(
          username: widget.username,
          chatIds: chatIds,
        );

// Optional: Listen for changes in count
        _messageNotifier?.addListener(() {
          if (mounted) {
            setState(() {}); // to update notificationCount in the UI
          }
        });

        //_listenToNotifications(chatIds);
        setState(() {
          _photoUrl = data['photo'];
          _fullName = data['firstName'] +
              " " +
              data['lastName']; // Assuming API returns 'photoUrl'
          _isLoadingPhoto = false;
        });
      } else {
        setState(() {
          _isLoadingPhoto = false;
        });
        // Handle error
        print('Failed to load user details: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoadingPhoto = false;
      });
      // Handle exception
      print('Error fetching user details: $e');
    }
  }

  void _listenToNotifications(List<String> chatIds) {
    for (String chatId in chatIds) {
      DatabaseReference chatRef =
          FirebaseDatabase.instance.ref('chats/$chatId/messages');

      chatRef.onChildAdded.listen((event) {
        if (event.snapshot.value != null) {
          final messageData =
              Map<String, dynamic>.from(event.snapshot.value as Map);
          bool isSeen = messageData['isSeen'] ?? true;
          String senderId = messageData['senderId'] ?? '';

          if (!isSeen && senderId != widget.username) {
            setState(() {
              notificationCount++;
            });
          }
        }
      });

      chatRef.onChildChanged.listen((event) {
        if (event.snapshot.value != null) {
          final messageData =
              Map<String, dynamic>.from(event.snapshot.value as Map);
          bool isSeen = messageData['isSeen'] ?? true;

          setState(() {
            if (isSeen) {
              notificationCount =
                  (notificationCount > 0) ? notificationCount - 1 : 0;
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    // Remove observer when BasePage is disposed
    WidgetsBinding.instance.removeObserver(this);

    // Cancel any pending state change timer
    //_stateChangeTimer?.cancel();

    // Set user state to "offline" when BasePage is destroyed
    _userStateNotifier.setOffline();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes with debounce
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _setOfflineWithDebounce();
    } else if (state == AppLifecycleState.resumed) {
      _setOnlineWithDebounce();
    }
  }

  void _setOnlineWithDebounce() {
    _stateChangeTimer?.cancel(); // Cancel any pending offline timer
    _stateChangeTimer = Timer(const Duration(seconds: 2), () {
      _userStateNotifier.setOnline();
    });
  }

  void _setOfflineWithDebounce() {
    _stateChangeTimer?.cancel(); // Cancel any pending online timer
    _stateChangeTimer = Timer(const Duration(seconds: 15), () {
      _userStateNotifier.setOffline();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      key: _scaffoldKey, // Use the GlobalKey for the Scaffold
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text(
          "Pro Counsellor",
          style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.group),
            tooltip: "Friends",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FriendsPage(
                    username: widget.username,
                    onSignOut: widget.onSignOut,
                  ),
                ),
              );
            },
          ),
          Stack(
            children: [
              IconButton(
                  icon: Icon(Icons.chat),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          userId: widget.username,
                          onSignOut: widget.onSignOut,
                        ),
                      ),
                    );
                    // _messageNotifier?.clearNotificationCount();
                  }),
              Positioned(
                right: 6,
                top: 6,
                child: (_messageNotifier?.hasUnseenMessages ?? false)
                    ? Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      )
                    : Container(),
              ),
            ],
          ),
        ],
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer(); // Open the drawer
          },
        ),
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.logout),
        //     onPressed: () {
        //       _stateChangeTimer?.cancel(); // Cancel any pending timer
        //       _userStateNotifier
        //           .setOffline(); // Explicitly set state to offline on logout
        //       widget.onSignOut();
        //     },
        //   ),
        // ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFFF0BB78),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                    child: _isLoadingPhoto || _photoUrl == null
                        ? Text(
                            _fullName.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF0BB78),
                            ),
                          )
                        : null,
                  ),
                  SizedBox(height: 10),
                  Text(
                    _fullName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                _navigateToPage(0);
              },
            ),
            ListTile(
              leading: Icon(Icons.lightbulb),
              title: Text('Learn with Us'),
              onTap: () {
                _navigateToPage(1);
              },
            ),
            ListTile(
              leading: Icon(Icons.groups),
              title: Text('Community'),
              onTap: () {
                _navigateToPage(2);
              },
            ),
            ListTile(
              leading: Icon(Icons.list_alt),
              title: Text('My Activities'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () {
                _navigateToPage(4);
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () async {
                _stateChangeTimer?.cancel(); // Cancel any pending timer
                _userStateNotifier
                    .setOffline(); // Explicitly set state to offline on logout
                await widget.onSignOut();
              },
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Color(0xFFF0BB78), // Custom color for selected item
        unselectedItemColor: Colors.grey, // Color for unselected items
        backgroundColor:
            Colors.white, // Set a consistent white background color
        type: BottomNavigationBarType
            .fixed, // Use fixed to keep the white background
        showSelectedLabels: true, // Show label only for selected item
        showUnselectedLabels: false, // Hide labels for unselected items
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb),
            label: "Learn with Us",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: "Community",
          ),
          BottomNavigationBarItem(
            icon: missedCallNotificationCount > 0
                ? Icon(Icons.call_missed,
                    color: Colors
                        .red) // 🔴 Show missed call icon if there are missed calls
                : Icon(Icons.call_sharp), // 📞 Default call icon
            label: "Calls",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  void _navigateToPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Close the drawer
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
