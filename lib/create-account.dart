// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_application_11/pageview.dart';
// import 'package:flutter_application_11/passwordencryption.dart';
// import 'package:flutter_application_11/static_data.dart';
// import 'package:flutter_application_11/user_model.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:uuid/uuid.dart';

// class MyCreateAccount extends StatefulWidget {
//   const MyCreateAccount({super.key});

//   @override
//   State<MyCreateAccount> createState() => _MyCreateAccountState();
// }

// class _MyCreateAccountState extends State<MyCreateAccount> {
//   TextEditingController emailController = TextEditingController();
//   TextEditingController passwordController = TextEditingController();
//   TextEditingController numberController = TextEditingController();
//   TextEditingController nameController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         title: const Text('Create Account'),
//         centerTitle: true,
//         backgroundColor: Colors.teal,
//       ),
//       body: Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
//           child: Card(
//             elevation: 8,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: Padding(
//               padding: const EdgeInsets.all(20.0),
//               child: Column(
//                 children: [
//                   const Text(
//                     'Welcome!',
//                     style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.teal,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   _buildTextField(nameController, 'Name', Icons.person),
//                   const SizedBox(height: 12),
//                   _buildTextField(emailController, 'Email', Icons.email),
//                   const SizedBox(height: 12),
//                   _buildTextField(numberController, 'Number', Icons.phone),
//                   const SizedBox(height: 12),
//                   _buildTextField(
//                     passwordController,
//                     'Password',
//                     Icons.lock,
//                     obscureText: true,
//                   ),
//                   const SizedBox(height: 20),
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: _createAccount,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.teal,
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       child: const Text(
//                         'Create Account',
//                         style: TextStyle(fontSize: 18, color: Colors.black),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField(
//     TextEditingController controller,
//     String hintText,
//     IconData icon, {
//     bool obscureText = false,
//   }) {
//     return TextField(
//       controller: controller,
//       obscureText: obscureText,
//       decoration: InputDecoration(
//         prefixIcon: Icon(icon, color: Colors.teal),
//         hintText: hintText,
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//         filled: true,
//         fillColor: Colors.grey[200],
//       ),
//     );
//   }

//   Future<void> _createAccount() async {
//     final email = emailController.text.trim();

//     // 1️⃣ Check if email already exists
//     final checkEmail = await FirebaseFirestore.instance
//         .collection("muazam users")
//         .where("email", isEqualTo: email)
//         .get();

//     if (checkEmail.docs.isNotEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("This email is already registered")),
//       );
//       return;
//     }

//     // 2️⃣ Create account
//     var uid = Uuid();
//     String userId = uid.v4();
//     String hashedPassword = EncryptionService().hashPassword(
//       passwordController.text.trim(),
//     );

//     UserModel model = UserModel(
//       email: email,
//       name: nameController.text.trim(),
//       number: numberController.text.trim(),
//       password: hashedPassword,
//       userId: userId,
//     );

//     await FirebaseFirestore.instance
//         .collection("muazam users")
//         .doc(userId)
//         .set(model.toMap());

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Account created successfully")),
//     );
//     StaticData.model = model;

//     // Shared Preferences me save karo
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('userId', userId);

//     // Navigate to PageView
//     Navigator.of(context).pushReplacement(
//       MaterialPageRoute(builder: (context) => const MyPageview()),
//     );
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_11/l10n/app_localizations.dart';
import 'package:flutter_application_11/pageview.dart';
import 'package:flutter_application_11/passwordencryption.dart';
import 'package:flutter_application_11/static_data.dart';
import 'package:flutter_application_11/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class MyCreateAccount extends StatefulWidget {
  const MyCreateAccount({super.key});

  @override
  State<MyCreateAccount> createState() => _MyCreateAccountState();
}

