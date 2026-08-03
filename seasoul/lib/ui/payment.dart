// lib/ui/payment.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:seasoul/services/api_service.dart';
import 'package:seasoul/services/auth_services.dart';
import 'package:seasoul/constants/api_constants.dart';
import 'package:seasoul/services/razorpay_services.dart';
import 'package:seasoul/ui/payment_succes.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class payment extends StatefulWidget {
  final String? productId;
  final String? activityId;
  final String itemName;
  final String itemType;
  final double amount;
  final String? bookingId;
  final String itemImage;
  final int duration;
  final DateTime? selectedDate;

  const payment({
    super.key,
    this.productId,
    this.activityId,
    this.itemName = 'Package',
    this.itemType = 'product',
    this.amount = 0,
    this.bookingId,
    this.itemImage = '',
    this.duration = 1,
    this.selectedDate,
  });

  @override
  State<payment> createState() => _paymentState();
}

class _paymentState extends State<payment> {
  bool _isProcessing = false;
  bool _isSuccess = false;
  String? _razorpayOrderId;
  String? _createdBookingId;
  String? _paymentId;
  String? _errorMessage;

  static const Color deepNavy = Color(0xFF1A2B49);
  static const Color oceanBlue = Color(0xFF0099CC);
  static const Color turquoiseLagoon = Color(0xFF00C2A8);
  static const Color sunsetOrange = Color(0xFFFFB84D);
  static const Color outline = Color(0xFF6E7880);
  static const Color sandWhite = Color(0xFFF8FBFF);

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    RazorpayService.initialize(
      successCallback: _handlePaymentSuccess,
      errorCallback: _handlePaymentError,
      externalWalletCallback: _handleExternalWallet,
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('✅ Payment Success: ${response.paymentId}');

    setState(() {
      _isProcessing = true;
      _paymentId = response.paymentId;
    });

    try {
      final checkInDate = widget.selectedDate ?? DateTime.now();
      final checkOutDate = widget.selectedDate != null 
          ? widget.selectedDate!.add(Duration(days: widget.duration))
          : DateTime.now().add(Duration(days: widget.duration));

      final verifyResponse = await RazorpayService.verifyPaymentWithBooking(
        orderId: response.orderId!,
        paymentId: response.paymentId!,
        signature: response.signature!,
        productId: widget.productId,
        activityId: widget.activityId,
        amount: widget.amount,
        guests: 1,
        checkIn: checkInDate.toIso8601String(),
        checkOut: checkOutDate.toIso8601String(),
      );

      if (verifyResponse['success'] == true) {
        final bookingId = verifyResponse['booking']?['id'] ?? 
                         verifyResponse['booking']?['_id'];
        
        setState(() {
          _createdBookingId = bookingId;
          _isSuccess = true;
          _isProcessing = false;
        });

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => payment_success(
                bookingId: bookingId ?? '',
                productId: widget.productId,
                activityId: widget.activityId,
                itemName: widget.itemName,
                itemType: widget.itemType,
                amount: widget.amount,
                paymentId: response.paymentId!,
              ),
            ),
          );
        }
      } else {
        _showErrorDialog('Payment verification failed. Please contact support.');
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      print('❌ Payment verification error: $e');
      _showErrorDialog('Error verifying payment: $e');
      setState(() => _isProcessing = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('❌ Payment Error: ${response.message}');
    setState(() {
      _isProcessing = false;
      _errorMessage = response.message ?? 'Payment failed';
    });
    _showErrorDialog('Payment failed: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External Wallet: ${response.walletName}');
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _processPayment() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final rawReceipt = 'PAY_$timestamp';
      final receipt = rawReceipt.length > 40
          ? rawReceipt.substring(0, 40)
          : rawReceipt;

      final orderResponse = await RazorpayService.createOrder(
        amount: widget.amount,
        receipt: receipt,
        notes: {
          'product_id': widget.productId ?? '',
          'activity_id': widget.activityId ?? '',
          'item_name': widget.itemName,
          'item_type': widget.itemType,
          'amount': widget.amount.toString(),
        },
      );

      _razorpayOrderId = orderResponse['id'];
      print('✅ Razorpay order created: $_razorpayOrderId');

      final user = await AuthService.getCurrentUser();
      final keyId = await RazorpayService.getRazorpayKey();
      print('✅ Razorpay key obtained');

      await RazorpayService.openCheckout(
        keyId: keyId,
        orderId: _razorpayOrderId!,
        amount: widget.amount,
        receipt: receipt,
        itemName: widget.itemName,
        customerName: user?['fullName'] ?? user?['name'] ?? 'Customer',
        customerEmail: user?['email'] ?? 'customer@example.com',
        customerContact: user?['phone'] ?? '9999999999',
        bookingId: null,
      );
    } catch (e) {
      print('❌ Payment processing error: $e');
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment Failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  void dispose() {
    RazorpayService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: sandWhite,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: deepNavy),
          onPressed: () {
            if (!_isProcessing) {
              Navigator.maybePop(context);
            }
          },
        ),
        title: const Text(
          'Secure Payment',
          style: TextStyle(
            color: deepNavy,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E8FF).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user,
                      color: Color(0xFF006B5C),
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'SSL SECURED',
                      style: TextStyle(
                        color: Color(0xFF006B5C),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBookingSummaryCard(),
            const SizedBox(height: 16),
            _buildTrustBadgeMetrics(),
            const SizedBox(height: 24),
            _buildPayButton(),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              _buildErrorMessage(),
            ],
            const SizedBox(height: 24),
            _buildContextualHelpCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingSummaryCard() {
    final String imageUrl = widget.itemImage.isNotEmpty
        ? widget.itemImage
        : (widget.itemType == 'product'
              ? 'https://images.unsplash.com/photo-1573843981267-be1999ff37cd?w=600'
              : 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=600');

    final String displayBookingId =
        _createdBookingId ?? widget.bookingId ?? 'New Booking';
    final String shortBookingId = displayBookingId.length > 12
        ? '${displayBookingId.substring(0, 12)}...'
        : displayBookingId;

    // Format dates
    final checkInDate = widget.selectedDate ?? DateTime.now();
    final checkOutDate = widget.selectedDate != null 
        ? widget.selectedDate!.add(Duration(days: widget.duration))
        : DateTime.now().add(Duration(days: widget.duration));

    final String checkInFormatted = 
        '${checkInDate.day.toString().padLeft(2, '0')}/'
        '${checkInDate.month.toString().padLeft(2, '0')}/'
        '${checkInDate.year} (2:00 PM)';
    
    final String checkOutFormatted = 
        '${checkOutDate.day.toString().padLeft(2, '0')}/'
        '${checkOutDate.month.toString().padLeft(2, '0')}/'
        '${checkOutDate.year} (11:00 AM)';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: deepNavy.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: outline, size: 20),
              SizedBox(width: 8),
              Text(
                'Booking Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: deepNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Item Image & Name
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                    onError: (_, __) => const Icon(Icons.image, size: 40),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.itemName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: deepNavy,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.itemType == 'product' ? 'Package' : 'Activity',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: outline,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: oceanBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '⭐ ${widget.itemType == 'product' ? 'Package' : 'Activity'}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: oceanBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(color: Color(0xFFF1F3FF), thickness: 1),
          ),
          
          // Details Grid - 2 columns
          _buildDetailRow('Item', widget.itemName),
          const SizedBox(height: 14),
          _buildDetailRow('Type', widget.itemType == 'product' ? 'Package' : 'Activity'),
          const SizedBox(height: 14),
          _buildDetailRow('Check-in', checkInFormatted),
          const SizedBox(height: 14),
          _buildDetailRow('Check-out', checkOutFormatted),
          const SizedBox(height: 14),
          _buildDetailRow('Duration', '${widget.duration} ${widget.duration == 1 ? 'Day' : 'Days'}'),
          const SizedBox(height: 14),
          _buildDetailRow('Booking ID', shortBookingId),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(color: Color(0xFFE8EDFF), thickness: 1.5, height: 1),
          ),
          
          // Total Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL AMOUNT',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: outline.withOpacity(0.8),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '₹${widget.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: deepNavy,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF006B5C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Secure',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006B5C),
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Enhanced detail row with better alignment
  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: outline,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: deepNavy,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildTrustBadgeMetrics() {
    return Row(
      children: [
        _buildSingleBadge(Icons.verified_outlined, 'PCI-DSS Compliant'),
        const SizedBox(width: 12),
        _buildSingleBadge(
          Icons.enhanced_encryption_outlined,
          '256-bit AES Protection',
        ),
        const SizedBox(width: 12),
        _buildSingleBadge(Icons.security_outlined, 'Secure Payment'),
      ],
    );
  }

  Widget _buildSingleBadge(IconData icon, String message) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: oceanBlue, size: 18),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: deepNavy,
                  fontFamily: 'Inter',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage ?? 'Payment failed',
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: _isSuccess
              ? null
              : const LinearGradient(colors: [oceanBlue, turquoiseLagoon]),
          color: _isSuccess ? const Color(0xFF006B5C) : null,
          boxShadow: [
            BoxShadow(
              color: (_isSuccess ? const Color(0xFF006B5C) : oceanBlue)
                  .withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: (_isProcessing || _isSuccess) ? null : _processPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isProcessing
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Processing...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : _isSuccess
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Payment Successful!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Pay ₹${widget.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildContextualHelpCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border(left: BorderSide(color: sunsetOrange, width: 4)),
        boxShadow: [
          BoxShadow(
            color: deepNavy.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: sunsetOrange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.headphones_outlined,
              color: sunsetOrange,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need help?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: deepNavy,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Our support team is available 24/7.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}