// lib/services/razorpay_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class RazorpayService {
  static Razorpay? _razorpay;
  static Function(PaymentSuccessResponse)? _onSuccess;
  static Function(PaymentFailureResponse)? _onError;
  static Function(ExternalWalletResponse)? _onExternalWallet;

  // Store pending data for use in verify callback
  static String? _pendingBookingId;
  static double? _pendingAmount;
  static String? _pendingOrderId;

  // Initialize Razorpay with callbacks
  static void initialize({
    required Function(PaymentSuccessResponse) successCallback,
    required Function(PaymentFailureResponse) errorCallback,
    Function(ExternalWalletResponse)? externalWalletCallback,
  }) {
    _razorpay = Razorpay();
    _onSuccess = successCallback;
    _onError = errorCallback;
    _onExternalWallet = externalWalletCallback;

    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  // Get Razorpay key from backend
  static Future<String> getRazorpayKey() async {
    try {
      final token = await _getAuthToken();

      final response = await http.get(
        Uri.parse(ApiConstants.razorpayGetKey),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📥 Key Response Status: ${response.statusCode}');
      print('📥 Key Response Body: ${response.body}');

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? errorData['error'] ?? 'Failed to get Razorpay key: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);

      if (data['success'] != true) {
        throw Exception(data['message'] ?? data['error'] ?? 'Failed to get key');
      }

      return data['key_id'];
    } catch (e) {
      throw Exception('Error getting Razorpay key: $e');
    }
  }

  // Create order on backend
  static Future<Map<String, dynamic>> createOrder({
    required double amount,
    required String receipt,
    Map<String, String>? notes,
  }) async {
    try {
      final token = await _getAuthToken();

      // ✅ Razorpay receipt max is 40 chars — truncate safely
      final safeReceipt = receipt.length > 40 ? receipt.substring(0, 40) : receipt;

      final payload = {
        'amount': amount,
        'currency': 'INR',
        'receipt': safeReceipt,
        'notes': notes ?? {},
      };

      print('📦 Creating Razorpay order: $payload');

      final response = await http.post(
        Uri.parse(ApiConstants.razorpayCreateOrder),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      print('📥 Order Response Status: ${response.statusCode}');
      print('📥 Order Response Body: ${response.body}');

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? errorData['error'] ?? 'Failed to create order');
      }

      final data = jsonDecode(response.body);

      if (data['success'] != true) {
        throw Exception(data['message'] ?? data['error'] ?? 'Order creation failed');
      }

      return data;
    } catch (e) {
      throw Exception('Failed to create Razorpay order: $e');
    }
  }

  // Verify payment with booking creation on backend
  static Future<Map<String, dynamic>> verifyPaymentWithBooking({
    required String orderId,
    required String paymentId,
    required String signature,
    String? productId,
    String? activityId,
    required double amount,
    required int guests,
    String? checkIn,
    String? checkOut,
  }) async {
    try {
      final token = await _getAuthToken();

      final response = await http.post(
        Uri.parse(ApiConstants.razorpayVerifyPayment),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
          if (productId != null && productId.isNotEmpty) 'productId': productId,
          if (activityId != null && activityId.isNotEmpty) 'activityId': activityId,
          'amount': amount,
          'guests': guests,
          if (checkIn != null) 'checkIn': checkIn,
          if (checkOut != null) 'checkOut': checkOut,
        }),
      );

      print('📥 Verify Response Status: ${response.statusCode}');
      print('📥 Verify Response Body: ${response.body}');

      if (response.statusCode != 200) {
        final responseData = jsonDecode(response.body);
        final message = responseData['message'] ?? responseData['error'] ?? 'Payment verification failed';
        throw Exception(message);
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        throw Exception(data['message'] ?? data['error'] ?? 'Payment verification failed');
      }

      return data;
    } catch (e) {
      print('❌ Verification error: $e');
      throw Exception('Error verifying payment: $e');
    }
  }

  // Verify payment on backend (legacy method - kept for compatibility)
  static Future<bool> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    String? bookingId,
    double? amount,
  }) async {
    try {
      final token = await _getAuthToken();

      final response = await http.post(
        Uri.parse(ApiConstants.razorpayVerifyPayment),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
          if (bookingId != null && bookingId.isNotEmpty) 'bookingId': bookingId,
          if (amount != null) 'amount': amount,
        }),
      );

      print('📥 Verify Response Status: ${response.statusCode}');
      print('📥 Verify Response Body: ${response.body}');

      if (response.statusCode != 200) {
        final responseData = jsonDecode(response.body);
        final message = responseData['message'] ?? responseData['error'] ?? 'Payment verification failed';
        throw Exception(message);
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        throw Exception(data['message'] ?? data['error'] ?? 'Payment verification failed');
      }

      return true;
    } catch (e) {
      print('❌ Verification error: $e');
      throw Exception('Error verifying payment: $e');
    }
  }

  // Open Razorpay checkout
  static Future<void> openCheckout({
    required String keyId,
    required String orderId,
    required double amount,
    required String receipt,
    required String itemName,
    required String customerName,
    required String customerEmail,
    required String customerContact,
    String? bookingId,
  }) async {
    if (_razorpay == null) {
      throw Exception('Razorpay not initialized. Call initialize() first.');
    }

    // Store pending data for use in success callback
    _pendingBookingId = bookingId;
    _pendingAmount = amount;
    _pendingOrderId = orderId;

    final options = {
      'key': keyId,
      'amount': (amount * 100).toInt(), // Convert rupees to paise
      'name': 'SeaSoul',
      'description': itemName,
      'order_id': orderId,
      'prefill': {
        'contact': customerContact,
        'email': customerEmail,
        'name': customerName,
      },
      'theme': {
        'color': '#0099CC',
      },
      'modal': {
        'backdrop_color': '#1A2B49',
      },
    };

    print('🔑 Opening Razorpay with options: $options');
    _razorpay!.open(options);
  }

  // Payment success handler
  static void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print('✅ Payment Success: ${response.paymentId}');
    _onSuccess?.call(response);
  }

  // Payment error handler
  static void _handlePaymentError(PaymentFailureResponse response) {
    print('❌ Payment Error: ${response.message}');
    _onError?.call(response);
  }

  // External wallet handler
  static void _handleExternalWallet(ExternalWalletResponse response) {
    print('💳 External Wallet: ${response.walletName}');
    _onExternalWallet?.call(response);
  }

  // Get auth token
  static Future<String> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      throw Exception('User not authenticated');
    }
    return token;
  }

  // Get stored pending booking id (accessible from payment screen)
  static String? get pendingBookingId => _pendingBookingId;
  static double? get pendingAmount => _pendingAmount;
  static String? get pendingOrderId => _pendingOrderId;

  // Dispose
  static void dispose() {
    _razorpay?.clear();
    _razorpay = null;
    _pendingBookingId = null;
    _pendingAmount = null;
    _pendingOrderId = null;
  }
}