// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_application_11/l10n/app_localizations.dart';
// import 'package:flutter_application_11/main.dart';
// import 'package:flutter_application_11/passwordencryption.dart';
// import 'package:flutter_application_11/splash_screen.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:flutter_application_11/create-account.dart';
// import 'package:flutter_application_11/forgetpassword.dart';
// import 'package:flutter_application_11/pageview.dart';
// import 'package:flutter_application_11/static_data.dart';
// import 'package:flutter_application_11/user_model.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});

//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   TextEditingController emailController = TextEditingController();
//   TextEditingController Passwordcontroller = TextEditingController();
//   String image = "img";
//   String name = "name";
//   String email = "email";
//   String id = 'id';

//   @override
//   void initState() {
//     super.initState();
//   }

//   Future signInWithGoogle() async {
//     {
//       final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

//       final GoogleSignInAuthentication? googleAuth =
//           await googleUser?.authentication;

//       final credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth?.accessToken,
//         idToken: googleAuth?.idToken,
//       );

//       UserCredential userCredential = await FirebaseAuth.instance
//           .signInWithCredential(credential);
//       User user = userCredential.user!;
//       email = user.email!;
//       name = user.displayName!;
//       id = user.uid;
//       image = user.photoURL!;
//       setState(() {});
//       // ignore: unused_local_variable
//       UserModel model = UserModel(userId: id, email: email, name: name);

//       Navigator.of(context).pushReplacement(
//         MaterialPageRoute(builder: (context) => const MyPageview()),
//       );
//     }
//   }

//   void addDataTosf(String id) async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setString('userId', id);
//   }

//   Widget _langTile(String label, Locale locale) {
//     final isSelected = appLocale.value == locale;
//     return ListTile(
//       title: Text(label, style: const TextStyle(fontSize: 16)),
//       trailing: isSelected
//           ? const Icon(Icons.check, color: Colors.green)
//           : null,
//       onTap: () {
//         appLocale.value = locale;
//         Navigator.pop(context);
//       },
//     );
//   }

