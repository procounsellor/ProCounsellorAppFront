import 'dart:io';
import 'package:ProCounsellor/main_service.dart';
import 'package:ProCounsellor/screens/dashboards/userDashboard/chatting_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ProCounsellor/screens/newCallingScreen/save_fcm_token.dart';
import 'package:ProCounsellor/screens/signInScreens/user_signin_page.dart';
import 'firebase_options.dart';
import 'package:ProCounsellor/screens/dashboards/adminDashboard/admin_base_page.dart';
import 'package:ProCounsellor/screens/dashboards/userDashboard/base_page.dart';
import 'package:ProCounsellor/screens/dashboards/counsellorDashboard/counsellor_base_page.dart';
import 'package:permission_handler/permission_handler.dart';

import 'screens/dashboards/counsellorDashboard/counsellor_chatting_page.dart';
import 'screens/dashboards/userDashboard/Friends/UserToUserChattingPage.dart';
import 'screens/newCallingScreen/audio_call_screen.dart';
import 'screens/newCallingScreen/video_call_screen.dart';

// Initialize secure storage
final storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);

@pragma('vm:entry-point') // Required for background messaging on Android
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('🔕 Background FCM: ${message.data}');

  if (message.data['type'] == 'incoming_call') {
      MainService().showNativeIncomingCall(
        callerName: message.data['callerName'],
        callType: message.data['callType'],
        channelId: message.data['channelId'],
        receiverName: message.data['receiverName'],
      );
    }
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel callChannel = AndroidNotificationChannel(
  'high_importance_channel', // ID must match backend & CallKit setup
  'Call Notifications',
  description: 'Channel for incoming call notifications',
  importance: Importance.high,
  playSound: true,
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
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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
    if (Platform.isAndroid) {
      final status = await Permission.phone.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        // Show message to user or fallback
        print("Phone permission denied. Cannot show call screen.");
        return;
      }
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
  String? jwtToken;
  String? userId;
  String? role;
  bool isLoading = true;
  Widget? redirectPage;
  MainService _mainService = MainService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
    listenCallKitEvents();
    listenFCMMessages();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void listenCallKitEvents() {
    FlutterCallkitIncoming.onEvent.listen((event) async {
      final data = event?.body;
      final eventType = event?.event;
      final callType = data?['extra']?['callType'] ?? 'audio';
      final channelId = data?['extra']?['channelId'];
      final callerName = data?['extra']?['callerName'];
      final receiverName = data?['extra']?['receiverName'];

      print("👉 callType: $callType");
      print("👉 channelId: $channelId");
      print("👉 callerName: $callerName");
      print("👉 userId (receiverId): $userId");

      if (eventType == Event.actionCallAccept) {
        navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (_) => callType == 'audio'
            ? AudioCallScreen(
                channelId: channelId!,
                isCaller: false,
                callerId: callerName,
                receiverId: receiverName,
                onSignOut: restartApp,
              )
            : VideoCallScreen(
                channelId: channelId!,
                isCaller: false,
                callerId: callerName,
                receiverId: receiverName,
                onSignOut: restartApp,
              ),
        ));
      } else if (eventType == Event.actionCallDecline ||
          eventType == Event.actionCallEnded) {
        await FlutterCallkitIncoming.endAllCalls();
      }
    });
}

Future<String?> fetchChannelId(String receiverId) async {
  final snapshot = await FirebaseDatabase.instance
      .ref("agora_call_signaling")
      .child(receiverId)
      .get();

  if (snapshot.exists) {
    final data = snapshot.value as Map<dynamic, dynamic>;
    return data['channelId']?.toString(); // ✅ safely extract
  } else {
    print("❌ No signaling data found for $receiverId");
    return null;
  }
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

      if (role == "user") {
        FirestoreService.saveFCMTokenUser(userId!);
      } else if (role == "counsellor") {
        FirestoreService.saveFCMTokenCounsellor(userId!);
      }

      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
        if (initialMessage != null && initialMessage.data['type'] == 'incoming_call') {
          _mainService.showNativeIncomingCall(
            callerName: initialMessage.data['callerName'],
            channelId: initialMessage.data['channelId'],
            callType: initialMessage.data['callType'],
            receiverName: initialMessage.data['receiverName'],
          );
        }

        final calls = await FlutterCallkitIncoming.activeCalls();
        for (var call in calls) {
          final isAccepted = call['isAccepted'] ?? false;
          final callType = call['extra']?['callType'];
          //final channelId = call['extra']?['channelId'];
          final callerName = call['extra']?['callerName'];
          final receiverName = call['extra']?['receiverName'];
          final channelId = await fetchChannelId(receiverName);
          print("channelId" + channelId!);

          if (isAccepted &&
            call['extra'] != null &&
            callerName != null &&
            receiverName != null &&
            channelId != null) {
            print("✅ Cold start call accept — redirecting!" + channelId);

            redirectPage = callType == 'video'
                ? VideoCallScreen(
                    channelId: channelId,
                    isCaller: false,
                    callerId: callerName,
                    receiverId: receiverName,
                    onSignOut: restartApp,
                  )
                : AudioCallScreen(
                    channelId: channelId,
                    isCaller: false,
                    callerId: callerName,
                    receiverId: receiverName,
                    onSignOut: restartApp,
                  );
            break;
          }
        }

        await flutterLocalNotificationsPlugin.initialize(
          const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          ),
        );

        await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(callChannel);
    } catch (e) {
      print("❌ Error reading secure storage: $e");
    }

    setState(() {
      isLoading = false;
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print("🔁 FCM Token refreshed: $newToken");
      if (role == "user") {
        FirestoreService.saveFCMTokenUser(userId!);
      } else if (role == "counsellor") {
        FirestoreService.saveFCMTokenCounsellor(userId!);
      }
    });
  }

  void listenFCMMessages() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📩 FCM in foreground: ${message.data}");

    if (message.data['type'] == 'incoming_call') {
      _mainService.showNativeIncomingCall(
        callerName: message.data['callerName'],
        callType: message.data['callType'],
        channelId: message.data['channelId'],
        receiverName: message.data['receiverName'],
      );
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("📩 Tapped notification: ${message.data}");

    if (message.data['type'] == 'incoming_call') {
      _mainService.showNativeIncomingCall(
        callerName: message.data['callerName'],
        callType: message.data['callType'],
        channelId: message.data['channelId'],
        receiverName: message.data['receiverName'],
      );
    }
  });
}

  
  Future<void> restartApp() async {
    print("🚪 Logging out...");

    try {
      // Step 1: Delete secure storage
      await storage.deleteAll();
      final remaining = await storage.readAll();
      print("🧼 Remaining after deleteAll(): $remaining");

      // Step 2: Delete FCM Token
      await FirebaseMessaging.instance.deleteToken();
      print("🔥 FCM token deleted");
    } catch (e) {
      print("⚠️ Error during logout cleanup: $e");
    }

    // Step 4: Navigate to login screen and clear backstack
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => UserSignInPage(onSignOut: restartApp),
      ),
      (route) => false,
    );
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

  if (redirectPage != null) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: redirectPage!,
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
        home:
            CounsellorBasePage(onSignOut: restartApp, counsellorId: userId!),
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
                Text("Invalid Role. Please contact support.",
                    style: TextStyle(fontSize: 18, color: Colors.red)),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: restartApp,
                  child: Text("Go to Login"),
                  style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
                ),
              ],
            ),
          ),
        ),
      );
  }
}
}
