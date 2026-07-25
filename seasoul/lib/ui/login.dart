import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seasoul/ui/forgot_password.dart';
import 'package:seasoul/ui/signup.dart';
import 'package:seasoul/ui/user_home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../constants/api_constants.dart';
import '../services/google_signin_service_v2.dart';


class login extends StatefulWidget {
  const login({super.key});

  @override
  State<login> createState() => _loginState();
}

class _loginState extends State<login> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final FocusNode _identifierFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _isIdentifierFocused = false;
  bool _isPasswordFocused = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isSuccess = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _identifierFocus.addListener(() {
      setState(() => _isIdentifierFocused = _identifierFocus.hasFocus);
    });
    _passwordFocus.addListener(() {
      setState(() => _isPasswordFocused = _passwordFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _identifierFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ✅ Normal Login
  void _handleLogin() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _isSuccess = false;
    });

    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter email/phone and password'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    final isEmail = identifier.contains('@');

    if (isEmail && !emailRegex.hasMatch(identifier)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final data = {
        'identifier': identifier,
        'password': password,
      };

      final response = await ApiService.post(ApiConstants.login, data);

      await ApiService.saveToken(response['token']);

      await ApiService.saveUserData({
        '_id': response['_id'],
        'fullName': response['fullName'],
        'email': response['email'],
        'phone': response['phone'],
        'profileImage': response['profileImage'] ??
            'https://res.cloudinary.com/demo/image/upload/v1/default-avatar.png',
        'bio': response['bio'] ?? '',
        'location': response['location'] ?? '',
      });

      setState(() {
        _isSuccess = true;
        _isLoading = false;
      });

      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserHome()),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login Failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleLoading) return;

    setState(() => _isGoogleLoading = true);

    try {
      print('🔐 Initiating Google Sign-In...');
      
      final result = await GoogleSignInServiceV2.signInWithBackend();

      if (result == null) {
        setState(() => _isGoogleLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Google sign in cancelled or failed'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (result['success'] == false) {
        setState(() => _isGoogleLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['message'] ?? "Sign in failed"}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print('✅ User signed in successfully!');
      print('✅ Email: ${result['email']}');
      print('✅ Name: ${result['fullName']}');

      await _saveUserData(result);

      setState(() => _isGoogleLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Welcome ${result['fullName']}!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserHome()),
        );
      }
    } catch (e) {
      setState(() => _isGoogleLoading = false);
      print('❌ Error in _handleGoogleSignIn: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Sign in error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('auth_token', userData['token'] ?? '');

    final user = userData['user'] ?? {};
    await prefs.setString('user_data', jsonEncode(user));

    await ApiService.saveToken(userData['token'] ?? '');
    await ApiService.saveUserData(user);

    print('✅ User data saved locally');
  }

  @override
  Widget build(BuildContext context) {
    const colorBackground = Color(0xFF0D1516);
    const colorPrimaryContainer = Color(0xFF00E5FF);
    const colorSecondary = Color(0xFF59DBC7);
    const colorOnSurface = Color(0xFFDCE4E5);
    const colorOnSurfaceVariant = Color(0xFFBAC9CC);
    const colorOutline = Color(0xFF849396);
    const colorOutlineVariant = Color(0xFF3B494C);
    const colorLowestSurface = Color(0xFF080F11);

    return Scaffold(
      backgroundColor: colorBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.6, -0.4),
                  radius: 0.7,
                  colors: [Color(0x1400E5FF), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.6, 0.4),
                  radius: 0.7,
                  colors: [Color(0x1459DBC7), Colors.transparent],
                ),
              ),
            ),
          ),
          Center(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 30.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SeaSoul',
                      style: GoogleFonts.montserrat(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: colorPrimaryContainer,
                        letterSpacing: -0.02,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'LUXURIOUS ISLAND GETAWAYS',
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: colorOutline,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 440),
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome Back',
                                style: GoogleFonts.montserrat(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: colorOnSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Please enter your details to continue your journey.',
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  color: colorOnSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 28),
                              _buildFormLabel('Email or Phone', colorOutline),
                              const SizedBox(height: 6),
                              _buildInputField(
                                controller: _identifierController,
                                focusNode: _identifierFocus,
                                hintText: 'marina@example.com',
                                icon: Icons.person_outline,
                                isFocused: _isIdentifierFocused,
                                lowestBg: colorLowestSurface,
                                activeTint: colorPrimaryContainer,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildFormLabel('Password', colorOutline),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ForgotPasswordPage(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Forgot Password?',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: colorPrimaryContainer,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _buildPasswordField(
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                hintText: '••••••••',
                                isFocused: _isPasswordFocused,
                                lowestBg: colorLowestSurface,
                                activeTint: colorPrimaryContainer,
                              ),
                              const SizedBox(height: 28),
                              _buildSubmitButton(
                                colorPrimaryContainer,
                                colorSecondary,
                              ),
                              const SizedBox(height: 28),
                              // ✅ Divider with OR
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color:
                                          colorOutlineVariant.withOpacity(0.5),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0,
                                    ),
                                    child: Text(
                                      'OR CONTINUE WITH',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: colorOutline,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color:
                                          colorOutlineVariant.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              _buildGoogleButton(),
                              const SizedBox(height: 24),
                              Center(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const SignupPage(),
                                      ),
                                    );
                                  },
                                  child: RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.montserrat(
                                        fontSize: 13,
                                        color: colorOnSurfaceVariant,
                                      ),
                                      children: const [
                                        TextSpan(text: 'New to SeaSoul? '),
                                        TextSpan(
                                          text: 'Register',
                                          style: TextStyle(
                                            color: Color(0xFF00E5FF),
                                            fontWeight: FontWeight.w600,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormLabel(String label, Color color) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.montserrat(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData icon,
    required bool isFocused,
    required Color lowestBg,
    required Color activeTint,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: isFocused
            ? [BoxShadow(color: activeTint.withOpacity(0.15), blurRadius: 15)]
            : null,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: GoogleFonts.montserrat(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.montserrat(
            color: Colors.white24,
            fontSize: 15,
          ),
          prefixIcon: Icon(
            icon,
            color: isFocused ? activeTint : const Color(0xFF849396),
            size: 20,
          ),
          filled: true,
          fillColor: lowestBg,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: activeTint, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required bool isFocused,
    required Color lowestBg,
    required Color activeTint,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: isFocused
            ? [BoxShadow(color: activeTint.withOpacity(0.15), blurRadius: 15)]
            : null,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: _obscurePassword,
        style: GoogleFonts.montserrat(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.montserrat(
            color: Colors.white24,
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.lock_outline,
            color: isFocused ? activeTint : const Color(0xFF849396),
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: isFocused ? activeTint : const Color(0xFF849396),
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          filled: true,
          fillColor: lowestBg,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: activeTint, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(Color fromGradient, Color toGradient) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        gradient: LinearGradient(
          colors: [fromGradient, toGradient],
        ),
        boxShadow: [
          BoxShadow(
            color: fromGradient.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        onPressed: _isLoading ? null : _handleLogin,
        child: _isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white54,
                ),
              )
            : Text(
                _isSuccess ? 'Success!' : 'Login',
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // ✅ Google Sign-In Button (Web + Mobile)
  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.grey),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isGoogleLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.blue,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ✅ Google Icon - Works for both Web & Mobile
                  Image.network(
                    'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.g_mobiledata,
                        color: Colors.blue,
                        size: 24,
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Sign in with Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}