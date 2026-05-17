import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_11/audioController.dart';
import 'package:flutter_application_11/call_screen.dart';
import 'package:flutter_application_11/call_screens/audio_call_screen.dart';
import 'package:flutter_application_11/call_screens/video_call_screen.dart';
import 'package:flutter_application_11/database_helper.dart';
import 'package:flutter_application_11/friendmodel.dart';
import 'package:flutter_application_11/l10n/app_localizations.dart';
import 'package:flutter_application_11/livetracking.dart';
import 'package:flutter_application_11/message_model.dart';
import 'package:flutter_application_11/pdfview.dart';
import 'package:flutter_application_11/sendlocationscreen.dart';
import 'package:flutter_application_11/static_data.dart';
import 'package:flutter_application_11/messageencrypt.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_application_11/video.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'NearbySearchMap.dart';

class ChatScreen extends StatefulWidget {
  final String chatroomId;
  final Friendmodel profileModel;

  const ChatScreen({
    super.key,
    required this.chatroomId,
    required this.profileModel,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController msgController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker picker = ImagePicker();
  final AudioController audioController = Get.put(AudioController());
  final AudioRecorder _recorder = AudioRecorder();

  bool showMediaOptions = false;
  bool showFileOptions = false;
  XFile? selectedImage;
  XFile? selectedVideo;
  String prizeImage = "img";
  bool isRecording = false;
  String? recordFilePath;
  StreamSubscription? _liveLocationSub;
  StreamSubscription? _callListener;
  bool _incomingCall = false;
  StreamSubscription? _connectivitySub;
  Map<String, dynamic>? _callData;

  final ChatDatabaseHelper _chatDb = ChatDatabaseHelper();
  bool _isOnline = true;
  List<ChatMessage> _localMessages = [];

  @override
  void initState() {
    super.initState();
    _listenForIncomingCalls();
    _checkConnectivity();
    _loadLocalMessages();
  }

  void _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (mounted) setState(() => _isOnline = result != ConnectivityResult.none);

    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      bool online = result != ConnectivityResult.none;
      if (!_isOnline && online) {
        _syncPendingMessages();
      }
      if (mounted) setState(() => _isOnline = online);
    });
  }

  void _loadLocalMessages() async {
    final msgs = await _chatDb.getMessages(widget.chatroomId);
    setState(() => _localMessages = msgs);
  }

  Future<void> _syncPendingMessages() async {
    List<ChatMessage> pending = await _chatDb.getPendingMessages(
      widget.chatroomId,
    );

    for (ChatMessage msg in pending) {
      try {
        DocumentReference ref = await _firestore
            .collection('muazam chatroom')
            .doc(widget.chatroomId)
            .collection('muazam chats')
            .add({
              "sendBy": msg.sendBy,
              "message": msg.message,
              "type": msg.type,
              "time": FieldValue.serverTimestamp(),
              "deletedFor": [],
              "status": "sent",
            });

        await _chatDb.deleteMessage(msg.firebaseId);
        msg.firebaseId = ref.id;
        msg.isPending = false;
        msg.status = 'sent';
        await _chatDb.insertMessage(msg);
      } catch (e) {
        debugPrint("Sync failed for ${msg.firebaseId}: $e");
      }
    }
    _loadLocalMessages();
  }

  void _listenForIncomingCalls() {
    _callListener = FirebaseFirestore.instance
        .collection('muazam calls')
        .doc(StaticData.model!.userId)
        .snapshots()
        .listen((doc) {
          if (!doc.exists) return;
          final data = doc.data()!;
          if (data['type'] == 'offer' && !_incomingCall) {
            setState(() {
              _incomingCall = true;
              _callData = data;
            });
          }
        });
  }

  void _acceptCall() {
    setState(() => _incomingCall = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          roomId: _callData!['roomId'],
          isVideo: _callData!['isVideo'],
          isCaller: false,
          frindModel: widget.profileModel,
        ),
      ),
    );
  }

  void _declineCall() async {
    setState(() => _incomingCall = false);
    await FirebaseFirestore.instance
        .collection('muazam calls')
        .doc(StaticData.model!.userId)
        .update({'type': 'end'});
  }

  @override
  void dispose() {
    _callListener?.cancel();
    _liveLocationSub?.cancel();
    _connectivitySub?.cancel();
    msgController.dispose();
    super.dispose();
  }

  Future<void> pickAndUploadImage() async {
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      selectedImage = pickedFile;
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('/image')
          .child(selectedImage!.name);
      await ref.putData(
        await selectedImage!.readAsBytes(),
        SettableMetadata(contentType: "image/jpeg"),
      );
      prizeImage = await ref.getDownloadURL();
      onsendMessage(prizeImage, "img");
    }
  }

  Future<void> pickAndUploadVideo() async {
    final XFile? pickedVideo = await picker.pickVideo(
      source: ImageSource.gallery,
    );
    if (pickedVideo != null) {
      selectedVideo = pickedVideo;
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('/videos')
          .child(selectedVideo!.name);
      await ref.putFile(
        File(selectedVideo!.path),
        SettableMetadata(contentType: "video/mp4"),
      );
      String videoUrl = await ref.getDownloadURL();
      onsendMessage(videoUrl, "video");
    }
  }

  Future<void> pickAndUploadPDF() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return;

    final path = result.files.single.path;
    if (path == null) return;

    File file = File(path);
    String fileName = result.files.single.name;

    Reference ref = FirebaseStorage.instance
        .ref()
        .child('pdfs')
        .child(fileName);

    await ref.putFile(file, SettableMetadata(contentType: "application/pdf"));

    String pdfUrl = await ref.getDownloadURL();

    onsendMessage(pdfUrl, "pdf");
  }
  // Future<void> pickAndUploadPDF() async {
  //   FilePickerResult? result = await FilePicker.platform.pickFiles(
  //     type: FileType.custom,
  //     allowedExtensions: ['pdf'],
  //   );

  //   if (result != null && result.files.single.path != null) {
  //     File file = File(result.files.single.path!);
  //     String fileName = result.files.single.name;
  //     Reference ref = FirebaseStorage.instance
  //         .ref()
  //         .child('pdfs')
  //         .child(fileName);
  //     await ref.putFile(file, SettableMetadata(contentType: "application/pdf"));
  //     String pdfUrl = await ref.getDownloadURL();
  //     onsendMessage(pdfUrl, "pdf");
  //   }
  // }

  Future<void> startRecord() async {
    if (!await _recorder.hasPermission()) return;
    final dir = await getApplicationDocumentsDirectory();
    recordFilePath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: recordFilePath!,
    );
    setState(() => isRecording = true);
  }

  Future<void> stopRecord() async {
    final path = await _recorder.stop();
    setState(() => isRecording = false);
    if (path != null) {
      recordFilePath = path;
      await uploadVoiceMessage();
    }
  }

  Future<void> uploadVoiceMessage() async {
    if (recordFilePath == null) return;
    final file = File(recordFilePath!);
    final ref = FirebaseStorage.instance
        .ref()
        .child('voice')
        .child(file.path.split('/').last);
    await ref.putFile(file, SettableMetadata(contentType: 'audio/m4a'));
    final url = await ref.getDownloadURL();
    onsendMessage(url, "voice");
  }

  void onsendMessage(String msg, String type) async {
    if (msg.isEmpty) return;

    String encryptedMsg = MessageEncryptionService().encryptMessage(msg);
    final now = DateTime.now();
    String timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    String tempId = 'pending_${now.millisecondsSinceEpoch}';

    ChatMessage localMsg = ChatMessage(
      firebaseId: tempId,
      chatroomId: widget.chatroomId,
      sendBy: StaticData.model!.userId!,
      message: encryptedMsg,
      type: type,
      time: timeStr,
      status: _isOnline ? 'sent' : 'pending',
      isPending: !_isOnline,
    );
    await _chatDb.insertMessage(localMsg);
    msgController.clear();
    _loadLocalMessages();

    if (_isOnline) {
      try {
        DocumentReference ref = await _firestore
            .collection('muazam chatroom')
            .doc(widget.chatroomId)
            .collection('muazam chats')
            .add({
              "sendBy": StaticData.model!.userId,
              "message": encryptedMsg,
              "type": type,
              "time": FieldValue.serverTimestamp(),
              "deletedFor": [],
              "status": "sent",
            });

        await _chatDb.deleteMessage(tempId);
        localMsg.firebaseId = ref.id;
        localMsg.isPending = false;
        await _chatDb.insertMessage(localMsg);
        _loadLocalMessages();
      } catch (e) {
        debugPrint("Firebase send failed: $e");
      }
    }
  }

  void startLiveLocation() {
    _liveLocationSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 10,
          ),
        ).listen((Position position) {
          String mapsUrl =
              "https://www.google.com/maps?q=${position.latitude},${position.longitude}";
          onsendMessage(mapsUrl, "live_location");
        });
  }

  void stopLiveLocation() {
    _liveLocationSub?.cancel();
  }

  void deleteMessage(DocumentSnapshot doc, bool isSender) async {
    final l10n = AppLocalizations.of(context)!;
    String currentUser = StaticData.model!.userId!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.delete),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSender) ...[
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(l10n.deleteForMe),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteForMe(doc, currentUser);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: Text(l10n.deleteForEveryone),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteForEveryone(doc);
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(l10n.deleteForMe),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteForMe(doc, currentUser);
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
          ],
        );
      },
    );
  }

  void _deleteForMe(DocumentSnapshot doc, String currentUser) async {
    final l10n = AppLocalizations.of(context)!;
    await _firestore
        .collection('muazam chatroom')
        .doc(widget.chatroomId)
        .collection('muazam chats')
        .doc(doc.id)
        .update({
          "deletedFor": FieldValue.arrayUnion([currentUser]),
        });

    final msgs = await _chatDb.getMessages(widget.chatroomId);
    final localMsg = msgs.where((m) => m.firebaseId == doc.id).firstOrNull;
    if (localMsg != null) {
      localMsg.deletedFor = localMsg.deletedFor.isEmpty
          ? currentUser
          : '${localMsg.deletedFor},$currentUser';
      await _chatDb.updateMessage(localMsg);
    }
    _loadLocalMessages();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.messageDeletedForYou)));
  }

  void _deleteForEveryone(DocumentSnapshot doc) async {
    final l10n = AppLocalizations.of(context)!;
    String encrypted = MessageEncryptionService().encryptMessage(
      "This message was deleted",
    );

    await _firestore
        .collection('muazam chatroom')
        .doc(widget.chatroomId)
        .collection('muazam chats')
        .doc(doc.id)
        .update({
          "deletedFor": ["all"],
          "message": encrypted,
        });

    final msgs = await _chatDb.getMessages(widget.chatroomId);
    final localMsg = msgs.where((m) => m.firebaseId == doc.id).firstOrNull;
    if (localMsg != null) {
      localMsg.deletedFor = 'all';
      localMsg.message = encrypted;
      await _chatDb.updateMessage(localMsg);
    }
    _loadLocalMessages();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.messageDeletedForEveryone)));
  }

  void editMessage(DocumentSnapshot doc) async {
    final l10n = AppLocalizations.of(context)!;
    String decryptedMessage = MessageEncryptionService().decryptMessage(
      doc['message'],
    );
    msgController.text = decryptedMessage;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(l10n.editMessage),
          content: TextField(
            controller: msgController,
            decoration: InputDecoration(hintText: l10n.editMessage),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                String encrypted = MessageEncryptionService().encryptMessage(
                  msgController.text,
                );

                await _firestore
                    .collection('muazam chatroom')
                    .doc(widget.chatroomId)
                    .collection('muazam chats')
                    .doc(doc.id)
                    .update({"message": encrypted, "isEdited": true});

                final msgs = await _chatDb.getMessages(widget.chatroomId);
                final localMsg = msgs
                    .where((m) => m.firebaseId == doc.id)
                    .firstOrNull;
                if (localMsg != null) {
                  localMsg.message = encrypted;
                  localMsg.isEdited = true;
                  await _chatDb.updateMessage(localMsg);
                }
                _loadLocalMessages();
                msgController.clear();
                Navigator.pop(context);
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.blueAccent,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget messages(
    Size size,
    Map<String, dynamic> map,
    int index,
    String docId,
  ) {
    final l10n = AppLocalizations.of(context)!;
    bool isMe = map['sendBy'] == StaticData.model!.userId;

    String timeString = "";
    final rawTime = map['time'];
    if (rawTime is Timestamp) {
      DateTime dt = rawTime.toDate();
      timeString =
          "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } else if (rawTime is String && rawTime.isNotEmpty) {
      timeString = rawTime;
    }

    String messageText = MessageEncryptionService().decryptMessage(
      map['message'] ?? "",
    );
    bool isEdited = map['isEdited'] == true;
    String status = map['status'] ?? "sent";
    Color textColor = Colors.black87;
    String messageType = map['type'] ?? "txt";

    List deletedFor = map['deletedFor'] is List
        ? map['deletedFor']
        : (map['deletedFor'] as String?)
                  ?.split(',')
                  .where((s) => s.isNotEmpty)
                  .toList() ??
              [];
    String currentUser = StaticData.model!.userId!;
    bool isDeletedForMe =
        deletedFor.contains(currentUser) || deletedFor.contains("all");

    if (_isOnline && !isMe && status != "seen") {
      _firestore
          .collection('muazam chatroom')
          .doc(widget.chatroomId)
          .collection('muazam chats')
          .doc(docId)
          .update({"status": "seen"});
    }

    return Container(
      width: size.width,
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: size.width * 0.75),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFFB3D4FF) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: isMe
                  ? const Radius.circular(20)
                  : const Radius.circular(4),
              bottomRight: isMe
                  ? const Radius.circular(4)
                  : const Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isDeletedForMe)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.block,
                      size: 16,
                      color: textColor.withOpacity(0.6),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      deletedFor.contains("all")
                          ? l10n.deletedForAll
                          : l10n.youDeletedMessage,
                      style: TextStyle(
                        color: textColor.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                      ),
                    ),
                  ],
                )
              else ...[
                if (messageType == "img")
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            backgroundColor: Colors.black,
                            appBar: AppBar(
                              backgroundColor: Colors.black,
                              iconTheme: const IconThemeData(
                                color: Colors.white,
                              ),
                            ),
                            body: Center(
                              child: InteractiveViewer(
                                child: Image.network(messageText),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        messageText,
                        width: size.width * 0.6,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 50),
                      ),
                    ),
                  )
                else if (messageType == "video")
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              VideoPlayerScreen(videoUrl: messageText),
                        ),
                      );
                    },
                    child: Container(
                      width: size.width * 0.6,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.play_circle_outline,
                            color: Colors.white,
                            size: 60,
                          ),
                          Positioned(
                            bottom: 5,
                            left: 5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                l10n.tapToPlayVideo,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (messageType == "pdf")
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PDFViewerScreen(pdfUrl: messageText),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.red,
                            size: 40,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            l10n.pdfDocument,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (messageType == "voice")
                  GestureDetector(
                    onTap: () {
                      audioController.onPressedPlayButton(
                        docId.hashCode,
                        messageText,
                      );
                    },
                    child: Obx(() {
                      bool isPlaying =
                          audioController.isRecordPlaying &&
                          audioController.currentId == docId.hashCode;
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPlaying
                                  ? Icons.pause_circle
                                  : Icons.play_circle,
                              color: Colors.blue,
                              size: 30,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.voiceMessage,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                if (isPlaying)
                                  Obx(() {
                                    double progress = audioController
                                        .completedPercentage
                                        .value;
                                    return Container(
                                      width: 100,
                                      height: 3,
                                      margin: const EdgeInsets.only(top: 4),
                                      child: LinearProgressIndicator(
                                        value: progress.isNaN ? 0 : progress,
                                        backgroundColor: Colors.blue.shade200,
                                        valueColor:
                                            const AlwaysStoppedAnimation(
                                              Colors.blue,
                                            ),
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  )
                else if (messageType == "location" ||
                    messageType == "live_location")
                  GestureDetector(
                    onTap: () {
                      String url = messageText;
                      if (url.contains("maps?q=")) {
                        try {
                          String coords = url.split("maps?q=").last;
                          double lat = double.parse(coords.split(",")[0]);
                          double lng = double.parse(coords.split(",")[1]);
                          LatLng destination = LatLng(lat, lng);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LiveTracking(
                                chatroomId: widget.chatroomId,
                                isReceiver:
                                    map['sendBy'] != StaticData.model!.userId,
                                destination: destination,
                                apiKey:
                                    "AIzaSyC2fWxeerzaACQnhahbU85T83o4fTTOszw",
                              ),
                            ),
                          );
                        } catch (e) {
                          debugPrint("Invalid maps link: $e");
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.blue,
                            size: 26,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.viewLocation,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Text(
                    messageText,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
              ],

              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isEdited)
                    Text(
                      l10n.edited,
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Text(
                    timeString,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      status == "pending"
                          ? Icons.access_time
                          : status == "sent"
                          ? Icons.check
                          : Icons.done_all,
                      size: 16,
                      color: status == "seen"
                          ? Colors.blue
                          : status == "pending"
                          ? Colors.orange
                          : Colors.grey,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    final l10n = AppLocalizations.of(context)!;
    if (_isOnline) {
      return StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('muazam chatroom')
            .doc(widget.chatroomId)
            .collection('muazam chats')
            .orderBy("time", descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          for (var doc in snapshot.data!.docs) {
            final map = doc.data() as Map<String, dynamic>;
            final cached = ChatMessage.fromFirestore(
              doc.id,
              map,
              widget.chatroomId,
            );
            _chatDb.upsertMessage(cached);
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot doc = snapshot.data!.docs[index];
              Map<String, dynamic> map = doc.data() as Map<String, dynamic>;
              return GestureDetector(
                onLongPress: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) {
                      return SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.content_copy),
                              title: Text(l10n.copy),
                              onTap: () {
                                String decryptedText =
                                    MessageEncryptionService().decryptMessage(
                                      map['message'],
                                    );
                                Clipboard.setData(
                                  ClipboardData(text: decryptedText),
                                );
                                Navigator.pop(context);
                              },
                            ),
                            if (map['sendBy'] == StaticData.model!.userId)
                              ListTile(
                                leading: const Icon(Icons.edit),
                                title: Text(l10n.edit),
                                onTap: () {
                                  Navigator.pop(context);
                                  editMessage(doc);
                                },
                              ),
                            ListTile(
                              leading: const Icon(Icons.delete),
                              title: Text(l10n.delete),
                              onTap: () {
                                Navigator.pop(context);
                                deleteMessage(
                                  doc,
                                  map['sendBy'] == StaticData.model!.userId,
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                child: messages(
                  MediaQuery.of(context).size,
                  map,
                  index,
                  doc.id,
                ),
              );
            },
          );
        },
      );
    }

    if (_localMessages.isEmpty) {
      return Center(
        child: Text(
          l10n.offlineNoMessages,
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      itemCount: _localMessages.length,
      itemBuilder: (context, index) {
        final msg = _localMessages[index];
        final map = <String, dynamic>{
          'sendBy': msg.sendBy,
          'message': msg.message,
          'type': msg.type,
          'time': msg.time,
          'deletedFor': msg.deletedFor,
          'status': msg.status,
          'isEdited': msg.isEdited,
        };
        return messages(
          MediaQuery.of(context).size,
          map,
          index,
          msg.firebaseId,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF246BFD),
        title: Row(
          children: [
            const CircleAvatar(
              backgroundImage: AssetImage('images/person2.jpeg'),
              radius: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.profileModel.friendName ?? 'Friend',
                    style: const TextStyle(fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('muazam users')
                      .doc(widget.profileModel.friendId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const SizedBox.shrink();
                    }
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final isOnline = data['isOnline'] ?? false;
                    final Timestamp? lastSeenTimestamp = data['lastSeen'];

                    if (isOnline) {
                      return Text(
                        l10n.online,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      );
                    } else if (lastSeenTimestamp != null) {
                      final lastSeen = lastSeenTimestamp.toDate();
                      return Text(
                        '${l10n.lastSeen} ${timeago.format(lastSeen)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      );
                    } else {
                      return Text(
                        l10n.offline,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      );
                    }
                  },
                ),
              ],
            ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AudioCall(
                    roomId: "",
                    callstatus: false,
                    friendmodel: widget.profileModel,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoCallScreen(
                    roomId: "",
                    callstatus: false,
                    friendmodel: widget.profileModel,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (!_isOnline)
                Container(
                  width: double.infinity,
                  color: Colors.orange.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Text(
                    l10n.offlineBanner,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),

              Expanded(child: _buildMessageList()),
              Divider(color: Colors.grey[400], height: 1),

              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showMediaOptions)
                    Container(
                      color: Colors.grey[200],
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildOption(
                            Icons.image,
                            l10n.image,
                            pickAndUploadImage,
                          ),
                          _buildOption(
                            Icons.videocam,
                            l10n.video,
                            pickAndUploadVideo,
                          ),
                        ],
                      ),
                    ),
                  if (showFileOptions)
                    Container(
                      color: Colors.grey[200],
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildOption(
                            Icons.picture_as_pdf,
                            l10n.pdfDocument,
                            pickAndUploadPDF,
                          ),
                          _buildOption(
                            Icons.my_location,
                            l10n.sendLocation,
                            () async {
                              Position position =
                                  await Geolocator.getCurrentPosition(
                                    desiredAccuracy: LocationAccuracy.high,
                                  );
                              LatLng currentLatLng = LatLng(
                                position.latitude,
                                position.longitude,
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SendLocationScreen(
                                    currentLatLng: currentLatLng,
                                    onSend: (LatLng loc) {
                                      String mapsUrl =
                                          "https://www.google.com/maps?q=${loc.latitude},${loc.longitude}";
                                      onsendMessage(mapsUrl, "location");
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            l10n.locationSentSuccess,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                          _buildOption(Icons.search, l10n.nearby, () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NearbySearchMap(),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          offset: Offset(0, -1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 5),
                        GestureDetector(
                          onLongPress: startRecord,
                          onLongPressUp: stopRecord,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isRecording ? Colors.red : const Color(0xFFE9F0FF),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.mic,
                              color: isRecording ? Colors.white : const Color(0xFF246BFD),
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F7FC),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: msgController,
                                    decoration: InputDecoration(
                                      hintText: l10n.typeMessage,
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.camera_alt, color: Colors.grey),
                                  onPressed: () {
                                    setState(() {
                                      showMediaOptions = !showMediaOptions;
                                      showFileOptions = false;
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.attach_file, color: Colors.grey),
                                  onPressed: () {
                                    setState(() {
                                      showFileOptions = !showFileOptions;
                                      showMediaOptions = false;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => onsendMessage(msgController.text, "txt"),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Color(0xFF246BFD),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (_incomingCall)
            Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${widget.profileModel.friendName} ${l10n.isCalling}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            onPressed: _acceptCall,
                            child: Text(l10n.accept),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: _declineCall,
                            child: Text(l10n.decline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
// import 'dart:async';
// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_application_11/audioController.dart';
// import 'package:flutter_application_11/call_screen.dart';
// import 'package:flutter_application_11/call_screens/audio_call_screen.dart';
// import 'package:flutter_application_11/call_screens/video_call_screen.dart';
// import 'package:flutter_application_11/database_helper.dart';
// import 'package:flutter_application_11/friendmodel.dart';
// import 'package:flutter_application_11/livetracking.dart';
// import 'package:flutter_application_11/message_model.dart';
// import 'package:flutter_application_11/pdfview.dart';
// import 'package:flutter_application_11/sendlocationscreen.dart';
// import 'package:flutter_application_11/static_data.dart';
// import 'package:flutter_application_11/messageencrypt.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter_application_11/video.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:record/record.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:timeago/timeago.dart' as timeago;
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/services.dart';
// import 'NearbySearchMap.dart';

// class ChatScreen extends StatefulWidget {
//   final String chatroomId;
//   final Friendmodel profileModel;

//   const ChatScreen({
//     super.key,
//     required this.chatroomId,
//     required this.profileModel,
//   });

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   TextEditingController msgController = TextEditingController();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final ImagePicker picker = ImagePicker();
//   final AudioController audioController = Get.put(AudioController());
//   final AudioRecorder _recorder = AudioRecorder();

//   bool showMediaOptions = false;
//   bool showFileOptions = false;
//   XFile? selectedImage;
//   XFile? selectedVideo;
//   String prizeImage = "img";
//   bool isRecording = false;
//   String? recordFilePath;
//   StreamSubscription? _liveLocationSub;
//   StreamSubscription? _callListener;
//   bool _incomingCall = false;
//   StreamSubscription? _connectivitySub;
//   Map<String, dynamic>? _callData;

//   // ── SQLite + Connectivity (naye) ─────────────────────
//   final ChatDatabaseHelper _chatDb = ChatDatabaseHelper();
//   bool _isOnline = true;
//   List<ChatMessage> _localMessages = [];

//   @override
//   void initState() {
//     super.initState();
//     _listenForIncomingCalls();
//     _checkConnectivity();
//     _loadLocalMessages();
//   }

//   //  CONNECTIVITY

//   void _checkConnectivity() async {
//     final result = await Connectivity().checkConnectivity();
//     if (mounted) setState(() => _isOnline = result != ConnectivityResult.none);

//     // Stream ko variable mein save karo
//     _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
//       bool online = result != ConnectivityResult.none;
//       if (!_isOnline && online) {
//         _syncPendingMessages();
//       }
//       //  mounted check — screen band ho chuki ho toh setState mat karo
//       if (mounted) setState(() => _isOnline = online);
//     });
//   }

//   //  LOCAL DB LOAD

//   void _loadLocalMessages() async {
//     final msgs = await _chatDb.getMessages(widget.chatroomId);
//     setState(() => _localMessages = msgs);
//   }

//   //  SYNC PENDING MESSAGES (offline mein likhe hue)
//   Future<void> _syncPendingMessages() async {
//     List<ChatMessage> pending = await _chatDb.getPendingMessages(
//       widget.chatroomId,
//     );

//     for (ChatMessage msg in pending) {
//       try {
//         DocumentReference ref = await _firestore
//             .collection('muazam chatroom')
//             .doc(widget.chatroomId)
//             .collection('muazam chats')
//             .add({
//               "sendBy": msg.sendBy,
//               "message": msg.message,
//               "type": msg.type,
//               "time": FieldValue.serverTimestamp(),
//               "deletedFor": [],
//               "status": "sent",
//             });

//         // Old temp entry delete karo, real Firebase ID se save karo
//         await _chatDb.deleteMessage(msg.firebaseId);
//         msg.firebaseId = ref.id;
//         msg.isPending = false;
//         msg.status = 'sent';
//         await _chatDb.insertMessage(msg);
//       } catch (e) {
//         debugPrint("Sync failed for ${msg.firebaseId}: $e");
//       }
//     }
//     _loadLocalMessages();
//   }

//   //  INCOMING CALLS

//   void _listenForIncomingCalls() {
//     _callListener = FirebaseFirestore.instance
//         .collection('muazam calls')
//         .doc(StaticData.model!.userId)
//         .snapshots()
//         .listen((doc) {
//           if (!doc.exists) return;
//           final data = doc.data()!;
//           if (data['type'] == 'offer' && !_incomingCall) {
//             setState(() {
//               _incomingCall = true;
//               _callData = data;
//             });
//           }
//         });
//   }

//   void _acceptCall() {
//     setState(() => _incomingCall = false);
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => CallScreen(
//           roomId: _callData!['roomId'],
//           isVideo: _callData!['isVideo'],
//           isCaller: false,
//           frindModel: widget.profileModel,
//         ),
//       ),
//     );
//   }

//   void _declineCall() async {
//     setState(() => _incomingCall = false);
//     await FirebaseFirestore.instance
//         .collection('muazam calls')
//         .doc(StaticData.model!.userId)
//         .update({'type': 'end'});
//   }

//   @override
//   void dispose() {
//     _callListener?.cancel();
//     _liveLocationSub?.cancel();
//     _connectivitySub?.cancel();
//     msgController.dispose();
//     super.dispose();
//   }

//   //  IMAGE UPLOAD
//   Future<void> pickAndUploadImage() async {
//     final XFile? pickedFile = await picker.pickImage(
//       source: ImageSource.gallery,
//     );
//     if (pickedFile != null) {
//       selectedImage = pickedFile;
//       Reference ref = FirebaseStorage.instance
//           .ref()
//           .child('/image')
//           .child(selectedImage!.name);
//       await ref.putData(
//         await selectedImage!.readAsBytes(),
//         SettableMetadata(contentType: "image/jpeg"),
//       );
//       prizeImage = await ref.getDownloadURL();
//       onsendMessage(prizeImage, "img");
//     }
//   }

//   //  VIDEO UPLOAD
//   Future<void> pickAndUploadVideo() async {
//     final XFile? pickedVideo = await picker.pickVideo(
//       source: ImageSource.gallery,
//     );
//     if (pickedVideo != null) {
//       selectedVideo = pickedVideo;
//       Reference ref = FirebaseStorage.instance
//           .ref()
//           .child('/videos')
//           .child(selectedVideo!.name);
//       await ref.putFile(
//         File(selectedVideo!.path),
//         SettableMetadata(contentType: "video/mp4"),
//       );
//       String videoUrl = await ref.getDownloadURL();
//       onsendMessage(videoUrl, "video");
//     }
//   }

//   //  PDF UPLOAD
//   Future<void> pickAndUploadPDF() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['pdf'],
//     );
//     if (result != null && result.files.single.path != null) {
//       File file = File(result.files.single.path!);
//       String fileName = result.files.single.name;
//       Reference ref = FirebaseStorage.instance
//           .ref()
//           .child('pdfs')
//           .child(fileName);
//       await ref.putFile(file, SettableMetadata(contentType: "application/pdf"));
//       String pdfUrl = await ref.getDownloadURL();
//       onsendMessage(pdfUrl, "pdf");
//     }
//   }

//   //  VOICE RECORD
//   Future<void> startRecord() async {
//     if (!await _recorder.hasPermission()) return;
//     final dir = await getApplicationDocumentsDirectory();
//     recordFilePath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';
//     await _recorder.start(
//       const RecordConfig(
//         encoder: AudioEncoder.aacLc,
//         bitRate: 128000,
//         sampleRate: 44100,
//       ),
//       path: recordFilePath!,
//     );
//     setState(() => isRecording = true);
//   }

//   Future<void> stopRecord() async {
//     final path = await _recorder.stop();
//     setState(() => isRecording = false);
//     if (path != null) {
//       recordFilePath = path;
//       await uploadVoiceMessage();
//     }
//   }

//   Future<void> uploadVoiceMessage() async {
//     if (recordFilePath == null) return;
//     final file = File(recordFilePath!);
//     final ref = FirebaseStorage.instance
//         .ref()
//         .child('voice')
//         .child(file.path.split('/').last);
//     await ref.putFile(file, SettableMetadata(contentType: 'audio/m4a'));
//     final url = await ref.getDownloadURL();
//     onsendMessage(url, "voice");
//   }

//   //  SEND MESSAGE — SQLite + Firebase (UPDATED)
//   void onsendMessage(String msg, String type) async {
//     if (msg.isEmpty) return;

//     String encryptedMsg = MessageEncryptionService().encryptMessage(msg);
//     final now = DateTime.now();
//     String timeStr =
//         '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
//     String tempId = 'pending_${now.millisecondsSinceEpoch}';

//     // ── Step 1: Pehle SQLite mein save karo ─────────
//     ChatMessage localMsg = ChatMessage(
//       firebaseId: tempId,
//       chatroomId: widget.chatroomId,
//       sendBy: StaticData.model!.userId!,
//       message: encryptedMsg,
//       type: type,
//       time: timeStr,
//       status: _isOnline ? 'sent' : 'pending',
//       isPending: !_isOnline,
//     );
//     await _chatDb.insertMessage(localMsg);
//     msgController.clear();
//     _loadLocalMessages();

//     // ── Step 2: Online ho toh Firebase ko bhi bhejo ─
//     if (_isOnline) {
//       try {
//         DocumentReference ref = await _firestore
//             .collection('muazam chatroom')
//             .doc(widget.chatroomId)
//             .collection('muazam chats')
//             .add({
//               "sendBy": StaticData.model!.userId,
//               "message": encryptedMsg,
//               "type": type,
//               "time": FieldValue.serverTimestamp(),
//               "deletedFor": [],
//               "status": "sent",
//             });

//         // Temp entry replace karo real Firebase ID se
//         await _chatDb.deleteMessage(tempId);
//         localMsg.firebaseId = ref.id;
//         localMsg.isPending = false;
//         await _chatDb.insertMessage(localMsg);
//         _loadLocalMessages();
//       } catch (e) {
//         debugPrint("Firebase send failed: $e");
//         // Pending rahega — sync baad mein hoga
//       }
//     }
//   }

//   //  LIVE LOCATION
//   void startLiveLocation() {
//     _liveLocationSub =
//         Geolocator.getPositionStream(
//           locationSettings: const LocationSettings(
//             accuracy: LocationAccuracy.best,
//             distanceFilter: 10,
//           ),
//         ).listen((Position position) {
//           String mapsUrl =
//               "https://www.google.com/maps?q=${position.latitude},${position.longitude}";
//           onsendMessage(mapsUrl, "live_location");
//         });
//   }

//   void stopLiveLocation() {
//     _liveLocationSub?.cancel();
//   }
//   //  DELETE MESSAGE
//   void deleteMessage(DocumentSnapshot doc, bool isSender) async {
//     String currentUser = StaticData.model!.userId!;
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Delete Message'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               if (isSender) ...[
//                 ListTile(
//                   leading: const Icon(Icons.delete_outline, color: Colors.red),
//                   title: const Text('Delete for Me'),
//                   onTap: () {
//                     Navigator.pop(context);
//                     _deleteForMe(doc, currentUser);
//                   },
//                 ),
//                 ListTile(
//                   leading: const Icon(Icons.delete_forever, color: Colors.red),
//                   title: const Text('Delete for Everyone'),
//                   onTap: () {
//                     Navigator.pop(context);
//                     _deleteForEveryone(doc);
//                   },
//                 ),
//               ] else ...[
//                 ListTile(
//                   leading: const Icon(Icons.delete_outline, color: Colors.red),
//                   title: const Text('Delete for Me'),
//                   onTap: () {
//                     Navigator.pop(context);
//                     _deleteForMe(doc, currentUser);
//                   },
//                 ),
//               ],
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _deleteForMe(DocumentSnapshot doc, String currentUser) async {
//     // Firebase update
//     await _firestore
//         .collection('muazam chatroom')
//         .doc(widget.chatroomId)
//         .collection('muazam chats')
//         .doc(doc.id)
//         .update({
//           "deletedFor": FieldValue.arrayUnion([currentUser]),
//         });

//     // SQLite update
//     final msgs = await _chatDb.getMessages(widget.chatroomId);
//     final localMsg = msgs.where((m) => m.firebaseId == doc.id).firstOrNull;
//     if (localMsg != null) {
//       localMsg.deletedFor = localMsg.deletedFor.isEmpty
//           ? currentUser
//           : '${localMsg.deletedFor},$currentUser';
//       await _chatDb.updateMessage(localMsg);
//     }
//     _loadLocalMessages();

//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(const SnackBar(content: Text('Message deleted for you')));
//   }

//   void _deleteForEveryone(DocumentSnapshot doc) async {
//     String encrypted = MessageEncryptionService().encryptMessage(
//       "This message was deleted",
//     );

//     // Firebase update
//     await _firestore
//         .collection('muazam chatroom')
//         .doc(widget.chatroomId)
//         .collection('muazam chats')
//         .doc(doc.id)
//         .update({
//           "deletedFor": ["all"],
//           "message": encrypted,
//         });

//     // SQLite update
//     final msgs = await _chatDb.getMessages(widget.chatroomId);
//     final localMsg = msgs.where((m) => m.firebaseId == doc.id).firstOrNull;
//     if (localMsg != null) {
//       localMsg.deletedFor = 'all';
//       localMsg.message = encrypted;
//       await _chatDb.updateMessage(localMsg);
//     }
//     _loadLocalMessages();

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Message deleted for everyone')),
//     );
//   }

//   //  EDIT MESSAGE
//   void editMessage(DocumentSnapshot doc) async {
//     String decryptedMessage = MessageEncryptionService().decryptMessage(
//       doc['message'],
//     );
//     msgController.text = decryptedMessage;

//     showDialog(
//       context: context,
//       builder: (_) {
//         return AlertDialog(
//           title: const Text("Edit Message"),
//           content: TextField(
//             controller: msgController,
//             decoration: const InputDecoration(hintText: "Edit your message"),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text("Cancel"),
//             ),
//             TextButton(
//               onPressed: () async {
//                 String encrypted = MessageEncryptionService().encryptMessage(
//                   msgController.text,
//                 );

//                 // Firebase update
//                 await _firestore
//                     .collection('muazam chatroom')
//                     .doc(widget.chatroomId)
//                     .collection('muazam chats')
//                     .doc(doc.id)
//                     .update({"message": encrypted, "isEdited": true});

//                 // SQLite update
//                 final msgs = await _chatDb.getMessages(widget.chatroomId);
//                 final localMsg = msgs
//                     .where((m) => m.firebaseId == doc.id)
//                     .firstOrNull;
//                 if (localMsg != null) {
//                   localMsg.message = encrypted;
//                   localMsg.isEdited = true;
//                   await _chatDb.updateMessage(localMsg);
//                 }
//                 _loadLocalMessages();

//                 msgController.clear();
//                 Navigator.pop(context);
//               },
//               child: const Text("Save"),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildOption(IconData icon, String label, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           CircleAvatar(
//             radius: 25,
//             backgroundColor: Colors.blueAccent,
//             child: Icon(icon, color: Colors.white),
//           ),
//           const SizedBox(height: 5),
//           Text(label, style: const TextStyle(fontSize: 12)),
//         ],
//       ),
//     );
//   }
//   Widget messages(
//     Size size,
//     Map<String, dynamic> map,
//     int index,
//     String docId,
//   ) {
//     bool isMe = map['sendBy'] == StaticData.model!.userId;

//     // Time — Firebase Timestamp ya local String dono handle karo
//     String timeString = "";
//     final rawTime = map['time'];
//     if (rawTime is Timestamp) {
//       DateTime dt = rawTime.toDate();
//       timeString =
//           "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
//     } else if (rawTime is String && rawTime.isNotEmpty) {
//       timeString = rawTime;
//     }

//     String messageText = MessageEncryptionService().decryptMessage(
//       map['message'] ?? "",
//     );
//     bool isEdited = map['isEdited'] == true;
//     String status = map['status'] ?? "sent";
//     Color textColor = isMe ? Colors.white : Colors.black87;
//     String messageType = map['type'] ?? "txt";

//     List deletedFor = map['deletedFor'] is List
//         ? map['deletedFor']
//         : (map['deletedFor'] as String?)
//                   ?.split(',')
//                   .where((s) => s.isNotEmpty)
//                   .toList() ??
//               [];
//     String currentUser = StaticData.model!.userId!;
//     bool isDeletedForMe =
//         deletedFor.contains(currentUser) || deletedFor.contains("all");

//     // Mark as seen (only online)
//     if (_isOnline && !isMe && status != "seen") {
//       _firestore
//           .collection('muazam chatroom')
//           .doc(widget.chatroomId)
//           .collection('muazam chats')
//           .doc(docId)
//           .update({"status": "seen"});
//     }

//     return Container(
//       width: size.width,
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
//       child: ConstrainedBox(
//         constraints: BoxConstraints(maxWidth: size.width * 0.75),
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
//           decoration: BoxDecoration(
//             gradient: isMe
//                 ? LinearGradient(
//                     colors: [Colors.green.shade400, Colors.green.shade300],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   )
//                 : LinearGradient(
//                     colors: [Colors.grey.shade200, Colors.grey.shade300],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//             borderRadius: BorderRadius.only(
//               topLeft: const Radius.circular(20),
//               topRight: const Radius.circular(20),
//               bottomLeft: isMe
//                   ? const Radius.circular(20)
//                   : const Radius.circular(5),
//               bottomRight: isMe
//                   ? const Radius.circular(5)
//                   : const Radius.circular(20),
//             ),
//             boxShadow: const [
//               BoxShadow(
//                 color: Colors.black12,
//                 blurRadius: 4,
//                 offset: Offset(2, 2),
//               ),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: isMe
//                 ? CrossAxisAlignment.end
//                 : CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // ── Deleted message ────────────────────
//               if (isDeletedForMe)
//                 Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(
//                       Icons.block,
//                       size: 16,
//                       color: textColor.withOpacity(0.6),
//                     ),
//                     const SizedBox(width: 5),
//                     Text(
//                       deletedFor.contains("all")
//                           ? "This message was deleted"
//                           : "You deleted this message",
//                       style: TextStyle(
//                         color: textColor.withOpacity(0.6),
//                         fontStyle: FontStyle.italic,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 )
//               else ...[
//                 // ── IMAGE ─────────────────────────────
//                 if (messageType == "img")
//                   GestureDetector(
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => Scaffold(
//                             backgroundColor: Colors.black,
//                             appBar: AppBar(
//                               backgroundColor: Colors.black,
//                               iconTheme: const IconThemeData(
//                                 color: Colors.white,
//                               ),
//                             ),
//                             body: Center(
//                               child: InteractiveViewer(
//                                 child: Image.network(messageText),
//                               ),
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(10),
//                       child: Image.network(
//                         messageText,
//                         width: size.width * 0.6,
//                         fit: BoxFit.cover,
//                         loadingBuilder: (context, child, loadingProgress) {
//                           if (loadingProgress == null) return child;
//                           return Center(
//                             child: CircularProgressIndicator(
//                               value: loadingProgress.expectedTotalBytes != null
//                                   ? loadingProgress.cumulativeBytesLoaded /
//                                         loadingProgress.expectedTotalBytes!
//                                   : null,
//                             ),
//                           );
//                         },
//                         errorBuilder: (context, error, stackTrace) =>
//                             const Icon(Icons.broken_image, size: 50),
//                       ),
//                     ),
//                   )
//                 // ── VIDEO ─────────────────────────────
//                 else if (messageType == "video")
//                   GestureDetector(
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) =>
//                               VideoPlayerScreen(videoUrl: messageText),
//                         ),
//                       );
//                     },
//                     child: Container(
//                       width: size.width * 0.6,
//                       height: 150,
//                       decoration: BoxDecoration(
//                         color: Colors.black,
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: Stack(
//                         alignment: Alignment.center,
//                         children: [
//                           const Icon(
//                             Icons.play_circle_outline,
//                             color: Colors.white,
//                             size: 60,
//                           ),
//                           Positioned(
//                             bottom: 5,
//                             left: 5,
//                             child: Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 6,
//                                 vertical: 2,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: Colors.black54,
//                                 borderRadius: BorderRadius.circular(4),
//                               ),
//                               child: const Text(
//                                 "Tap to Play Video",
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 12,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   )
//                 // ── PDF ───────────────────────────────
//                 else if (messageType == "pdf")
//                   GestureDetector(
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => PDFViewerScreen(pdfUrl: messageText),
//                         ),
//                       );
//                     },
//                     child: Container(
//                       padding: const EdgeInsets.all(10),
//                       decoration: BoxDecoration(
//                         color: Colors.red.shade100,
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: const [
//                           Icon(
//                             Icons.picture_as_pdf,
//                             color: Colors.red,
//                             size: 40,
//                           ),
//                           SizedBox(width: 10),
//                           Text(
//                             "PDF Document",
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: Colors.red,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   )
//                 // ── VOICE ─────────────────────────────
//                 else if (messageType == "voice")
//                   GestureDetector(
//                     onTap: () {
//                       audioController.onPressedPlayButton(
//                         docId.hashCode,
//                         messageText,
//                       );
//                     },
//                     child: Obx(() {
//                       bool isPlaying =
//                           audioController.isRecordPlaying &&
//                           audioController.currentId == docId.hashCode;
//                       return Container(
//                         padding: const EdgeInsets.all(10),
//                         decoration: BoxDecoration(
//                           color: Colors.blue.shade100,
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Icon(
//                               isPlaying
//                                   ? Icons.pause_circle
//                                   : Icons.play_circle,
//                               color: Colors.blue,
//                               size: 30,
//                             ),
//                             const SizedBox(width: 10),
//                             Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 const Text(
//                                   "Voice Message",
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.blue,
//                                   ),
//                                 ),
//                                 if (isPlaying)
//                                   Obx(() {
//                                     double progress = audioController
//                                         .completedPercentage
//                                         .value;
//                                     return Container(
//                                       width: 100,
//                                       height: 3,
//                                       margin: const EdgeInsets.only(top: 4),
//                                       child: LinearProgressIndicator(
//                                         value: progress.isNaN ? 0 : progress,
//                                         backgroundColor: Colors.blue.shade200,
//                                         valueColor:
//                                             const AlwaysStoppedAnimation(
//                                               Colors.blue,
//                                             ),
//                                       ),
//                                     );
//                                   }),
//                               ],
//                             ),
//                           ],
//                         ),
//                       );
//                     }),
//                   )
//                 // ── LOCATION / LIVE LOCATION ──────────
//                 else if (messageType == "location" ||
//                     messageType == "live_location")
//                   GestureDetector(
//                     onTap: () {
//                       String url = messageText;
//                       if (url.contains("maps?q=")) {
//                         try {
//                           String coords = url.split("maps?q=").last;
//                           double lat = double.parse(coords.split(",")[0]);
//                           double lng = double.parse(coords.split(",")[1]);
//                           LatLng destination = LatLng(lat, lng);
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => LiveTracking(
//                                 chatroomId: widget.chatroomId,
//                                 isReceiver:
//                                     map['sendBy'] != StaticData.model!.userId,
//                                 destination: destination,
//                                 apiKey:
//                                     "AIzaSyC2fWxeerzaACQnhahbU85T83o4fTTOszw",
//                               ),
//                             ),
//                           );
//                         } catch (e) {
//                           debugPrint("Invalid maps link: $e");
//                         }
//                       }
//                     },
//                     child: Container(
//                       padding: const EdgeInsets.all(10),
//                       decoration: BoxDecoration(
//                         color: Colors.green.shade100,
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: const [
//                           Icon(Icons.location_on, color: Colors.blue, size: 26),
//                           SizedBox(width: 8),
//                           Text(
//                             "View Location",
//                             style: TextStyle(
//                               color: Colors.blue,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   )
//                 // ── TEXT ─────────────────────────────
//                 else
//                   Text(
//                     messageText,
//                     style: TextStyle(
//                       color: textColor,
//                       fontSize: 16,
//                       height: 1.4,
//                     ),
//                   ),
//               ],

//               const SizedBox(height: 4),

//               // ── Time + Status row ──────────────────
//               Row(
//                 mainAxisSize: MainAxisSize.min,
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   if (isEdited)
//                     Text(
//                       "Edited",
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: textColor.withOpacity(0.7),
//                       ),
//                     ),
//                   const SizedBox(width: 4),
//                   Text(
//                     timeString,
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: textColor.withOpacity(0.7),
//                     ),
//                   ),
//                   if (isMe) ...[
//                     const SizedBox(width: 4),
//                     Icon(
//                       // ⏳ Pending clock
//                       status == "pending"
//                           ? Icons.access_time
//                           : status == "sent"
//                           ? Icons.check
//                           : Icons.done_all,
//                       size: 16,
//                       color: status == "seen"
//                           ? Colors.blue
//                           : status == "pending"
//                           ? Colors.orange
//                           : Colors.grey,
//                     ),
//                   ],
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   //  MESSAGE LIST — Online: Firebase | Offline: SQLite

//   Widget _buildMessageList() {
//     if (_isOnline) {
//       // ── ONLINE: Firebase StreamBuilder ────────────
//       return StreamBuilder<QuerySnapshot>(
//         stream: _firestore
//             .collection('muazam chatroom')
//             .doc(widget.chatroomId)
//             .collection('muazam chats')
//             .orderBy("time", descending: false)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.data == null) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           // Firebase messages SQLite mein cache karo
//           for (var doc in snapshot.data!.docs) {
//             final map = doc.data() as Map<String, dynamic>;
//             final cached = ChatMessage.fromFirestore(
//               doc.id,
//               map,
//               widget.chatroomId,
//             );
//             _chatDb.upsertMessage(cached); // fire-and-forget
//           }

//           return ListView.builder(
//             itemCount: snapshot.data!.docs.length,
//             itemBuilder: (context, index) {
//               DocumentSnapshot doc = snapshot.data!.docs[index];
//               Map<String, dynamic> map = doc.data() as Map<String, dynamic>;
//               return GestureDetector(
//                 onLongPress: () {
//                   showModalBottomSheet(
//                     context: context,
//                     builder: (_) {
//                       return SafeArea(
//                         child: Wrap(
//                           children: [
//                             ListTile(
//                               leading: const Icon(Icons.content_copy),
//                               title: const Text("Copy"),
//                               onTap: () {
//                                 String decryptedText =
//                                     MessageEncryptionService().decryptMessage(
//                                       map['message'],
//                                     );
//                                 Clipboard.setData(
//                                   ClipboardData(text: decryptedText),
//                                 );
//                                 Navigator.pop(context);
//                               },
//                             ),
//                             if (map['sendBy'] == StaticData.model!.userId)
//                               ListTile(
//                                 leading: const Icon(Icons.edit),
//                                 title: const Text("Edit"),
//                                 onTap: () {
//                                   Navigator.pop(context);
//                                   editMessage(doc);
//                                 },
//                               ),
//                             ListTile(
//                               leading: const Icon(Icons.delete),
//                               title: const Text("Delete"),
//                               onTap: () {
//                                 Navigator.pop(context);
//                                 deleteMessage(
//                                   doc,
//                                   map['sendBy'] == StaticData.model!.userId,
//                                 );
//                               },
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   );
//                 },
//                 child: messages(
//                   MediaQuery.of(context).size,
//                   map,
//                   index,
//                   doc.id,
//                 ),
//               );
//             },
//           );
//         },
//       );
//     }

//     // ── OFFLINE: SQLite se dikhao ──────────────────
//     if (_localMessages.isEmpty) {
//       return const Center(
//         child: Text(
//           '📵 Offline — No cached messages',
//           style: TextStyle(color: Colors.grey, fontSize: 16),
//         ),
//       );
//     }
//     return ListView.builder(
//       itemCount: _localMessages.length,
//       itemBuilder: (context, index) {
//         final msg = _localMessages[index];
//         final map = <String, dynamic>{
//           'sendBy': msg.sendBy,
//           'message': msg.message,
//           'type': msg.type,
//           'time': msg.time,
//           'deletedFor': msg.deletedFor,
//           'status': msg.status,
//           'isEdited': msg.isEdited,
//         };
//         return messages(
//           MediaQuery.of(context).size,
//           map,
//           index,
//           msg.firebaseId,
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blueAccent,
//         title: Row(
//           children: [
//             const CircleAvatar(
//               backgroundImage: AssetImage('images/person2.jpeg'),
//               radius: 20,
//             ),
//             const SizedBox(width: 10),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   widget.profileModel.friendName ?? 'Friend',
//                   style: const TextStyle(fontSize: 18),
//                 ),
//                 StreamBuilder<DocumentSnapshot>(
//                   stream: FirebaseFirestore.instance
//                       .collection('muazam users')
//                       .doc(widget.profileModel.friendId)
//                       .snapshots(),
//                   builder: (context, snapshot) {
//                     if (!snapshot.hasData || !snapshot.data!.exists) {
//                       return const SizedBox.shrink();
//                     }
//                     final data = snapshot.data!.data() as Map<String, dynamic>;
//                     final isOnline = data['isOnline'] ?? false;
//                     final Timestamp? lastSeenTimestamp = data['lastSeen'];

//                     if (isOnline) {
//                       return const Text(
//                         'Online',
//                         style: TextStyle(
//                           color: Colors.greenAccent,
//                           fontSize: 12,
//                         ),
//                       );
//                     } else if (lastSeenTimestamp != null) {
//                       final lastSeen = lastSeenTimestamp.toDate();
//                       return Text(
//                         'Last seen ${timeago.format(lastSeen)}',
//                         style: const TextStyle(
//                           color: Colors.white70,
//                           fontSize: 12,
//                         ),
//                       );
//                     } else {
//                       return const Text(
//                         'offline',
//                         style: TextStyle(color: Colors.white70, fontSize: 12),
//                       );
//                     }
//                   },
//                 ),
//               ],
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.call),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => AudioCall(
//                     roomId: "",
//                     callstatus: false,
//                     friendmodel: widget.profileModel,
//                   ),
//                 ),
//               );
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.videocam),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => VideoCallScreen(
//                     roomId: "",
//                     callstatus: false,
//                     friendmodel: widget.profileModel,
//                   ),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           Column(
//             children: [
//               // ── Offline banner ───────────────────────
//               if (!_isOnline)
//                 Container(
//                   width: double.infinity,
//                   color: Colors.orange.shade700,
//                   padding: const EdgeInsets.symmetric(vertical: 5),
//                   child: const Text(
//                     '📵 Offline — Messages will sync when online',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(color: Colors.white, fontSize: 12),
//                   ),
//                 ),

//               // ── Message list ─────────────────────────
//               Expanded(child: _buildMessageList()),

//               Divider(color: Colors.grey[400], height: 1),

//               // ── Input area ───────────────────────────
//               Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   if (showMediaOptions)
//                     Container(
//                       color: Colors.grey[200],
//                       padding: const EdgeInsets.symmetric(vertical: 10),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: [
//                           _buildOption(
//                             Icons.image,
//                             "Image",
//                             pickAndUploadImage,
//                           ),
//                           _buildOption(
//                             Icons.videocam,
//                             "Video",
//                             pickAndUploadVideo,
//                           ),
//                         ],
//                       ),
//                     ),
//                   if (showFileOptions)
//                     Container(
//                       color: Colors.grey[200],
//                       padding: const EdgeInsets.symmetric(vertical: 10),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: [
//                           _buildOption(
//                             Icons.picture_as_pdf,
//                             "PDF",
//                             pickAndUploadPDF,
//                           ),
//                           _buildOption(
//                             Icons.my_location,
//                             "Send Location",
//                             () async {
//                               Position position =
//                                   await Geolocator.getCurrentPosition(
//                                     desiredAccuracy: LocationAccuracy.high,
//                                   );
//                               LatLng currentLatLng = LatLng(
//                                 position.latitude,
//                                 position.longitude,
//                               );
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (_) => SendLocationScreen(
//                                     currentLatLng: currentLatLng,
//                                     onSend: (LatLng loc) {
//                                       String mapsUrl =
//                                           "https://www.google.com/maps?q=${loc.latitude},${loc.longitude}";
//                                       onsendMessage(mapsUrl, "location");
//                                       ScaffoldMessenger.of(
//                                         context,
//                                       ).showSnackBar(
//                                         const SnackBar(
//                                           content: Text(
//                                             "Location sent successfully",
//                                           ),
//                                         ),
//                                       );
//                                     },
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                           _buildOption(Icons.search, "Nearby", () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (_) => const NearbySearchMap(),
//                               ),
//                             );
//                           }),
//                         ],
//                       ),
//                     ),
//                   Row(
//                     children: [
//                       const SizedBox(width: 10),
//                       GestureDetector(
//                         onLongPress: startRecord,
//                         onLongPressUp: stopRecord,
//                         child: Container(
//                           padding: const EdgeInsets.all(8),
//                           decoration: BoxDecoration(
//                             color: isRecording ? Colors.red : Colors.blueAccent,
//                             shape: BoxShape.circle,
//                           ),
//                           child: const Icon(
//                             Icons.mic,
//                             color: Colors.white,
//                             size: 24,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 5),
//                       Expanded(
//                         child: TextField(
//                           controller: msgController,
//                           decoration: const InputDecoration(
//                             hintText: "Type a message...",
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 5),
//                       IconButton(
//                         icon: const Icon(Icons.camera_alt),
//                         onPressed: () {
//                           setState(() {
//                             showMediaOptions = !showMediaOptions;
//                             showFileOptions = false;
//                           });
//                         },
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.attach_file),
//                         onPressed: () {
//                           setState(() {
//                             showFileOptions = !showFileOptions;
//                             showMediaOptions = false;
//                           });
//                         },
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.send),
//                         onPressed: () =>
//                             onsendMessage(msgController.text, "txt"),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ],
//           ),

//           // ── Incoming call overlay ──────────────────
//           if (_incomingCall)
//             Container(
//               color: Colors.black54,
//               alignment: Alignment.center,
//               child: Card(
//                 margin: const EdgeInsets.symmetric(horizontal: 30),
//                 child: Padding(
//                   padding: const EdgeInsets.all(20),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(
//                         "${widget.profileModel.friendName} is calling...",
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: [
//                           ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.green,
//                             ),
//                             onPressed: _acceptCall,
//                             child: const Text("Accept"),
//                           ),
//                           ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.red,
//                             ),
//                             onPressed: _declineCall,
//                             child: const Text("Decline"),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
