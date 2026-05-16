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

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Container(width: width, height: height, color: Colors.black),
            Positioned(
              bottom: 0,
              child: Container(
                height: height * 0.7,
                width: width,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              left: 30,
              right: 30,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white38),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  Text(
                    l10n.requests,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white),
                    ),
                    child: Icon(Icons.contacts, color: Colors.white),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 190.0, left: 30),
              child: Text(
                l10n.friendRequests,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 200.0),
              child: SizedBox(
                width: width,
                child: ListView.builder(
                  itemCount: allRequests.length,
                  scrollDirection: Axis.vertical,
                  itemBuilder: (context, index) {
                    // ignore: unused_local_variable
                    var req = allRequests[index];
                    return Padding(
                      padding: const EdgeInsets.only(
                        top: 20.0,
                        left: 20,
                        right: 20,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 60,
                            width: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              //   image: DecorationImage(
                              //     image: NetworkImage(req["sender image"] ??
                              //         "https://via.placeholder.com/150"),
                              //   ),
                            ),
                          ),
                          SizedBox(width: 30),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                allRequests[index].senderName!,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Spacer(),
                          IconButton(
                            icon: Icon(Icons.check_circle),
                            onPressed: () {
                              acceptRequest(index);
                            },
                          ),
                          Spacer(),
                          IconButton(
                            icon: Icon(Icons.cancel, color: Colors.red),
                            onPressed: () {
                              rejectRequest(index);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
