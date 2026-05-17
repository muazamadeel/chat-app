import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_11/request_model.dart';
import 'package:flutter_application_11/static_data.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_application_11/l10n/app_localizations.dart';

class Mycontacts extends StatefulWidget {
  const Mycontacts({super.key});

  @override
  State<Mycontacts> createState() => _MycontactsState();
}

class _MycontactsState extends State<Mycontacts> {
  List<Reqmodel> allRequests = [];

  getRequest() async {
    allRequests.clear();
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("muazam requests")
        .where("reciverId", isEqualTo: StaticData.model!.userId)
        .get();

    for (var req in snapshot.docs) {
      Reqmodel model = Reqmodel.fromMap(req.data() as Map<String, dynamic>);
      setState(() {
        allRequests.add(model);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getRequest();
  }

  acceptRequest(int index) async {
    final req = allRequests[index];

    /// 🔍 CHECK: already friends?
    final alreadyFriend = await FirebaseFirestore.instance
        .collection("muazam contacts")
        .where("userId", isEqualTo: req.reciverId)
        .where("friendId", isEqualTo: req.senderId)
        .get();

    if (alreadyFriend.docs.isNotEmpty) {
      // already added, sirf request delete
      await FirebaseFirestore.instance
          .collection("muazam requests")
          .doc(req.reqId)
          .delete();

      setState(() {
        allRequests.removeAt(index);
      });
      return;
    }
    var uid = Uuid().v4();

    await FirebaseFirestore.instance
        .collection("muazam contacts")
        .doc(uid)
        .set({
          "friendName": allRequests[index].reciverName,
          "friendId": allRequests[index].reciverId,
          "userId": allRequests[index].senderId,
          "id": uid,
        });

    var uid2 = Uuid().v4();
    await FirebaseFirestore.instance
        .collection("muazam contacts")
        .doc(uid2)
        .set({
          "friendName": allRequests[index].senderName,
          "friendId": allRequests[index].senderId,
          "userId": allRequests[index].reciverId,
          "id": uid2,
        });
    await FirebaseFirestore.instance
        .collection("muazam requests")
        .doc(allRequests[index].reqId)
        .delete();

    setState(() {
      allRequests.removeAt(index);
    });
  }

  rejectRequest(int index) async {
    await FirebaseFirestore.instance
        .collection("muazam requests")
        .doc(allRequests[index].reqId)
        .delete();

    setState(() {
      allRequests.removeAt(index);
    });
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
              child: Row(
                children: [
                  const SizedBox(width: 40), // Placeholder for centering
                  Expanded(
                    child: Center(
                      child: Text(
                        l10n.requests,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const Icon(Icons.person_add_alt_1, color: Colors.white, size: 28),
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
                        l10n.friendRequests,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: allRequests.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inbox_rounded, size: 80, color: Colors.grey.shade300),
                                  const SizedBox(height: 15),
                                  Text(
                                    "No new requests",
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                                  )
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              itemCount: allRequests.length,
                              itemBuilder: (context, index) {
                                var req = allRequests[index];
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
                                      // Dynamically fetch profile picture of the sender
                                      FutureBuilder<DocumentSnapshot>(
                                        future: FirebaseFirestore.instance
                                            .collection("muazam users")
                                            .doc(req.senderId)
                                            .get(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return CircleAvatar(
                                              radius: 28,
                                              backgroundColor: Colors.grey.shade200,
                                              child: const CircularProgressIndicator(strokeWidth: 2),
                                            );
                                          }
                                          if (snapshot.hasData && snapshot.data != null) {
                                            var data = snapshot.data!.data() as Map<String, dynamic>?;
                                            if (data != null && data.containsKey("imageUrl") && data["imageUrl"].isNotEmpty) {
                                              return CircleAvatar(
                                                radius: 28,
                                                backgroundColor: Colors.grey.shade200,
                                                backgroundImage: NetworkImage(data["imageUrl"]),
                                              );
                                            }
                                          }
                                          return CircleAvatar(
                                            radius: 28,
                                            backgroundColor: const Color(0xFFE9F0FF),
                                            child: const Icon(Icons.person, color: Color(0xFF246BFD), size: 30),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              req.senderName ?? "Unknown User",
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
                                              "Wants to be your friend",
                                              style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Actions
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () => acceptRequest(index),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF246BFD).withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.check_rounded, color: Color(0xFF246BFD), size: 24),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          GestureDetector(
                                            onTap: () => rejectRequest(index),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade50,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(Icons.close_rounded, color: Colors.red.shade400, size: 24),
                                            ),
                                          ),
                                        ],
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
