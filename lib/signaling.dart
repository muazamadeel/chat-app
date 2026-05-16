// // import 'dart:convert';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:flutter_application_11/call_controller.dart';
// // import 'package:flutter_webrtc/flutter_webrtc.dart';

// // typedef StreamStateCallback = void Function(MediaStream stream);

// // class Signaling {
// //   Map<String, dynamic> configuration = {
// //     'iceServers': [
// //       {
// //         'urls': [
// //           'stun:stun1.l.google.com:19302',
// //           'stun:stun2.l.google.com:19302',
// //         ],
// //       },
// //     ],
// //   };

// //   RTCPeerConnection? peerConnection;
// //   MediaStream? localStream;
// //   MediaStream? remoteStream;
// //   String? roomId;
// //   String? currentRoomText;
// //   StreamStateCallback? onAddRemoteStream;

// //   Future<String> createRoom(RTCVideoRenderer remoteRenderer) async {
// //     FirebaseFirestore db = FirebaseFirestore.instance;
// //     DocumentReference roomRef = db.collection('muazam rooms').doc();

// //     print('Create PeerConnection with configuration: $configuration');

// //     peerConnection = await createPeerConnection(configuration);

// //     registerPeerConnectionListeners();

// //     localStream?.getTracks().forEach((track) {
// //       peerConnection?.addTrack(track, localStream!);
// //     });

// //     // Code for collecting ICE candidates below
// //     var callerCandidatesCollection = roomRef.collection('callerCandidates');

// //     peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
// //       print('Got candidate: ${candidate.toMap()}');
// //       callerCandidatesCollection.add(candidate.toMap());
// //     };

// //     // Finish Code for collecting ICE candidate

// //     // Add code for creating a room
// //     RTCSessionDescription offer = await peerConnection!.createOffer();
// //     await peerConnection!.setLocalDescription(offer);
// //     print('Created offer: $offer');

// //     Map<String, dynamic> roomWithOffer = {'offer': offer.toMap()};

// //     await roomRef.set(roomWithOffer);
// //     var roomId = roomRef.id;
// //     print('New room created with SDK offer. Room ID: $roomId');
// //     currentRoomText = 'Current room is $roomId - You are the caller!';
// //     // Created a Room

// //     peerConnection?.onTrack = (RTCTrackEvent event) {
// //       print('Got remote track: ${event.streams[0]}');

// //       event.streams[0].getTracks().forEach((track) {
// //         print('Add a track to the remoteStream $track');
// //         remoteStream?.addTrack(track);
// //       });
// //     };

// //     // Listening for remote session description below
// //     roomRef.snapshots().listen((snapshot) async {
// //       print('Got updated room: ${snapshot.data()}');

// //       Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
// //       if (peerConnection?.getRemoteDescription() != null &&
// //           data['answer'] != null) {
// //         var answer = RTCSessionDescription(
// //           data['answer']['sdp'],
// //           data['answer']['type'],
// //         );

// //         print("Someone tried to connect");
// //         await peerConnection?.setRemoteDescription(answer);
// //       }
// //     });
// //     // Listening for remote session description above

// //     // Listen for remote Ice candidates below
// //     roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
// //       for (var change in snapshot.docChanges) {
// //         if (change.type == DocumentChangeType.added) {
// //           Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
// //           print('Got new remote ICE candidate: ${jsonEncode(data)}');
// //           peerConnection!.addCandidate(
// //             RTCIceCandidate(
// //               data['candidate'],
// //               data['sdpMid'],
// //               data['sdpMLineIndex'],
// //             ),
// //           );
// //         }
// //       }
// //     });
// //     // Listen for remote ICE candidates above

// //     return roomId;
// //   }

// //   Future<void> joinRoom(String roomId, RTCVideoRenderer remoteVideo) async {
// //     FirebaseFirestore db = FirebaseFirestore.instance;
// //     DocumentReference roomRef = db.collection('muazam rooms').doc(roomId);
// //     var roomSnapshot = await roomRef.get();
// //     print('Got room ${roomSnapshot.exists}');

// //     if (roomSnapshot.exists) {
// //       print('Create PeerConnection with configuration: $configuration');
// //       peerConnection = await createPeerConnection(configuration);

// //       registerPeerConnectionListeners();

// //       localStream?.getTracks().forEach((track) {
// //         peerConnection?.addTrack(track, localStream!);
// //       });

// //       // Code for collecting ICE candidates below
// //       var calleeCandidatesCollection = roomRef.collection('calleeCandidates');
// //       peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
// //         print('onIceCandidate: ${candidate.toMap()}');
// //         calleeCandidatesCollection.add(candidate.toMap());
// //       };

// //       // Code for collecting ICE candidate above

