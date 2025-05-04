import UIKit
import Flutter
import Firebase
import UserNotifications
import PushKit
import flutter_callkit_incoming
import FirebaseFirestore

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate {
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()

    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()

    GeneratedPluginRegistrant.register(with: self)

    // Register for VoIP PushKit
    let voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
    voipRegistry.delegate = self
    voipRegistry.desiredPushTypes = [.voIP]

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle foreground notification display
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler([.alert, .badge, .sound])
  }

  func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
    let deviceToken = credentials.token.map { String(format: "%02x", $0) }.joined()
    print("📱 VoIP Token: \(deviceToken)")

    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(deviceToken)

    let userDefaults = UserDefaults.standard
    userDefaults.set(deviceToken, forKey: "flutter.cached_voip_token")
  }


  // ✅ PushKit: Invalidate Token
  func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
    print("🔕 VoIP token invalidated")
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
  }
  
  func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
    let dictionary = payload.dictionaryPayload

    // 🔍 Check for call cancellation
    if let pushType = dictionary["type"] as? String, pushType == "cancel_call" {
        print("📴 VoIP Push: Cancel call received via PushKit")
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.endAllCalls()
        completion()
        return
    }

    // 🆔 Save UUID in Firestore
    if let receiverId = (dictionary["extra"] as? [String: Any])?["receiverName"] as? String,
       let callUUID = dictionary["id"] as? String {

        print("📞 Received callUUID: \(callUUID) for receiverId: \(receiverId)")
        saveCallUUIDToFirestore(receiverId: receiverId, uuid: callUUID)
    }

    // Show call UI
    var info = [String: Any?]()
    info["id"] = dictionary["id"] ?? UUID().uuidString
    info["nameCaller"] = dictionary["nameCaller"] ?? "Unknown"
    info["handle"] = dictionary["handle"] ?? "Caller"
    info["type"] = dictionary["type"] ?? 0
    info["textAccept"] = dictionary["textAccept"] ?? "Answer"
    info["textDecline"] = dictionary["textDecline"] ?? "Decline"
    info["textMissedCall"] = dictionary["textMissedCall"] ?? "Missed call"
    info["textCallback"] = dictionary["textCallback"] ?? "Call back"
    info["extra"] = dictionary["extra"] ?? [:]
    info["ios"] = dictionary["ios"] ?? [
        "iconName": "CallKitIcon",
        "handleType": "generic",
        "supportsVideo": true,
        "maximumCallGroups": 2,
        "maximumCallsPerCallGroup": 1
    ]

    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(
        flutter_callkit_incoming.Data(args: info),
        fromPushKit: true
    )

    completion()
}
func saveCallUUIDToFirestore(receiverId: String, uuid: String) {
    let usersRef = Firestore.firestore().collection("users").document(receiverId)
    let counsellorsRef = Firestore.firestore().collection("counsellors").document(receiverId)

    usersRef.getDocument { (doc, error) in
        if let doc = doc, doc.exists {
            usersRef.updateData(["currectCallUUID": uuid]) { error in
                if let error = error {
                    print("❌ Error updating user UUID: \(error)")
                } else {
                    print("✅ UUID updated for user")
                }
            }
        } else {
            counsellorsRef.getDocument { (doc, error) in
                if let doc = doc, doc.exists {
                    counsellorsRef.updateData(["currectCallUUID": uuid]) { error in
                        if let error = error {
                            print("❌ Error updating counsellor UUID: \(error)")
                        } else {
                            print("✅ UUID updated for counsellor")
                        }
                    }
                } else {
                    print("⚠️ User not found in either collection")
                }
            }
        }
    }
}
}
