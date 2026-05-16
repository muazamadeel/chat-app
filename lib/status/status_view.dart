import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_11/static_data.dart';
import 'package:story_view/story_view.dart';
import 'package:video_player/video_player.dart';

class StatusViewScreen extends StatefulWidget {
  final List<Map<String, dynamic>> statuses;
  final String ownerId;
  final String ownerName;
  final Map<String, String> viewerNames;

  const StatusViewScreen({
    super.key,
    required this.statuses,
    required this.ownerId,
    required this.ownerName,
    this.viewerNames = const {},
  });

  @override
  State<StatusViewScreen> createState() => _StatusViewScreenState();
}

class _StatusViewScreenState extends State<StatusViewScreen> {
  final StoryController controller = StoryController();
  final Set<String> _markedStatusIds = {};
  late final List<Map<String, dynamic>> _orderedStatuses;
  late final List<StoryItem> _storyItems;
  int _currentStatusIndex = 0;

  @override
  void initState() {
    super.initState();
    _prepareStories();
    _markAllStatusesViewed();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _prepareStories() {
    _orderedStatuses = widget.statuses
        .where((status) {
          final type = (status["type"] ?? "image").toString().toLowerCase();
          if (type == "text") {
            final text = (status["text"] ?? "").toString().trim();
            return text.isNotEmpty;
          }
          final mediaUrl = (status["mediaUrl"] ?? "").toString().trim();
          return mediaUrl.isNotEmpty;
        })
        .map((status) => Map<String, dynamic>.from(status))
        .toList();

    _orderedStatuses.sort((a, b) {
      final aTime = _statusTime(a["createdAt"]);
      final bTime = _statusTime(b["createdAt"]);
      return aTime.compareTo(bTime);
    });

    _storyItems = _orderedStatuses.map((status) {
      final mediaUrl = status["mediaUrl"].toString();
      final caption = (status["caption"] ?? "").toString().trim();
      final type = (status["type"] ?? "image").toString().toLowerCase();
      final text = (status["text"] ?? "").toString().trim();
      final bgColorValue = status["bgColor"];

      if (type == "video") {
        return StoryItem(
          Container(
            color: Colors.black,
            child: Stack(
              children: [
                _StatusStoryVideo(url: mediaUrl, storyController: controller),
                if (caption.isNotEmpty)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: 24),
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      color: Colors.black54,
                      child: Text(
                        caption,
                        style: TextStyle(fontSize: 15, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          duration: Duration(seconds: 30),
        );
      }

      if (type == "text") {
        Color bgColor = Colors.black87;
        if (bgColorValue is int) {
          bgColor = Color(bgColorValue);
        } else if (bgColorValue is num) {
          bgColor = Color(bgColorValue.toInt());
        } else if (bgColorValue is String) {
          final parsed = int.tryParse(bgColorValue);
          if (parsed != null) {
            bgColor = Color(parsed);
          }
        }

        return StoryItem.text(
          title: text,
          backgroundColor: bgColor,
          textStyle: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
          duration: Duration(seconds: 5),
        );
      }

      return StoryItem.pageImage(
        url: mediaUrl,
        controller: controller,
        caption: caption.isEmpty
            ? null
            : Text(
                caption,
                style: TextStyle(color: Colors.white, fontSize: 15),
                textAlign: TextAlign.center,
              ),
      );
    }).toList();
  }

  DateTime _statusTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  DateTime? _statusViewTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      final asInt = int.tryParse(value);
      if (asInt != null) {
        return DateTime.fromMillisecondsSinceEpoch(asInt);
      }
      return DateTime.tryParse(value);
    }
    return null;
  }

  List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString().trim()).toList();
    }
    return [];
  }

  bool get _isOwnerViewing {
    final viewerId = StaticData.model?.userId;
    if (viewerId == null || viewerId.isEmpty) return false;
    return viewerId == widget.ownerId;
  }