// //       peerConnection?.onTrack = (RTCTrackEvent event) {
// //         print('Got remote track: ${event.streams[0]}');
// //         event.streams[0].getTracks().forEach((track) {
// //           print('Add a track to the remoteStream: $track');
// //           remoteStream?.addTrack(track);
// //         });
// //       };

// //       // Code for creating SDP answer below
// //       var data = roomSnapshot.data() as Map<String, dynamic>;
// //       print('Got offer $data');
// //       var offer = data['offer'];
// //       await peerConnection?.setRemoteDescription(
// //         RTCSessionDescription(offer['sdp'], offer['type']),
// //       );
// //       var answer = await peerConnection!.createAnswer();
// //       print('Created Answer $answer');

// //       await peerConnection!.setLocalDescription(answer);

// //       Map<String, dynamic> roomWithAnswer = {
// //         'answer': {'type': answer.type, 'sdp': answer.sdp},
// //       };

// //       await roomRef.update(roomWithAnswer);
// //       // Finished creating SDP answer

// //       // Listening for remote ICE candidates below
// //       roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
// //         for (var document in snapshot.docChanges) {
// //           var data = document.doc.data() as Map<String, dynamic>;
// //           print(data);
// //           print('Got new remote ICE candidate: $data');
// //           peerConnection!.addCandidate(
// //             RTCIceCandidate(
// //               data['candidate'],
// //               data['sdpMid'],
// //               data['sdpMLineIndex'],
// //             ),
// //           );
// //         }
// //       });
// //     }
// //   }

// //   muteMic() {
// //     if (localStream != null) {
// //       bool enabled = localStream!.getAudioTracks()[0].enabled;
// //       localStream!.getAudioTracks()[0].enabled = !enabled;
// //       CallController.to.changeMuteStatus(!enabled);
// //     }
// //   }

// //   void switchCamera() {
// //     if (localStream != null) {
// //       Helper.switchCamera(localStream!.getVideoTracks()[0]);
// //     }
// //   }

// //   Future<void> openUserMedia(
// //     RTCVideoRenderer localVideo,
// //     RTCVideoRenderer remoteVideo,
// //   ) async {
// //     var stream = await navigator.mediaDevices.getUserMedia({
// //       'video': true,
// //       'audio': true,
// //     });

// //     localVideo.srcObject = stream;

// //     localStream = stream;

// //     remoteVideo.srcObject = await createLocalMediaStream('key');
// //   }

// //   Future<void> openAudioUserMedia(
// //     RTCVideoRenderer localVideo,
// //     RTCVideoRenderer remoteVideo,
// //   ) async {
// //     var stream = await navigator.mediaDevices.getUserMedia({
// //       'video': false,
// //       'audio': true,
// //     });

// //     localVideo.srcObject = stream;

// //     localStream = stream;

// //     remoteVideo.srcObject = await createLocalMediaStream('key');
// //   }

// //   Future<void> hangUp(RTCVideoRenderer localVideo) async {
// //     List<MediaStreamTrack> tracks = localVideo.srcObject!.getTracks();
// //     for (var track in tracks) {
// //       track.stop();
// //     }

// //     if (remoteStream != null) {
// //       remoteStream!.getTracks().forEach((track) => track.stop());
// //     }
// //     if (peerConnection != null) peerConnection!.close();

// //     if (roomId != null) {
// //       var db = FirebaseFirestore.instance;
// //       var roomRef = db.collection('muazam rooms').doc(roomId);
// //       var calleeCandidates = await roomRef.collection('calleeCandidates').get();
// //       for (var document in calleeCandidates.docs) {
// //         document.reference.delete();
// //       }

// //       var callerCandidates = await roomRef.collection('callerCandidates').get();
// //       for (var document in callerCandidates.docs) {
// //         document.reference.delete();
// //       }

// //       await roomRef.delete();
// //     }

// //     localStream!.dispose();
// //     remoteStream?.dispose();
// //   }

// //   void registerPeerConnectionListeners() {
// //     peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
// //       print('ICE gathering state changed: $state');
// //     };

// //     peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
// //       print('Connection state change: $state');
// //     };

// //     peerConnection?.onSignalingState = (RTCSignalingState state) {
// //       print('Signaling state change: $state');
// //     };

// //     peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
// //       print('ICE connection state change: $state');
// //     };

// //     peerConnection?.onAddStream = (MediaStream stream) {
// //       print("Add remote stream");
// //       onAddRemoteStream?.call(stream);
// //       remoteStream = stream;
// //     };
// //   }
// // }
// import 'dart:convert';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_application_11/call_controller.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';

// typedef StreamStateCallback = void Function(MediaStream stream);

