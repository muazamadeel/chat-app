import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_11/request_model.dart';
import 'package:flutter_application_11/static_data.dart';
import 'package:flutter_application_11/user_model.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_application_11/l10n/app_localizations.dart';

class Mycalls extends StatefulWidget {
  const Mycalls({super.key});

  @override
  State<Mycalls> createState() => _MycallsState();
}

class _MycallsState extends State<Mycalls> {
  List<UserModel> allUsers = [];
  List<UserModel> filteredUsers = [];
  bool isSearching = false;
  final TextEditingController searchController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    getAllUsers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void getAllUsers() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("muazam users")
        .where("userId", isNotEqualTo: StaticData.model!.userId)
        .get();
    
    for (var user in snapshot.docs) {
      UserModel model = UserModel.fromMap(user.data() as Map<String, dynamic>);
      allUsers.add(model);
    }
    filteredUsers = List.from(allUsers);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void filterUsers(String query) {
    if (query.isEmpty) {
      filteredUsers = List.from(allUsers);
    } else {
      filteredUsers = allUsers
          .where((user) => (user.name ?? "").toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    setState(() {});
  }

  Future<void> _sendRequest(UserModel targetUser) async {
    final l10n = AppLocalizations.of(context)!;
    final senderId = StaticData.model!.userId;
    final receiverId = targetUser.userId;

    final friendCheck = await FirebaseFirestore.instance
        .collection("muazam contacts")
        .where("userId", isEqualTo: senderId)
        .where("friendId", isEqualTo: receiverId)
        .get();

    if (friendCheck.docs.isNotEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.alreadyInContacts)));
      return;
    }

    final reverseCheck = await FirebaseFirestore.instance
        .collection("muazam requests")
        .where("senderId", isEqualTo: receiverId)
        .where("reciverId", isEqualTo: senderId)
        .get();

    if (reverseCheck.docs.isNotEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.userAlreadySentRequest)));
      return;
    }

    final requestCheck = await FirebaseFirestore.instance
        .collection("muazam requests")
        .where("senderId", isEqualTo: senderId)
        .where("reciverId", isEqualTo: receiverId)
        .get();

    if (requestCheck.docs.isNotEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.alreadySentRequest)));
      return;
    }

    var uid = const Uuid();
    String reqID = uid.v4();

    Reqmodel model = Reqmodel(
      reciverId: receiverId,
      reciverName: targetUser.name,
      reqId: reqID,
      senderId: senderId,
      senderName: StaticData.model!.name,
    );

    await FirebaseFirestore.instance.collection("muazam requests").doc(reqID).set(model.toMap());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.requestSent), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: const Color(0xFF246BFD),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 20),
              child: isSearching
                  ? Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Color(0xFF246BFD)),
                            onPressed: () {
                              setState(() {
                                isSearching = false;
                                searchController.clear();
                                filterUsers('');
                              });
                            },
                          ),
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              autofocus: true,
                              style: const TextStyle(color: Colors.black, fontSize: 16),
                              decoration: const InputDecoration(
                                hintText: "Search users...",
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                              ),
                              onChanged: filterUsers,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isSearching = true;
                            });
                          },
                          child: Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.search_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        Text(
                          l10n.users,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 45), // Replaces the call icon to keep the title centered
                      ],
                    ),
            ),
            
            // Main White Container
            Expanded(
              child: Container(
                width: width,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 30.0, left: 25, bottom: 10),
                      child: Text(
                        l10n.users,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF246BFD)))
                          : filteredUsers.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person_search_rounded, size: 80, color: Colors.grey.shade300),
                                      const SizedBox(height: 15),
                                      Text(
                                        "No users found",
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                                      )
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  itemCount: filteredUsers.length,
                                  itemBuilder: (context, index) {
                                    final user = filteredUsers[index];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 15),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.04),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                        border: Border.all(color: Colors.grey.shade100),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 28,
                                            backgroundColor: Colors.grey.shade200,
                                            backgroundImage: (user.imageUrl != null && user.imageUrl!.isNotEmpty)
                                                ? NetworkImage(user.imageUrl!) as ImageProvider
                                                : const AssetImage('images/person2.jpeg') as ImageProvider,
                                          ),
                                          const SizedBox(width: 15),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  user.name ?? 'Unknown',
                                                  style: const TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  user.email ?? '',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade500,
                                                    fontSize: 12,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => _sendRequest(user),
                                            child: Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF246BFD).withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.person_add_alt_1, color: Color(0xFF246BFD), size: 24),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
