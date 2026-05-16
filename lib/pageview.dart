import 'package:flutter/material.dart';
import 'package:flutter_application_11/calls.dart';
import 'package:flutter_application_11/contacts.dart';
import 'package:flutter_application_11/home.dart';
import 'package:flutter_application_11/l10n/app_localizations.dart';

import 'package:flutter_application_11/settings.dart';

class MyPageview extends StatefulWidget {
  const MyPageview({super.key});

  @override
  State<MyPageview> createState() => _PageviewState();
}

class _PageviewState extends State<MyPageview> {
  PageController controller = PageController();
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        body: PageView(
          controller: controller,
          onPageChanged: (value) {
            setState(() {
              index = value;
            });
          },
          children: [
            Home(), Mycalls(), Mycontacts(), Mysetting(),

            // Screen()
          ],
        ),
        bottomNavigationBar: Container(
          height: height * 0.1,
          width: width,
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              InkWell(
                onTap: () {
                  controller.jumpToPage(0);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.message_rounded,
                      color: index == 0 ? Colors.blue : Colors.black,
                    ),
                    Text(l10n.message),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  controller.jumpToPage(1);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.call,
                      color: index == 1 ? Colors.blue : Colors.black,
                    ),
                    Text(l10n.users),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  controller.jumpToPage(2);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_add,
                      color: index == 2 ? Colors.blue : Colors.black,
                    ),
                    Text(l10n.requests),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  controller.jumpToPage(3);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.settings,
                      color: index == 3 ? Colors.blue : Colors.black,
                    ),
                    Text(l10n.settings),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
