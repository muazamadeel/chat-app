import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_11/call_controller.dart';
import 'package:flutter_application_11/friendmodel.dart';
import 'package:flutter_application_11/l10n/app_localizations.dart';
import 'package:flutter_application_11/ringtone_service_final.dart';
import 'package:flutter_application_11/signaling.dart';
import 'package:flutter_application_11/static_data.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';

class VideoCallScreen extends StatefulWidget {
  final String roomId;
  final bool callstatus;
  final Friendmodel friendmodel;

  const VideoCallScreen({
    super.key,
    required this.roomId,
    required this.callstatus,
    required this.friendmodel,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late Signaling signaling;
  final RingtoneService _ringtoneService = RingtoneService();

  String? roomId;
  bool isConnecting = true;
  bool isDisposing = false;
  bool isCallConnected = false;

  Map<String, RTCVideoRenderer> remoteRenderers = {};
  Map<String, String> participantNames = {};

  @override
  void initState() {
    super.initState();
    roomId = widget.roomId;
    signaling = Signaling();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await CallController.to.initilizeRTcREneders();
      signaling.onAddRemotePeerStream = _handleRemoteStream;

      if (widget.callstatus) {
        await _ringtoneService.playNativeRingtone(isIncoming: true);
      } else {
        await _ringtoneService.playNativeRingtone(isIncoming: false);
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) await startCall(widget.callstatus);
    } catch (e) {
      print('❌ Error in initialization: $e');
      if (mounted) setState(() => isConnecting = false);
    }
  }

  void _handleRemoteStream(String peerId, MediaStream stream) async {
    print('🎥 Remote stream received from: $peerId');

    if (!isCallConnected && stream.getVideoTracks().isNotEmpty) {
      isCallConnected = true;
      await _ringtoneService.stopRingtone();
    }

    if (!mounted || isDisposing) return;

    if (!remoteRenderers.containsKey(peerId)) {
      final renderer = RTCVideoRenderer();
      await renderer.initialize();
      if (!mounted || isDisposing) return;
      renderer.srcObject = stream;
      setState(() {
        remoteRenderers[peerId] = renderer;
      });
    } else {
      remoteRenderers[peerId]!.srcObject = stream;
      setState(() {});
    }

    _getParticipantName(peerId);
  }

  Future<void> _getParticipantName(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('muazam users')
          .doc(userId)
          .get();
      if (doc.exists && mounted && !isDisposing) {
        setState(() {
          participantNames[userId] = doc.data()?['name'] ?? 'User';
        });
      }
    } catch (e) {
      print('Error getting participant name: $e');
    }
  }

