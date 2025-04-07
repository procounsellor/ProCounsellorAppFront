import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_app/screens/newCallingScreen/save_fcm_token.dart';
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
  _initFCM();

  runApp(AppRoot());
}

Future<void> _initFCM() async {
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  await firebaseMessaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Register for push (important for iOS)
  await firebaseMessaging.getToken().then((token) {
    print("✅ FCM Token initialized: $token");
  });
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
    _initializeApp();
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
          setupNotificationListeners(
            currentUserId: userId!,
            onSignOut: restartApp,
          );
        }
      } catch (e) {
        print("❌ Error reading secure storage: $e");
      }

      setState(() {
        isLoading = false;
      });

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        print("🔁 FCM Token refreshed: $newToken");
        if(role == "user"){
          FirestoreService.saveFCMTokenUser(userId!);
        }
        else if(role == "counsellor"){
          FirestoreService.saveFCMTokenCounsellor(userId!);
        }
      });
    }

    void setupNotificationListeners({
      required String currentUserId,
      required Future<void> Function() onSignOut,
    }) {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('🔔 Foreground notification: ${message.data}');
        _handleIncomingCall(message.data, currentUserId, onSignOut);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('📲 Opened app via notification: ${message.data}');
        _handleIncomingCall(message.data, currentUserId, onSignOut);
      });

      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null && message.data['type'] == 'incoming_call') {
          _handleIncomingCall(message.data, currentUserId, onSignOut);
        }
      });
    }

   void _handleIncomingCall(
  Map<String, dynamic> data,
  String currentUserId,
  Future<void> Function() onSignOut,
) {
  if (data['type'] != 'incoming_call') return;

  final String channelId = data['channelId'] ?? '';

  // Safely delay navigation till current frame ends
  Future.microtask(() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (navigatorKey.currentState?.mounted ?? false) {
        final currentContext = navigatorKey.currentContext;

        final isAlreadyOnCallScreen = ModalRoute.of(currentContext!)?.settings.name == 'incoming_call';

        if (!isAlreadyOnCallScreen) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => IncomingCallScreen(
                receiverId: currentUserId,
                channelId: channelId,
                onSignOut: onSignOut,
              ),
              settings: const RouteSettings(name: 'incoming_call'),
            ),
          );
        }
      } else {
        print("❌ Navigator not mounted. Cannot push IncomingCallScreen.");
      }
    });
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
