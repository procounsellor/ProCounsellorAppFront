import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_app/screens/callingScreens/call_layover_manager.dart';
import 'package:my_app/screens/callingScreens/call_page.dart';
import 'package:my_app/screens/callingScreens/video_call_page.dart';
import 'package:my_app/screens/signInScreens/get_user_details_step2.dart';
import 'package:my_app/screens/signInScreens/user_details.dart';
import 'package:my_app/screens/signInScreens/user_signin_page.dart';

import 'package:my_app/services/firebase_signaling_service.dart';
import 'firebase_options.dart';
import 'package:my_app/screens/dashboards/adminDashboard/admin_base_page.dart';
import 'package:my_app/screens/dashboards/userDashboard/base_page.dart';
import 'package:my_app/screens/dashboards/counsellorDashboard/counsellor_base_page.dart';

import 'package:permission_handler/permission_handler.dart';

import 'services/call_service.dart';

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

Future<void> requestPermissions() async {
  if (kIsWeb) return;

  if (Platform.isAndroid || Platform.isIOS) {
    // Request Camera permission
    var cameraStatus = await Permission.camera.request();
    if (cameraStatus.isDenied) {
      print("Camera permission is denied.");
    }

    // Request Microphone permission
    var micStatus = await Permission.microphone.request();
    if (micStatus.isDenied) {
      print("Microphone permission is denied.");
    }

    // Request Photo Library access (iOS only)
    if (Platform.isIOS) {
      var photoStatus = await Permission.photos.request();
      if (photoStatus.isDenied) {
        print("Photo library permission is denied.");
      }
    }
  }
}

Future<void> requestNotificationPermission() async {
  // Web does not need explicit notification permission handling
  if (kIsWeb) return;

  if (Platform.isIOS || Platform.isAndroid) {
    var status = await Permission.notification.request();
    if (status.isDenied) {
      print("Notification permission is denied.");
    }
  }
}

class AppRoot extends StatefulWidget {
  @override
  _AppRootState createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> with WidgetsBindingObserver {
  final FirebaseSignalingService _signalingService = FirebaseSignalingService();
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

  // ✅ Detect App Lifecycle Changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && userId != null) {
      _signalingService.clearIncomingCall(userId!);
    }
  }

  Future<void> _initializeApp() async {
    try {
      jwtToken = await storage.read(key: "jwtToken");
      userId = await storage.read(key: "userId");
      role = await storage.read(key: "role");

      debugPrint("JWT Token: $jwtToken");
      debugPrint("User ID: $userId");
      debugPrint("User Role: $role");

      if (userId != null && (role == "user" || role == "counsellor")) {
        _startListeningForCalls(context); // ✅ Pass the context correctly
      }
    } catch (e) {
      debugPrint("Error reading secure storage: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  // 🔹 Listen for incoming calls globally
  void _startListeningForCalls(BuildContext context) {
    final CallService _callService = CallService();

    _signalingService.listenForIncomingCalls(userId!, (callData) {
      CallOverlayManager.showIncomingCall(
        callData,
        context,
        () {
          bool isVideoCall = callData['callType'] == 'video';

          CallOverlayManager.removeOverlay();

          // ✅ Use the global navigator key for safe navigation
          CallOverlayManager.navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => isVideoCall
                  ? VideoCallPage(
                      callId: callData['callId'],
                      id: userId!,
                      isCaller: false,
                      callInitiatorId:
                          callData['senderId'] ?? callData['callerId'],
                      onSignOut: restartApp,
                    )
                  : CallPage(
                      callId: callData['callId'],
                      id: userId!,
                      isCaller: false,
                      callInitiatorId:
                          callData['senderId'] ?? callData['callerId'],
                      onSignOut: restartApp,
                    ),
            ),
          );

          _signalingService.clearIncomingCall(userId!);
        },
        () {
          _signalingService.clearIncomingCall(userId!);
          _callService.declinedCall(callData['callId']);
          _signalingService.listenForCallEnd(
              callData['callId'], _handleCallEnd);
        },
      );
      // ✅ Listen for Call Cancellation (Fixes the issue)
      _signalingService.listenForCallEnd(callData['callId'], () {
        print("🚨 Call was canceled before being answered!");
        CallOverlayManager
            .removeOverlay(); // ✅ Automatically remove overlay if call is canceled
      });
    });
  }

  void _handleCallEnd() {
    Navigator.pop(context);
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
          resizeToAvoidBottomInset: false,
          body: Center(child: CircularProgressIndicator()),
        ),
        theme: ThemeData(
          scaffoldBackgroundColor:
              Colors.white, // Sets default background to white
        ),
      );
    }

    if (jwtToken == null || jwtToken!.isEmpty || userId == null) {
      return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: CallOverlayManager.navigatorKey,
          home: UserSignInPage(onSignOut: restartApp));
      // home: GetUserDetailsStep2(
      //     userDetails: new UserDetails(userInterestedStates: []),
      //     userId: "",
      //     jwtToken: "jwtToken",
      //     firebaseCustomToken: "firebaseCustomToken",
      //     onSignOut: restartApp));
    }

    switch (role?.toLowerCase()) {
      case "user":
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: CallOverlayManager.navigatorKey,
          home: BasePage(username: userId!, onSignOut: restartApp),
        );
      case "counsellor":
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: CallOverlayManager.navigatorKey,
          home:
              CounsellorBasePage(onSignOut: restartApp, counsellorId: userId!),
        );
      case "admin":
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: AdminBasePage(onSignOut: restartApp, adminId: userId!),
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
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
