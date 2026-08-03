// ui/signup.dart - Google Sign‑In with backend service
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seasoul/services/google_signin_service_simple.dart';
import 'package:seasoul/ui/login.dart';
import 'package:seasoul/ui/user_home.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  bool _isLoading = false;

  static const Color colorBackground = Color(0xFF0D1516);
  static const Color colorPrimaryContainer = Color(0xFF00E5FF);
  static const Color colorOnSurface = Color(0xFFDCE4E5);
  static const Color colorOnSurfaceVariant = Color(0xFFBAC9CC);

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final result = await GoogleSignInServiceSimple.signInWithBackend();

      if (result == null) {
        setState(() => _isLoading = false);
        return;
      }

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Welcome! You are signed in with Google.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const UserHome()),
          );
        }
      } else {
        final errorMsg = result['message'] ?? 'Google sign‑in failed.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Google Sign‑In error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign‑in failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0D1516), Color(0xFF05080B)],
                ),
              ),
            ),
          ),
          // Wave decoration
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(
                size: Size(MediaQuery.of(context).size.width, 240),
                painter: WavePainter(),
              ),
            ),
          ),
          // Main content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 40.0,
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            colorPrimaryContainer,
                            colorPrimaryContainer.withOpacity(0.5),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorPrimaryContainer.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.sailing_rounded,
                        size: 40,
                        color: colorBackground,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Brand name
                    Text(
                      'SeaSoul Holidays',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        textStyle: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: colorPrimaryContainer,
                          letterSpacing: -0.02,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'LUXURIOUS ISLAND GETAWAYS',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        textStyle: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: colorPrimaryContainer.withOpacity(0.6),
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Glass card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: Container(
                          padding: const EdgeInsets.all(32.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Title
                              Text(
                                'Welcome Aboard',
                                style: GoogleFonts.montserrat(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: colorOnSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Description
                              Text(
                                'Sign in with Google to continue your journey\nto the pristine islands of Lakshadweep.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: colorOnSurfaceVariant,
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 32),
                              
                              // ✅ Google Sign‑In Button - Brand color
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorPrimaryContainer,
                                    foregroundColor: colorBackground,
                                    shadowColor: colorPrimaryContainer.withOpacity(0.4),
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 14,
                                    ),
                                  ),
                                  onPressed: _isLoading ? null : _signInWithGoogle,
                                  icon: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Image.asset(
                                      'assets/google_logo.png',
                                      height: 18,
                                      width: 18,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.g_mobiledata, size: 18, color: Colors.black87),
                                    ),
                                  ),
                                  label: Text(
                                    _isLoading ? 'Signing in...' : 'Sign in with Google',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: colorBackground,
                                    ),
                                  ),
                                ),
                              ),
                              
                              if (_isLoading) ...[
                                const SizedBox(height: 16),
                                const CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: colorPrimaryContainer,
                                ),
                              ],
                              
                              const SizedBox(height: 28),
                              
                              // Divider
                              Container(
                                padding: const EdgeInsets.only(top: 24),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: Colors.white.withOpacity(0.06),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Already have an account?',
                                      style: GoogleFonts.montserrat(
                                        color: colorOnSurfaceVariant,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const login(),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                      child: Text(
                                        'Sign In',
                                        style: GoogleFonts.montserrat(
                                          color: colorPrimaryContainer,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // Terms text
                              Text(
                                'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: colorOnSurfaceVariant.withOpacity(0.5),
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Trust badges
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTrustBadge(
                          Icons.gpp_good_outlined,
                          'Secure Booking',
                        ),
                        const SizedBox(width: 32),
                        _buildTrustBadge(
                          Icons.support_agent_outlined,
                          '24/7 Concierge',
                        ),
                        const SizedBox(width: 32),
                        _buildTrustBadge(
                          Icons.payment_outlined,
                          'Easy Payments',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String label) {
    return Opacity(
      opacity: 0.4,
      child: Column(
        children: [
          Icon(icon, size: 20, color: colorPrimaryContainer),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.montserrat(
              fontSize: 8,
              color: Colors.white.withOpacity(0.5),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Wave Painter
class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.7,
        size.width * 0.5,
        size.height * 0.5,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.3,
        size.width,
        size.height * 0.6,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
    
    // Second wave
    final paint2 = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final path2 = Path()
      ..moveTo(0, size.height * 0.6)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.8,
        size.width * 0.6,
        size.height * 0.55,
      )
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.4,
        size.width,
        size.height * 0.65,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}