import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:seasoul/services/api_service.dart';
import 'dart:convert';
import '../constants/api_constants.dart';

class GoogleSignInServiceSimple {
  // ✅ Client IDs
  static const String _androidClientId =
      '982762507474-cns94029a218jbghi6sagk118igk49pr.apps.googleusercontent.com';

  static const String _webClientId =
      '982762507474-6blv3lmb1s32akhth9fv3kg2fa38betr.apps.googleusercontent.com';

  static String get _clientId {
    return kIsWeb ? _webClientId : _androidClientId;
  }

  static String get _backendUrl {
    return ApiConstants.baseUrl;
  }

  // ✅ FIXED: GoogleSignIn configuration with serverClientId for Android
  static GoogleSignIn get _googleSignIn {
    if (kIsWeb) {
      return GoogleSignIn(
        clientId: _webClientId,
        scopes: ['email', 'profile', 'openid'],
        signInOption: SignInOption.standard,
      );
    } else {
      // ✅ CRITICAL FIX: Add serverClientId for Android
      return GoogleSignIn(
        clientId: _androidClientId,
        serverClientId: _webClientId,  // 👈 THIS WAS MISSING - CAUSING ERROR 10
        scopes: ['email', 'profile', 'openid'],
      );
    }
  }

  // ✅ Main Sign-In Method
  static Future<Map<String, dynamic>?> signInWithBackend() async {
    try {
      print('🔐 Starting Google Sign-In...');
      print('📱 Platform: ${kIsWeb ? "Web" : "Mobile"}');

      final GoogleSignIn googleSignIn = _googleSignIn;

      // Sign in the user
      final googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        print('❌ User cancelled sign-in');
        return null;
      }

      print('✅ User signed in: ${googleUser.email}');

      // Get authentication details
      final googleAuth = await googleUser.authentication;

      String? idToken = googleAuth.idToken;
      String? accessToken = googleAuth.accessToken;

      print('🔑 ID Token: ${idToken != null ? "✅ Available" : "❌ Missing"}');
      print('🔑 Access Token: ${accessToken != null ? "✅ Available" : "❌ Missing"}');

      // For web, if no ID token, we'll use email-based auth
      // For mobile, we should get an ID token
      final platform = kIsWeb ? 'web' : 'mobile';

      final Map<String, dynamic> payload = {
        'email': googleUser.email,
        'name': googleUser.displayName ?? 'User',
        'photoUrl': googleUser.photoUrl ?? '',
        'googleId': googleUser.id,
        'platform': platform,
      };

      // Add tokens if available
      if (idToken != null) {
        payload['idToken'] = idToken;
      }
      if (accessToken != null) {
        payload['accessToken'] = accessToken;
      }

      // Send to backend
      final response = await http.post(
        Uri.parse('$_backendUrl/api/auth/google/simple'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print('📥 Backend Response Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          // Save token and user data
          if (data['token'] != null) {
            await ApiService.saveToken(data['token']);
          }
          if (data['user'] != null) {
            await ApiService.saveUserData(data['user']);
          }

          return {
            'email': googleUser.email,
            'fullName': googleUser.displayName ?? 'User',
            'profileImage': googleUser.photoUrl ?? '',
            'token': data['token'],
            'user': data['user'],
            'success': true,
          };
        } else {
          print('❌ Backend auth failed: ${data['message']}');
          return {'success': false, 'message': data['message']};
        }
      } else {
        print('❌ Backend error: ${response.body}');
        return {'success': false, 'message': 'Backend error'};
      }

    } catch (error) {
      print('❌ Google Sign-In Error: $error');
      return {'success': false, 'message': error.toString()};
    }
  }

  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await ApiService.deleteToken();
      print('✅ Signed out from Google');
    } catch (e) {
      print('❌ Error signing out: $e');
    }
  }
}