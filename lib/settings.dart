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
      shape: const RoundedRectangleBorder(
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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
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
      title: Text(label, style: const TextStyle(fontSize: 16)),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
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

    return Scaffold(
      backgroundColor: const Color(0xFF246BFD),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 20),
              child: Row(
                children: [
                  const SizedBox(width: 40), // Placeholder for centering
                  Expanded(
                    child: Center(
                      child: Text(
                        l10n.settings,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _showLanguagePicker,
                    icon: const Icon(Icons.language, color: Colors.white, size: 26),
                    tooltip: l10n.changeLanguage,
                  ),
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
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  children: [
                    // Profile Row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: (StaticData.model != null &&
                                  StaticData.model!.imageUrl != null &&
                                  StaticData.model!.imageUrl!.isNotEmpty)
                              ? NetworkImage(StaticData.model!.imageUrl!) as ImageProvider
                              : const AssetImage('images/person2.jpeg'),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name ?? l10n.loading,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                StaticData.model?.email ?? "",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.qr_code, size: 35, color: Color(0xFF246BFD)),
                      ],
                    ),
                    const SizedBox(height: 25),
                    const Divider(color: Colors.black12, thickness: 1),
                    const SizedBox(height: 15),

                    // Settings Items
                    _buildSettingsItem(
                      icon: Icons.person_outline,
                      title: l10n.editProfile,
                      subtitle: l10n.editProfileSub,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const Editprofile()),
                      ),
                    ),
                    
                    _buildSettingsItem(
                      icon: Icons.lock_outline_rounded,
                      title: l10n.changePassword,
                      subtitle: l10n.changePasswordSub,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const Changepassword()),
                      ),
                    ),
                    
                    _buildSettingsItem(
                      icon: Icons.notifications_none_rounded,
                      title: l10n.notifications,
                      subtitle: l10n.notificationsSub,
                      onTap: () {},
                    ),
                    
                    _buildSettingsItem(
                      icon: Icons.language,
                      title: l10n.changeLanguage,
                      subtitle: "${l10n.english} / ${l10n.urdu} / ${l10n.french}",
                      onTap: _showLanguagePicker,
                    ),

                    const SizedBox(height: 20),

                    // Logout Button
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.logout_rounded, color: Colors.red, size: 24),
                      ),
                      title: Text(
                        l10n.logout,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF246BFD).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF246BFD), size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }
}
