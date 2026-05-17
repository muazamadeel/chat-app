import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_11/l10n/app_localizations.dart';
import 'package:flutter_application_11/main.dart';
import 'package:flutter_application_11/passwordencryption.dart';
import 'package:flutter_application_11/splash_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_application_11/create-account.dart';
import 'package:flutter_application_11/forgetpassword.dart';
import 'package:flutter_application_11/pageview.dart';
import 'package:flutter_application_11/static_data.dart';
import 'package:flutter_application_11/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final Passwordcontroller = TextEditingController();

  bool _passwordVisible = false;
  bool _isLoading = false;

  String image = "img";
  String name = "name";
  String email = "email";
  String id = 'id';

  static const _primary = Color(0xFF246BFD);

  @override
  void dispose() {
    emailController.dispose();
    Passwordcontroller.dispose();
    super.dispose();
  }

  Future signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    User user = userCredential.user!;
    email = user.email!;
    name = user.displayName!;
    id = user.uid;
    image = user.photoURL!;
    setState(() {});
    // ignore: unused_local_variable
    UserModel model = UserModel(userId: id, email: email, name: name);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MyPageview()),
    );
  }

  void addDataTosf(String id) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', id);
  }

  Widget _langTile(String label, Locale locale) {
    final isSelected = appLocale.value == locale;
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 15, color: Colors.black87)),
      trailing: isSelected ? const Icon(Icons.check_rounded, color: Color(0xFF246BFD), size: 20) : null,
      onTap: () {
        appLocale.value = locale;
        Navigator.pop(context);
      },
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Select Language",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            _langTile("🇬🇧  English", const Locale('en')),
            _langTile("🇵🇰  اردو", const Locale('ur')),
            _langTile("🇫🇷  Français", const Locale('fr')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _primary,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Top Blue Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.login,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        l10n.welcome,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _showLanguagePicker,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.language_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),

            // White Rounded Container
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: _avatar()),
                      const SizedBox(height: 28),

                      _field(
                        controller: emailController,
                        hint: l10n.email,
                        label: 'EMAIL',
                        icon: Icons.alternate_email_rounded,
                        keyboard: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      _field(
                        controller: Passwordcontroller,
                        hint: l10n.password,
                        label: 'PASSWORD',
                        icon: Icons.lock_outline_rounded,
                        obscure: !_passwordVisible,
                        suffix: IconButton(
                          icon: Icon(
                            _passwordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: _primary.withOpacity(0.6),
                            size: 20,
                          ),
                          onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                        ),
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => Forgetpassword()),
                          ),
                          child: Text(
                            l10n.forgetPassword,
                            style: const TextStyle(color: _primary, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            disabledBackgroundColor: _primary.withOpacity(0.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                            shadowColor: _primary.withOpacity(0.4),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : Text(
                                  l10n.login,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      _googleButton(l10n),

                      const SizedBox(height: 28),

                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Don't have an account?  ",
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => MyCreateAccount()),
                              ),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(color: _primary, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: size.height * 0.02),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar() {
    if (image == 'img') {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _primary.withOpacity(0.08),
          border: Border.all(color: _primary.withOpacity(0.3), width: 1.5),
        ),
        child: const Icon(Icons.person_rounded, color: _primary, size: 40),
      );
    }
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _primary.withOpacity(0.4), width: 2),
        image: DecorationImage(image: NetworkImage(image), fit: BoxFit.cover),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboard,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              color: _primary.withOpacity(0.8),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboard,
          style: const TextStyle(color: Colors.black87, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(icon, color: _primary.withOpacity(0.7), size: 20),
            suffixIcon: suffix,
            filled: true,
            fillColor: const Color(0xFFF4F7FC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _googleButton(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: signInWithGoogle,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CustomPaint(painter: _GooglePainter()),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.loginWithGoogle,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);

    final enteredHashedPassword = EncryptionService().hashPassword(Passwordcontroller.text.trim());

    final snapshot = await FirebaseFirestore.instance
        .collection("muazam users")
        .where("email", isEqualTo: emailController.text)
        .where("password", isEqualTo: enteredHashedPassword)
        .get();

    setState(() => _isLoading = false);

    if (snapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.emailOrPasswordIncorrect),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final model = UserModel.fromMap(
        snapshot.docs[0].data() as Map<String, dynamic>,
      );
      StaticData.model = model;
      addDataTosf(model.userId!);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('introSeen', false);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MySplash()));
    }
  }
}

// ── Google Logo Painter ───────────────────────────────────────────
class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    final segments = [
      (const Color(0xFF4285F4), 270.0, 90.0),
      (const Color(0xFF34A853), 0.0, 90.0),
      (const Color(0xFFFBBC05), 90.0, 90.0),
      (const Color(0xFFEA4335), 180.0, 90.0),
    ];

    for (final (color, start, sweep) in segments) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.72),
        _rad(start),
        _rad(sweep),
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.28,
      );
    }

    canvas.drawCircle(Offset(cx, cy), r * 0.38, Paint()..color = Colors.white);

    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r * 0.72, cy),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = size.width * 0.28
        ..strokeCap = StrokeCap.round,
    );
  }

  double _rad(double deg) => deg * 3.14159265 / 180;

  @override
  bool shouldRepaint(_) => false;
}
