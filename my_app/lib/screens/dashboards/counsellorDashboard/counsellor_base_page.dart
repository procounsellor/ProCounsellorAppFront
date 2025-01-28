import 'dart:async'; // Import Timer
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import http for API calls
import 'dart:convert'; // For JSON decoding
import 'package:my_app/screens/dashboards/counsellorDashboard/counsellor_community_page.dart';
import 'counsellor_dashboard.dart';
import 'counsellor_my_activities_page.dart'; // Import My Activities Page
import 'counsellor_transactions_page.dart'; // Import Transactions Page
import 'counsellor_profile_page.dart';
import 'counsellor_state_notifier.dart';
import 'package:firebase_database/firebase_database.dart';
import 'counsellor_chat_page.dart';

class CounsellorBasePage extends StatefulWidget {
  final VoidCallback onSignOut;
  final String counsellorId;

  CounsellorBasePage({required this.onSignOut, required this.counsellorId});

  @override
  _CounsellorBasePageState createState() => _CounsellorBasePageState();
}

class _CounsellorBasePageState extends State<CounsellorBasePage>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  late CounsellorStateNotifier _counsellorStateNotifier;
  Timer? _stateChangeTimer; // Timer for debouncing state changes

  // Define the pages that can be navigated to
  final List<Widget> _pages = [];
  String? _photoUrl; // To store the counsellor's photo URL
  bool _isLoadingPhoto = true; // To track photo loading state
  int notificationCount = 0;
  late DatabaseReference chatRef;

  @override
  void initState() {
    super.initState();
    // _listenToNotifications();

    // Add WidgetsBindingObserver to listen for app lifecycle events
    WidgetsBinding.instance.addObserver(this);

    // Initialize CounsellorStateNotifier
    _counsellorStateNotifier = CounsellorStateNotifier(widget.counsellorId);

    // Fetch counsellor details
    _fetchCounsellorDetails();

    // Set counsellor state to "online" when BasePage is created
    _setOnlineWithDebounce();

    // Initialize the pages with dynamic data
    _pages.add(CounsellorDashboard(
        onSignOut: widget.onSignOut,
        counsellorId: widget.counsellorId)); // User Dashboard
    _pages.add(CounsellorTransactionsPage()); // Transactions Page
    _pages.add(CounsellorCommunityPage()); // Community Page
    _pages.add(CounsellorMyActivitiesPage(
        username: widget.counsellorId)); // My Activities Page
    _pages.add(
        CounsellorProfilePage(username: widget.counsellorId)); // Profile Page
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

          if (!isSeen && senderId != widget.counsellorId) {
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
          String senderId = messageData['senderId'] ?? '';

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

  Future<void> _fetchCounsellorDetails() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://localhost:8080/api/counsellor/${widget.counsellorId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<String> chatIds =
            List<String>.from(data['chatIdsCreatedForCounsellor'] ?? []);
        _listenToNotifications(chatIds);
        setState(() {
          _photoUrl = data['photoUrl']; // Assuming API returns 'photoUrl'
          _isLoadingPhoto = false;
        });
      } else {
        setState(() {
          _isLoadingPhoto = false;
        });
        // Handle error
        print('Failed to load counsellor details: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoadingPhoto = false;
      });
      // Handle exception
      print('Error fetching counsellor details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Use the GlobalKey for the Scaffold
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Pro Counsellor",
          style: TextStyle(
              color: Color.fromARGB(
                  255, 0, 0, 0)), // Set the title color to #F0BB78
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer(); // Open the drawer
          },
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                  icon: Icon(Icons.chat),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ChatsPage(counsellorId: widget.counsellorId),
                      ),
                    );
                  }),
              Positioned(
                right: 6,
                top: 6,
                child: notificationCount > 0
                    ? Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$notificationCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : Container(),
              ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
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
                        ? Icon(Icons.person, size: 40, color: Color(0xFFF0BB78))
                        : null,
                  ),
                  SizedBox(height: 10),
                  Text(
                    widget.counsellorId,
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
              leading: Icon(Icons.currency_rupee),
              title: Text('Transactions'),
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
              onTap: () {
                _navigateToPage(3);
              },
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
              onTap: () {
                _stateChangeTimer?.cancel(); // Cancel any pending timer
                _counsellorStateNotifier
                    .setOffline(); // Explicitly set state to offline on logout
                widget.onSignOut();
              },
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Color(0xFFF0BB78), // Color for selected icon
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white, // Color for unselected icons
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.currency_rupee), label: "Transactions"),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: "Community"),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt), label: "My Activities"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Remove observer when BasePage is disposed
    WidgetsBinding.instance.removeObserver(this);

    // Cancel any pending state change timer
    // _stateChangeTimer?.cancel();

    // Set counsellor state to "offline" when BasePage is destroyed
    _counsellorStateNotifier.setOffline();
    super.dispose();
    chatRef.onDisconnect();
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
      _counsellorStateNotifier.setOnline();
    });
  }

  void _setOfflineWithDebounce() {
    _stateChangeTimer?.cancel(); // Cancel any pending online timer
    _stateChangeTimer = Timer(const Duration(seconds: 15), () {
      _counsellorStateNotifier.setOffline();
    });
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
