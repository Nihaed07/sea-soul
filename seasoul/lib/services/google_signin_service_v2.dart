import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:seasoul/services/api_service.dart';
import 'dart:convert';
import '../constants/api_constants.dart';

import 'origin_helper.dart' if (dart.library.html) 'origin_helper_web.dart';

class GoogleSignInServiceV2 {
  // ✅ Your Client IDs
  static const String _androidClientId =
      '982762507474-cns94029a218jbghi6sagk118igk49pr.apps.googleusercontent.com';

  static const String _iosClientId =
      '982762507474-cns94029a218jbghi6sagk118igk49pr.apps.googleusercontent.com';

  static const String _webClientId =
      '982762507474-6blv3lmb1s32akhth9fv3kg2fa38betr.apps.googleusercontent.com';

  static String get _clientId {
    if (kIsWeb) {
      return _webClientId;
    } else {
      return _androidClientId;
    }
  }

  static String get _backendUrl {
    return ApiConstants.baseUrl;
  }

  static String get _currentOrigin {
    if (kIsWeb) {
      return getOrigin();
    }
    return '';
  }

  // ✅ Configure GoogleSignIn to request ID token
  static GoogleSignIn get _googleSignIn {
    if (kIsWeb) {
      return GoogleSignIn(
        clientId: _clientId,
        scopes: [
          'email',
          'profile',
          'openid', // Required for ID token
        ],
        // serverClientId is NOT supported on web
        signInOption: SignInOption.standard,
      );
    } else {
      return GoogleSignIn(
        clientId: _clientId,
        scopes: [
          'email',
          'profile',
          'openid',
        ],
        // Only for mobile platforms
        serverClientId: _clientId,
      );
    }
  }

  /// ✅ Improved sign-in with proper ID token handling
  static Future<Map<String, dynamic>?> signInWithBackend() async {
    try {
      print('🔐 Starting Google Sign-In V2...');
      print('📱 Platform: ${kIsWeb ? "Web" : "Mobile"}');
      print('📱 Client ID: $_clientId');
      print('📱 Backend URL: $_backendUrl');

      final GoogleSignIn googleSignIn = _googleSignIn;

      // Step 1: Sign in the user
      GoogleSignInAccount? googleUser;

      if (kIsWeb) {
        print('📱 Web: Using signInSilently first...');
        googleUser = await googleSignIn.signInSilently();

        if (googleUser == null) {
          print('📱 Web: No cached user, showing sign-in dialog...');
          googleUser = await googleSignIn.signIn();
        }
      } else {
        googleUser = await googleSignIn.signIn();
      }

      if (googleUser == null) {
        print('❌ User cancelled sign-in');
        return null;
      }

      print('✅ Google user signed in: ${googleUser.email}');

      // Step 2: Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Step 3: Get ID token (this is crucial!)
      String? idToken = googleAuth.idToken;

      // ✅ If no ID token from googleAuth, try to get it via server auth code
      if (idToken == null || idToken.isEmpty) {
        print('⚠️ No ID token from googleAuth, trying server auth code...');

        // Get server auth code
        final serverAuthCode = googleUser.serverAuthCode;

        if (serverAuthCode != null) {
          print('✅ Got server auth code, exchanging for tokens...');

          // Exchange server auth code for tokens via backend
          final response = await http.post(
            Uri.parse('$_backendUrl/api/auth/google/exchange-code'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'code': serverAuthCode,
              'platform': kIsWeb ? 'web' : 'mobile',
            }),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            idToken = data['idToken'];
            print('✅ Got ID token from server auth code');
          }
        }
      }

      // Step 4: If still no ID token, try alternative authentication
      if (idToken == null || idToken.isEmpty) {
        print('⚠️ Still no ID token, using email/OAuth authentication...');

        // Send user info directly (less secure but works)
        final response = await http.post(
          Uri.parse('$_backendUrl/api/auth/google/email-auth'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': googleUser.email,
            'displayName': googleUser.displayName ?? 'User',
            'photoUrl': googleUser.photoUrl ?? '',
            'id': googleUser.id,
            'accessToken': googleAuth.accessToken,
            'platform': kIsWeb ? 'web' : 'mobile',
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            await ApiService.saveToken(data['token']);
            await ApiService.saveUserData(data['user']);

            return {
              'id': googleUser.id,
              'email': googleUser.email,
              'fullName': googleUser.displayName ?? 'User',
              'profileImage': googleUser.photoUrl ?? '',
              'token': data['token'],
              'user': data['user'],
              'success': true,
            };
          }
        }

        print('❌ Email authentication failed');
        return {'success': false, 'message': 'Authentication failed'};
      }

      // Step 5: Standard ID token authentication
      print('✅ Using ID token authentication');
      print('📧 Email: ${googleUser.email}');
      print('👤 Name: ${googleUser.displayName}');

      final platform = kIsWeb ? 'web' : 'mobile';

      final response = await http.post(
        Uri.parse('$_backendUrl/api/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
          'platform': platform,
        }),
      );

      print('📥 Backend Response Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (data['token'] != null) {
            await ApiService.saveToken(data['token']);
          }
          if (data['user'] != null) {
            await ApiService.saveUserData(data['user']);
          }

          return {
            'id': googleUser.id,
            'email': googleUser.email,
            'fullName': googleUser.displayName ?? 'User',
            'profileImage': googleUser.photoUrl ?? '',
            'idToken': idToken,
            'accessToken': googleAuth.accessToken,
            'token': data['token'],
            'user': data['user'],
            'success': true,
          };
        } else {
          print('❌ Backend authentication failed: ${data['message']}');
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

  static Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
      await ApiService.deleteToken();
      print('✅ Disconnected from Google');
    } catch (e) {
      print('❌ Error disconnecting: $e');
    }
  }

  static Future<bool> isSignedIn() async {
    try {
      final account = _googleSignIn.currentUser;
      if (account != null) return true;

      if (kIsWeb) {
        try {
          final cachedUser = await _googleSignIn.signInSilently();
          return cachedUser != null;
        } catch (e) {
          return false;
        }
      }
      return false;
    } catch (e) {
      print('❌ Error checking sign in status: $e');
      return false;
    }
  }

  static GoogleSignInAccount? getCurrentUser() {
    return _googleSignIn.currentUser;
  }

  static Future<void> clearCache() async {
    try {
      await _googleSignIn.signOut();
      await Future.delayed(const Duration(milliseconds: 500));
      print('✅ Google Sign-In cache cleared');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }
}
