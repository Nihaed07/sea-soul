// ui/signup.dart - COMPLETE FULL CODE
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seasoul/ui/login.dart';
import 'package:seasoul/ui/otp.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _termsAccepted = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(() => setState(() {}));
    _emailFocus.addListener(() => setState(() {}));
    _phoneFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ✅ Format phone number - extract 10 digits
  String _formatPhoneNumber(String phone) {
    String cleanPhone = phone.replaceAll(RegExp(r'\s'), '');
    
    if (cleanPhone.startsWith('+91')) {
      cleanPhone = cleanPhone.substring(3);
    } else if (cleanPhone.startsWith('91')) {
      cleanPhone = cleanPhone.substring(2);
    } else if (cleanPhone.startsWith('0')) {
      cleanPhone = cleanPhone.substring(1);
    }
    
    return cleanPhone;
  }

  void _sendOTP() async {
    if (_isLoading) return;

    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    // ✅ Validate all fields
    if (fullName.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ Validate email format
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // ✅ Format and validate phone (10 digits)
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    final cleanPhone = _formatPhoneNumber(phone);
    
    if (!phoneRegex.hasMatch(cleanPhone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept Terms & Conditions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ Check if phone is already registered
      final data = {
        'phone': cleanPhone,
      };
      
      print('📤 Checking phone availability: $cleanPhone');
      
      final response = await ApiService.post(ApiConstants.sendOTP, data);
      print('📱 API Response: $response');

      if (response['success'] == false) {
        String errorMsg = response['message'] ?? 'Something went wrong';
        
        if (errorMsg.toLowerCase().contains('already registered') || 
            errorMsg.toLowerCase().contains('exists')) {
          errorMsg = 'This phone number is already registered. Please login or use another.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // ✅ Success - proceed to OTP verification with Firebase
      print('✅ Phone number available, proceeding to Firebase OTP...');

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPPage(
              phone: cleanPhone,
              email: email,
              fullName: fullName,
              password: password,
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error: $e');
      
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('already registered') || 
          errorMsg.contains('exists') ||
          (errorMsg.contains('phone') && errorMsg.contains('registered'))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This phone number is already registered. Please login or use another.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
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
    const colorBackground = Color(0xFF0D1516);
    const colorPrimaryContainer = Color(0xFF00E5FF);
    const colorOutline = Color(0xFF849396);
    const colorOnSurface = Color(0xFFDCE4E5);
    const colorOnSurfaceVariant = Color(0xFFBAC9CC);

    return Scaffold(
      backgroundColor: colorBackground,
      body: Stack(
        children: [
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
                    const Icon(
                      Icons.sailing_rounded,
                      size: 48,
                      color: colorPrimaryContainer,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'SeaSoul Holidays',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        textStyle: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: colorPrimaryContainer,
                          letterSpacing: -0.02,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
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
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Account',
                                style: GoogleFonts.montserrat(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: colorOnSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Embark on your journey to the pristine islands of Lakshadweep.',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: colorOnSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 32),
                              _buildInputField(
                                label: 'FULL NAME',
                                icon: Icons.person_outline,
                                hint: 'Enter your full name',
                                controller: _fullNameController,
                                focusNode: _nameFocus,
                              ),
                              const SizedBox(height: 24),
                              _buildInputField(
                                label: 'EMAIL ADDRESS',
                                icon: Icons.mail_outline,
                                hint: 'email@seasoul.com',
                                controller: _emailController,
                                focusNode: _emailFocus,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 24),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  if (constraints.maxWidth > 400) {
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _buildInputField(
                                            label: 'PHONE NUMBER',
                                            icon: Icons.call_outlined,
                                            hint: '9876543210',
                                            controller: _phoneController,
                                            focusNode: _phoneFocus,
                                            keyboardType: TextInputType.phone,
                                          ),
                                        ),
                                        const SizedBox(width: 24),
                                        Expanded(
                                          child: _buildInputField(
                                            label: 'PASSWORD',
                                            icon: Icons.lock_outline,
                                            hint: '••••••••',
                                            controller: _passwordController,
                                            focusNode: _passwordFocus,
                                            obscureText: true,
                                          ),
                                        ),
                                      ],
                                    );
                                  } else {
                                    return Column(
                                      children: [
                                        _buildInputField(
                                          label: 'PHONE NUMBER',
                                          icon: Icons.call_outlined,
                                          hint: '9876543210',
                                          controller: _phoneController,
                                          focusNode: _phoneFocus,
                                          keyboardType: TextInputType.phone,
                                        ),
                                        const SizedBox(height: 24),
                                        _buildInputField(
                                          label: 'PASSWORD',
                                          icon: Icons.lock_outline,
                                          hint: '••••••••',
                                          controller: _passwordController,
                                          focusNode: _passwordFocus,
                                          obscureText: true,
                                        ),
                                      ],
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 24),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Theme(
                                    data: ThemeData(
                                      unselectedWidgetColor: Colors.white
                                          .withOpacity(0.2),
                                    ),
                                    child: Checkbox(
                                      value: _termsAccepted,
                                      activeColor: const Color(0xFF00E5FF),
                                      checkColor: const Color(0xFF0D1516),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      onChanged: (val) {
                                        setState(() {
                                          _termsAccepted = val ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 12.0),
                                      child: RichText(
                                        text: TextSpan(
                                          style: GoogleFonts.montserrat(
                                            fontSize: 14,
                                            color: colorOnSurfaceVariant,
                                            height: 1.4,
                                          ),
                                          children: const [
                                            TextSpan(text: 'I agree to the '),
                                            TextSpan(
                                              text: 'Terms & Conditions',
                                              style: TextStyle(
                                                color: colorPrimaryContainer,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                            TextSpan(text: ' and '),
                                            TextSpan(
                                              text: 'Privacy Policy',
                                              style: TextStyle(
                                                color: colorPrimaryContainer,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                            TextSpan(text: '.'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF00E5FF),
                                      Color(0xFF00A694),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF00E5FF,
                                      ).withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _isLoading ? null : _sendOTP,
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Color(0xFF001F24),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Continue',
                                              style: GoogleFonts.montserrat(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF001F24),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              color: Color(0xFF001F24),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              Container(
                                padding: const EdgeInsets.only(top: 24),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: Colors.white.withOpacity(0.05),
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
                                        fontSize: 16,
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
                                      child: Text(
                                        'Sign In',
                                        style: GoogleFonts.montserrat(
                                          color: colorPrimaryContainer,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTrustBadge(
                          Icons.gpp_good_outlined,
                          'Secure Booking',
                          colorOutline,
                        ),
                        const SizedBox(width: 40),
                        _buildTrustBadge(
                          Icons.support_agent_outlined,
                          '24/7 Concierge',
                          colorOutline,
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

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isFocused = focusNode.hasFocus;
    final isPasswordField = label == 'PASSWORD';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF849396),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: isPasswordField ? _obscurePassword : obscureText,
            keyboardType: keyboardType,
            style: GoogleFonts.montserrat(
              color: const Color(0xFFDCE4E5),
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.montserrat(
                color: Colors.white24,
                fontSize: 16,
              ),
              prefixIcon: Icon(
                icon,
                color: isFocused
                    ? const Color(0xFF00E5FF)
                    : const Color(0xFF849396),
              ),
              suffixIcon: isPasswordField
                  ? IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: isFocused
                            ? const Color(0xFF00E5FF)
                            : const Color(0xFF849396),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF05080B),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF59DBC7),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrustBadge(IconData icon, String label, Color color) {
    return Opacity(
      opacity: 0.4,
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Wave Painter for background
class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.3)
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
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}