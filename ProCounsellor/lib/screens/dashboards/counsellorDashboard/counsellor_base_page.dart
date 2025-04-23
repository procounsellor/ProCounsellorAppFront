import 'dart:async'; // Import Timer
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import http for API calls
import 'dart:convert'; // For JSON decoding
import 'package:ProCounsellor/screens/dashboards/counsellorDashboard/counsellor_community_page.dart';
import '../../../services/api_utils.dart';
import '../../paymentScreens/transaction_history.dart';
import 'counsellor_dashboard.dart';
import 'counsellor_profile_page.dart';
import 'ActivityPage.dart';
import 'counsellor_state_notifier.dart';
import 'package:firebase_database/firebase_database.dart';
import 'counsellor_chat_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'call_history_page.dart';

class CounsellorBasePage extends StatefulWidget {
  final Future<void> Function() onSignOut;
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
  String? _photoUrl;
  String _fullName = ""; // To store the counsellor's photo URL
  bool _isLoadingPhoto = true; // To track photo loading state
  int notificationCount = 0;
  int subscriberNotificationCount = 0;
  List<String> activityLogs = [];
  int missedCallNotificationCount = 0;

  DatabaseReference? chatRef;
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
    _listenToSubscriberChanges();
    _listenToFollowerChanges();
    _listenToReviewChanges();
    _listenToMissedCalls();

    // Set counsellor state to "online" when BasePage is created
    _setOnlineWithDebounce();