//   // ✅ Fix: _showLanguagePicker alag method hai
//   void _showLanguagePicker() {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (_) => Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//               "Select Language",
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 15),
//             _langTile("🇬🇧 English", const Locale('en')),
//             _langTile("🇵🇰 اردو", const Locale('ur')),
//             _langTile("🇫🇷 Français", const Locale('fr')),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     final height = MediaQuery.of(context).size.height;
//     final width = MediaQuery.of(context).size.width;
//     return SafeArea(
//       child: Scaffold(
//         resizeToAvoidBottomInset: false,
//         appBar: AppBar(
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           actions: [
//             IconButton(
//               onPressed: _showLanguagePicker,
//               icon: const Icon(Icons.language, color: Colors.blue, size: 28),
//               tooltip: l10n.changeLanguage,
//             ),
//           ],
//         ),
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: <Widget>[
//               image == 'img'
//                   ? Container(
//                       height: height * 0.2,
//                       width: width * 0.2,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: Colors.amber,
//                       ),
//                     )
//                   : Container(
//                       height: height * 0.1,
//                       width: width * 0.1,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         image: DecorationImage(image: NetworkImage(image)),
//                       ),
//                     ),
//               SizedBox(height: height * 0.012),
//               Padding(
//                 padding: const EdgeInsets.only(left: 20.0, right: 20),
//                 child: TextField(
//                   controller: emailController,
//                   decoration: InputDecoration(hintText: l10n.email),
//                 ),
//               ),
//               SizedBox(height: height * 0.01),
//               Padding(
//                 padding: const EdgeInsets.only(left: 20.0, right: 20),
//                 child: TextField(
//                   controller: Passwordcontroller,
//                   obscureText: true,
//                   decoration: InputDecoration(hintText: l10n.password),
//                 ),
//               ),
//               SizedBox(height: height * 0.015),
//               ElevatedButton(
//                 onPressed: (() async {
//                   String enteredHashedPassword = EncryptionService()
//                       .hashPassword(Passwordcontroller.text.trim());
//                   QuerySnapshot snapshot = await FirebaseFirestore.instance
//                       .collection("muazam users")
//                       .where("email", isEqualTo: emailController.text)
//                       .where("password", isEqualTo: enteredHashedPassword)
//                       .get();
//                   if (snapshot.docs.isEmpty) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text(l10n.emailOrPasswordIncorrect),
//                         duration: Duration(seconds: 2),
//                         backgroundColor: Colors.red,
//                       ),
//                     );
//                   } else {
//                     // login successful
//                     UserModel model = UserModel.fromMap(
//                       snapshot.docs[0].data() as Map<String, dynamic>,
//                     );
//                     StaticData.model = model;
//                     addDataTosf(model.userId!);
//                     final SharedPreferences prefs =
//                         await SharedPreferences.getInstance();
//                     await prefs.setBool('introSeen', false);
//                     if (!mounted) return;
//                     Navigator.of(context).pushReplacement(
//                       MaterialPageRoute(builder: (context) => const MySplash()),
//                     );
//                   }
//                   // final message = await AuthService().login(
//                   //   email: emailController.text,
//                   //   password: Passwordcontroller.text,
//                   // );

//                   // if (message == "Success") {
//                   //   Navigator.of(context).pushReplacement(
//                   //     MaterialPageRoute(builder: (context) => const Home()),
//                   //   );
//                   // } else {
//                   //   ScaffoldMessenger.of(context).showSnackBar(
//                   //     SnackBar(content: Text(message ?? "Login failed")),
//                   //   );
//                   // }
//                 }),
//                 child: Text(l10n.login),
//               ),
//               TextButton(
//                 onPressed: (() {
//                   Navigator.of(context).push(
//                     MaterialPageRoute(builder: (context) => MyCreateAccount()),
//                   );
//                 }),
//                 child: Text(l10n.createAccount),
//               ),
//               SizedBox(height: height * 0.01),
//               TextButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => Forgetpassword()),
//                   );
//                 },
//                 child: Text(l10n.forgetPassword),
//               ),

//               SizedBox(height: height * 0.01),
//               InkWell(
//                 onTap: () {
//                   signInWithGoogle();
//                 },
//                 child: Container(
//                   height: height * 0.05,
//                   width: width * 0.4,
//                   color: Colors.blue,
//                   child: Center(child: Text(l10n.loginWithGoogle)),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
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

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final Passwordcontroller = TextEditingController();

  bool _passwordVisible = false;
  bool _isLoading = false;

  String image = "img";
  String name = "name";
  String email = "email";
  String id = 'id';

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
    emailController.dispose();
    Passwordcontroller.dispose();
    super.dispose();
  }

  // ── Google Sign In (unchanged) ───────────────────────────────
  Future signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    UserCredential userCredential = await FirebaseAuth.instance
        .signInWithCredential(credential);
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
      title: Text(
        label,
        style: const TextStyle(fontSize: 15, color: Colors.white),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_rounded, color: Color(0xFFD4AF37), size: 20)
          : null,
      onTap: () {
        appLocale.value = locale;
        Navigator.pop(context);
      },
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
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
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Select Language",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
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

  // ── BUILD ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: _bg,
      body: Stack(
        children: [
          // background glows
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
            child: Column(
              children: [
                // ── Language button top-right ──────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16, top: 8),
                    child: GestureDetector(
                      onTap: _showLanguagePicker,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _gold.withOpacity(0.25)),
                        ),
                        child: const Icon(
                          Icons.language_rounded,
                          color: _gold,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: size.height * 0.025),

                        // ── Avatar ─────────────────────────
                        Center(child: _avatar()),
                        SizedBox(height: size.height * 0.025),

                        // ── Title ──────────────────────────
                        Center(
                          child: Column(
                            children: [
                              Text(
                                l10n.login,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.welcome,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.35),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Gold Divider ───────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: _goldDivider(),
                        ),

                        // ── Email ──────────────────────────
                        _field(
                          controller: emailController,
                          hint: l10n.email,
                          label: 'Email',
                          icon: Icons.alternate_email_rounded,
                          keyboard: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),

                        // ── Password ───────────────────────
                        _field(
                          controller: Passwordcontroller,
                          hint: l10n.password,
                          label: 'Password',
                          icon: Icons.lock_outline_rounded,
                          obscure: !_passwordVisible,
                          suffix: IconButton(
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: _gold.withOpacity(0.7),
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _passwordVisible = !_passwordVisible,
                            ),
                          ),
                        ),

                        // ── Forget Password ────────────────
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Forgetpassword(),
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                l10n.forgetPassword,
                                style: TextStyle(
                                  color: _gold.withOpacity(0.7),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),

                        _shimmerButton(l10n),
                        const SizedBox(height: 12),

                        _googleButton(l10n),

                        SizedBox(height: size.height * 0.022),

                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "${l10n.createAccount}? ",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.38),
                                  fontSize: 13,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MyCreateAccount(),
                                  ),
                                ),
                                child: const Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: _gold,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: size.height * 0.03),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper Widgets ───────────────────────────────────────────

  Widget _glow(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, Colors.transparent]),
    ),
  );

  Widget _avatar() {
    if (image == 'img') {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _card,
          border: Border.all(color: _gold.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _gold.withOpacity(0.14),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.person_rounded, color: _gold, size: 38),
      );
    }
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _gold.withOpacity(0.4), width: 2),
        image: DecorationImage(image: NetworkImage(image), fit: BoxFit.cover),
      ),
    );
  }

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
              color: _gold.withOpacity(0.7),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboard,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14.5,
            letterSpacing: 0.3,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 13,
            ),
            prefixIcon: Icon(icon, color: _gold.withOpacity(0.75), size: 19),
            suffixIcon: suffix,
            filled: true,
            fillColor: _fieldBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _gold, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }

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
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                l10n.login,
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

  Widget _googleButton(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: _gold.withOpacity(0.06),
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
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Login Logic──────────────────────────────────
  Future<void> _login() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);

    final enteredHashedPassword = EncryptionService().hashPassword(
      Passwordcontroller.text.trim(),
    );

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
        // ignore: unnecessary_cast
        snapshot.docs[0].data() as Map<String, dynamic>,
      );
      StaticData.model = model;
      addDataTosf(model.userId!);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('introSeen', false);
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MySplash()));
    }
  }
}

// ── Google Logo Painter ──────────────────────────────────────────
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

    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.38,
      Paint()..color = const Color(0xFF1E1E1E),
    );

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
