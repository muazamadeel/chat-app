import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_11/call_controller.dart';
import 'package:flutter_application_11/friendmodel.dart';
import 'package:flutter_application_11/l10n/app_localizations.dart';
import 'package:flutter_application_11/ringtone_service_final.dart';
import 'package:flutter_application_11/signaling.dart';
import 'package:flutter_application_11/static_data.dart';

import 'package:get/get.dart';

class AudioCall extends StatefulWidget {
  final String roomId;
  final bool callstatus;
  final Friendmodel friendmodel;

  const AudioCall({
    super.key,
    required this.roomId,
    required this.callstatus,
    required this.friendmodel,
  });

  @override
  State<AudioCall> createState() => _AudioCallState();
}

class _AudioCallState extends State<AudioCall> {
  Signaling signaling = Signaling();
  final RingtoneService _ringtoneService = RingtoneService();

  String? roomId;
  List<String> participantNames = [];
  bool isConnecting = true;
  bool isCallActive = false;
  bool isCallConnected = false;

  @override
  void initState() {
    super.initState();
    roomId = widget.roomId.isNotEmpty ? widget.roomId : null;

    try {
      CallController.to.initilizeRTcREneders();
    } catch (e) {
      print('❌ Error initializing renderers: $e');
    }

    signaling.onAddRemotePeerStream = (peerId, stream) {
      if (!isCallConnected) {
        isCallConnected = true;
        _ringtoneService.stopRingtone();
        print('✅ AUDIO call connected - stopping ringtone');
      }
      if (mounted) {
        setState(() {
          if (!participantNames.contains(peerId)) {
            participantNames.add(peerId);
          }
        });
      }
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startCallSafely();
    });
  }

  Future<void> _startCallSafely() async {
    try {
      if (widget.callstatus) {
        await _ringtoneService.playNativeRingtone(isIncoming: true);
      } else {
        await _ringtoneService.playNativeRingtone(isIncoming: false);
      }
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) await startCall(widget.callstatus);
    } catch (e) {
      print('❌ Error in _startCallSafely: $e');
      await _ringtoneService.stopRingtone();
      if (mounted) _showError('Failed to start call: ${e.toString()}');
    }
  }

  Future<void> startCall(bool isJoining) async {
    if (!mounted) return;
    try {
      setState(() {
        isConnecting = true;
        isCallActive = false;
      });

      await signaling.openUserMedia(
        CallController.to.localRenderer,
        CallController.to.remoteRenderer,
      );

      if (!mounted) return;

      if (!isJoining) {
        List<String> initialParticipants = [
          StaticData.model!.userId!,
          widget.friendmodel.friendId!,
        ];

        final createdRoomId = await signaling.createGroupRoom(
          CallController.to.remoteRenderer,
          initialParticipants,
        );

        if (!mounted) return;
        if (createdRoomId.isEmpty) {
          throw Exception('Failed to create room');
        }

        setState(() {
          roomId = createdRoomId;
          isConnecting = false;
          isCallActive = true;
        });

        signaling.currentUserId = StaticData.model!.userId!;

        await setCallStatus(
          true,
          createdRoomId,
          widget.friendmodel.friendId!,
          "audio",
        );

        await signaling.joinGroupCall(
          createdRoomId,
          StaticData.model!.userId!,
          CallController.to.remoteRenderer,
        );
      } else {
        await signaling.joinGroupCall(
          widget.roomId,
          StaticData.model!.userId!,
          CallController.to.remoteRenderer,
        );

        if (mounted) {
          setState(() {
            isConnecting = false;
            isCallActive = true;
          });
        }
      }
    } catch (e) {
      print('❌ Error in startCall: $e');
      await _ringtoneService.stopRingtone();
      if (mounted) {
        setState(() {
          isConnecting = false;
          isCallActive = false;
        });
        _showError('Failed to start call: ${e.toString()}');
      }
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
      print('❌ Error setting call status: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void showAddParticipantDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!isCallActive || roomId == null || roomId!.isEmpty) {
      _showError(l10n.pleaseWaitConnecting);
      return;
    }

    final String currentRoomId = roomId!;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.addParticipant),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: _buildParticipantList(currentRoomId),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.close),
            ),
          ],
        );
      },
    );
  }

  Widget _buildParticipantList(String currentRoomId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('muazam rooms')
          .doc(currentRoomId)
          .snapshots(),
      builder: (context, roomSnapshot) {
        final l10n = AppLocalizations.of(context)!;

        if (roomSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (roomSnapshot.hasError) {
          return Center(child: Text('Error: ${roomSnapshot.error}'));
        }
        if (!roomSnapshot.hasData || !roomSnapshot.data!.exists) {
          return Center(child: Text(l10n.loading));
        }

        final roomData =
            roomSnapshot.data!.data() as Map<String, dynamic>? ?? {};
        final List currentParticipants = List.from(
          roomData['participants'] ?? [],
        );

        return _buildFriendsList(currentParticipants);
      },
    );
  }

  Widget _buildFriendsList(List currentParticipants) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('muazam contacts')
          .where("userId", isEqualTo: StaticData.model!.userId)
          .snapshots(),
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context)!;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
            final friend = friends[index].data() as Map<String, dynamic>;
            return _buildFriendTile(friend);
          },
        );
      },
    );
  }

  Widget _buildFriendTile(Map<String, dynamic> friend) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text(friend['friendName'] ?? 'Friend'),
      trailing: IconButton(
        icon: const Icon(Icons.add_call),
        onPressed: () => _inviteFriend(friend),
      ),
    );
  }

  Future<void> _inviteFriend(Map<String, dynamic> friend) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await signaling.inviteParticipant(friend['friendId']);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${friend['friendName']} ${l10n.invitedToCall}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error inviting participant: $e');
      if (mounted) _showError('Failed to invite: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red.shade400, Colors.red.shade800],
          ),
        ),
        child: Stack(
          children: [
            _buildMainContent(l10n),
            if (isCallActive && roomId != null && roomId!.isNotEmpty)
              _buildAddButton(),
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 120,
          width: 120,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.call, size: 60, color: Colors.red),
        ),
        const SizedBox(height: 30),
        Text(
          l10n.audioCall,
          style: const TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        _buildParticipantCount(l10n),
      ],
    );
  }

  Widget _buildParticipantCount(AppLocalizations l10n) {
    if (!isCallActive || roomId == null || roomId!.isEmpty) {
      return Text(
        widget.callstatus ? l10n.incomingCall : l10n.calling,
        style: const TextStyle(fontSize: 18, color: Colors.white70),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('muazam rooms')
          .doc(roomId!)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null) {
            final count = List.from(data['participants'] ?? []).length;
            return Text(
              '$count ${count != 1 ? l10n.participants : l10n.participant}',
              style: const TextStyle(fontSize: 18, color: Colors.white70),
            );
          }
        }
        return Text(
          l10n.loading,
          style: const TextStyle(fontSize: 18, color: Colors.white70),
        );
      },
    );
  }

  Widget _buildAddButton() {
    return Positioned(
      top: 50,
      right: 20,
      child: InkWell(
        onTap: () => showAddParticipantDialog(context),
        child: Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.3),
          ),
          child: const Icon(Icons.person_add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Positioned(
      bottom: 50,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GetBuilder<CallController>(
            builder: (calobj) {
              return InkWell(
                onTap: () => signaling.muteMic(),
                child: Container(
                  height: 70,
                  width: 70,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Icon(
                    calobj.ismute ? Icons.mic_off : Icons.mic,
                    size: 35,
                    color: Colors.red,
                  ),
                ),
              );
            },
          ),
          InkWell(
            onTap: _endCall,
            child: Container(
              height: 70,
              width: 70,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const Icon(Icons.call_end, color: Colors.red, size: 35),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _endCall() async {
    try {
      await _ringtoneService.stopRingtone();

      if (CallController.to.localRenderer.srcObject != null) {
        CallController.to.localRenderer.srcObject!.getTracks().forEach(
          (track) => track.stop(),
        );
      }

      await signaling.hangUp(CallController.to.localRenderer);
      await setCallStatus(false, '', widget.friendmodel.friendId!, '');

      if (mounted) Navigator.pop(context);
    } catch (e) {
      print('❌ Error ending call: $e');
      try {
        await _ringtoneService.stopRingtone();
      } catch (_) {}
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    print('🔴 AudioCall disposing...');
    _ringtoneService.stopRingtone();
    super.dispose();
  }
}
