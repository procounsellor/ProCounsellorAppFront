import 'package:ProCounsellor/services/api_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MainService {
  Future<void> showNativeIncomingCall({
    required String callerName,
    required String callType,
    required String channelId,
    required String receiverName
  }) async {
    final uuid = const Uuid().v4();
    await _saveCallUuidToFirestore(receiverName, uuid);

    final params = CallKitParams(
      id: uuid,
      nameCaller: callerName,
      appName: 'ProCounsellor',
      avatar: 'https://yourdomain.com/photo.png',
      handle: 'Caller',
      type: callType == 'video' ? 1 : 0,
      duration: 60000,
      textAccept: 'Answer',
      textDecline: 'Decline',
      extra: {
        'channelId': channelId,
        'callType': callType,
        'callerName': callerName,
        'receiverName': receiverName
      },
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: null,
        backgroundColor: '#0955fa',
        backgroundUrl: null,
        actionColor: '#4CAF50',
        isShowFullLockedScreen: true,
      ),
      ios: const IOSParams(
        iconName: 'CallKitIcon',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 2,
        maximumCallsPerCallGroup: 1,
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);

    print("📲 Showing call UI: $callerName → $callType → $channelId");

    // ✅ Listen for call cancellation before pickup
    _listenForCallerCancel(channelId);

    // ✅ Auto-dismiss the call if unanswered in 60 seconds
    Future.delayed(const Duration(seconds: 60), () async {
      final activeCalls = await FlutterCallkitIncoming.activeCalls();
      if (activeCalls.any((call) => call['id'] == uuid)) {
        print("⏳ Auto-ending unanswered call...");
        await FlutterCallkitIncoming.endCall(uuid);
      }
    });
  }

  void _listenForCallerCancel(String channelId) {
  final ref = FirebaseDatabase.instance.ref().child("calls").child(channelId);
  ref.onValue.listen((event) {
    final data = event.snapshot.value;
    if (data != null && data is Map && data['status'] == 'Missed Call') {
      print("📴 Caller cancelled before pickup.");
      FlutterCallkitIncoming.endAllCalls();
    }
  });
}

  /// 🔁 Update currentCallUUID for user or counsellor
  Future<void> _saveCallUuidToFirestore(String userId, String uuid) async {
    final firestore = FirebaseFirestore.instance;

    final userDoc = await firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      await firestore.collection('users').doc(userId).update({
        'currentCallUUID': uuid,
      });
      print("✅ currentCallUUID saved in users");
      return;
    }

    final counsellorDoc = await firestore.collection('counsellors').doc(userId).get();
    if (counsellorDoc.exists) {
      await firestore.collection('counsellors').doc(userId).update({
        'currentCallUUID': uuid,
      });
      print("✅ currentCallUUID saved in counsellors");
      return;
    }

    print("⚠️ User not found in either users or counsellors collection.");
  }

  Future<bool> senderIsUser(String senderId) async {
  final firestore = FirebaseFirestore.instance;

  try {
    // 🔍 Check in `users` collection
    final userDoc = await firestore.collection('users').doc(senderId).get();
    if (userDoc.exists) return true;

    // 🔍 Else, check in `counsellors` collection
    final counsellorDoc = await firestore.collection('counsellors').doc(senderId).get();
    if (counsellorDoc.exists) return false;

    // 🟡 Neither found — optional: handle this case
    print("⚠️ Sender ID not found in either collection.");
    return false;
  } catch (e) {
    print("❌ Error checking sender type: $e");
    return false;
  }
}

Future<Map<String, dynamic>> getUserFromUserId(String userId) async {
  final userRes = await http.get(Uri.parse('${ApiUtils.baseUrl}/api/user/$userId'));
  return json.decode(userRes.body);
}

Future<Map<String, dynamic>> getCounsellorFromCounsellorId(String counsellorId) async {
  final counsellorRes = await http.get(Uri.parse('${ApiUtils.baseUrl}/api/counsellor/$counsellorId'));
  return json.decode(counsellorRes.body);
}
}