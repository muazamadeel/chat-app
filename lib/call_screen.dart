import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_application_11/friendmodel.dart';
import 'package:get/get.dart' hide navigator;
import '../call_controller.dart';

class CallScreen extends StatefulWidget {
  final String roomId;
  final bool isVideo;
  final bool isCaller;
  final Friendmodel frindModel;

  const CallScreen({
    super.key,
    required this.roomId,
    required this.isVideo,
    required this.isCaller,
    required this.frindModel,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _micOn = true;
  bool _cameraOn = true;
  bool _usingFrontCamera = true;

  MediaStream? _localStream;

  @override
  void initState() {
    super.initState();
    _startCall();
  }

  Future<void> _startCall() async {
    try {
      await CallController.to.initilizeRTcREneders();

      // Same approach as signaling.dart
      final Map<String, dynamic> mediaConstraints = {
        'audio': true,
        'video': widget.isVideo
            ? {'facingMode': _usingFrontCamera ? 'user' : 'environment'}
            : false,
      };

      _localStream = await navigator.mediaDevices.getUserMedia(
        mediaConstraints,
      );
      CallController.to.localRenderer.srcObject = _localStream;

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error starting call: $e');
    }
  }

  void _switchCamera() async {
    if (_localStream == null) return;
    if (_localStream!.getVideoTracks().isEmpty) return;

    final track = _localStream!.getVideoTracks().first;
    await Helper.switchCamera(track);

    if (mounted) {
      setState(() => _usingFrontCamera = !_usingFrontCamera);
    }
  }

  void _endCall() {
    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream?.dispose();
    _localStream = null;

    Get.back();
    Get.delete<CallController>();
  }

  @override
  void dispose() {
    _localStream = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // VIDEO VIEW
          widget.isVideo
              ? RTCVideoView(
                  CallController.to.localRenderer,
                  mirror: _usingFrontCamera,
                )
              : const Center(
                  child: Icon(Icons.call, color: Colors.white, size: 80),
                ),

          // CONTROLS
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // MIC
                IconButton(
                  icon: Icon(
                    _micOn ? Icons.mic : Icons.mic_off,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() => _micOn = !_micOn);
                    _localStream?.getAudioTracks().forEach(
                      (t) => t.enabled = _micOn,
                    );
                  },
                ),

                // CAMERA
                if (widget.isVideo)
                  IconButton(
                    icon: Icon(
                      _cameraOn ? Icons.videocam : Icons.videocam_off,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() => _cameraOn = !_cameraOn);
                      _localStream?.getVideoTracks().forEach(
                        (t) => t.enabled = _cameraOn,
                      );
                    },
                  ),

                // SWITCH CAMERA
                if (widget.isVideo)
                  IconButton(
                    icon: const Icon(Icons.cameraswitch, color: Colors.white),
                    onPressed: _switchCamera,
                  ),

                // END CALL
                FloatingActionButton(
                  backgroundColor: Colors.red,
                  onPressed: _endCall,
                  child: const Icon(Icons.call_end),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
