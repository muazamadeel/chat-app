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

    final items = [
      _NavItem(icon: Icons.message_rounded, label: l10n.message),
      _NavItem(icon: Icons.people_alt_rounded, label: l10n.users),
      _NavItem(icon: Icons.person_add_rounded, label: l10n.requests),
      _NavItem(icon: Icons.settings_rounded, label: l10n.settings),
    ];

    return Scaffold(
      body: PageView(
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (value) => setState(() => index = value),
        children: [Home(), Mycalls(), Mycontacts(), Mysetting()],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 65,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isActive = index == i;
              return GestureDetector(
                onTap: () => controller.jumpToPage(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF246BFD).withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[i].icon,
                        color: isActive ? const Color(0xFF246BFD) : Colors.grey.shade500,
                        size: 24,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[i].label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                          color: isActive ? const Color(0xFF246BFD) : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