// class Signaling {
//   Map<String, dynamic> configuration = {
//     'iceServers': [
//       {
//         'urls': [
//           'stun:stun1.l.google.com:19302',
//           'stun:stun2.l.google.com:19302',
//         ],
//       },
//     ],
//   };

//   RTCPeerConnection? peerConnection;
//   MediaStream? localStream;
//   MediaStream? remoteStream;
//   String? roomId;
//   String? currentRoomText;
//   StreamStateCallback? onAddRemoteStream;

//   Future<String> createRoom(RTCVideoRenderer remoteRenderer) async {
//     FirebaseFirestore db = FirebaseFirestore.instance;
//     DocumentReference roomRef = db.collection('muazam rooms').doc();

//     print('Create PeerConnection with configuration: $configuration');

//     peerConnection = await createPeerConnection(configuration);

//     registerPeerConnectionListeners();

//     localStream?.getTracks().forEach((track) {
//       peerConnection?.addTrack(track, localStream!);
//     });

//     // Code for collecting ICE candidates below
//     var callerCandidatesCollection = roomRef.collection('callerCandidates');

//     peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
//       print('Got candidate: ${candidate.toMap()}');
//       callerCandidatesCollection.add(candidate.toMap());
//     };

//     // Finish Code for collecting ICE candidate

//     // Add code for creating a room
//     RTCSessionDescription offer = await peerConnection!.createOffer();
//     await peerConnection!.setLocalDescription(offer);
//     print('Created offer: $offer');

//     Map<String, dynamic> roomWithOffer = {'offer': offer.toMap()};

//     await roomRef.set(roomWithOffer);
//     var roomId = roomRef.id;
//     print('New room created with SDK offer. Room ID: $roomId');
//     currentRoomText = 'Current room is $roomId - You are the caller!';
//     // Created a Room

//     peerConnection?.onTrack = (RTCTrackEvent event) {
//       print('Got remote track: ${event.streams[0]}');

//       event.streams[0].getTracks().forEach((track) {
//         print('Add a track to the remoteStream $track');
//         remoteStream?.addTrack(track);
//       });
//     };

//     // Listening for remote session description below
//     roomRef.snapshots().listen((snapshot) async {
//       print('Got updated room: ${snapshot.data()}');

//       Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
//       if (peerConnection?.getRemoteDescription() != null &&
//           data['answer'] != null) {
//         var answer = RTCSessionDescription(
//           data['answer']['sdp'],
//           data['answer']['type'],
//         );

//         print("Someone tried to connect");
//         await peerConnection?.setRemoteDescription(answer);
//       }
//     });
//     // Listening for remote session description above

//     // Listen for remote Ice candidates below
//     roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
//       for (var change in snapshot.docChanges) {
//         if (change.type == DocumentChangeType.added) {
//           Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
//           print('Got new remote ICE candidate: ${jsonEncode(data)}');
//           peerConnection!.addCandidate(
//             RTCIceCandidate(
//               data['candidate'],
//               data['sdpMid'],
//               data['sdpMLineIndex'],
//             ),
//           );
//         }
//       }
//     });
//     // Listen for remote ICE candidates above

//     return roomId;
//   }

//   Future<void> joinRoom(String roomId, RTCVideoRenderer remoteVideo) async {
//     FirebaseFirestore db = FirebaseFirestore.instance;
//     DocumentReference roomRef = db.collection('muazam rooms').doc(roomId);
//     var roomSnapshot = await roomRef.get();
//     print('Got room ${roomSnapshot.exists}');

//     if (roomSnapshot.exists) {
//       print('Create PeerConnection with configuration: $configuration');
//       peerConnection = await createPeerConnection(configuration);

//       registerPeerConnectionListeners();

//       localStream?.getTracks().forEach((track) {
//         peerConnection?.addTrack(track, localStream!);
//       });

//       // Code for collecting ICE candidates below
//       var calleeCandidatesCollection = roomRef.collection('calleeCandidates');
//       peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
//         print('onIceCandidate: ${candidate.toMap()}');
//         calleeCandidatesCollection.add(candidate.toMap());
//       };

//       // Code for collecting ICE candidate above

//       peerConnection?.onTrack = (RTCTrackEvent event) {
//         print('Got remote track: ${event.streams[0]}');
//         event.streams[0].getTracks().forEach((track) {
//           print('Add a track to the remoteStream: $track');
//           remoteStream?.addTrack(track);
//         });
//       };

//       // Code for creating SDP answer below
//       var data = roomSnapshot.data() as Map<String, dynamic>;
//       print('Got offer $data');
//       var offer = data['offer'];
//       await peerConnection?.setRemoteDescription(
//         RTCSessionDescription(offer['sdp'], offer['type']),
//       );
//       var answer = await peerConnection!.createAnswer();
//       print('Created Answer $answer');

