import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_11/call_controller.dart';
import 'package:flutter_application_11/call_screens/audio_call_screen.dart';
import 'package:flutter_application_11/call_screens/video_call_screen.dart';
import 'package:flutter_application_11/chatpage.dart';
import 'package:flutter_application_11/friendmodel.dart';
import 'package:flutter_application_11/signaling.dart';
import 'package:flutter_application_11/static_data.dart';
import 'package:flutter_application_11/status/status_service.dart';
import 'package:flutter_application_11/status/status_tile_model.dart';
import 'package:flutter_application_11/status/status_view.dart';
import 'package:flutter_application_11/user_model.dart';
import 'package:get/get.dart';
import 'package:flutter_application_11/l10n/app_localizations.dart';
import 'package:flutter_application_11/editprofile.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  List<Friendmodel> contacts = [];
  List<Friendmodel> filteredContacts = [];
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();

  Signaling signaling = Signaling();

  final StatusService statusService = StatusService();
  final Map<String, DateTime> _locallyViewedStatusTimeByUserId = {};
  final List<Color> _textStatusColors = [
    Color(0xFF1F2937),
    Color(0xFFB91C1C),
    Color(0xFF0F766E),
    Color(0xFF6D28D9),
    Color(0xFF0C4A6E),
    Color(0xFF7C2D12),
  ];

  getfriend() async {
    contacts.clear();
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("muazam contacts")
        .where("userId", isEqualTo: StaticData.model!.userId)
        .get();

    for (var req in snapshot.docs) {
      Friendmodel model = Friendmodel.fromMap(
        req.data() as Map<String, dynamic>,
      );
      contacts.add(model);
    }
    if (mounted) {
      setState(() {
        filteredContacts = List.from(contacts);
      });
    }
  }

  void _filterContacts(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredContacts = List.from(contacts);
      });
    } else {
      setState(() {
        filteredContacts = contacts.where((c) => 
          (c.friendName ?? "").toLowerCase().contains(query.toLowerCase())
        ).toList();
      });
    }
  }

  String chatRoomId(String user1, String user2) {
    if (user1[0].toLowerCase().codeUnits[0] >
        user2.toLowerCase().codeUnits[0]) {
      return "$user1$user2";
    } else {
      return "$user2$user1";
    }
  }

  @override
  void initState() {
    super.initState();
    getfriend();
    Get.put(CallController());
    WidgetsBinding.instance.addObserver(this);
    setStatus(true);
  }

  @override
  void dispose() {
    setStatus(false);
    WidgetsBinding.instance.removeObserver(this);
    CallController.to.disposeRenderers();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setStatus(true);
    } else if (state == AppLifecycleState.paused) {
      setStatus(false);
    }
  }

  void setStatus(bool status) async {
    await FirebaseFirestore.instance
        .collection('muazam users')
        .doc(StaticData.model!.userId!)
        .update({
          "online": status,
          "lastSeen": status ? null : FieldValue.serverTimestamp(),
        });
  }

  Stream<UserModel?> callerProfileStream(String callerId) {
    return FirebaseFirestore.instance
        .collection('muazam users')
        .doc(callerId)
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            return UserModel.fromMap(doc.data()!);
          }
          return null;
        });
  }

  // ───────────── Status helpers ─────────────

  Set<String> _buildVisibleStatusUserIds() {
    final Set<String> ids = {};
    final myId = StaticData.model?.userId;
    if (myId != null && myId.isNotEmpty) ids.add(myId);
    for (var friend in contacts) {
      final friendId = friend.friendId;
      if (friendId != null && friendId.isNotEmpty) ids.add(friendId);
    }
    return ids;
  }

  Map<String, String> _buildFriendNameMap() {
    final Map<String, String> friendNames = {};
    final myId = StaticData.model?.userId ?? "";
    final myName = (StaticData.model?.name ?? "Me").toString();
    if (myId.isNotEmpty) friendNames[myId] = myName;
    for (var friend in contacts) {
      final friendId = friend.friendId;
      if (friendId == null || friendId.isEmpty) continue;
      friendNames[friendId] = friend.friendName ?? "User";
    }
    return friendNames;
  }

  DateTime _statusTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  List<String> _toStringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString().trim()).toList();
    return [];
  }

  List<StatusTileModel> _buildStatusTiles(
    Map<String, List<Map<String, dynamic>>> groupedStatuses,
    String viewerId,
    Map<String, String> friendNames,
  ) {
    final List<StatusTileModel> tiles = [];
    groupedStatuses.forEach((userId, statuses) {
      if (userId == viewerId) return;
      if (statuses.isEmpty) return;

      bool hasUnViewed = false;
      for (var status in statuses) {
        final viewers = _toStringList(status["viewers"]);
        if (!viewers.contains(viewerId)) {
          hasUnViewed = true;
          break;
        }
      }

      final DateTime lastTime = _statusTime(statuses.last["createdAt"]);
      final String name = (friendNames[userId] ?? "User").toString();
      final locallyViewedTime = _locallyViewedStatusTimeByUserId[userId];
      if (locallyViewedTime != null && !lastTime.isAfter(locallyViewedTime)) {
        hasUnViewed = false;
      }

      tiles.add(
        StatusTileModel(
          userId: userId,
          name: name,
          statuses: statuses,
          hasUnViewed: hasUnViewed,
          lastStatusTime: lastTime,
        ),
      );
    });

    tiles.sort((a, b) {
      if (a.hasUnViewed && !b.hasUnViewed) return -1;
      if (!a.hasUnViewed && b.hasUnViewed) return 1;
      return b.lastStatusTime.compareTo(a.lastStatusTime);
    });

    return tiles;
  }

  // ───────────── Upload methods ─────────────

  // SAHI FLOW: Pehle gallery kholo → phir caption → phir upload
  Future<void> _pickAndUploadMedia({required bool isVideo}) async {
    // Step 1: Gallery se file pick karo
    final String? filePath = isVideo
        ? await statusService.pickVideo()
        : await statusService.pickImage();

    if (filePath == null) return; // user ne cancel kiya
    if (!mounted) return;

    // Step 2: Caption dialog dikhao
    String caption = "";
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(isVideo ? "Video Caption" : "Image Caption"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                maxLines: 3,
                maxLength: 150,
                autofocus: false,
                onChanged: (value) => caption = value,
                decoration: InputDecoration(
                  hintText: "Write a caption (optional)",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "You can skip caption.",
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Skip"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Post"),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    // Step 3: Loading dikhao aur upload karo
    _showLoadingSnackBar(isVideo ? "Uploading video..." : "Uploading image...");

    bool uploaded;
    if (isVideo) {
      uploaded = await statusService.uploadVideoStatusFromFile(
        filePath: filePath,
        caption: caption.trim(),
      );
    } else {
      uploaded = await statusService.uploadImageStatusFromFile(
        filePath: filePath,
        caption: caption.trim(),
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (uploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isVideo ? "Video status uploaded!" : "Image status uploaded!",
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Upload failed. Try again."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showLoadingSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text(message),
          ],
        ),
        duration: Duration(seconds: 60),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _uploadTextStatus({
    required String text,
    required Color color,
  }) async {
    final uploaded = await statusService.uploadTextStatus(
      text: text,
      backgroundColor: color.value,
    );
    if (!mounted) return;
    if (uploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Text status uploaded!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showTextStatusDialog() async {
    String statusText = "";
    Color selectedColor = _textStatusColors.first;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: Text("Text Status"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      maxLines: 4,
                      maxLength: 300,
                      onChanged: (value) => statusText = value,
                      decoration: InputDecoration(
                        hintText: "Type your status...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: _textStatusColors.map((color) {
                        final selected = color.value == selectedColor.value;
                        return GestureDetector(
                          onTap: () =>
                              setLocalState(() => selectedColor = color),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected ? Colors.black : Colors.white,
                                width: selected ? 2 : 1,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    final text = statusText.trim();
                    if (text.isEmpty) return;
                    Navigator.pop(context);
                    await _uploadTextStatus(text: text, color: selectedColor);
                  },
                  child: Text("Post"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showStatusUploadOptions() async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.image),
                title: Text("Image Status"),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickAndUploadMedia(isVideo: false);
                },
              ),
              ListTile(
                leading: Icon(Icons.videocam),
                title: Text("Video Status"),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickAndUploadMedia(isVideo: true);
                },
              ),
              ListTile(
                leading: Icon(Icons.text_fields),
                title: Text("Text Status"),
                onTap: () async {
                  Navigator.pop(context);
                  await _showTextStatusDialog();
                },
              ),
              SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  // ───────────── Status bar widget ─────────────

  Widget _buildStatusBar() {
    return StreamBuilder<Map<String, List<Map<String, dynamic>>>>(
      stream: statusService.getGroupedStatuses(
        visibleUserIds: _buildVisibleStatusUserIds(),
      ),
      builder: (context, snapshot) {
        final groupedStatuses = snapshot.data ?? {};
        final myId = (StaticData.model?.userId ?? "").toString();
        final friendNames = _buildFriendNameMap();
        final myStatuses = groupedStatuses[myId] ?? [];
        final statusTiles = _buildStatusTiles(
          groupedStatuses,
          myId,
          friendNames,
        );
        final myName = (friendNames[myId] ?? "My Status").toString();
        final myInitial = myName.isNotEmpty ? myName[0].toUpperCase() : "M";

        return SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: statusTiles.length + 1,
            itemBuilder: (context, index) {
              // ── My Status ──
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () async {
                          if (myId.isEmpty) return;
                          if (myStatuses.isEmpty) {
                            await _showStatusUploadOptions();
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StatusViewScreen(
                                statuses: myStatuses,
                                ownerId: myId,
                                ownerName: myName,
                                viewerNames: friendNames,
                              ),
                            ),
                          );
                        },
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: myStatuses.isEmpty
                                      ? Colors.white38
                                      : Colors.green,
                                  width: 3,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.grey.shade300,
                                child: Text(
                                  myInitial,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: () async {
                                  await _showStatusUploadOptions();
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.green,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.add,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "My Status",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // ── Friends Status ──
              final statusModel = statusTiles[index - 1];
              final String initial = statusModel.name.isNotEmpty
                  ? statusModel.name[0].toUpperCase()
                  : "U";

              return GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StatusViewScreen(
                        statuses: statusModel.statuses,
                        ownerId: statusModel.userId,
                        ownerName: statusModel.name,
                        viewerNames: friendNames,
                      ),
                    ),
                  );
                  if (mounted) {
                    setState(() {
                      _locallyViewedStatusTimeByUserId[statusModel.userId] =
                          statusModel.lastStatusTime;
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: statusModel.hasUnViewed
                                ? Colors.green
                                : Colors.grey,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey.shade300,
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        statusModel.name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ───────────── Build ─────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF246BFD),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection("muazam users")
              .doc(StaticData.model!.userId)
              .snapshots(),
          builder: (context, profileSnapshot) {
              return Stack(
                children: [
                  // Background color updated to Hichat Blue
                  Container(
                    width: size.width,
                    height: size.height,
                    color: const Color(0xFF246BFD),
                  ),

                  // White bottom card
                  Positioned(
                    bottom: 0,
                    child: Container(
                      height: size.height * 0.58,
                      width: size.width,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                    ),
                  ),

                  // Top header
                  Positioned(
                    top: 20,
                    left: 20,
                    right: 20,
                    child: isSearching
                        ? Container(
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: TextField(
                              controller: searchController,
                              onChanged: _filterContacts,
                              style: TextStyle(color: Colors.black87),
                              decoration: InputDecoration(
                                hintText: "Search friends...",
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.search, color: Colors.black54),
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.close, color: Colors.black54),
                                  onPressed: () {
                                    setState(() {
                                      isSearching = false;
                                      searchController.clear();
                                      _filterContacts("");
                                    });
                                  },
                                ),
                              ),
                            ),
                          )
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              // Center text
                              Align(
                                alignment: Alignment.center,
                                child: Text(
                                  "Chatbox",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              // Left profile
                              Align(
                                alignment: Alignment.centerLeft,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => Editprofile()),
                                    );
                                  },
                                  child: Container(
                                    width: 45,
                                    height: 45,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: DecorationImage(
                                        image: (StaticData.model?.imageUrl != null && StaticData.model!.imageUrl!.isNotEmpty)
                                            ? NetworkImage(StaticData.model!.imageUrl!) as ImageProvider
                                            : const AssetImage("images/person2.jpeg") as ImageProvider,
                                        fit: BoxFit.cover,
                                      ),
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                              ),
                              // Right search
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  icon: Icon(Icons.search_rounded, color: Colors.white, size: 28),
                                  onPressed: () {
                                    setState(() {
                                      isSearching = true;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),

                  // Status bar
                  Positioned(
                    top: 90,
                    left: 0,
                    right: 0,
                    child: _buildStatusBar(),
                  ),

                  // Chat list (Original layout)
                  Padding(
                    padding: const EdgeInsets.only(top: 220.0),
                    child: SizedBox(
                      height: size.height * 0.7,
                      width: size.width,
                      child: ListView.builder(
                        itemCount: isSearching && searchController.text.isNotEmpty 
                            ? filteredContacts.length 
                            : contacts.length,
                        scrollDirection: Axis.vertical,
                        itemBuilder: (context, index) {
                          final currentContact = isSearching && searchController.text.isNotEmpty 
                              ? filteredContacts[index] 
                              : contacts[index];
                              
                          return GestureDetector(
                            onTap: () {
                              String id = chatRoomId(
                                currentContact.friendId!,
                                StaticData.model!.userId!,
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    chatroomId: id,
                                    profileModel: currentContact,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: const Color(0xFFE9F0FF),
                                    child: Text(
                                      currentContact.friendName != null && currentContact.friendName!.isNotEmpty
                                          ? currentContact.friendName![0].toUpperCase()
                                          : "U",
                                      style: const TextStyle(
                                        color: Color(0xFF246BFD),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          currentContact.friendName ?? 'Unknown',
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Tap to chat...",
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "",
                                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                                      ),
                                      const SizedBox(height: 6),
                                      Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 22),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Incoming call overlay
                  profileSnapshot.data != null
                      ? profileSnapshot.data!.get('callStatus') == true
                            ? Align(
                                alignment: Alignment.center,
                                child: StreamBuilder(
                                  stream: callerProfileStream(
                                    profileSnapshot.data!.get('callerId'),
                                  ),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const CircularProgressIndicator(
                                        color: Colors.white,
                                      );
                                    }

                                    final callerUser = snapshot.data!;
                                    final Friendmodel callerFriend =
                                        Friendmodel(
                                          friendId: callerUser.userId,
                                          friendName: callerUser.name,
                                          id: "",
                                          userId: StaticData.model!.userId,
                                        );

                                    // Modern Incoming Call Card
                                    return Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        margin: const EdgeInsets.all(20),
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(28),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.18),
                                              blurRadius: 30,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Caller avatar
                                            CircleAvatar(
                                              radius: 36,
                                              backgroundColor: const Color(0xFFE9F0FF),
                                              child: Text(
                                                (callerFriend.friendName ?? 'U')[0].toUpperCase(),
                                                style: const TextStyle(
                                                  color: Color(0xFF246BFD),
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              callerFriend.friendName ?? 'Unknown',
                                              style: const TextStyle(
                                                color: Colors.black87,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            const Text(
                                              'Incoming Call...',
                                              style: TextStyle(color: Colors.grey, fontSize: 14),
                                            ),
                                            const SizedBox(height: 24),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              children: [
                                                // Decline
                                                GestureDetector(
                                                  onTap: () async {
                                                    signaling.hangUp(CallController.to.localRenderer);
                                                    await FirebaseFirestore.instance
                                                        .collection('muazam users')
                                                        .doc(profileSnapshot.data!.get('userId'))
                                                        .update({"callStatus": false, "roomId": '', "callType": "", "callerId": ""});
                                                  },
                                                  child: Column(
                                                    children: [
                                                      Container(
                                                        width: 60, height: 60,
                                                        decoration: BoxDecoration(
                                                          color: Colors.red.shade50,
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(Icons.call_end_rounded, color: Colors.red, size: 28),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      const Text('Decline', style: TextStyle(color: Colors.red, fontSize: 12)),
                                                    ],
                                                  ),
                                                ),
                                                // Accept
                                                GestureDetector(
                                                  onTap: () async {
                                                    if (profileSnapshot.data!.get('callType') == "audio") {
                                                      Navigator.push(context, MaterialPageRoute(
                                                        builder: (context) => AudioCall(
                                                          roomId: profileSnapshot.data!.get('roomId'),
                                                          callstatus: true,
                                                          friendmodel: callerFriend,
                                                        ),
                                                      ));
                                                    } else {
                                                      Navigator.push(context, MaterialPageRoute(
                                                        builder: (context) => VideoCallScreen(
                                                          roomId: profileSnapshot.data!.get('roomId'),
                                                          callstatus: true,
                                                          friendmodel: callerFriend,
                                                        ),
                                                      ));
                                                    }
                                                    await FirebaseFirestore.instance
                                                        .collection('muazam users')
                                                        .doc(profileSnapshot.data!.get('userId'))
                                                        .update({"callStatus": false, "roomId": ''});
                                                  },
                                                  child: Column(
                                                    children: [
                                                      Container(
                                                        width: 60, height: 60,
                                                        decoration: BoxDecoration(
                                                          color: Colors.green.shade50,
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(Icons.call_rounded, color: Colors.green, size: 28),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      const Text('Accept', style: TextStyle(color: Colors.green, fontSize: 12)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                            : const SizedBox()
                      : const SizedBox(),
                ],
              );
            },
          ),
        ),
    );
  }
}
