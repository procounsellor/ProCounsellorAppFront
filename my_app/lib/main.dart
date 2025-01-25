import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_app/screens/dashboards/adminDashboard/admin_base_page.dart';
import 'package:my_app/screens/dashboards/userDashboard/base_page.dart';
import 'package:my_app/screens/dashboards/counsellorDashboard/counsellor_base_page.dart';
import 'package:my_app/screens/newSignUpScreens/new_signin_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Initialize secure storage with platform-specific options
final storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Ensure Firebase is initialized only once using generated options file
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  runApp(AppRoot());
}

class AppRoot extends StatefulWidget {
  @override
  _AppRootState createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  String? jwtToken;
  String? userId;
  String? role;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      jwtToken = await storage.read(key: "jwtToken");
      userId = await storage.read(key: "userId");
      role = await storage.read(key: "role");

      debugPrint("JWT Token: $jwtToken");
      debugPrint("User ID: $userId");
      debugPrint("User Role: $role");
    } catch (e) {
      debugPrint("Error reading secure storage: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> restartApp() async {
    await storage.deleteAll();
    setState(() {
      jwtToken = null;
      userId = null;
      role = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (jwtToken == null || jwtToken!.isEmpty || userId == null) {
      // Show login page if token or userId is not present
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: NewSignInPage(
          onSignOut: restartApp,
        ),
      );
    }

    // Navigate based on role
    switch (role?.toLowerCase()) {
      case "user":
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: BasePage(
            username: userId!,
            onSignOut: restartApp,
          ),
        );
      case "counsellor":
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: CounsellorBasePage(
            onSignOut: restartApp,
            counsellorId: userId!,
          ),
        );
      case "admin":
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: AdminBasePage(
            onSignOut: restartApp,
            adminId: userId!,
          ),
        );
      default:
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Invalid Role. Please contact support.",
                    style: TextStyle(fontSize: 18, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: restartApp,
                    child: Text("Go to Login"),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }
}
