// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String? name;
  String? email;
  String? password;
  String? number;
  String? userId;

  bool? online;
  Timestamp? lastSeen;

  // 🔥 CALL FIELDS (NEW)
  String? roomId; // call room
  bool? callStatus; // true = incoming / active
  String? callerId; // kis ne call ki
  String? callType; // audio / video

  UserModel({
    this.name,
    this.email,
    this.password,
    this.number,
    this.userId,
    this.online,
    this.lastSeen,

    // new
    this.roomId,
    this.callStatus,
    this.callerId,
    this.callType,
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? password,
    String? number,
    String? userId,
    bool? online,
    Timestamp? lastSeen,

    // new
    String? roomId,
    bool? callStatus,
    String? callerId,
    String? callType,
  }) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      number: number ?? this.number,
      userId: userId ?? this.userId,
      online: online ?? this.online,
      lastSeen: lastSeen ?? this.lastSeen,

      roomId: roomId ?? this.roomId,
      callStatus: callStatus ?? this.callStatus,
      callerId: callerId ?? this.callerId,
      callType: callType ?? this.callType,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
      'number': number,
      'userId': userId,
      'online': online,
      'lastSeen': lastSeen,

      // 🔥 call
      'roomId': roomId,
      'callStatus': callStatus,
      'callerId': callerId,
      'callType': callType,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'],
      email: map['email'],
      password: map['password'],
      number: map['number'],
      userId: map['userId'],
      online: map['online'],
      lastSeen: map['lastSeen'],

      // 🔥 safe parsing (old users crash nahi honge)
      roomId: map.containsKey('roomId') ? map['roomId'] : null,
      callStatus: map.containsKey('callStatus') ? map['callStatus'] : false,
      callerId: map.containsKey('callerId') ? map['callerId'] : null,
      callType: map.containsKey('callType') ? map['callType'] : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'UserModel(name: $name, email: $email, userId: $userId, online: $online, roomId: $roomId, callStatus: $callStatus)';
  }
}
