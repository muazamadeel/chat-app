import 'package:flutter/material.dart';
import 'package:flutter_application_11/l10n/app_localizations.dart';
import 'package:flutter_application_11/pageview.dart';
import 'package:flutter_application_11/widgetintro.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  bool islastpage = false;
  final controller = PageController();

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(bottom: 85),
        child: PageView(
          controller: controller,
          onPageChanged: (index) {
            setState(() {
              islastpage = index == 3;
            });
          },
          children: [
            buildImageContainer(
              Colors.white,
              l10n.welcomeToChatBox,
              l10n.welcomeDesc,
              "images/chatapp.jpeg",
            ),
            buildImageContainer(
              Colors.white,
              l10n.exploreNewChats,
              l10n.exploreDesc,
              "images/WhatsApp Image 2026-02-11 at 7.03.13 PM.jpeg",
            ),
            buildImageContainer(
              Colors.white,
              l10n.fastSecure,
              l10n.fastDesc,
              "images/bts.jpeg",
            ),
            buildImageContainer(
              Colors.white,
              l10n.stayConnected,
              l10n.stayDesc,
              "images/community chat.jpeg",
            ),
          ],
        ),
      ),
      bottomSheet: islastpage
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('introSeen', true);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => MyPageview()),
                    );
                  },
                  child: Text(
                    l10n.getStarted,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            )
          : SizedBox(
              height: height * 0.1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => controller.jumpToPage(3),
                      child: Text(
                        l10n.skip,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    SmoothPageIndicator(
                      controller: controller,
                      count: 4,
                      effect: const WormEffect(
                        spacing: 10,
                        dotColor: Colors.grey,
                        activeDotColor: Colors.deepPurple,
                      ),
                      onDotClicked: (index) {
                        controller.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                    TextButton(
                      onPressed: () => controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      child: Text(
                        l10n.next,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
