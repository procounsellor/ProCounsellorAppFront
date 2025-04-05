import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_database/firebase_database.dart';
import 'agora_service.dart';

const String appId = "118a5a8d61b242fdab4fc18f7f6c5479";

class VideoCallScreen extends StatefulWidget {
  final String channelId;
  final bool isCaller;
  final String callerId;
  final String receiverId;
  final Future<void> Function() onSignOut;

  const VideoCallScreen({
    Key? key,
    required this.channelId,
    required this.isCaller,
    required this.callerId,
    required this.receiverId,
    required this.onSignOut
  }) : super(key: key);

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late RtcEngine agoraEngine;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _joined = false;
  bool _isMuted = false;
  bool _isVideoDisabled = false;
  bool _callAnswered = false;
  bool _isEnding = false;
  Timer? _ringingTimer;
  Timer? _callTimer;
  int _callDurationInSeconds = 0;
  String _formattedDuration = "00:00";
  int? _remoteUid;

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
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    await agoraEngine.enableVideo();
    await agoraEngine.startPreview();

    agoraEngine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() => _joined = true);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          _stopRingtone();
          _startCallTimer();
          _callPicked();//needs to be created
          setState(() {
            _remoteUid = remoteUid;
          });
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
          autoSubscribeVideo: true,
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
    //       _endCall();
    //     }
    //   });
    // }
  }

  void _playRingtone() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('sounds/ringtone.mp3'));
    _ringingTimer = Timer(Duration(minutes: 1), () {
      if (!_callAnswered) {
        print("⏳ Call not answered. Ending after 1 minute.");
        _endCall();
      }
    });
  }

  void _stopRingtone() {
    if (!_callAnswered) {
      _callAnswered = true;
      _audioPlayer.stop();
      _ringingTimer?.cancel();
    }
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

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    agoraEngine.muteLocalAudioStream(_isMuted);
  }

  void _toggleVideo() {
    setState(() => _isVideoDisabled = !_isVideoDisabled);
    agoraEngine.muteLocalVideoStream(_isVideoDisabled);
  }

  void _switchCamera() {
    agoraEngine.switchCamera();
  }

  Future<void> _endCall() async {
    if (_isEnding) return;

    await AgoraService.endCall(widget.channelId);
    _isEnding = true;
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
    _audioPlayer.dispose();
    _ringingTimer?.cancel();
    _stopCallTimer();
    _stopRingtone();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _joined && _remoteUid != null
              ? AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: agoraEngine,
                    canvas: VideoCanvas(uid: _remoteUid),
                  ),
                )
              : const Center(child: CircularProgressIndicator()),

               // Picture-in-picture local video
              Positioned(
                bottom: 100,
                right: 16,
                child: SizedBox(
                  width: 120,
                  height: 160,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: agoraEngine,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    ),
                  ),
                ),
              ),

          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Text(
                    _joined
                        ? "Video Call with ${widget.isCaller ? widget.receiverId : widget.callerId}"
                        : "Calling...",
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  if (_joined)
                    Text(
                      _formattedDuration,
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _controlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    label: _isMuted ? 'Unmute' : 'Mute',
                    onPressed: _toggleMute,
                  ),
                  _controlButton(
                    icon: Icons.call_end,
                    label: 'End',
                    onPressed: _endCall,
                    color: Colors.red,
                  ),
                  _controlButton(
                    icon: _isVideoDisabled ? Icons.videocam_off : Icons.videocam,
                    label: _isVideoDisabled ? 'Video Off' : 'Video On',
                    onPressed: _toggleVideo,
                  ),
                  _controlButton(
                    icon: Icons.switch_camera,
                    label: 'Switch',
                    onPressed: _switchCamera,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color color = Colors.white,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundColor: color,
          radius: 28,
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
