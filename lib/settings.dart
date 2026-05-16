import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_11/changepassword.dart';
import 'package:flutter_application_11/editprofile.dart';
import 'package:flutter_application_11/l10n/app_localizations.dart';
import 'package:flutter_application_11/login.dart';
import 'package:flutter_application_11/main.dart';
import 'package:flutter_application_11/static_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Mysetting extends StatefulWidget {
  const Mysetting({super.key});

  @override
  State<Mysetting> createState() => _MysettingState();
}

class _MysettingState extends State<Mysetting> {
  String? name;

  Future<void> getUserData() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection("muazam users")
        .doc(StaticData.model!.userId!)
        .get();
    if (snapshot.exists) {
      var data = snapshot.data() as Map<String, dynamic>;
      setState(() {
        name = data['name'];
      });
    } else {
      print("User document not found!");
    }
  }

  Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.remove("userId");
    await prefs.setBool('introSeen', false);
    StaticData.model = null;

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _showLanguagePicker() {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.selectLanguage,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 15),
              _langTile(
                "🇬🇧 ${l10n.english}",
                const Locale('en'),
                setModalState,
              ),
              _langTile("🇵🇰 ${l10n.urdu}", const Locale('ur'), setModalState),
              _langTile(
                "🇫🇷 ${l10n.french}",
                const Locale('fr'),
                setModalState,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langTile(String label, Locale locale, StateSetter setModalState) {
    final isSelected = appLocale.value == locale;
    return ListTile(
      title: Text(label, style: TextStyle(fontSize: 16)),
      trailing: isSelected ? Icon(Icons.check, color: Colors.green) : null,
      onTap: () {
        appLocale.value = locale;
        Navigator.pop(context);
      },
    );
  }

  @override
  void initState() {
    getUserData();
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
            // Top bar
            Positioned(
              top: 20,
              left: 30,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.arrow_back, color: Colors.white, size: 30),
                  SizedBox(width: 60),
                  Text(
                    l10n.settings,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: _showLanguagePicker,
                    icon: Icon(Icons.language, color: Colors.white, size: 26),
                    tooltip: l10n.changeLanguage,
                  ),
                ],
              ),
            ),
            // Profile row
            Padding(
              padding: const EdgeInsets.only(top: 160.0, left: 20, right: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: AssetImage('images/person2.jpeg'),
                  ),
                  SizedBox(width: 30),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name ?? l10n.loading,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  Icon(Icons.qr_code, size: 40),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 225.0),
              child: Divider(color: Colors.black38, thickness: 1),
            ),
            // Edit Profile
            Padding(
              padding: const EdgeInsets.only(top: 255.0, left: 20, right: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.key_outlined, color: Colors.grey, size: 30),
                  SizedBox(width: 40),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => Editprofile()),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.editProfile,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(l10n.editProfileSub),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Change Password
            Padding(
              padding: const EdgeInsets.only(top: 335.0, left: 20, right: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.chat_rounded, color: Colors.grey, size: 30),
                  SizedBox(width: 40),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => Changepassword()),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.changePassword,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(l10n.changePasswordSub),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Notifications
            Padding(
              padding: const EdgeInsets.only(top: 405.0, left: 20, right: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notifications, color: Colors.grey, size: 30),
                  SizedBox(width: 40),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.notifications,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(l10n.notificationsSub),
                    ],
                  ),
                ],
              ),
            ),
            // Help
            Padding(
              padding: const EdgeInsets.only(top: 475.0, left: 20, right: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.question_mark_rounded,
                    color: Colors.grey,
                    size: 30,
                  ),
                  SizedBox(width: 40),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.help,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(l10n.helpSub),
                    ],
                  ),
                ],
              ),
            ),
            // Change Language row
            Padding(
              padding: const EdgeInsets.only(top: 545.0, left: 20, right: 20),
              child: InkWell(
                onTap: _showLanguagePicker,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.language, color: Colors.grey, size: 30),
                    SizedBox(width: 40),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.changeLanguage,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text("${l10n.english} / ${l10n.urdu} / ${l10n.french}"),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Logout
            Padding(
              padding: const EdgeInsets.only(top: 610.0, left: 20, right: 20),
              child: InkWell(
                onTap: () async {
                  await FirebaseFirestore.instance
                      .collection('muazam users')
                      .doc(StaticData.model!.userId!)
                      .update({
                        "online": false,
                        "lastSeen": FieldValue.serverTimestamp(),
                      });
                  await logout(context);
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.person, color: Colors.grey, size: 30),
                    SizedBox(width: 40),
                    Text(
                      l10n.logout,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
