import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart';

import 'agora_service.dart';

const String appId = "118a5a8d61b242fdab4fc18f7f6c5479";

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
    required this.onSignOut
  }) : super(key: key);

  @override
  _AudioCallScreenState createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  late RtcEngine agoraEngine;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _joined = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _callAnswered = false; // ✅ Track if call is answered
  Timer? _ringingTimer;

  Timer? _callTimer;
  int _callDurationInSeconds = 0;
  String _formattedDuration = "00:00";

  bool _isEnding = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
    if (widget.isCaller) _playRingtone();
  }

  Future<void> _initAgora() async {
    agoraEngine = createAgoraRtcEngine();

    await agoraEngine.initialize(
      RtcEngineContext(
        appId: appId,
        channelProfile: kIsWeb
            ? ChannelProfileType.channelProfileLiveBroadcasting
            : ChannelProfileType.channelProfileCommunication,
      ),
    );

    agoraEngine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() => _joined = true);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          _stopRingtone();
          _startCallTimer();
          _callPicked();
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          setState(() => _joined = false);
          Navigator.pop(context);
        },
      ),
    );

    // agoraEngine.registerEventHandler(
    //   RtcEngineEventHandler(
    //     onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
    //       setState(() => _joined = true);
    //     },
    //     onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
    //       setState(() => _joined = false);
    //       Navigator.pop(context);
    //     },
    //   ),
    // );

    String? token = await AgoraService.fetchAgoraToken(widget.channelId, widget.isCaller ? 1 : 2);
    if (token != null) {
      await agoraEngine.joinChannel(
        token: token,
        channelId: widget.channelId,
        uid: widget.isCaller ? 1 : 2,
        options: const ChannelMediaOptions(
          autoSubscribeAudio: true,
          autoSubscribeVideo: false,
        ),
      );
    }

    // if (widget.isCaller) {
    //   FirebaseDatabase.instance
    //       .ref("agora_call_signaling")
    //       .child(widget.receiverId)
    //       .onValue
    //       .listen((event) {
    //     if (!event.snapshot.exists && mounted) {
    //       print("📞 Receiver cut the call. Ending on caller side.");
    //       _endCall(); // 💥 End the call on caller side
    //     }
    //   });
    // }
  }

  void _startCallTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _callDurationInSeconds++;
        final minutes = (_callDurationInSeconds ~/ 60).toString().padLeft(2, '0');
        final seconds = (_callDurationInSeconds % 60).toString().padLeft(2, '0');
        _formattedDuration = "$minutes:$seconds";
      });
    });
  }

  void _callPicked(){
    AgoraService.pickedCall(widget.channelId);
  }

  void _stopCallTimer() {
    _callTimer?.cancel();
    _callDurationInSeconds = 0;
    _formattedDuration = "00:00";
  }

  void _playRingtone() async {
    print("🔔 Starting Ringer...");
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('sounds/ringtone.mp3'));

    // 🔹 Auto stop ringer after 1 minute if call is not answered
    _ringingTimer = Timer(Duration(minutes: 1), () {
      if (!_callAnswered) {
        print(
            "⏳ Call not answered. Stopping ringer and cutting the call after 1 minute.");
        _endCall();
      }
    });
  }

  void _stopRingtone() {
    if (!_callAnswered) {
      print("🔕 Stopping Ringer...");
      _callAnswered = true;
      _audioPlayer.stop();
      _ringingTimer?.cancel();
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    agoraEngine.muteLocalAudioStream(_isMuted);
  }

  void _toggleSpeaker() {
    if (!kIsWeb) {
      setState(() {
        _isSpeakerOn = !_isSpeakerOn;
      });
      agoraEngine.setEnableSpeakerphone(_isSpeakerOn);
    }
  }

  Future<void> _endCall() async {
    if (_isEnding) return;

    _isEnding = true;
    await AgoraService.endCall(widget.channelId);
    _stopCallTimer();
    _stopRingtone();
    FirebaseDatabase.instance.ref("agora_call_signaling").child(widget.receiverId).remove();
    agoraEngine.leaveChannel();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    agoraEngine.leaveChannel();
    agoraEngine.release();
    _stopCallTimer();
    _stopRingtone();
    _audioPlayer.dispose();
    _ringingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _joined
                ? "Audio Call with ${widget.isCaller ? widget.receiverId : widget.callerId}"
                : "Calling...",
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            if (_joined)
              Text(
                _formattedDuration,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _callButton(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  label: _isMuted ? 'Unmute' : 'Mute',
                  onPressed: _toggleMute,
                ),
                const SizedBox(width: 20),
                _callButton(
                  icon: Icons.call_end,
                  label: 'End',
                  color: Colors.red,
                  onPressed: _endCall,
                ),
                const SizedBox(width: 20),
                if (!kIsWeb)
                  _callButton(
                    icon: _isSpeakerOn ? Icons.volume_up : Icons.hearing,
                    label: _isSpeakerOn ? 'Speaker' : 'Earpiece',
                    onPressed: _toggleSpeaker,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _callButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color color = Colors.white,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: color,
          child: IconButton(
            icon: Icon(icon, color: Colors.black),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}