//       await peerConnection!.setLocalDescription(answer);

//       Map<String, dynamic> roomWithAnswer = {
//         'answer': {'type': answer.type, 'sdp': answer.sdp},
//       };

//       await roomRef.update(roomWithAnswer);
//       // Finished creating SDP answer

//       // Listening for remote ICE candidates below
//       roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
//         for (var document in snapshot.docChanges) {
//           var data = document.doc.data() as Map<String, dynamic>;
//           print(data);
//           print('Got new remote ICE candidate: $data');
//           peerConnection!.addCandidate(
//             RTCIceCandidate(
//               data['candidate'],
//               data['sdpMid'],
//               data['sdpMLineIndex'],
//             ),
//           );
//         }
//       });
//     }
//   }

//   muteMic() {
//     if (localStream != null) {
//       bool enabled = localStream!.getAudioTracks()[0].enabled;
//       localStream!.getAudioTracks()[0].enabled = !enabled;
//       CallController.to.changeMuteStatus(!enabled);
//     }
//   }

//   void switchCamera() {
//     if (localStream != null) {
//       Helper.switchCamera(localStream!.getVideoTracks()[0]);
//     }
//   }

//   Future<void> openUserMedia(
//     RTCVideoRenderer localVideo,
//     RTCVideoRenderer remoteVideo,
//   ) async {
//     var stream = await navigator.mediaDevices.getUserMedia({
//       'video': true,
//       'audio': true,
//     });

//     localVideo.srcObject = stream;

//     localStream = stream;

//     remoteVideo.srcObject = await createLocalMediaStream('key');
//   }

//   Future<void> openAudioUserMedia(
//     RTCVideoRenderer localVideo,
//     RTCVideoRenderer remoteVideo,
//   ) async {
//     var stream = await navigator.mediaDevices.getUserMedia({
//       'video': false,
//       'audio': true,
//     });

//     localVideo.srcObject = stream;

//     localStream = stream;

//     remoteVideo.srcObject = await createLocalMediaStream('key');
//   }

//   Future<void> hangUp(RTCVideoRenderer localVideo) async {
//     List<MediaStreamTrack> tracks = localVideo.srcObject!.getTracks();
//     for (var track in tracks) {
//       track.stop();
//     }

//     if (remoteStream != null) {
//       remoteStream!.getTracks().forEach((track) => track.stop());
//     }
//     if (peerConnection != null) peerConnection!.close();

//     if (roomId != null) {
//       var db = FirebaseFirestore.instance;
//       var roomRef = db.collection('muazam rooms').doc(roomId);
//       var calleeCandidates = await roomRef.collection('calleeCandidates').get();
//       for (var document in calleeCandidates.docs) {
//         document.reference.delete();
//       }

//       var callerCandidates = await roomRef.collection('callerCandidates').get();
//       for (var document in callerCandidates.docs) {
//         document.reference.delete();
//       }

//       await roomRef.delete();
//     }

//     localStream!.dispose();
//     remoteStream?.dispose();
//   }

//   void registerPeerConnectionListeners() {
//     peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
//       print('ICE gathering state changed: $state');
//     };

//     peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
//       print('Connection state change: $state');
//     };

//     peerConnection?.onSignalingState = (RTCSignalingState state) {
//       print('Signaling state change: $state');
//     };

//     peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
//       print('ICE connection state change: $state');
//     };

//     peerConnection?.onAddStream = (MediaStream stream) {
//       print("Add remote stream");
//       onAddRemoteStream?.call(stream);
//       remoteStream = stream;
//     };
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_11/call_controller.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

typedef StreamStateCallback = void Function(MediaStream stream);
typedef RemoteStreamCallback = void Function(String peerId, MediaStream stream);

