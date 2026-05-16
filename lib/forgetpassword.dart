// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_application_11/l10n/app_localizations.dart';

// class Forgetpassword extends StatefulWidget {
//   const Forgetpassword({super.key});

//   @override
//   State<Forgetpassword> createState() => _ForgetpasswordState();
// }

// class _ForgetpasswordState extends State<Forgetpassword> {
//   TextEditingController emailController = TextEditingController();

//   Future resetPassword(AppLocalizations l10n) async {
//     try {
//       await FirebaseAuth.instance.sendPasswordResetEmail(
//         email: emailController.text.trim(),
//       );
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text(l10n.resetEmailSent)));
//     } on FirebaseAuthException catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(e.message ?? l10n.somethingWentWrong)),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     return SafeArea(
//       child: Scaffold(
//         appBar: AppBar(title: Text(l10n.forgetPasswordTitle)),
//         body: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             children: [
//               TextField(
//                 controller: emailController,
//                 decoration: InputDecoration(hintText: l10n.sendResetLink),
//               ),
//               SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: () => resetPassword(l10n),
//                 child: Text(l10n.sendResetLink),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_11/l10n/app_localizations.dart';

class Forgetpassword extends StatefulWidget {
  const Forgetpassword({super.key});

  @override
  State<Forgetpassword> createState() => _ForgetpasswordState();
}

class _ForgetpasswordState extends State<Forgetpassword>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  bool _isLoading = false;

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
    super.dispose();
  }

  Future<void> _resetPassword(AppLocalizations l10n) async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _showSnack(l10n.somethingWentWrong, Colors.redAccent);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) _showSnack(l10n.resetEmailSent, Colors.green.shade600);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showSnack(e.message ?? l10n.somethingWentWrong, Colors.redAccent);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      resizeToAvoidBottomInset: false,
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Same background glows as login page
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

                  // Back button — same style as login's language button
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

                  SizedBox(height: size.height * 0.03),

                  // Lock avatar — same style as login's person avatar
                  Center(
                    child: Container(
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
                  ),

                  SizedBox(height: size.height * 0.025),

                  // Title + subtitle
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'Reset Password',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "We'll send a reset link to your email",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.35),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Gold divider
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: _goldDivider(),
                  ),

                  // Email field — same _field style as login
                  _field(
                    controller: emailController,
                    hint: l10n.email,
                    label: 'EMAIL',
                    icon: Icons.alternate_email_rounded,
                    keyboard: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      '• Check spam folder if not received',
                      style: TextStyle(
                        color: _gold.withOpacity(0.45),
                        fontSize: 11,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Shimmer gold button — identical to login
                  _shimmerButton(l10n),
                  SizedBox(height: size.height * 0.022),

                  // Back to login link
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Remember it?  ",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.38),
                            fontSize: 13,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            'Sign In',
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

  // ── Helpers (same as LoginPage) ──────────────────────────────

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

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required String label,
    required IconData icon,
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
        onPressed: _isLoading ? null : () => _resetPassword(l10n),
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
            : const Text(
                'SEND RESET LINK',
                style: TextStyle(
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