  Future<void> startCall(bool isJoining) async {
    await _ringtoneService.stopRingtone();
    try {
      await signaling.openUserMedia(
        CallController.to.localRenderer,
        CallController.to.remoteRenderer,
      );

      if (!isJoining) {
        List<String> initialParticipants = [
          StaticData.model!.userId!,
          widget.friendmodel.friendId!,
        ];

        roomId = await signaling.createGroupRoom(
          CallController.to.remoteRenderer,
          initialParticipants,
        );

        signaling.currentUserId = StaticData.model!.userId!;

        if (mounted) setState(() => isConnecting = false);

        await setCallStatus(
          true,
          roomId!,
          widget.friendmodel.friendId!,
          "video",
        );

        await signaling.joinGroupCall(
          roomId!,
          StaticData.model!.userId!,
          CallController.to.remoteRenderer,
        );
      } else {
        if (mounted) setState(() => isConnecting = false);

        signaling.currentUserId = StaticData.model!.userId!;

        await signaling.joinGroupCall(
          widget.roomId,
          StaticData.model!.userId!,
          CallController.to.remoteRenderer,
        );
      }

      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) setState(() {});
    } catch (e) {
      print('❌ Error in startCall: $e');
      await _ringtoneService.stopRingtone();
      if (mounted) setState(() => isConnecting = false);
    }
  }

  Future<void> setCallStatus(
    bool status,
    String roomid,
    String uid,
    String calltype,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('muazam users')
          .doc(uid)
          .update({
            "callStatus": status,
            "roomId": roomid,
            "callType": calltype,
            "callerId": StaticData.model!.userId,
          });
    } catch (e) {
      print('Error updating call status: $e');
    }
  }

  void showAddParticipantDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (roomId == null || roomId!.isEmpty || isConnecting) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseWaitConnecting)));
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.addParticipant),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('muazam rooms')
                  .doc(roomId!)
                  .snapshots(),
              builder: (context, roomSnapshot) {
                // final l10n = AppLocalizations.of(context)!;

                if (!roomSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final roomData =
                    roomSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                final List currentParticipants = roomData['participants'] ?? [];

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('muazam contacts')
                      .where("userId", isEqualTo: StaticData.model!.userId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final l10n = AppLocalizations.of(context)!;

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.data!.docs.isEmpty) {
                      return Center(child: Text(l10n.noFriendsFound));
                    }

                    final friends = snapshot.data!.docs.where((doc) {
                      final friend = doc.data() as Map<String, dynamic>;
                      return !currentParticipants.contains(friend['friendId']);
                    }).toList();

                    if (friends.isEmpty) {
                      return Center(child: Text(l10n.allFriendsInCall));
                    }

                    return ListView.builder(
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final l10n = AppLocalizations.of(context)!;
                        final friend =
                            friends[index].data() as Map<String, dynamic>;
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(friend['friendName'] ?? 'Friend'),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_call),
                            onPressed: () async {
                              await signaling.inviteParticipant(
                                friend['friendId'],
                              );
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${friend['friendName']} ${l10n.invitedToCall}',
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    if (isDisposing) {
      super.dispose();
      return;
    }
    isDisposing = true;
    _ringtoneService.stopRingtone();
    _disposeRemoteRenderers();
    super.dispose();
  }

  Future<void> _disposeRemoteRenderers() async {
    for (var entry in remoteRenderers.entries) {
      try {
        final renderer = entry.value;
        if (renderer.srcObject != null) {
          renderer.srcObject!.getTracks().forEach((track) {
            try {
              track.stop();
            } catch (_) {}
          });
          renderer.srcObject = null;
        }
        if (renderer.textureId != null) {
          await renderer.dispose();
        }
      } catch (e) {
        print('Error disposing renderer: $e');
      }
    }
    remoteRenderers.clear();
    participantNames.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    int totalParticipants = remoteRenderers.length + 1;

    return WillPopScope(
      onWillPop: () async {
        await _endCall();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              _buildWhatsAppGrid(totalParticipants),

              if (!isConnecting && roomId != null && roomId!.isNotEmpty)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => showAddParticipantDialog(context),
                      borderRadius: BorderRadius.circular(25),
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.person_add,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),

              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people, color: Colors.white, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        '$totalParticipants',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GetBuilder<CallController>(
                      builder: (calobj) {
                        return _buildControlButton(
                          icon: calobj.ismute ? Icons.mic_off : Icons.mic,
                          color: calobj.ismute ? Colors.red : Colors.white,
                          backgroundColor: calobj.ismute
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          onTap: () => signaling.muteMic(),
                        );
                      },
                    ),
                    _buildControlButton(
                      icon: Icons.switch_camera,
                      color: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      onTap: () => signaling.switchCamera(),
                    ),
                    _buildControlButton(
                      icon: Icons.call_end,
                      color: Colors.white,
                      backgroundColor: Colors.red,
                      onTap: _endCall,
                    ),
                  ],
                ),
              ),

              if (isConnecting)
                Positioned.fill(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 20),
                        Text(
                          widget.callstatus
                              ? l10n.incomingVideoCall
                              : l10n.calling,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWhatsAppGrid(int totalParticipants) {
    return Positioned.fill(
      top: 80,
      bottom: 120,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: _getGridLayout(totalParticipants),
      ),
    );
  }

  Widget _getGridLayout(int count) {
    if (count == 1) return _buildSingleView();
    if (count == 2) return _buildTwoPersonLayout();
    if (count == 3) return _buildThreePersonLayout();
    if (count == 4) return _buildFourPersonLayout();
    if (count <= 6) return _buildSixPersonLayout();
    return _buildNinePersonLayout();
  }

  Widget _buildSingleView() {
    return Center(
      child: _buildVideoTile(
        renderer: CallController.to.localRenderer,
        label: 'You',
        isLocal: true,
        borderColor: Colors.green,
      ),
    );
  }

  Widget _buildTwoPersonLayout() {
    return Column(
      children: [
        Expanded(
          child: _buildVideoTile(
            renderer: CallController.to.localRenderer,
            label: 'You',
            isLocal: true,
            borderColor: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _getRemoteVideoTile(0)),
      ],
    );
  }

  Widget _buildThreePersonLayout() {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: _buildVideoTile(
            renderer: CallController.to.localRenderer,
            label: 'You',
            isLocal: true,
            borderColor: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _getRemoteVideoTile(0)),
              const SizedBox(width: 8),
              Expanded(child: _getRemoteVideoTile(1)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFourPersonLayout() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildVideoTile(
                  renderer: CallController.to.localRenderer,
                  label: 'You',
                  isLocal: true,
                  borderColor: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _getRemoteVideoTile(0)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _getRemoteVideoTile(1)),
              const SizedBox(width: 8),
              Expanded(child: _getRemoteVideoTile(2)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSixPersonLayout() {
    int count = remoteRenderers.length + 1;
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildVideoTile(
                  renderer: CallController.to.localRenderer,
                  label: 'You',
                  isLocal: true,
                  borderColor: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _getRemoteVideoTile(0)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _getRemoteVideoTile(1)),
              const SizedBox(width: 8),
              Expanded(child: _getRemoteVideoTile(2)),
            ],
          ),
        ),
        if (count > 4) const SizedBox(height: 8),
        if (count > 4)
          Expanded(
            child: Row(
              children: [
                Expanded(child: _getRemoteVideoTile(3)),
                if (count > 5) const SizedBox(width: 8),
                if (count > 5) Expanded(child: _getRemoteVideoTile(4)),
                if (count == 5) Expanded(child: Container()),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNinePersonLayout() {
    int count = remoteRenderers.length + 1;
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildVideoTile(
                  renderer: CallController.to.localRenderer,
                  label: 'You',
                  isLocal: true,
                  borderColor: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _getRemoteVideoTile(0)),
              const SizedBox(width: 8),
              Expanded(child: _getRemoteVideoTile(1)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _getRemoteVideoTile(2)),
              const SizedBox(width: 8),
              Expanded(child: _getRemoteVideoTile(3)),
              const SizedBox(width: 8),
              Expanded(child: _getRemoteVideoTile(4)),
            ],
          ),
        ),
        if (count > 7) const SizedBox(height: 8),
        if (count > 7)
          Expanded(
            child: Row(
              children: [
                Expanded(child: _getRemoteVideoTile(5)),
                if (count > 8) const SizedBox(width: 8),
                if (count > 8) Expanded(child: _getRemoteVideoTile(6)),
                if (count > 8) const SizedBox(width: 8),
                if (count > 8) Expanded(child: _getRemoteVideoTile(7)),
                if (count == 8) Expanded(flex: 2, child: Container()),
              ],
            ),
          ),
      ],
    );
  }

  Widget _getRemoteVideoTile(int index) {
    if (index < remoteRenderers.length) {
      try {
        String peerId = remoteRenderers.keys.elementAt(index);
        RTCVideoRenderer renderer = remoteRenderers[peerId]!;
        String label = participantNames[peerId] ?? 'Participant';
        return _buildVideoTile(
          renderer: renderer,
          label: label,
          isLocal: false,
          borderColor: Colors.blue,
        );
      } catch (e) {
        return _buildPlaceholderTile();
      }
    }
    return _buildPlaceholderTile();
  }

  Widget _buildPlaceholderTile() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!, width: 2),
      ),
      child: Center(
        child: Icon(Icons.person_outline, size: 40, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildVideoTile({
    required RTCVideoRenderer renderer,
    required String label,
    required bool isLocal,
    required Color borderColor,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[900],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (renderer.srcObject != null && renderer.textureId != null)
              RTCVideoView(
                renderer,
                mirror: isLocal,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              )
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person, size: 40, color: Colors.grey[600]),
                    const SizedBox(height: 8),
                    Text(
                      isLocal ? l10n.cameraLoading : l10n.connecting,
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                    ),
                  ],
                ),
              ),
            Positioned(
              bottom: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32.5),
        child: Container(
          height: 65,
          width: 65,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 32),
        ),
      ),
    );
  }

  Future<void> _endCall() async {
    if (isDisposing) return;
    try {
      isDisposing = true;
      await _ringtoneService.stopRingtone();
      await signaling.hangUp(CallController.to.localRenderer);
      await setCallStatus(false, '', widget.friendmodel.friendId!, '');
      await CallController.to.disposeRenderers();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      print('❌ Error ending call: $e');
      try {
        await _ringtoneService.stopRingtone();
        await CallController.to.disposeRenderers();
      } catch (_) {}
      if (mounted) Navigator.pop(context);
    }
  }
}
