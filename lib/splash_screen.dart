import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_11/introscreen.dart';
import 'package:flutter_application_11/login.dart';
import 'package:flutter_application_11/pageview.dart';
import 'package:flutter_application_11/static_data.dart';
import 'package:flutter_application_11/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MySplash extends StatefulWidget {
  const MySplash({super.key});

  @override
  State<MySplash> createState() => _MySplashState();
}

class _MySplashState extends State<MySplash>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    animation = CurvedAnimation(parent: controller, curve: Curves.easeInOut);

    _navigateUser();
  }

  Future<void> _navigateUser() async {
    await Future.delayed(const Duration(seconds: 3));

    final prefs = await SharedPreferences.getInstance();
    final String? action = prefs.getString('userId');
    final introSeen = prefs.getBool('introSeen') ?? false;

    if (!mounted) return;

    // Agar user logged in nahi hai → LoginScreen
    if (action == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
      return;
    }

    //  User logged in → load model from Firestore
    final snapshot = await FirebaseFirestore.instance
        .collection("muazam users")
        .where("userId", isEqualTo: action)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      StaticData.model = UserModel.fromMap(snapshot.docs.first.data());
    } else {
      // Agar user model Firestore me nahi mila → logout kardo
      await prefs.remove('userId');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
      return;
    }

    //  Decide next screen based on introSeen
    if (!introSeen) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => IntroScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyPageview()),
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ScaleTransition(
            scale: animation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: height * 0.12,
                  width: width * 0.6,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                        "images/WhatsApp Image 2026-02-11 at 7.23.42 PM.jpeg",
                      ),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Chatbox",
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 22, 22, 22),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