class Signaling {
  Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
        ],
      },
      //     {
      //       'urls': 'turn:openrelay.metered.ca:80',
      //       'username': 'openrelayproject',
      //       'credential': 'openrelayproject',
      //     },
      //     {
      //       'urls': 'turn:openrelay.metered.ca:443',
      //       'username': 'openrelayproject',
      //       'credential': 'openrelayproject',
      //     },
      //   ],
      //   'sdpSemantics': 'unified-plan',
      // };
    ],
    'sdpSemantics': 'unified-plan',
  };

  Map<String, RTCPeerConnection> peerConnections = {};
  MediaStream? localStream;
  Map<String, MediaStream> remoteStreams = {};
  Map<String, List<RTCIceCandidate>> pendingCandidates = {};
  Set<String> negotiatingPeers = {};

  String? roomId;
  String? currentUserId;
  StreamStateCallback? onAddRemoteStream;
  RemoteStreamCallback? onAddRemotePeerStream;

  Future<String> createGroupRoom(
    RTCVideoRenderer remoteRenderer,
    List<String> participantIds,
  ) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef = db.collection('muazam rooms').doc();

    roomId = roomRef.id;

    await roomRef.set({
      'offer': {},
      'participants': participantIds,
      'createdAt': FieldValue.serverTimestamp(),
    });

    print('✅ Group room created with ID: $roomId');
    return roomId!;
  }

  bool _shouldInitiate(String peerId) {
    if (currentUserId == null) return false;
    return currentUserId!.compareTo(peerId) > 0;
  }

  // 🔥 CRITICAL FIX: Proper peer connection creation with tracks
  Future<void> createPeerConnectionForPeer(
    String peerId,
    bool forceOffer,
  ) async {
    print('🔧 Creating peer connection for: $peerId');

    if (peerConnections.containsKey(peerId)) {
      print('⚠️ Peer connection already exists for $peerId');
      return;
    }

    try {
      RTCPeerConnection pc = await createPeerConnection(configuration);
      peerConnections[peerId] = pc;

      // ✅ CRITICAL: Add local tracks to peer connection
      if (localStream != null) {
        print('📤 Adding local tracks to peer connection for $peerId');
        localStream!.getTracks().forEach((track) {
          print('   Adding ${track.kind} track to $peerId');
          pc.addTrack(track, localStream!);
        });
        print('✅ Local tracks added for $peerId');
      } else {
        print('⚠️ No local stream available for $peerId');
      }

      // ✅ Handle ICE candidates
      pc.onIceCandidate = (RTCIceCandidate candidate) {
        _sendIceCandidate(peerId, candidate);
      };

      // ✅ CRITICAL: Handle remote tracks
      pc.onTrack = (RTCTrackEvent event) {
        print('🎥 onTrack event from $peerId: ${event.track.kind}');

        if (event.streams.isNotEmpty) {
          MediaStream stream = event.streams[0];
          print(
            '✅ Remote stream received from $peerId with ${stream.getTracks().length} tracks',
          );

          // Store stream
          remoteStreams[peerId] = stream;

          // ✅ CRITICAL: Notify UI
          if (onAddRemotePeerStream != null) {
            onAddRemotePeerStream!(peerId, stream);
            print('✅ Notified UI about remote stream from $peerId');
          } else {
            print('⚠️ onAddRemotePeerStream callback is null!');
          }
        } else {
          print('⚠️ No streams in track event from $peerId');
        }
      };

      // Monitor connection state
      pc.onConnectionState = (RTCPeerConnectionState state) {
        print('🔗 Connection state with $peerId: $state');

        if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateClosed ||
            state ==
                RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          print('❌ Peer $peerId disconnected or failed');
          _cleanupPeerConnection(peerId);
        }
      };

      pc.onSignalingState = (RTCSignalingState state) {
        print('📡 Signaling state with $peerId: $state');
      };

      pc.onIceConnectionState = (RTCIceConnectionState state) {
        print('🧊 ICE connection state with $peerId: $state');
      };

      // ✅ Decide who initiates
      bool shouldWeInitiate = _shouldInitiate(peerId);
      print('🤔 Should we initiate to $peerId? $shouldWeInitiate');

      if (shouldWeInitiate || forceOffer) {
        await _createAndSendOffer(peerId, pc);
      } else {
        print('⏳ Waiting for offer from $peerId');
      }
    } catch (e, stackTrace) {
      print('❌ Error creating peer connection for $peerId: $e');
      print('Stack: $stackTrace');
    }
  }

  Future<void> _cleanupPeerConnection(String peerId) async {
    try {
      RTCPeerConnection? pc = peerConnections[peerId];
      if (pc != null) {
        List<RTCRtpSender> senders = await pc.getSenders();
        for (var sender in senders) {
          if (sender.track != null) {
            await pc.removeTrack(sender);
          }
        }
        await pc.close();
        peerConnections.remove(peerId);
      }

      if (remoteStreams.containsKey(peerId)) {
        remoteStreams[peerId]?.getTracks().forEach((track) => track.stop());
        remoteStreams.remove(peerId);
      }

      pendingCandidates.remove(peerId);
      negotiatingPeers.remove(peerId);

      print('🧹 Cleaned up peer connection for $peerId');
    } catch (e) {
      print('❌ Error cleaning up peer $peerId: $e');
    }
  }

  Future<void> _sendIceCandidate(
    String peerId,
    RTCIceCandidate candidate,
  ) async {
    if (roomId == null || currentUserId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('muazam rooms')
          .doc(roomId)
          .collection('candidates')
          .add({
            'from': currentUserId,
            'to': peerId,
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
            'timestamp': FieldValue.serverTimestamp(),
          });

      print('📤 ICE candidate sent to $peerId');
    } catch (e) {
      print('❌ Error sending ICE candidate to $peerId: $e');
    }
  }

  Future<void> _createAndSendOffer(String peerId, RTCPeerConnection pc) async {
    try {
      negotiatingPeers.add(peerId);

      print('📤 Creating offer for $peerId');

      // ✅ Create offer with proper constraints
      RTCSessionDescription offer = await pc.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      });

      await pc.setLocalDescription(offer);

      await FirebaseFirestore.instance
          .collection('muazam rooms')
          .doc(roomId)
          .collection('offers')
          .add({
            'from': currentUserId,
            'to': peerId,
            'sdp': offer.sdp,
            'type': offer.type,
            'timestamp': FieldValue.serverTimestamp(),
          });

      print('✅ Offer sent to $peerId');
    } catch (e) {
      print('❌ Error creating/sending offer to $peerId: $e');
      negotiatingPeers.remove(peerId);
    }
  }

  Future<void> joinGroupCall(
    String roomId,
    String userId,
    RTCVideoRenderer remoteRenderer,
  ) async {
    this.roomId = roomId;
    currentUserId = userId;

    print('🔵 Joining group call - Room: $roomId, User: $userId');

    DocumentSnapshot roomDoc = await FirebaseFirestore.instance
        .collection('muazam rooms')
        .doc(roomId)
        .get();

    if (!roomDoc.exists) {
      print('❌ Room does not exist');
      return;
    }

    Map<String, dynamic> roomData = roomDoc.data() as Map<String, dynamic>;
    List<String> participants = List<String>.from(
      roomData['participants'] ?? [],
    );

    print('👥 Current participants: $participants');

    if (!participants.contains(userId)) {
      participants.add(userId);
      await FirebaseFirestore.instance
          .collection('muazam rooms')
          .doc(roomId)
          .update({'participants': participants});
    }

    // ✅ Start listeners BEFORE creating connections
    _listenForOffers();
    _listenForAnswers();
    _listenForIceCandidates();
    _listenForNewParticipants();

    // ✅ Create peer connections with all other participants
    for (String participantId in participants) {
      if (participantId != userId) {
        await createPeerConnectionForPeer(participantId, false);
      }
    }

    print('✅ Joined group call successfully');
  }

  void _listenForNewParticipants() {
    FirebaseFirestore.instance
        .collection('muazam rooms')
        .doc(roomId)
        .snapshots()
        .listen((snapshot) async {
          if (!snapshot.exists) return;

          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          List<String> participants = List<String>.from(
            data['participants'] ?? [],
          );

          for (String participantId in participants) {
            if (participantId != currentUserId &&
                !peerConnections.containsKey(participantId)) {
              print('🆕 New participant detected: $participantId');
              await createPeerConnectionForPeer(participantId, false);
            }
          }
        });
  }

  void _listenForOffers() {
    FirebaseFirestore.instance
        .collection('muazam rooms')
        .doc(roomId)
        .collection('offers')
        .where('to', isEqualTo: currentUserId)
        .snapshots()
        .listen((snapshot) async {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data()!;
              final String fromPeer = data['from'];
              final String sdp = data['sdp'];
              final String type = data['type'];

              print('📥 Received offer from: $fromPeer');

              if (!peerConnections.containsKey(fromPeer)) {
                print(
                  '🔧 Creating peer connection for incoming offer from $fromPeer',
                );
                await createPeerConnectionForPeer(fromPeer, false);
                await Future.delayed(const Duration(milliseconds: 100));
              }

              final pc = peerConnections[fromPeer];
              if (pc == null) {
                print('❌ No peer connection for $fromPeer');
                await change.doc.reference.delete();
                return;
              }

              try {
                RTCSignalingState? currentState;
                try {
                  currentState = pc.signalingState;
                } catch (e) {
                  currentState = RTCSignalingState.RTCSignalingStateStable;
                }

                print(
                  '📊 Current signaling state for $fromPeer: $currentState',
                );

                if (currentState == null ||
                    currentState == RTCSignalingState.RTCSignalingStateStable) {
                  await pc.setRemoteDescription(
                    RTCSessionDescription(sdp, type),
                  );

                  print('✅ Remote offer set for $fromPeer');

                  // ✅ Create answer with proper constraints
                  final answer = await pc.createAnswer({
                    'offerToReceiveAudio': true,
                    'offerToReceiveVideo': true,
                  });

                  await pc.setLocalDescription(answer);

                  await FirebaseFirestore.instance
                      .collection('muazam rooms')
                      .doc(roomId)
                      .collection('answers')
                      .add({
                        'from': currentUserId,
                        'to': fromPeer,
                        'sdp': answer.sdp,
                        'type': answer.type,
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                  print('✅ Answer sent to $fromPeer');

                  if (pendingCandidates.containsKey(fromPeer)) {
                    print(
                      '📦 Adding ${pendingCandidates[fromPeer]!.length} pending candidates for $fromPeer',
                    );
                    for (var candidate in pendingCandidates[fromPeer]!) {
                      try {
                        await pc.addCandidate(candidate);
                      } catch (e) {
                        print('⚠️ Error adding candidate: $e');
                      }
                    }
                    pendingCandidates.remove(fromPeer);
                  }
                } else if (currentState ==
                    RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
                  print('⚠️ Offer collision with $fromPeer');

                  if (_shouldInitiate(fromPeer)) {
                    print(
                      '🚫 Ignoring offer from $fromPeer (we have priority)',
                    );
                  } else {
                    print('🔄 Rolling back our offer for $fromPeer');

                    await pc.setRemoteDescription(
                      RTCSessionDescription(sdp, type),
                    );

                    final answer = await pc.createAnswer({
                      'offerToReceiveAudio': true,
                      'offerToReceiveVideo': true,
                    });

                    await pc.setLocalDescription(answer);

                    await FirebaseFirestore.instance
                        .collection('muazam rooms')
                        .doc(roomId)
                        .collection('answers')
                        .add({
                          'from': currentUserId,
                          'to': fromPeer,
                          'sdp': answer.sdp,
                          'type': answer.type,
                          'timestamp': FieldValue.serverTimestamp(),
                        });

                    print('✅ Rollback complete - answer sent to $fromPeer');

                    if (pendingCandidates.containsKey(fromPeer)) {
                      for (var candidate in pendingCandidates[fromPeer]!) {
                        try {
                          await pc.addCandidate(candidate);
                        } catch (e) {
                          print('⚠️ Error adding candidate: $e');
                        }
                      }
                      pendingCandidates.remove(fromPeer);
                    }
                  }
                } else {
                  print('⚠️ Cannot process offer in state: $currentState');
                }
              } catch (e, stackTrace) {
                print('❌ Error processing offer from $fromPeer: $e');
                print('Stack: $stackTrace');
              }

              try {
                await change.doc.reference.delete();
              } catch (e) {
                print('⚠️ Error deleting offer: $e');
              }
            }
          }
        });
  }

  void _listenForAnswers() {
    FirebaseFirestore.instance
        .collection('muazam rooms')
        .doc(roomId)
        .collection('answers')
        .where('to', isEqualTo: currentUserId)
        .snapshots()
        .listen((snapshot) async {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data()!;
              final String fromPeer = data['from'];
              final String sdp = data['sdp'];
              final String type = data['type'];

              print('📥 Received answer from: $fromPeer');

              final pc = peerConnections[fromPeer];
              if (pc == null) {
                print('❌ No peer connection for answer from $fromPeer');
                return;
              }

              try {
                final remoteDesc = await pc.getRemoteDescription();

                if (remoteDesc == null) {
                  await pc.setRemoteDescription(
                    RTCSessionDescription(sdp, type),
                  );
                  print('✅ Answer processed from $fromPeer');

                  if (pendingCandidates.containsKey(fromPeer)) {
                    print(
                      '📦 Adding ${pendingCandidates[fromPeer]!.length} pending candidates for $fromPeer',
                    );
                    for (var candidate in pendingCandidates[fromPeer]!) {
                      await pc.addCandidate(candidate);
                    }
                    pendingCandidates.remove(fromPeer);
                  }

                  negotiatingPeers.remove(fromPeer);
                } else {
                  print('⚠️ Remote description already set for $fromPeer');
                }
              } catch (e) {
                print('❌ Error processing answer from $fromPeer: $e');
              }

              try {
                await change.doc.reference.delete();
              } catch (e) {
                print('⚠️ Error deleting answer: $e');
              }
            }
          }
        });
  }

  void _listenForIceCandidates() {
    FirebaseFirestore.instance
        .collection('muazam rooms')
        .doc(roomId)
        .collection('candidates')
        .where('to', isEqualTo: currentUserId)
        .snapshots()
        .listen((snapshot) async {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data()!;
              final String fromPeer = data['from'];

              final candidate = RTCIceCandidate(
                data['candidate'],
                data['sdpMid'],
                data['sdpMLineIndex'],
              );

              final pc = peerConnections[fromPeer];
              if (pc != null) {
                final remoteDesc = await pc.getRemoteDescription();

                if (remoteDesc != null) {
                  try {
                    await pc.addCandidate(candidate);
                    print('✅ ICE candidate added for $fromPeer');
                  } catch (e) {
                    print('❌ Error adding candidate for $fromPeer: $e');
                  }
                } else {
                  pendingCandidates
                      .putIfAbsent(fromPeer, () => [])
                      .add(candidate);
                  print('📦 ICE candidate queued for $fromPeer');
                }
              }

              try {
                await change.doc.reference.delete();
              } catch (e) {
                print('⚠️ Error deleting candidate: $e');
              }
            }
          }
        });
  }

  Future<void> inviteParticipant(String participantId) async {
    if (roomId == null) return;

    print('📞 Inviting participant: $participantId');

    await FirebaseFirestore.instance
        .collection('muazam rooms')
        .doc(roomId)
        .update({
          'participants': FieldValue.arrayUnion([participantId]),
        });

    await FirebaseFirestore.instance
        .collection('muazam users')
        .doc(participantId)
        .update({
          'callStatus': true,
          'roomId': roomId,
          'callType': 'video',
          'callerId': currentUserId,
        });

    print('✅ Participant $participantId invited');
  }

  void muteMic() {
    if (localStream != null) {
      bool enabled = localStream!.getAudioTracks()[0].enabled;
      localStream!.getAudioTracks()[0].enabled = !enabled;
      CallController.to.changeMuteStatus(!enabled);
    }
  }

  void switchCamera() {
    if (localStream != null && localStream!.getVideoTracks().isNotEmpty) {
      Helper.switchCamera(localStream!.getVideoTracks()[0]);
    }
  }

  // ✅ CRITICAL: Open user media properly
  Future<void> openUserMedia(
    RTCVideoRenderer localVideo,
    RTCVideoRenderer remoteVideo,
  ) async {
    try {
      print('📹 Opening user media...');

      var stream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        },
      });

      print('✅ Got media stream with ${stream.getTracks().length} tracks');
      for (var track in stream.getTracks()) {
        print('   Track: ${track.kind}, enabled: ${track.enabled}');
      }

      localVideo.srcObject = stream;
      localStream = stream;

      print('✅ Local media opened successfully');
    } catch (e, stackTrace) {
      print('❌ Error opening user media: $e');
      print('Stack: $stackTrace');
      rethrow;
    }
  }

  Future<void> hangUp(RTCVideoRenderer localVideo) async {
    try {
      print('🔴 Starting hangup process...');

      for (var entry in peerConnections.entries) {
        String peerId = entry.key;
        RTCPeerConnection pc = entry.value;

        print('📤 Removing tracks from peer: $peerId');

        try {
          List<RTCRtpSender> senders = await pc.getSenders();
          for (var sender in senders) {
            if (sender.track != null) {
              await pc.removeTrack(sender);
            }
          }
        } catch (e) {
          print('⚠️ Error removing track from $peerId: $e');
        }
      }

      if (localVideo.srcObject != null) {
        try {
          List<MediaStreamTrack> tracks = localVideo.srcObject!.getTracks();
          for (var track in tracks) {
            track.stop();
          }
        } catch (e) {
          print('⚠️ Error stopping local tracks: $e');
        }
      }

      for (var entry in remoteStreams.entries) {
        try {
          entry.value.getTracks().forEach((track) => track.stop());
        } catch (e) {
          print('⚠️ Error stopping remote stream: $e');
        }
      }
      remoteStreams.clear();

      for (var entry in peerConnections.entries) {
        try {
          await entry.value.close();
        } catch (e) {
          print('⚠️ Error closing peer connection: $e');
        }
      }
      peerConnections.clear();
      pendingCandidates.clear();
      negotiatingPeers.clear();

      if (localStream != null) {
        try {
          await localStream!.dispose();
          localStream = null;
        } catch (e) {
          print('⚠️ Error disposing local stream: $e');
        }
      }

      if (roomId != null && currentUserId != null) {
        try {
          await FirebaseFirestore.instance
              .collection('muazam rooms')
              .doc(roomId)
              .update({
                'participants': FieldValue.arrayRemove([currentUserId]),
              });
        } catch (e) {
          print('⚠️ Error cleaning Firestore: $e');
        }
      }

      print('✅ Hangup completed successfully');
    } catch (e, stackTrace) {
      print('❌ Error during hangup: $e');
      print('Stack: $stackTrace');

      peerConnections.clear();
      remoteStreams.clear();
      pendingCandidates.clear();
      negotiatingPeers.clear();
      localStream = null;
    }
  }

  void registerPeerConnectionListeners() {
    // Handled per-peer in createPeerConnectionForPeer
  }
}