    // Initialize the pages with dynamic data
    _pages.add(CounsellorDashboard(
        onSignOut: widget.onSignOut,
        counsellorId: widget.counsellorId)); // User Dashboard
    _pages.add(TransactionHistoryPage(username: widget.counsellorId)); // Transactions Page
    _pages.add(CounsellorCommunityPage()); // Community Page
    // _pages.add(CounsellorMyActivitiesPage(
    //     username: widget.counsellorId, onSignOut: widget.onSignOut,)); // My Activities Page
    _pages.add(CallHistoryPage(
      counsellorId: widget.counsellorId,
      onSignOut: widget.onSignOut,
      onMissedCallUpdated: _resetMissedCallCount,
    ));
    _pages.add(CounsellorProfilePage(
      username: widget.counsellorId,
      onSignOut: widget.onSignOut,
    )); // Profile Page
  }

  void _listenToMissedCalls() {
    DatabaseReference callRef = FirebaseDatabase.instance.ref('calls');

    callRef.onValue.listen((event) {
      int newMissedCalls = 0;
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> calls =
            event.snapshot.value as Map<dynamic, dynamic>;

        calls.forEach((key, callData) {
          if (callData["receiverId"] == widget.counsellorId &&
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
    if (!mounted) return;
    setState(() {
      missedCallNotificationCount = 0;
    });
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
            if (!mounted) return;
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
          //String senderId = messageData['senderId'] ?? '';
          if (!mounted) return;
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
        Uri.parse('${ApiUtils.baseUrl}/api/counsellor/${widget.counsellorId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<String> chatIds =
            List<String>.from(data['chatIdsCreatedForCounsellor'] ?? []);
        _listenToNotifications(chatIds);
        if (!mounted) return;
        setState(() {
          _photoUrl = data['photoUrl'];
          _fullName = data['firstName'] + " " + data['lastName'];
          // Assuming API returns 'photoUrl'
          _isLoadingPhoto = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isLoadingPhoto = false;
        });
        // Handle error
        print('Failed to load counsellor details: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingPhoto = false;
      });
      // Handle exception
      print('Error fetching counsellor details: $e');
    }
  }

  void _listenToSubscriberChanges() {
    DatabaseReference subscriberRef = FirebaseDatabase.instance
        .ref('realtimeSubscribers/${widget.counsellorId}');

    subscriberRef.onChildAdded.listen((event) {
      if (event.snapshot.value == false) {
        // Notify only if value is false
        if (!mounted) return;
        setState(() {
          subscriberNotificationCount++;
          activityLogs.add("New subscriber: ${event.snapshot.key}");
        });
        print("New subscriber added with false value: ${event.snapshot.key}");
      }
    });

    subscriberRef.onChildChanged.listen((event) {
      if (event.snapshot.value == false) {
        // Ensure it is still false
        if (!mounted) return;
        setState(() {
          subscriberNotificationCount++;
          activityLogs.add("Updated subscriber: ${event.snapshot.key}");
        });
        print("Updated subscriber still false: ${event.snapshot.key}");
      }
    });
  }

  void _listenToFollowerChanges() {
    DatabaseReference followerRef = FirebaseDatabase.instance
        .ref('realtimeFollowers/${widget.counsellorId}');

    followerRef.onChildAdded.listen((event) {
      if (event.snapshot.value == false) {
        // Notify only if value is false
        if (!mounted) return;
        setState(() {
          subscriberNotificationCount++;
          activityLogs.add("New follower: ${event.snapshot.key}");
        });
        print("New follower added with false value: ${event.snapshot.key}");
      }
    });

    followerRef.onChildChanged.listen((event) {
      if (event.snapshot.value == false) {
        // Ensure it is still false
        if (!mounted) return;
        setState(() {
          subscriberNotificationCount++;
          activityLogs.add("Updated follower: ${event.snapshot.key}");
        });
        print("Updated follower still false: ${event.snapshot.key}");
      }
    });
  }

  void _listenToReviewChanges() {
    DatabaseReference reviewRef = FirebaseDatabase.instance
        .ref('counsellorRealtimeReview/${widget.counsellorId}');

    reviewRef.onChildAdded.listen((event) {
      if (event.snapshot.value == false) {
        // Notify only if value is false
        if (!mounted) return;
        setState(() {
          subscriberNotificationCount++;
          activityLogs.add("New review: ${event.snapshot.key}");
        });
        print("New review added with false value: ${event.snapshot.key}");
      }
    });

    reviewRef.onChildChanged.listen((event) {
      if (event.snapshot.value == false) {
        // Ensure it is still false
        if (!mounted) return;
        setState(() {
          subscriberNotificationCount++;
          activityLogs.add("Updated Review: ${event.snapshot.key}");
        });
        print("Updated review still false: ${event.snapshot.key}");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                        builder: (context) => ChatPage(
                          counsellorId: widget.counsellorId,
                          onSignOut: widget.onSignOut,
                        ),
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
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications),
                onPressed: () async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.setInt(
                      'seenSubscriberCount_${widget.counsellorId}',
                      subscriberNotificationCount);
                  if (!mounted) return;
                  setState(() {
                    subscriberNotificationCount = 0;
                  });

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ActivityPage(
                        activityLogs: activityLogs,
                        counsellorId: widget.counsellorId,
                        onSignOut: widget.onSignOut,
                      ),
                    ),
                  );
                },
              ),
              if (subscriberNotificationCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$subscriberNotificationCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
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
                        ? Icon(Icons.person, size: 40, color: Color(0xFFF0BB78))
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
        type: BottomNavigationBarType
            .fixed, // Use fixed to keep the white background
        showSelectedLabels: true, // Show label only for selected item
        showUnselectedLabels: false, // Hide labels for unselected items
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.currency_rupee), label: "Transactions"),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: "Community"),
          BottomNavigationBarItem(
            icon: missedCallNotificationCount > 0
                ? Icon(Icons.call_missed,
                    color: Colors
                        .red) // 🔴 Show missed call icon if there are missed calls
                : Icon(Icons.call_sharp), // 📞 Default call icon
            label: "Calls",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stateChangeTimer?.cancel();
    _counsellorStateNotifier.setOffline();

    // Optionally detach any custom Firebase listeners
    chatRef?.onDisconnect();

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
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Close the drawer
  }

  void _onItemTapped(int index) {
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
    });
  }
}
