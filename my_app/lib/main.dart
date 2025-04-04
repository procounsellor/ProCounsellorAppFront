import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_app/screens/signInScreens/user_signin_page.dart';
import 'firebase_options.dart';
import 'package:my_app/screens/dashboards/adminDashboard/admin_base_page.dart';
import 'package:my_app/screens/dashboards/userDashboard/base_page.dart';
import 'package:my_app/screens/dashboards/counsellorDashboard/counsellor_base_page.dart';
import 'package:permission_handler/permission_handler.dart';

import 'screens/newCallingScreen/incoming_call_screen.dart';

// Initialize secure storage
final storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  await requestPermissions();
  await requestNotificationPermission();

  runApp(AppRoot());
}

/// ✅ **Request Camera & Microphone Permissions**
Future<void> requestPermissions() async {
  if (kIsWeb) return;

  if (Platform.isAndroid || Platform.isIOS) {
    var cameraStatus = await Permission.camera.request();
    var micStatus = await Permission.microphone.request();

    if (cameraStatus.isDenied) print("❌ Camera permission is denied.");
    if (micStatus.isDenied) print("❌ Microphone permission is denied.");

    if (Platform.isIOS) {
      var photoStatus = await Permission.photos.request();
      if (photoStatus.isDenied) print("❌ Photo library permission is denied.");
    }
  }
}

/// ✅ **Request Notification Permission**
Future<void> requestNotificationPermission() async {
  if (kIsWeb) return;

  if (Platform.isIOS || Platform.isAndroid) {
    var status = await Permission.notification.request();
    if (status.isDenied) print("❌ Notification permission is denied.");
  }
}

// ✅ Global navigator key to navigate outside widget tree
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// ✅ **Main AppRoot Class**
class AppRoot extends StatefulWidget {
  @override
  _AppRootState createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> with WidgetsBindingObserver {
  final DatabaseReference callRef = FirebaseDatabase.instance.ref("agora_call_signaling");
  String? jwtToken;
  String? userId;
  String? role;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp().then((_) {
      if (userId != null) {
        listenForIncomingCalls(); // ✅ Only start listening when userId is available
      } else {
        print("❌ Error: userId is still null after initialization!");
      }
    });
    //setupFirebaseMessaging();
  }

  void listenForIncomingCalls() {
    if (userId == null) {
      print("❌ Error: userId is null, cannot listen for calls.");
      return;
    }

    callRef.child(userId!).onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;

      if (data == null) {
        print("⚠️ No active call found.");
        return;
      }

      if (data is Map<dynamic, dynamic>) {
        String callerName = data["callerName"] ?? "Unknown Caller";
        String channelId = data["channelId"] ?? "";

        if (channelId.isNotEmpty) {
          print("📞 Incoming call from: $callerName");
          navigateToIncomingCallScreen(channelId);
        } else {
          print("⚠️ Missing channelId in Firebase data.");
        }
      } else {
        print("⚠️ Unexpected Firebase data format: $data");
      }
    });
  }


  /// ✅ **Firebase Messaging for Notifications**
  // void setupFirebaseMessaging() {
  //   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //     print("📩 Foreground notification received: ${message.notification?.title}");
  //     processIncomingCall(message);
  //   });

  //   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  //     processIncomingCall(message);
  //   });

  //   FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
  //     if (message != null) processIncomingCall(message);
  //   });
  // }

  /// ✅ **Process Incoming Call from FCM**
  // void processIncomingCall(RemoteMessage message) {
  //   if (message.data["type"] == "incoming_call" && message.data["channelId"] != null) {
  //     navigateToIncomingCallScreen(message.data["channelId"]);
  //   }
  // }

  /// ✅ **Navigate to Incoming Call Screen**
  void navigateToIncomingCallScreen(String channelId) {
    final context = navigatorKey.currentState?.overlay?.context;
    print(context);
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IncomingCallScreen(receiverId: userId!, channelId: channelId, onSignOut: restartApp),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

    Future<void> _initializeApp() async {
      try {
        jwtToken = await storage.read(key: "jwtToken");
        userId = await storage.read(key: "userId");
        role = await storage.read(key: "role");

        if (userId == null) {
          print("❌ Error: User ID not found in storage!");
        } else {
          print("✅ User ID Loaded: $userId");
        }
      } catch (e) {
        print("❌ Error reading secure storage: $e");
      }

      setState(() {
        isLoading = false;
      });
    }


  /// ✅ **Restart App (Logout & Clear Data)**
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
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        theme: ThemeData(scaffoldBackgroundColor: Colors.white),
      );
    }

    if (jwtToken == null || jwtToken!.isEmpty || userId == null) {
      return MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        home: UserSignInPage(onSignOut: restartApp),
      );
    }

    switch (role?.toLowerCase()) {
      case "user":
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          home: BasePage(username: userId!, onSignOut: restartApp),
        );
      case "counsellor":
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          home: CounsellorBasePage(onSignOut: restartApp, counsellorId: userId!),
        );
      case "admin":
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          home: AdminBasePage(onSignOut: restartApp, adminId: userId!),
        );
      default:
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Invalid Role. Please contact support.", style: TextStyle(fontSize: 18, color: Colors.red)),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: restartApp,
                    child: Text("Go to Login"),
                    style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }
}
