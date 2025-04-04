import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:my_app/screens/newCallingScreen/agora_service.dart';

class AudioCallScreen extends StatefulWidget {
  final String channelId;
  final bool isCaller;
  final String callerId;
  final String receiverId;
  final Future<void> Function() onSignOut;

  const AudioCallScreen({
    Key? key,
    required this.channelId,
    required this.isCaller,
    required this.callerId,
    required this.receiverId,
    required this.onSignOut,
  }) : super(key: key);

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  String? _token;
  bool _isLoading = true;
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    // No need to explicitly set platform unless you need advanced customization
    _fetchToken();
    //_setupAutoDecline();
  }


  Future<void> _fetchToken() async {
    final token = await AgoraService.fetchAgoraToken(
        widget.channelId, widget.isCaller ? 1 : 2);

    if (token == null) {
      print("❌ Failed to fetch Agora token.");
      if (mounted) Navigator.pop(context);
      return;
    }

    final url = 'http://localhost:8080/agora/audio_call.html'
        '?token=$token'
        '&channelId=${widget.channelId}'
        '&uid=${widget.isCaller ? 1 : 2}'
        '&callType=audio';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url));

    setState(() {
      _token = token;
      _isLoading = false;
    });
  }


  void _setupAutoDecline() {
    if (widget.isCaller) {
      FirebaseDatabase.instance
          .ref("agora_call_signaling")
          .child(widget.receiverId)
          .onValue
          .listen((event) {
        if (!event.snapshot.exists && mounted) {
          print("📞 Call was declined or ended.");
          Navigator.pop(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _token == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
