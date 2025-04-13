import 'dart:io';
import 'package:ProCounsellor/main_service.dart';
import 'package:ProCounsellor/screens/dashboards/userDashboard/chatting_page.dart';
import 'package:ProCounsellor/screens/newCallingScreen/agora_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
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


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // Must match the one used in FCM backend
  'High Importance Notifications',
  description: 'This channel is used for incoming calls',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("📩 FCM received (background): ${message.data}");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (message.data['type'] == 'incoming_call') {
    await MainService().showNativeIncomingCall(
      callerName: message.data['callerName'],
      callType: message.data['callType'],
      channelId: message.data['channelId'],
    );
  }
}

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

  await FirebaseMessaging.instance.setAutoInitEnabled(true); // optional safety

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await _setupFlutterNotifications();
  await requestPermissions();
  await requestNotificationPermission();
  _initFCM();

  runApp(AppRoot());
}

Future<void> _setupFlutterNotifications() async {
  // ✅ Create Android notification channel
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // ✅ Android setup
  const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

  // ✅ iOS (Darwin) setup
  final DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  // ✅ Combine platform settings
  final InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      print("🔔 Notification tapped (iOS/Android): ${response.payload}");
    },
  );
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
    _setupCallKitListeners();
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

         if(role == "user"){
            FirestoreService.saveFCMTokenUser(userId!);
          }
          else if(role == "counsellor"){
            FirestoreService.saveFCMTokenCounsellor(userId!);
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
      MainService _mainService = MainService();
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("📩 FCM received in foreground: ${message.data}");
        if (message.data['type'] == 'incoming_call') {
          _mainService.showNativeIncomingCall(
            callerName: message.data['callerName'],
            callType: message.data['callType'],
            channelId: message.data['channelId'],
          );
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
        print("📩 FCM received in 1foreground: ${message.data}");
        if (message.data['type'] == 'incoming_call') {
          _mainService.showNativeIncomingCall(
            callerName: message.data['callerName'],
            callType: message.data['callType'],
            channelId: message.data['channelId'],
          );
        }

        if (message.data['type'] == 'chat') {
          final senderId = message.data['senderId'];

          if(role == "user"){
            if(await _mainService.senderIsUser(senderId)){
              final user = await _mainService.getUserFromUserId(senderId);
              Navigator.push(
                navigatorKey.currentContext!,
                MaterialPageRoute(
                  builder: (_) => UserToUserChattingPage(
                    itemName: '${user['firstName']} ${user['lastName']}',
                    userId: userId!,
                    userId2: senderId,
                    onSignOut: restartApp,
                  ),
                ),
              );
            }
            else{
              final counsellor = await _mainService.getCounsellorFromCounsellorId(senderId);
              Navigator.push(
                navigatorKey.currentContext!,
                MaterialPageRoute(
                  builder: (_) => UserChattingPage(
                    itemName: '${counsellor['firstName']} ${counsellor['lastName']}',
                    userId: userId!,
                    counsellorId: senderId,
                    onSignOut: restartApp,
                  ),
                ),
              );
            }
          }
          else if(role == "counsellor"){
              final user = await _mainService.getUserFromUserId(senderId);
              Navigator.push(
              navigatorKey.currentContext!,
              MaterialPageRoute(
                builder: (_) => CounsellorChattingPage(
                  itemName: '${user['firstName']} ${user['lastName']}',
                  userId: senderId,
                  photo: user['photo'],
                  counsellorId: senderId,
                  onSignOut: restartApp,
                ),
              ),
            );
          }
        }
      });

      FirebaseMessaging.instance.getInitialMessage().then((message) async {
        print("📩 FCM received in sss: ${message}");
        if (message?.data['type'] == 'incoming_call') {
          _mainService.showNativeIncomingCall(
            callerName: message?.data['callerName'],
            callType: message?.data['callType'],
            channelId: message?.data['channelId'],
          );
        }
        else if (message?.data['type'] == 'chat') {
          final senderId = message?.data['senderId'];

          // 🔁 Wait until the first frame is drawn before navigating
          if(role == "user"){
            if(await _mainService.senderIsUser(senderId)){
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.push(
                navigatorKey.currentContext!,
                MaterialPageRoute(
                  builder: (_) => UserToUserChattingPage(
                    itemName: senderId,
                    userId: userId!,
                    userId2: senderId,
                    onSignOut: restartApp,
                  ),
                ),
                );
              });
            }
            else{
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.push(
                navigatorKey.currentContext!,
                MaterialPageRoute(
                  builder: (_) => UserChattingPage(
                    itemName: senderId,
                    userId: userId!,
                    counsellorId: senderId,
                    onSignOut: restartApp,
                  ),
                ),
              );
              });
            }
          }
          else if(role == "counsellor"){
             WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.push(
              navigatorKey.currentContext!,
              MaterialPageRoute(
                builder: (_) => CounsellorChattingPage(
                  itemName: senderId,
                  userId: senderId,
                  counsellorId: senderId,
                  onSignOut: restartApp,
                ),
              ),
            );
             });
          }
        }
      });
    }

  void _setupCallKitListeners() {
  print("ak");
  FlutterCallkitIncoming.onEvent.listen((event) async {
    final data = event?.body;

    switch (event?.event) {
      case Event.actionCallAccept:
        final callType = data?['extra']?['callType'] ?? 'audio';
        final channelId = data?['extra']?['channelId'];
        final callerName = data?['extra']?['callerName'];

        print("📞 Call Accepted → $callType");

        // Navigate based on type
        if (navigatorKey.currentState?.context != null) {
          final context = navigatorKey.currentState!.context;

          Widget screen = callType == "video"
              ? VideoCallScreen(
                  isCaller: false,
                  callerId: callerName,
                  receiverId: userId!,
                  channelId: channelId,
                  onSignOut: restartApp,
                )
              : AudioCallScreen(
                  isCaller: false,
                  callerId: callerName,
                  receiverId: userId!,
                  channelId: channelId,
                  onSignOut: restartApp,
                );

          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          );
        }
        break;

      case Event.actionCallDecline:
        final channelId = data?['extra']?['channelId'];
        print("📵 Call Declined → $channelId");
        if (channelId != null) {
          AgoraService.declinedCall(channelId);
        }
        break;

      case Event.actionCallEnded:
        print("📴 Call Ended");
        break;

      default:
        print("📱 CallKit Event: ${event?.event}");
    }
  });
}


   /// ✅ **Restart App (Logout & Clear Data)**
  Future<void> restartApp() async {
    print("🚪 Logging out...");
 
    // Step 1: Clear secure storage
    await storage.deleteAll();
    final remaining = await storage.readAll();
    print("🧼 Remaining after deleteAll(): $remaining");
 
    // Step 2: Navigate to login screen and clear all backstack
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
