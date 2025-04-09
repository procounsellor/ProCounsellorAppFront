import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ProCounsellor/screens/dashboards/adminDashboard/admin_dashboard.dart';
import 'dart:convert';

import 'package:ProCounsellor/screens/dashboards/adminDashboard/admin_profile_page.dart';
import 'package:ProCounsellor/services/api_utils.dart';

class AdminBasePage extends StatefulWidget {
  final VoidCallback onSignOut;
  final String adminId;

  AdminBasePage({required this.onSignOut, required this.adminId});

  @override
  _AdminBasePageState createState() => _AdminBasePageState();
}

class _AdminBasePageState extends State<AdminBasePage>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  // Define the pages that can be navigated to
  final List<Widget> _pages = [];
  String? _photoUrl;
  bool _isLoadingPhoto = true; // To track photo loading state

  @override
  void initState() {
    super.initState();

    // Add WidgetsBindingObserver to listen for app lifecycle events
    WidgetsBinding.instance.addObserver(this);

    // Fetch counsellor details
    _fetchAdminDetails();

    // Initialize the pages with dynamic data
    _pages.add(AdminDashboard(
        onSignOut: widget.onSignOut,
        adminId: widget.adminId)); // Admin Dashboard
    _pages.add(
        AdminProfilePage(
          onSignOut: widget.onSignOut,
          adminId: widget.adminId)); // Profile Page
  }

  Future<void> _fetchAdminDetails() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiUtils.baseUrl}/api/admin/${widget.adminId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _photoUrl = data['photoUrl'];
          _isLoadingPhoto = false;
        });
      } else {
        setState(() {
          _isLoadingPhoto = false;
        });
        // Handle error
        print('Failed to load admin details: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoadingPhoto = false;
      });
      // Handle exception
      print('Error fetching admin details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Use the GlobalKey for the Scaffold
      appBar: AppBar(
        title: Text(
          "Pro Counsellor",
          style: TextStyle(
              color: Color(0xFFF0BB78)), // Set the title color to #F0BB78
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer(); // Open the drawer
          },
        ),
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
                    widget.adminId,
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
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () {
                _navigateToPage(1);
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
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
        unselectedItemColor: Colors.grey, // Color for unselected icons
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _navigateToPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
