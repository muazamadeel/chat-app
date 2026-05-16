class ChatMessage {
  int? localId; // SQLite auto ID
  String firebaseId; // Firestore doc ID (pending ho toh "pending_timestamp")
  String chatroomId;
  String sendBy;
  String message; // encrypted
  String type; // txt, img, video, voice, pdf, location
  String time; // "HH:mm" string
  String deletedFor; // comma-separated userIds, "all" for everyone
  String status; // sent, delivered, seen, pending
  bool isEdited;
  bool isPending; // false = Firebase pe hai, true = offline queue mein

  ChatMessage({
    this.localId,
    required this.firebaseId,
    required this.chatroomId,
    required this.sendBy,
    required this.message,
    required this.type,
    required this.time,
    this.deletedFor = '',
    this.status = 'sent',
    this.isEdited = false,
    this.isPending = false,
  });

  // SQLite ke liye
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'firebaseId': firebaseId,
      'chatroomId': chatroomId,
      'sendBy': sendBy,
      'message': message,
      'type': type,
      'time': time,
      'deletedFor': deletedFor,
      'status': status,
      'isEdited': isEdited ? 1 : 0,
      'isPending': isPending ? 1 : 0,
    };
    if (localId != null) map['localId'] = localId;
    return map;
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      localId: map['localId'],
      firebaseId: map['firebaseId'],
      chatroomId: map['chatroomId'],
      sendBy: map['sendBy'],
      message: map['message'],
      type: map['type'],
      time: map['time'],
      deletedFor: map['deletedFor'] ?? '',
      status: map['status'] ?? 'sent',
      isEdited: map['isEdited'] == 1,
      isPending: map['isPending'] == 1,
    );
  }

  // Firebase se ChatMessage banana
  factory ChatMessage.fromFirestore(
    String docId,
    Map<String, dynamic> map,
    String chatroomId,
  ) {
    final ts = map['time'];
    String timeStr = '';
    if (ts != null) {
      final dt = ts.toDate();
      timeStr =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return ChatMessage(
      firebaseId: docId,
      chatroomId: chatroomId,
      sendBy: map['sendBy'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? 'txt',
      time: timeStr,
      deletedFor: (map['deletedFor'] as List?)?.join(',') ?? '',
      status: map['status'] ?? 'sent',
      isEdited: map['isEdited'] ?? false,
      isPending: false,
    );
  }
}
