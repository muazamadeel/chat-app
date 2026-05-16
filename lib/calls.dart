import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_11/recentcalls.dart';
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

  getAllUsers() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("muazam users")
        .where("userId", isNotEqualTo: StaticData.model!.userId)
        .get();
    for (var user in snapshot.docs) {
      UserModel model = UserModel.fromMap(user.data() as Map<String, dynamic>);
      allUsers.add(model);
      setState(() {});
    }
  }

  @override
  void initState() {
    getAllUsers();
    super.initState();
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
                    l10n.users,
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
                    child: Icon(Icons.call, color: Colors.white),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 180.0, left: 30),
              child: Text(
                l10n.users,
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
                  itemCount: allUsers.length,
                  scrollDirection: Axis.vertical,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: height * 0.07,
                            width: width * 0.2,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: AssetImage(recentcalls.mylist[0].image!),
                              ),
                            ),
                          ),
                          SizedBox(width: 30),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                allUsers[index].name!,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 05),
                              Text(allUsers[index].email!),
                            ],
                          ),
                          Spacer(),
                          InkWell(
                            onTap: () async {
                              final senderId = StaticData.model!.userId;
                              final receiverId = allUsers[index].userId;

                              /// 🔍 1️⃣ Already friends?
                              final friendCheck = await FirebaseFirestore
                                  .instance
                                  .collection("muazam contacts")
                                  .where("userId", isEqualTo: senderId)
                                  .where("friendId", isEqualTo: receiverId)
                                  .get();

                              if (friendCheck.docs.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.alreadyInContacts),
                                  ),
                                );
                                return;
                              }
                              final reverseCheck = await FirebaseFirestore
                                  .instance
                                  .collection("muazam requests")
                                  .where("senderId", isEqualTo: receiverId)
                                  .where("reciverId", isEqualTo: senderId)
                                  .get();

                              if (reverseCheck.docs.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.userAlreadySentRequest),
                                  ),
                                );
                                return;
                              }

                              /// 🔍 2️⃣ Request already sent?
                              final requestCheck = await FirebaseFirestore
                                  .instance
                                  .collection("muazam requests")
                                  .where("senderId", isEqualTo: senderId)
                                  .where("reciverId", isEqualTo: receiverId)
                                  .get();

                              if (requestCheck.docs.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.alreadySentRequest),
                                  ),
                                );
                                return;
                              }

                              /// ✅ SAME OLD LOGIC
                              var uid = Uuid();
                              String reqID = uid.v4();

                              Reqmodel model = Reqmodel(
                                reciverId: receiverId,
                                reciverName: allUsers[index].name,
                                reqId: reqID,
                                senderId: senderId,
                                senderName: StaticData.model!.name,
                              );

                              await FirebaseFirestore.instance
                                  .collection("muazam requests")
                                  .doc(reqID)
                                  .set(model.toMap());

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.requestSent)),
                              );
                            },

                            // onTap: () {
                            //   var uid = Uuid();
                            //   String reqID = uid.v4();
                            //   Reqmodel model = Reqmodel(
                            //     reciverId: allUsers[index].userId,
                            //     reciverName: allUsers[index].name,
                            //     reqId: reqID,
                            //     senderId: StaticData.model!.userId,
                            //     senderName: StaticData.model!.name,
                            //   );

                            //   FirebaseFirestore.instance
                            //       .collection("muazam requests")
                            //       .doc(reqID)
                            //       .set(model.toMap());
                            // },
                            child: Icon(Icons.person_add),
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
