import 'package:flutter/material.dart';
import 'screens/signin.dart';
import 'screens/dashboards/userDashboard/call_page.dart'; // Import CallPage
import 'screens/dashboards/userDashboard/liked_videos_page.dart'; // Import LikedVideosPage
import 'screens/dashboards/userDashboard/liked_articles_page.dart'; // Import LikedArticlesPage
import 'screens/dashboards/userDashboard/saved_articles_page.dart'; // Import SavedArticlesPage
import 'screens/dashboards/userDashboard/my_communities_page.dart'; // Import MyCommunitiesPage
import 'screens/dashboards/userDashboard/my_activities_page.dart'; // Import MyActivitiesPage
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with configuration for the web
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyCFKdFziXt7j7wsoCHZ1nWChoKsy6cCj8U",
      authDomain: "procounsellor-71824.firebaseapp.com",
      projectId: "procounsellor-71824",
      storageBucket: "procounsellor-71824.firebasestorage.app",
      messagingSenderId: "1000407154647",
      appId: "1:1000407154647:web:0cc6c26e11d212a233d592",
      databaseURL:
          "https://procounsellor-71824-default-rtdb.firebaseio.com", // Only needed for Realtime Database
    ),
  );

  runApp(ProCounsellorApp());
}

class ProCounsellorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProCounsellor',
      theme: ThemeData(
          // primarySwatch: Colors.blue,
          // scaffoldBackgroundColor:
          //     Colors.grey[100], // Optional for a polished look
          ),
      initialRoute: '/',
      routes: {
        '/': (context) => SignInScreen(), // Sign-in page as the initial route
        '/my_activities': (context) => MyActivitiesPage(
            username: 'User123'), // Replace with dynamic username as needed

        '/calls': (context) => CallPage(
              liveCounsellors: ["Counsellor A", "Counsellor B"],
              topRatedCounsellors: ["Counsellor X", "Counsellor Y"],
            ),
        '/liked_videos': (context) => LikedVideosPage(),
        '/liked_articles': (context) => LikedArticlesPage(),
        '/saved_articles': (context) => SavedArticlesPage(),
        '/my_communities': (context) => MyCommunitiesPage(),
      },
      debugShowCheckedModeBanner: false, // Removes the debug banner
    );
  }
}
