import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:my_app/screens/dashboards/call_layover_manager.dart';
import 'package:my_app/services/call_service.dart';
import 'package:my_app/services/firebase_signaling_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class CallPage extends StatefulWidget {
  final String callId;
  final String id;
  final bool isCaller;
  final String callInitiatorId;

  CallPage(
      {required this.callId,
      required this.id,
      required this.isCaller,
      required this.callInitiatorId});

  @override
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final FirebaseSignalingService _signalingService = FirebaseSignalingService();
  final CallService _callService = CallService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  RTCPeerConnection? _peerConnection;
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  String? callerName;
  String? callerPhoto;
  bool _isSpeaking = false;
  bool _callAnswered = false; // ✅ Track if call is answered
  Timer? _ringingTimer;

  @override
  void initState() {
    super.initState();
    _fetchCallerDetails();

    _initWebRTC();
    _signalingService.listenForCallEnd(widget.callId, _handleCallEnd);

    if (widget.isCaller) {
      _startRinging(); // ✅ Start ringing if initiating call
    }
  }

  Future<void> _fetchCallerDetails() async {
    String baseUrl = "http://localhost:8080/api";
    String userUrl = "$baseUrl/user/${widget.callInitiatorId}";
    String counsellorUrl = "$baseUrl/counsellor/${widget.callInitiatorId}";

    try {
      final userResponse = await http.get(Uri.parse(userUrl));
      if (userResponse.statusCode == 200 && userResponse.body.isNotEmpty) {
        final data = json.decode(userResponse.body);
        setState(() {
          callerName = "${data['firstName']} ${data['lastName']}";
          callerPhoto = data['photo'];
        });
        return;
      }

      final counsellorResponse = await http.get(Uri.parse(counsellorUrl));
      if (counsellorResponse.statusCode == 200 &&
          counsellorResponse.body.isNotEmpty) {
        final data = json.decode(counsellorResponse.body);
        setState(() {
          callerName = "${data['firstName']} ${data['lastName']}";
          callerPhoto = data['photoUrl'];
        });
      }
    } catch (e) {
      print("Error fetching caller details: $e");
    }
  }

  Future<void> _initWebRTC() async {
    print(widget.callId);
    print("I am getting a call from : " + widget.callInitiatorId.toString());
    print(widget.id);
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    Map<String, dynamic> config = {
      "iceServers": [
        {"urls": "stun:stun.l.google.com:19302"},
      ]
    };

    _peerConnection = await createPeerConnection(config);

    // ✅ Request both audio & video if needed
    MediaStream localStream = await navigator.mediaDevices
        .getUserMedia({'audio': true, 'video': false});

    _localRenderer.srcObject = localStream; // Assign local stream

    for (var track in localStream.getTracks()) {
      _peerConnection!.addTrack(track, localStream);
    }

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      _callService.sendIceCandidate(
          widget.callId, candidate.toMap(), widget.id);
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _stopRinging(); // ✅ Stop ringing when remote track arrives (call answered)
        print("🔹 Remote track received!");
        _remoteRenderer.srcObject = event.streams[0]; // ✅ Assign remote stream
      }
    };

    if (widget.isCaller) {
      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      _callService.sendOffer(widget.callId, offer);
    } else {
      _signalingService.listenForOffer(widget.callId, (offer) async {
        if (offer.isNotEmpty) {
          await _peerConnection!
              .setRemoteDescription(RTCSessionDescription(offer, "offer"));
          RTCSessionDescription answer = await _peerConnection!.createAnswer();
          await _peerConnection!.setLocalDescription(answer);
          _callService.sendAnswer(widget.callId, answer.sdp);
        } else {
          print("Received an empty offer");
        }
      });
    }

    _signalingService.listenForAnswer(widget.callId, _peerConnection!,
        (answerString) async {
      try {
        RTCSessionDescription answer =
            RTCSessionDescription(answerString, "answer");

        if (_peerConnection != null) {
          await _peerConnection!.setRemoteDescription(answer);
          print("✅ Remote description set successfully.");
          _stopRinging(); // ✅ Stop ringing when answer received
        } else {
          print("⚠️ Peer connection is null when setting remote description.");
        }
      } catch (e) {
        print("❌ Error setting remote description: $e");
      }
    });

    _signalingService.listenForIceCandidates(widget.callId, (candidate) async {
      if (_peerConnection == null) {
        print("Peer connection is null. Cannot add ICE candidate.");
        return;
      }

      RTCSessionDescription? remoteDesc =
          await _peerConnection!.getRemoteDescription();
      if (remoteDesc == null) {
        print("Remote description is null. Storing ICE candidate for later.");

        // Delay adding ICE candidates until remote description is set
        Future.delayed(Duration(seconds: 1), () async {
          RTCSessionDescription? updatedRemoteDesc =
              await _peerConnection!.getRemoteDescription();
          if (updatedRemoteDesc != null) {
            await _addIceCandidate(candidate);
          } else {
            print("Remote description is still null. Skipping ICE candidate.");
          }
        });
        return;
      }

      await _addIceCandidate(candidate);
    });

    // ✅ Start real-time voice detection after WebRTC setup
    _startVoiceDetection();
  }