  Future<void> _markViewedOnServer({
    required String statusId,
    required String viewerId,
  }) async {
    final docRef = FirebaseFirestore.instance
        .collection("muazam_status")
        .doc(widget.ownerId)
        .collection("statuses")
        .doc(statusId);

    try {
      await docRef.update({
        "viewers": FieldValue.arrayUnion([viewerId]),
        "viewerDetails.$viewerId": FieldValue.serverTimestamp(),
      });
    } catch (_) {
      await docRef
          .set({
            "viewers": FieldValue.arrayUnion([viewerId]),
            "viewerDetails": {viewerId: FieldValue.serverTimestamp()},
          }, SetOptions(merge: true))
          .catchError((error) {
            debugPrint("mark viewed error: $error");
          });
    }
  }

  String _viewerName(String viewerId) {
    final name = (widget.viewerNames[viewerId] ?? "").toString().trim();
    if (name.isEmpty) return viewerId;
    return name;
  }

  String _timeAgo(DateTime? dateTime) {
    if (dateTime == null) return "Seen";

    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hr ago";
    if (diff.inDays < 7) return "${diff.inDays} day ago";
    if (diff.inDays < 30) return "${(diff.inDays / 7).floor()} wk ago";

    final d = dateTime.day.toString().padLeft(2, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final y = dateTime.year.toString();
    final h = dateTime.hour.toString().padLeft(2, '0');
    final min = dateTime.minute.toString().padLeft(2, '0');
    return "$d/$m/$y $h:$min";
  }

  int _currentStatusViewCount() {
    if (!_isOwnerViewing) return 0;
    if (_orderedStatuses.isEmpty) return 0;
    if (_currentStatusIndex < 0 ||
        _currentStatusIndex >= _orderedStatuses.length) {
      return 0;
    }

    final status = _orderedStatuses[_currentStatusIndex];
    final viewers = _toStringList(status["viewers"]);
    final uniqueViewers = <String>{};
    for (var viewer in viewers) {
      if (viewer.isEmpty || viewer == widget.ownerId) continue;
      uniqueViewers.add(viewer);
    }
    return uniqueViewers.length;
  }

  Future<List<Map<String, dynamic>>> _loadCurrentStatusViews() async {
    if (!_isOwnerViewing) return [];
    if (_orderedStatuses.isEmpty) return [];
    if (_currentStatusIndex < 0 ||
        _currentStatusIndex >= _orderedStatuses.length) {
      return [];
    }

    Map<String, dynamic> status = Map<String, dynamic>.from(
      _orderedStatuses[_currentStatusIndex],
    );
    final statusId = (status["id"] ?? "").toString().trim();
    if (statusId.isEmpty) return [];

    try {
      final doc = await FirebaseFirestore.instance
          .collection("muazam_status")
          .doc(widget.ownerId)
          .collection("statuses")
          .doc(statusId)
          .get();
      final data = doc.data();
      if (data != null) {
        status = Map<String, dynamic>.from(data);
        _orderedStatuses[_currentStatusIndex] = status;
      }
    } catch (_) {}

    final viewers = _toStringList(status["viewers"]);
    final viewerDetails = status["viewerDetails"];
    final List<Map<String, dynamic>> rows = [];

    for (var viewerId in viewers) {
      if (viewerId.isEmpty || viewerId == widget.ownerId) continue;

      DateTime? viewedAt;
      if (viewerDetails is Map) {
        viewedAt = _statusViewTime(viewerDetails[viewerId]);
      }

      rows.add({
        "viewerId": viewerId,
        "name": _viewerName(viewerId),
        "viewedAt": viewedAt,
      });
    }

    rows.sort((a, b) {
      final aTime = a["viewedAt"] as DateTime?;
      final bTime = b["viewedAt"] as DateTime?;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    return rows;
  }

  Future<void> _showViewsBottomSheet() async {
    if (!_isOwnerViewing) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.55,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: 10),
              Container(
                height: 4,
                width: 42,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.remove_red_eye, color: Colors.black87),
                    SizedBox(width: 8),
                    Text(
                      "Status Views",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Divider(height: 1),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _loadCurrentStatusViews(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text("Could not load viewers"));
                    }

                    final viewers = snapshot.data ?? [];
                    if (viewers.isEmpty) {
                      return Center(
                        child: Text(
                          "No one has viewed this status yet",
                          style: TextStyle(color: Colors.black54),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: viewers.length,
                      separatorBuilder: (_, __) => Divider(height: 1),
                      itemBuilder: (context, index) {
                        final row = viewers[index];
                        final viewerId = (row["viewerId"] ?? "").toString();
                        final name = (row["name"] ?? viewerId).toString();
                        final viewedAt = row["viewedAt"] as DateTime?;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.black12,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : "U",
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            name,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            viewerId,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.black54),
                          ),
                          trailing: Text(
                            _timeAgo(viewedAt),
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _markAllStatusesViewed() {
    final viewerId = StaticData.model?.userId;

    if (viewerId == null || viewerId.isEmpty) return;
    if (widget.ownerId.isEmpty || widget.ownerId == viewerId) return;

    for (var status in _orderedStatuses) {
      final statusId = (status["id"] ?? "").toString();
      if (statusId.isEmpty || _markedStatusIds.contains(statusId)) continue;

      _markedStatusIds.add(statusId);
      _markViewedOnServer(statusId: statusId, viewerId: viewerId);
    }
  }

  void _onStoryShow(StoryItem item, int index) {
    if (index < 0 || index >= _orderedStatuses.length) return;
    if (_currentStatusIndex != index && mounted) {
      setState(() {
        _currentStatusIndex = index;
      });
    }

    final status = _orderedStatuses[index];
    final statusId = (status["id"] ?? "").toString();
    final viewerId = StaticData.model?.userId;

    if (viewerId == null || viewerId.isEmpty) return;
    if (widget.ownerId.isEmpty || widget.ownerId == viewerId) return;
    if (statusId.isEmpty || _markedStatusIds.contains(statusId)) return;

    _markedStatusIds.add(statusId);
    _markViewedOnServer(statusId: statusId, viewerId: viewerId);
  }

  @override
  Widget build(BuildContext context) {
    if (_storyItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.ownerName)),
        body: const Center(child: Text("No status media found")),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          StoryView(
            storyItems: _storyItems,
            controller: controller,
            onStoryShow: _onStoryShow,
            onComplete: () {
              if (mounted) {
                Navigator.pop(context);
              }
            },
            onVerticalSwipeComplete: (direction) {
              if (direction == Direction.down && mounted) {
                Navigator.pop(context);
              }
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white24,
                    child: Text(
                      widget.ownerName.isNotEmpty
                          ? widget.ownerName[0].toUpperCase()
                          : "U",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.ownerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isOwnerViewing)
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                minimum: EdgeInsets.only(bottom: 18),
                child: InkWell(
                  onTap: _showViewsBottomSheet,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.remove_red_eye,
                          size: 20,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Views (${_currentStatusViewCount()})",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusStoryVideo extends StatefulWidget {
  final String url;
  final StoryController storyController;

  const _StatusStoryVideo({required this.url, required this.storyController});

  @override
  State<_StatusStoryVideo> createState() => _StatusStoryVideoState();
}

class _StatusStoryVideoState extends State<_StatusStoryVideo> {
  VideoPlayerController? _videoController;
  bool _loading = true;
  bool _failed = false;
  bool _movedNext = false;
  StreamSubscription<PlaybackState>? _playbackSubscription;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      widget.storyController.pause();
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
      );

      await _videoController!.initialize();
      _videoController!.setLooping(false);
      _videoController!.addListener(_onVideoTick);

      _playbackSubscription = widget.storyController.playbackNotifier.listen((
        state,
      ) {
        if (_videoController == null ||
            !_videoController!.value.isInitialized) {
          return;
        }
        if (state == PlaybackState.pause) {
          _videoController!.pause();
        } else if (state == PlaybackState.play) {
          if (!_movedNext) {
            _videoController!.play();
          }
        }
      });

      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      _videoController!.play();
      widget.storyController.play();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          widget.storyController.next();
        }
      });
    }
  }

  void _onVideoTick() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }

    final position = _videoController!.value.position;
    final duration = _videoController!.value.duration;

    if (!_movedNext &&
        duration > Duration.zero &&
        position >= duration - Duration(milliseconds: 200)) {
      _movedNext = true;
      widget.storyController.next();
    }
  }

  @override
  void dispose() {
    _playbackSubscription?.cancel();
    _videoController?.removeListener(_onVideoTick);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_failed ||
        _videoController == null ||
        !_videoController!.value.isInitialized) {
      return Center(
        child: Text(
          "Video failed to load.",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio == 0
            ? 9 / 16
            : _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      ),
    );
  }
}
