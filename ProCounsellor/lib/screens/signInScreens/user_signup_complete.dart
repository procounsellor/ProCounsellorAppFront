import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ProCounsellor/screens/dashboards/userDashboard/base_page.dart';
import 'package:video_player/video_player.dart';
import '../newCallingScreen/save_fcm_token.dart';

final storage = FlutterSecureStorage();

class SignUpCompleteScreen extends StatefulWidget {
  final String userId;
  final String jwtToken;
  final String firebaseCustomToken;
  final Future<void> Function() onSignOut;

  const SignUpCompleteScreen({
    required this.userId,
    required this.jwtToken,
    required this.firebaseCustomToken,
    required this.onSignOut,
  });

  @override
  State<SignUpCompleteScreen> createState() => _SignUpCompleteScreenState();
}

class _SignUpCompleteScreenState extends State<SignUpCompleteScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/images/signin.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
      });

    _storeCredentials();
  }

  Future<void> _storeCredentials() async {
    await storage.write(key: "role", value: "user");
    await storage.write(key: "jwtToken", value: widget.jwtToken);
    await storage.write(key: "userId", value: widget.userId);
    await FirestoreService.saveFCMTokenUser(widget.userId);

    await FirebaseAuth.instance
        .signInWithCustomToken(widget.firebaseCustomToken);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /// 🔷 Centered Video
          SizedBox(
            height: screenHeight * 0.4,
            width: double.infinity,
            child: _controller.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),

          const SizedBox(height: 16),

          /// ✅ All Done Text
          const Text(
            "SignUp Success!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 16),

          /// 🟩 Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BasePage(
                        username: widget.userId,
                        onSignOut: widget.onSignOut,
                      ),
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent[700],
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Go to Dashboard",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
