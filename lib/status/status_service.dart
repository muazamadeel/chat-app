import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_11/static_data.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class StatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // ── Pick image from gallery and return path ──
  Future<String?> pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      return picked?.path;
    } catch (e) {
      debugPrint("pickImage error: $e");
      return null;
    }
  }

  // ── Pick video from gallery and return path ──
  Future<String?> pickVideo() async {
    try {
      final XFile? picked = await _picker.pickVideo(
        source: ImageSource.gallery,
      );
      return picked?.path;
    } catch (e) {
      debugPrint("pickVideo error: $e");
      return null;
    }
  }

  // ── Upload image from file path ──
  Future<bool> uploadImageStatusFromFile({
    required String filePath,
    String caption = "",
  }) async {
    return _uploadFromPath(
      filePath: filePath,
      isVideo: false,
      caption: caption,
    );
  }

  // ── Upload video from file path ──
  Future<bool> uploadVideoStatusFromFile({
    required String filePath,
    String caption = "",
  }) async {
    return _uploadFromPath(filePath: filePath, isVideo: true, caption: caption);
  }

  // ── Core upload method ──
  Future<bool> _uploadFromPath({
    required String filePath,
    required bool isVideo,
    String caption = "",
  }) async {
    try {
      final uid = StaticData.model?.userId;
      if (uid == null || uid.isEmpty) {
        debugPrint("uploadFromPath: uid is null");
        return false;
      }

      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint("uploadFromPath: file does not exist at $filePath");
        return false;
      }

      final statusId = const Uuid().v4();
      final fileExtension = filePath.split('.').last.toLowerCase();
      final contentType = isVideo
          ? "video/$fileExtension"
          : "image/$fileExtension";
      final statusType = isVideo ? "video" : "image";

      debugPrint("Uploading $statusType to storage...");

      final ref = _storage
          .ref()
          .child("status")
          .child(uid)
          .child("$statusId.$fileExtension");

      await ref.putFile(file, SettableMetadata(contentType: contentType));

      final url = await ref.getDownloadURL();
      debugPrint("Upload done. URL: $url");

      await _firestore
          .collection("muazam_status")
          .doc(uid)
          .collection("statuses")
          .doc(statusId)
          .set({
            "id": statusId,
            "userId": uid,
            "mediaUrl": url,
            "type": statusType,
            "caption": caption.trim(),
            "createdAt": Timestamp.now(),
            "expiresAt": Timestamp.fromDate(
              DateTime.now().add(const Duration(hours: 24)),
            ),
            "viewers": [],
          });

      debugPrint("Firestore write done.");
      return true;
    } catch (error) {
      debugPrint("_uploadFromPath error: $error");
      return false;
    }
  }

  // ── Upload text status ──
  Future<bool> uploadTextStatus({
    required String text,
    required int backgroundColor,
  }) async {
    try {
      final uid = StaticData.model?.userId;
      if (uid == null || uid.isEmpty) return false;

      final statusId = const Uuid().v4();

      await _firestore
          .collection("muazam_status")
          .doc(uid)
          .collection("statuses")
          .doc(statusId)
          .set({
            "id": statusId,
            "userId": uid,
            "mediaUrl": "",
            "type": "text",
            "text": text.trim(),
            "bgColor": backgroundColor,
            "caption": "",
            "createdAt": Timestamp.now(),
            "expiresAt": Timestamp.fromDate(
              DateTime.now().add(const Duration(hours: 24)),
            ),
            "viewers": [],
          });

      return true;
    } catch (error) {
      debugPrint("uploadTextStatus error: $error");
      return false;
    }
  }

  // ── Stream grouped statuses ──
  Stream<Map<String, List<Map<String, dynamic>>>> getGroupedStatuses({
    required Set<String> visibleUserIds,
  }) {
    final uid = StaticData.model?.userId;
    if (uid == null || uid.isEmpty) {
      return Stream.value({});
    }

    final Set<String> allowedIds = Set<String>.from(visibleUserIds);
    allowedIds.add(uid);

    return _firestore
        .collectionGroup("statuses")
        .where("expiresAt", isGreaterThan: Timestamp.now())
        .snapshots()
        .map((snapshot) {
          Map<String, List<Map<String, dynamic>>> grouped = {};

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final existingId = (data["id"] ?? "").toString().trim();
            if (existingId.isEmpty) {
              data["id"] = doc.id;
            }
            final userId = (data["userId"] ?? "").toString();
            final mediaUrl = (data["mediaUrl"] ?? "").toString().trim();
            final type = (data["type"] ?? "image").toString().toLowerCase();
            final text = (data["text"] ?? "").toString().trim();

            if (userId.isEmpty) continue;
            if (type != "image" && type != "video" && type != "text") continue;
            if ((type == "image" || type == "video") && mediaUrl.isEmpty) {
              continue;
            }
            if (type == "text" && text.isEmpty) continue;
            if (!allowedIds.contains(userId)) continue;

            if (!grouped.containsKey(userId)) {
              grouped[userId] = [];
            }
            grouped[userId]!.add(data);
          }

          grouped.forEach((key, value) {
            value.sort((a, b) {
              final aTime = _asDateTime(a["createdAt"]);
              final bTime = _asDateTime(b["createdAt"]);
              return aTime.compareTo(bTime);
            });
          });

          return grouped;
        })
        .handleError((error) {
          debugPrint("getGroupedStatuses error: $error");
        });
  }

  DateTime _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
