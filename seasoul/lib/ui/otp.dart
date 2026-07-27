// ui/otp.dart - Firebase Phone Authentication
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seasoul/ui/signup.dart';
import 'package:seasoul/ui/user_home.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class OTPPage extends StatefulWidget {
  final String phone;
  final String email;
  final String fullName;
  final String password;

  const OTPPage({
    super.key,
    required this.phone,
    required this.email,
    required this.fullName,
    required this.password,
  });

  @override
  State<OTPPage> createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> {
  static const int _otpLength = 6;
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;
  int? _resendToken;

  Timer? _countdownTimer;
  int _secondsLeft = 59;
  bool _canResend = false;
  bool _isLoading = false;
  bool _isVerifying = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(_otpLength, (index) => FocusNode());
    _controllers = List.generate(
      _otpLength,
      (index) => TextEditingController(),
    );
    _startTimer();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendInitialOTP();
    });
  }

  void _startTimer() {
    setState(() {
      _secondsLeft = 59;
      _canResend = false;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        setState(() {
          _countdownTimer?.cancel();
          _canResend = true;
        });
      } else {
        setState(() {
          _secondsLeft--;
        });
      }
    });
  }

  String _formatPhoneForFirebase(String phone) {
    String cleanPhone = phone.replaceAll(RegExp(r'\s'), '');
    
    // Remove country code if present
    if (cleanPhone.startsWith('+91')) {
      cleanPhone = cleanPhone.substring(3);
    } else if (cleanPhone.startsWith('91') && cleanPhone.length > 10) {
      cleanPhone = cleanPhone.substring(2);
    } else if (cleanPhone.startsWith('0')) {
      cleanPhone = cleanPhone.substring(1);
    }
    
    // Add +91 country code
    return '+91$cleanPhone';
  }

  String _formatPhoneForDisplay(String phone) {
    if (phone.isEmpty) return '';
    if (phone.length == 10) {
      return '+91 $phone';
    } else if (phone.length == 12 && phone.startsWith('91')) {
      return '+${phone.substring(0, 2)} ${phone.substring(2)}';
    }
    return phone;
  }

  Future<void> _sendInitialOTP() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    
    try {
      final phoneNumber = _formatPhoneForFirebase(widget.phone);
      print('📤 Sending Firebase OTP to: $phoneNumber');
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('✅ Auto-verification completed');
          await _handleAutoVerification(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print('❌ Verification failed: ${e.code} - ${e.message}');
          setState(() {
            _isLoading = false;
            _errorMessage = _getFirebaseErrorMessage(e);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          print('✅ OTP sent! Verification ID: $verificationId');
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ OTP sent to your phone!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('⏱️ Auto-retrieval timeout');
          setState(() {
            _verificationId = verificationId;
          });
        },
      );
    } catch (e) {
      print('❌ Error sending OTP: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to send OTP: ${e.toString()}';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleAutoVerification(PhoneAuthCredential credential) async {
    try {
      print('🔄 Processing auto-verification...');
      
      // Sign in with credential
      final userCredential = await _auth.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();
      
      if (idToken != null) {
        await _registerUser(idToken);
      }
    } catch (e) {
      print('❌ Auto-verification error: $e');
      setState(() {
        _errorMessage = 'Auto-verification failed: ${e.toString()}';
      });
    }
  }

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Invalid phone number format';
      case 'too-many-requests':
        return 'Too many requests. Please try again later';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later';
      case 'invalid-verification-code':
        return 'Invalid OTP. Please check and try again';
      case 'session-expired':
        return 'OTP expired. Please request a new one';
      default:
        return e.message ?? 'Verification failed';
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _verifyOTP() async {
    if (_isLoading || _isVerifying || _verificationId == null) return;

    setState(() {
      _errorMessage = '';
    });

    String otp = '';
    for (var controller in _controllers) {
      otp += controller.text;
    }

    if (otp.length != _otpLength) {
      setState(() {
        _errorMessage = 'Please enter complete 6-digit OTP';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter complete 6-digit OTP'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      print('📤 Verifying OTP: $otp');
      print('🔑 Verification ID: $_verificationId');
      
      // Create credential with OTP
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      // Sign in with credential
      final userCredential = await _auth.signInWithCredential(credential);
      print('✅ Firebase authentication successful');
      
      // Get ID token
      final idToken = await userCredential.user?.getIdToken();
      
      if (idToken == null) {
        throw Exception('Failed to get authentication token');
      }

      print('✅ Got Firebase ID token');
      await _registerUser(idToken);

    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      
      String errorMessage = _getFirebaseErrorMessage(e);
      
      setState(() {
        _errorMessage = errorMessage;
      });
      
      if (e.code == 'invalid-verification-code') {
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      } else if (e.code == 'session-expired') {
        _resendOTP();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error: $e');
      
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      
      setState(() {
        _errorMessage = errorMessage;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _registerUser(String firebaseToken) async {
    try {
      print('📤 Registering user with Firebase token...');
      
      // Verify with backend
      final verifyData = {
        'phone': widget.phone,
        'firebaseToken': firebaseToken,
      };
      
      final verifyResponse = await ApiService.post(ApiConstants.verifyOTP, verifyData);
      print('📥 Verify Response: $verifyResponse');

      if (verifyResponse['success'] == true && verifyResponse['verified'] == true) {
        print('✅ Backend verified! Registering user...');

        final registerData = {
          'fullName': widget.fullName,
          'email': widget.email,
          'phone': widget.phone,
          'password': widget.password,
        };

        print('📤 Registering user: $registerData');
        final registerResponse = await ApiService.post(ApiConstants.register, registerData);
        print('📥 Register Response: $registerResponse');

        if (registerResponse['success'] == true || registerResponse['token'] != null) {
          if (registerResponse['token'] != null) {
            await ApiService.saveToken(registerResponse['token']);
          }
          
          await ApiService.saveUserData({
            '_id': registerResponse['_id'] ?? registerResponse['user']?['_id'],
            'fullName': registerResponse['fullName'] ?? registerResponse['user']?['fullName'] ?? widget.fullName,
            'email': registerResponse['email'] ?? registerResponse['user']?['email'] ?? widget.email,
            'phone': registerResponse['phone'] ?? registerResponse['user']?['phone'] ?? widget.phone,
          });
          
          print('✅ Token and user data saved!');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Registration successful! Welcome to SeaSoul!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );

            await Future.delayed(const Duration(milliseconds: 500));
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const UserHome()),
            );
          }
        } else {
          throw Exception(registerResponse['message'] ?? 'Registration failed');
        }
      } else {
        throw Exception(verifyResponse['message'] ?? 'Verification failed');
      }
    } catch (e) {
      print('❌ Registration error: $e');
      throw e;
    }
  }

  void _resendOTP() async {
    if (!_canResend || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final phoneNumber = _formatPhoneForFirebase(widget.phone);
      print('📤 Resending Firebase OTP to: $phoneNumber');
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('✅ Auto-verification completed on resend');
          await _handleAutoVerification(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print('❌ Resend verification failed: ${e.code}');
          setState(() {
            _isLoading = false;
            _errorMessage = _getFirebaseErrorMessage(e);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          print('✅ OTP resent! New Verification ID: $verificationId');
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _isLoading = false;
          });
          
          for (var controller in _controllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
          _startTimer();
          
          print('✅ OTP resent successfully');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ OTP resent successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
          });
        },
      );
    } catch (e) {
      print('❌ Resend OTP Error: $e');
      
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _errorMessage = errorMessage;
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ $errorMessage'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _handleOtpChange(String value, int index) {
    setState(() {
      _errorMessage = '';
    });
    
    if (value.isNotEmpty) {
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_controllers.every((c) => c.text.isNotEmpty)) {
          _verifyOTP();
        }
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  void _goBackToSignup() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SignupPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const colorBackground = Color(0xFF0D1516);
    const colorPrimaryContainer = Color(0xFF00E5FF);
    const colorOnPrimaryFixed = Color(0xFF001F24);
    const colorOnSurface = Color(0xFFDCE4E5);
    const colorOnSurfaceVariant = Color(0xFFBAC9CC);
    const colorOutline = Color(0xFF849396);
    const colorError = Color(0xFFFF6B6B);

    final displayPhone = _formatPhoneForDisplay(widget.phone);

    return Scaffold(
      backgroundColor: colorBackground,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: Container(color: colorBackground)),
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuAIx0yomZ86ZvhZIuGwPhZH7msLm2aTLXqAsTiLsIzfo5QugjjV-qQz2yT18iOP7ttYlZnO9MVO2YtMha3I7p0fQ-Z1QtkkWfAcxy_z1VFaiO25e4xkfHRwE4dwtlMNQeFKFc_CIXv9oveAVD5Zg3JOL078YrJHLxObFhswT5uY9731bEdq2CaOY_8vJ4Ll4tX0DTWpgqrYdxcYkIOqSJVOvTcOrcXq_ZpnRXdSSqDKxPeHUqbr4AL9HuNtHUCGwgfsrPKnzjfqgtk',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(),
              ),
            ),
          ),
          Positioned(
            top: -200,
            right: -200,
            width: MediaQuery.of(context).size.width * 1.2,
            height: MediaQuery.of(context).size.width * 1.2,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colorPrimaryContainer.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 35,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: colorPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SeaSoul',
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: colorPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: colorOnSurface),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.05),
                        side: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      onPressed: _goBackToSignup,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Verify Your Identity',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: colorOnSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            color: colorOnSurfaceVariant,
                          ),
                          children: [
                            const TextSpan(text: "We've sent a 6-digit code to "),
                            TextSpan(
                              text: displayPhone,
                              style: const TextStyle(
                                color: Color(0xFFC3F5FF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        _otpLength,
                        (index) => _buildOtpField(index, colorPrimaryContainer),
                      ),
                    ),
                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: colorError, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage,
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  color: colorError,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    Column(
                      children: [
                        Text(
                          "Didn't receive the code?",
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: colorOutline,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _canResend && !_isLoading ? _resendOTP : null,
                          child: Text(
                            _isLoading
                                ? 'Sending...'
                                : _canResend
                                    ? 'Resend Code'
                                    : 'Resend in 00:${_secondsLeft.toString().padLeft(2, '0')}',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _canResend && !_isLoading
                                  ? const Color(0xFF59DBC7)
                                  : colorOutline.withOpacity(0.5),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Container(
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colorPrimaryContainer.withOpacity(0.15),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorPrimaryContainer,
                          foregroundColor: colorOnPrimaryFixed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: (_isVerifying || _isLoading) ? null : _verifyOTP,
                        child: _isVerifying || _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Color(0xFF001F24),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Verify & Proceed',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, size: 20),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpField(int index, Color activeAccent) {
    return SizedBox(
      width: 52,
      height: 72,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            maxLines: 1,
            showCursor: false,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: activeAccent,
            ),
            decoration: InputDecoration(
              counterText: "",
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF00E5FF),
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFFF6B6B),
                  width: 1.5,
                ),
              ),
            ),
            onChanged: (value) {
              _handleOtpChange(value, index);
            },
          ),
        ),
      ),
    );
  }
}
