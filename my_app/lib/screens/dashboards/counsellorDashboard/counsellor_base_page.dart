import 'dart:async'; // Import Timer
import 'package:flutter/material.dart';
import 'package:my_app/screens/dashboards/counsellorDashboard/counsellor_community_page.dart';
import 'counsellor_dashboard.dart';
import 'counsellor_my_activities_page.dart'; // Import My Activities Page
import 'counsellor_transactions_page.dart'; // Import Learn with Us Page
import 'counsellor_profile_page.dart';
import 'counsellor_state_notifier.dart';

class CounsellorBasePage extends StatefulWidget {
  final VoidCallback onSignOut;
  final String counsellorId;

  CounsellorBasePage({required this.onSignOut, required this.counsellorId});

  @override
  _CounsellorBasePageState createState() => _CounsellorBasePageState();
}

class _CounsellorBasePageState extends State<CounsellorBasePage>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  late CounsellorStateNotifier _counsellorStateNotifier;
  Timer? _stateChangeTimer; // Timer for debouncing state changes

  // Define the pages that can be navigated to
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();

    // Add WidgetsBindingObserver to listen for app lifecycle events
    WidgetsBinding.instance.addObserver(this);

    // Initialize CounsellorStateNotifier
    _counsellorStateNotifier = CounsellorStateNotifier(widget.counsellorId);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Pro Counsellor",
          style: TextStyle(
              color: Color(0xFFF0BB78)), // Set the title color to #F0BB78
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              _stateChangeTimer?.cancel(); // Cancel any pending timer
              _counsellorStateNotifier
                  .setOffline(); // Explicitly set state to offline on logout
              widget.onSignOut(); // Call sign-out function
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Color(0xFFF0BB78), // Color for selected icon
        unselectedItemColor: Colors.grey, // Color for unselected icons
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
    _stateChangeTimer?.cancel();

    // Set counsellor state to "offline" when BasePage is destroyed
    _counsellorStateNotifier.setOffline();
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
    _stateChangeTimer = Timer(const Duration(seconds: 2), () {
      _counsellorStateNotifier.setOffline();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