class _MyCreateAccountState extends State<MyCreateAccount>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final numberController = TextEditingController();
  final nameController = TextEditingController();

  bool _passwordVisible = false;
  bool _isLoading = false;

  static const _bg = Color(0xFF080808);
  static const _card = Color(0xFF161616);
  static const _gold = Color(0xFFD4AF37);
  static const _goldLight = Color(0xFFF5E070);
  static const _goldDark = Color(0xFFB8860B);
  static const _fieldBg = Color(0xFF1E1E1E);

  // nullable — initialized in initState, no LateError possible
  AnimationController? _shimmer;

  @override
  void initState() {
    super.initState();
    // addPostFrameCallback ensures vsync is ready
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
    passwordController.dispose();
    numberController.dispose();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: _bg,
      body: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: _glow(280, const Color(0x14D4AF37)),
          ),
          Positioned(
            bottom: 80,
            left: -90,
            child: _glow(240, const Color(0x09D4AF37)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: size.height * 0.035),

                  _buildHeader(l10n),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: _goldDivider(),
                  ),

                  Center(child: _avatar()),
                  SizedBox(height: size.height * 0.025),

                  _field(
                    nameController,
                    l10n.name,
                    'Full Name',
                    Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    emailController,
                    l10n.email,
                    'Email',
                    Icons.alternate_email_rounded,
                    keyboard: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    numberController,
                    l10n.number,
                    'Phone',
                    Icons.phone_iphone_rounded,
                    keyboard: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    passwordController,
                    l10n.password,
                    'Password',
                    Icons.lock_outline_rounded,
                    obscure: !_passwordVisible,
                    suffix: IconButton(
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: _gold.withOpacity(0.7),
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                    ),
                  ),

                  const Spacer(),

                  _shimmerButton(l10n),

                  SizedBox(height: size.height * 0.022),

                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.alreadyHaveAccount,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.38),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            'Login',
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

  Widget _buildHeader(AppLocalizations l10n) => Row(
    children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: _gold.withOpacity(0.28)),
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: _gold, size: 15),
        ),
      ),
      const SizedBox(width: 16),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.createAccountTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.welcome,
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 12,
            ),
          ),
        ],
      ),
    ],
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

  Widget _avatar() => Container(
    width: 72,
    height: 72,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: _card,
      border: Border.all(color: _gold.withOpacity(0.3), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: _gold.withOpacity(0.14),
          blurRadius: 18,
          spreadRadius: 2,
        ),
      ],
    ),
    child: const Icon(Icons.person_rounded, color: _gold, size: 34),
  );

  Widget _field(
    TextEditingController ctrl,
    String hint,
    String label,
    IconData icon, {
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
          controller: ctrl,
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
    // if shimmer not ready yet, show static gold button
    if (_shimmer == null) {
      return _staticButton(l10n);
    }
    return AnimatedBuilder(
      animation: _shimmer!,
      builder: (context, _) {
        final t = _shimmer!.value;
        return _buttonContainer(
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

  Widget _staticButton(AppLocalizations l10n) => _buttonContainer(
    gradient: const LinearGradient(
      colors: [_goldDark, _gold, _goldLight, _gold, _goldDark],
      stops: [0.0, 0.25, 0.5, 0.75, 1.0],
    ),
    l10n: l10n,
  );

  Widget _buttonContainer({
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
        onPressed: _isLoading ? null : () => _createAccount(l10n),
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
                l10n.createAccountBtn,
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

  // ── Firebase logic (unchanged) ───────────────────────────────

  Future<void> _createAccount(AppLocalizations l10n) async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        numberController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.fillAllFields),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final email = emailController.text.trim();

    final checkEmail = await FirebaseFirestore.instance
        .collection("muazam users")
        .where("email", isEqualTo: email)
        .get();

    if (checkEmail.docs.isNotEmpty) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.emailAlreadyRegistered),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final uid = Uuid();
    final userId = uid.v4();
    final hashedPw = EncryptionService().hashPassword(
      passwordController.text.trim(),
    );

    final model = UserModel(
      email: email,
      name: nameController.text.trim(),
      number: numberController.text.trim(),
      password: hashedPw,
      userId: userId,
    );

    await FirebaseFirestore.instance
        .collection("muazam users")
        .doc(userId)
        .set(model.toMap());

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.accountCreated),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    StaticData.model = model;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const MyPageview()));
  }
}
