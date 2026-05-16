// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_application_11/passwordencryption.dart';
// import 'package:flutter_application_11/static_data.dart';
// import 'package:flutter_application_11/l10n/app_localizations.dart';

// class Changepassword extends StatefulWidget {
//   const Changepassword({super.key});

//   @override
//   State<Changepassword> createState() => _ChangepasswordState();
// }

// class _ChangepasswordState extends State<Changepassword> {
//   TextEditingController Passwordcontroller = TextEditingController();

//   //  Update password function
//   void update() async {
//     final l10n = AppLocalizations.of(context)!;
//     String newPassword = Passwordcontroller.text.trim();

//     if (newPassword.isEmpty) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text(l10n.pleaseEnterNewPassword)));
//       return;
//     }

//     // Hash the password before saving
//     String hashedPassword = EncryptionService().hashPassword(newPassword);

//     DocumentReference documentReference = FirebaseFirestore.instance
//         .collection("muazam users")
//         .doc(StaticData.model!.userId);

//     Map<String, dynamic> updatedetails = {"password": hashedPassword};

//     await documentReference
//         .set(updatedetails, SetOptions(merge: true))
//         .then((value) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text(l10n.passwordUpdatedSuccessfully)),
//           );
//           Passwordcontroller.clear();
//         })
//         .onError((error, stackTrace) {
//           ScaffoldMessenger.of(
//             context,
//           ).showSnackBar(SnackBar(content: Text(l10n.errorUpdatingPassword)));
//         });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;

//     return SafeArea(
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text(l10n.changePassword),
//           backgroundColor: Colors.blue,
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back),
//             onPressed: () {
//               Navigator.pop(context);
//             },
//           ),
//         ),
//         body: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             children: [
//               const SizedBox(height: 20),
//               TextField(
//                 controller: Passwordcontroller,
//                 obscureText: true,
//                 decoration: InputDecoration(
//                   hintText: l10n.enterNewPassword,
//                   border: const OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: update,
//                 child: Text(l10n.updatePassword),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_11/passwordencryption.dart';
import 'package:flutter_application_11/static_data.dart';
import 'package:flutter_application_11/l10n/app_localizations.dart';

class Changepassword extends StatefulWidget {
  const Changepassword({super.key});

  @override
  State<Changepassword> createState() => _ChangepasswordState();
}

class _ChangepasswordState extends State<Changepassword>
    with SingleTickerProviderStateMixin {
  final TextEditingController Passwordcontroller = TextEditingController();
  bool _passwordVisible = false;

  static const _bg = Color(0xFF080808);
  static const _card = Color(0xFF161616);
  static const _gold = Color(0xFFD4AF37);
  static const _goldLight = Color(0xFFF5E070);
  static const _goldDark = Color(0xFFB8860B);
  static const _fieldBg = Color(0xFF1E1E1E);

  AnimationController? _shimmer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _shimmer = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1600),
      )..repeat();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _shimmer?.dispose();
    Passwordcontroller.dispose();
    super.dispose();
  }

  // ── Functionality unchanged ──────────────────────────────────
  void update() async {
    final l10n = AppLocalizations.of(context)!;
    String newPassword = Passwordcontroller.text.trim();

    if (newPassword.isEmpty) {
      _showSnack(l10n.pleaseEnterNewPassword, Colors.redAccent);
      return;
    }

    String hashedPassword = EncryptionService().hashPassword(newPassword);

    DocumentReference documentReference = FirebaseFirestore.instance
        .collection("muazam users")
        .doc(StaticData.model!.userId);

    Map<String, dynamic> updatedetails = {"password": hashedPassword};

    await documentReference
        .set(updatedetails, SetOptions(merge: true))
        .then((value) {
          _showSnack(l10n.passwordUpdatedSuccessfully, Colors.green.shade600);
          Passwordcontroller.clear();
        })
        .onError((error, stackTrace) {
          _showSnack(l10n.errorUpdatingPassword, Colors.redAccent);
        });
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Background glows
          Positioned(
            top: -100,
            left: -80,
            child: _glow(300, const Color(0x12D4AF37)),
          ),
          Positioned(
            bottom: 60,
            right: -80,
            child: _glow(240, const Color(0x09D4AF37)),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: size.height * 0.015),

                  // Top bar
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _gold.withOpacity(0.25)),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: _gold,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        l10n.changePassword,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: size.height * 0.04),

                  // Lock avatar
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _card,
                            border: Border.all(
                              color: _gold.withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _gold.withOpacity(0.14),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            color: _gold,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'SECURE YOUR ACCOUNT',
                          style: TextStyle(
                            color: _gold.withOpacity(0.55),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: _goldDivider(),
                  ),

                  // Password field
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      'NEW PASSWORD',
                      style: TextStyle(
                        color: _gold.withOpacity(0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  TextField(
                    controller: Passwordcontroller,
                    obscureText: !_passwordVisible,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      letterSpacing: 0.3,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.enterNewPassword,
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.2),
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline_rounded,
                        color: _gold.withOpacity(0.75),
                        size: 19,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: _gold.withOpacity(0.6),
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _passwordVisible = !_passwordVisible,
                        ),
                      ),
                      filled: true,
                      fillColor: _fieldBg,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _gold, width: 1.4),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      '• Use at least 8 characters with numbers & symbols',
                      style: TextStyle(
                        color: _gold.withOpacity(0.45),
                        fontSize: 11,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Shimmer button
                  _shimmerButton(l10n),
                  SizedBox(height: size.height * 0.03),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────

  Widget _glow(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, Colors.transparent]),
    ),
  );

  Widget _goldDivider() => Container(
    height: 1,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          _gold.withOpacity(0),
          _gold.withOpacity(0.55),
          _gold.withOpacity(0),
        ],
      ),
    ),
  );

  Widget _shimmerButton(AppLocalizations l10n) {
    if (_shimmer == null) {
      return _btnContainer(
        gradient: const LinearGradient(
          colors: [_goldDark, _gold, _goldLight, _gold, _goldDark],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
        l10n: l10n,
      );
    }
    return AnimatedBuilder(
      animation: _shimmer!,
      builder: (context, _) {
        final t = _shimmer!.value;
        return _btnContainer(
          gradient: LinearGradient(
            begin: Alignment(-1.0 + t * 2.5, 0),
            end: Alignment(0.6 + t * 2.5, 0),
            colors: const [_goldDark, _gold, _goldLight, _gold, _goldDark],
            stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
          ),
          l10n: l10n,
        );
      },
    );
  }

  Widget _btnContainer({
    required LinearGradient gradient,
    required AppLocalizations l10n,
  }) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: _gold.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: update,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          l10n.updatePassword.toUpperCase(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            letterSpacing: 1.4,
          ),
        ),
      ),
    );
  }
}
