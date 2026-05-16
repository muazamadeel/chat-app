import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_11/l10n/app_localizations.dart';
import 'package:flutter_application_11/ringtone_service_final.dart';
import 'package:flutter_application_11/static_data.dart';
import 'package:flutter_application_11/call_screens/video_call_screen.dart';
import 'package:flutter_application_11/friendmodel.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callerName;
  final String callerId;
  final String roomId;
  final String callType;

  const IncomingCallScreen({
    super.key,
    required this.callerName,
    required this.callerId,
    required this.roomId,
    required this.callType,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  final RingtoneService _ringtoneService = RingtoneService();

  @override
  void initState() {
    super.initState();
    _playRingtone();
  }

  Future<void> _playRingtone() async {
    try {
      await _ringtoneService.playNativeRingtone(isIncoming: true);
    } catch (e) {
      print('❌ Error playing ringtone: $e');
    }
  }

  @override
  void dispose() {
    _ringtoneService.stopRingtone();
    super.dispose();
  }

  Future<void> _acceptCall() async {
    try {
      await _ringtoneService.stopRingtone();
      await _clearCallStatus();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VideoCallScreen(
              roomId: widget.roomId,
              callstatus: true,
              friendmodel: Friendmodel(
                friendId: widget.callerId,
                friendName: widget.callerName,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error accepting call: $e');
    }
  }

  Future<void> _rejectCall() async {
    try {
      await _ringtoneService.stopRingtone();
      await _clearCallStatus();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ Error rejecting call: $e');
    }
  }

  Future<void> _clearCallStatus() async {
    try {
      await FirebaseFirestore.instance
          .collection('muazam users')
          .doc(StaticData.model!.userId)
          .update({
            'callStatus': false,
            'roomId': '',
            'callType': '',
            'callerId': '',
          });
    } catch (e) {
      print('Error clearing call status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[800],
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      widget.callerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.callType == 'video'
                          ? l10n.incomingVideoCall
                          : l10n.incomingAudioCall,
                      style: TextStyle(color: Colors.grey[400], fontSize: 18),
                    ),
                    const SizedBox(height: 40),
                    _buildRingingAnimation(l10n),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        InkWell(
                          onTap: _rejectCall,
                          child: Container(
                            height: 70,
                            width: 70,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                            child: const Icon(
                              Icons.call_end,
                              color: Colors.white,
                              size: 35,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.decline,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        InkWell(
                          onTap: _acceptCall,
                          child: Container(
                            height: 70,
                            width: 70,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green,
                            ),
                            child: Icon(
                              widget.callType == 'video'
                                  ? Icons.videocam
                                  : Icons.call,
                              color: Colors.white,
                              size: 35,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.accept,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRingingAnimation(AppLocalizations l10n) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.8 + (value * 0.2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone_in_talk, color: Colors.green[400], size: 20),
                  const SizedBox(width: 10),
                  Text(
                    l10n.ringing,
                    style: TextStyle(color: Colors.grey[400], fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) setState(() {});
      },
    );
  }
}