// Helper function to add ICE candidates
  Future<void> _addIceCandidate(Map<String, dynamic> candidate) async {
    if (candidate.containsKey("candidate") &&
        candidate.containsKey("sdpMid") &&
        candidate.containsKey("sdpMLineIndex")) {
      RTCIceCandidate iceCandidate = RTCIceCandidate(
        candidate["candidate"] as String,
        candidate["sdpMid"] as String,
        candidate["sdpMLineIndex"] as int,
      );
      print("Adding ICE Candidate: $candidate");
      await _peerConnection!.addCandidate(iceCandidate);
    } else {
      print("Invalid ICE candidate format: $candidate");
    }
  }

  void _startVoiceDetection() {
    Timer.periodic(Duration(milliseconds: 500), (timer) async {
      if (_peerConnection == null) {
        timer.cancel();
        return;
      }

      var stats = await _peerConnection!.getStats();

      for (var report in stats) {
        if (report.type == 'media-source' || report.type == 'ssrc') {
          var audioLevel =
              report.values['audioInputLevel'] ?? report.values['audioLevel'];

          if (audioLevel != null) {
            double level = double.tryParse(audioLevel.toString()) ?? 0.0;

            // ✅ If audio level is above threshold, mark as speaking
            setState(() {
              _isSpeaking =
                  level > 0.01; // Adjust this threshold for sensitivity
            });
            //print("🎤 Voice Activity Detected: $_isSpeaking (Level: $level)");
          }
        }
      }
    });
  }

  // ✅ Start Ringer with Auto-Stop After 1 Minute
  void _startRinging() async {
    print("🔔 Starting Ringer...");
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('sounds/ringtone.mp3'));

    // 🔹 Auto stop ringer after 1 minute if call is not answered
    _ringingTimer = Timer(Duration(minutes: 1), () {
      if (!_callAnswered) {
        print("⏳ Call not answered. Stopping ringer and cutting the call after 1 minute.");
        _endCall();
      }
    });
  }

  // ✅ Stop Ringer
  void _stopRinging() {
    if (!_callAnswered) {
      print("🔕 Stopping Ringer...");
      _callAnswered = true;
      _audioPlayer.stop();
      _ringingTimer?.cancel();
    }
  }


  void _handleCallEnd() {
    if (mounted) {
      _peerConnection?.close();
      _stopRinging();
      Navigator.pop(context);
    }
  }

  void _endCall() {
    _peerConnection?.close();
    _callService.endCall(widget.callId);
    _signalingService.clearIncomingCall(widget.callInitiatorId);
    _stopRinging();
     // ✅ Use Global Navigator Key to ensure correct pop
    CallOverlayManager.navigatorKey.currentState?.maybePop();
  }

  @override
  void dispose() {
    _peerConnection?.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _audioPlayer.dispose();
    _ringingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 1.0, end: _isSpeaking ? 1.3 : 1.0),
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent
                              .withOpacity(_isSpeaking ? 0.7 : 0.0),
                          blurRadius: _isSpeaking ? 30 : 0,
                          spreadRadius: _isSpeaking ? 10 : 0,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: callerPhoto != null
                          ? NetworkImage(callerPhoto!)
                          : null,
                      child: callerPhoto == null
                          ? Icon(Icons.person, size: 60, color: Colors.white)
                          : null,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            Text(
              callerName ?? "Unknown Caller",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _endCall,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text("End Call",
                    style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
