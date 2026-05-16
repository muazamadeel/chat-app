import 'dart:io';
import 'package:flutter_application_11/message_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class ChatDatabaseHelper {
  // ── Singleton  ──────────────────
  static ChatDatabaseHelper? _instance;
  static Database? _database;

  ChatDatabaseHelper._privateConstructor();
  factory ChatDatabaseHelper() =>
      _instance ??= ChatDatabaseHelper._privateConstructor();

  // ── Table & Column names ─────────────────────────────
  final String tableChat = 'chat_table';
  final String colLocalId = 'localId';
  final String colFirebaseId = 'firebaseId';
  final String colChatroomId = 'chatroomId';
  final String colSendBy = 'sendBy';
  final String colMessage = 'message';
  final String colType = 'type';
  final String colTime = 'time';
  final String colDeletedFor = 'deletedFor';
  final String colStatus = 'status';
  final String colIsEdited = 'isEdited';
  final String colIsPending = 'isPending';

  // ── DB getter ───────────────────
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory dir = await getApplicationDocumentsDirectory();
    String path = join(dir.path, 'chat.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableChat (
        $colLocalId     INTEGER PRIMARY KEY AUTOINCREMENT,
        $colFirebaseId  TEXT NOT NULL,
        $colChatroomId  TEXT NOT NULL,
        $colSendBy      TEXT NOT NULL,
        $colMessage     TEXT NOT NULL,
        $colType        TEXT NOT NULL,
        $colTime        TEXT,
        $colDeletedFor  TEXT DEFAULT '',
        $colStatus      TEXT DEFAULT 'sent',
        $colIsEdited    INTEGER DEFAULT 0,
        $colIsPending   INTEGER DEFAULT 0
      )
    ''');
  }

  // ── CRUD ─────────────────────────────────────────────

  Future<int> insertMessage(ChatMessage msg) async {
    Database db = await database;
    return await db.insert(tableChat, msg.toMap());
  }

  Future<int> updateMessage(ChatMessage msg) async {
    Database db = await database;
    return await db.update(
      tableChat,
      msg.toMap(),
      where: '$colFirebaseId = ?',
      whereArgs: [msg.firebaseId],
    );
  }

  // Firebase ID se upsert — naya ho toh insert, pehle se ho toh update
  Future<void> upsertMessage(ChatMessage msg) async {
    Database db = await database;
    List<Map> existing = await db.query(
      tableChat,
      where: '$colFirebaseId = ?',
      whereArgs: [msg.firebaseId],
    );
    if (existing.isEmpty) {
      await db.insert(tableChat, msg.toMap());
    } else {
      await db.update(
        tableChat,
        msg.toMap(),
        where: '$colFirebaseId = ?',
        whereArgs: [msg.firebaseId],
      );
    }
  }

  Future<int> deleteMessage(String firebaseId) async {
    Database db = await database;
    return await db.delete(
      tableChat,
      where: '$colFirebaseId = ?',
      whereArgs: [firebaseId],
    );
  }

  // Ek chatroom ke saare messages (time order mein)
  Future<List<ChatMessage>> getMessages(String chatroomId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      tableChat,
      where: '$colChatroomId = ?',
      whereArgs: [chatroomId],
      orderBy: '$colLocalId ASC',
    );
    return maps.map((e) => ChatMessage.fromMap(e)).toList();
  }

  // Sirf pending messages (Firebase ko bhejne hain)
  Future<List<ChatMessage>> getPendingMessages(String chatroomId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      tableChat,
      where: '$colChatroomId = ? AND $colIsPending = 1',
      whereArgs: [chatroomId],
    );
    return maps.map((e) => ChatMessage.fromMap(e)).toList();
  }
}
