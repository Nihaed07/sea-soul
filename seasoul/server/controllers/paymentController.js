// controllers/paymentController.js

const Razorpay = require('razorpay');
const crypto = require('crypto');

// Initialize Razorpay with error handling
let razorpay;
try {
  razorpay = new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID,
    key_secret: process.env.RAZORPAY_KEY_SECRET,
  });
  console.log('✅ Razorpay initialized successfully');
} catch (error) {
  console.error('❌ Failed to initialize Razorpay:', error.message);
  razorpay = null;
}

// ✅ 1. Test Razorpay configuration
exports.testRazorpayConfig = async (req, res) => {
  try {
    const keyId = process.env.RAZORPAY_KEY_ID || '';
    const keySecret = process.env.RAZORPAY_KEY_SECRET || '';
    const isTestKey = keyId.startsWith('rzp_test_');
    const isLiveKey = keyId.startsWith('rzp_live_');

    res.status(200).json({
      success: true,
      configured: Boolean(keyId && keySecret),
      mode: isTestKey ? 'test' : isLiveKey ? 'live' : 'unknown',
      keyIdPresent: Boolean(keyId),
      keySecretPresent: Boolean(keySecret),
      keyIdPreview: keyId ? `${keyId.slice(0, 8)}...` : null,
      razorpayInitialized: razorpay !== null,
      message: keyId && keySecret
        ? 'Razorpay credentials are configured.'
        : 'Razorpay credentials are missing.',
    });
  } catch (error) {
    console.error('❌ Error testing Razorpay config:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message,
    });
  }
};

// ✅ 2. Get Razorpay Key
exports.getRazorpayKey = async (req, res) => {
  try {
    const requester = req.user && req.user.id ? req.user.id : 'anonymous';
    console.log('🔑 Getting Razorpay key for user:', requester);

    const keyId = process.env.RAZORPAY_KEY_ID;

    if (!keyId) {
      console.error('❌ RAZORPAY_KEY_ID not set in environment');
      return res.status(500).json({
        success: false,
        message: 'Razorpay key not configured',
        error: 'RAZORPAY_KEY_ID is missing in environment variables',
      });
    }

    console.log('✅ Razorpay key retrieved:', keyId ? `${keyId.slice(0,8)}...` : null);

    res.status(200).json({
      success: true,
      key_id: keyId,
    });
  } catch (error) {
    console.error('❌ Error getting Razorpay key:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message,
    });
  }
};

// ✅ 3. Create Razorpay Order (FIXED)
exports.createRazorpayOrder = async (req, res) => {
  try {
    const { amount, currency = 'INR', receipt, notes } = req.body;
    const userId = req.user && req.user.id ? req.user.id : null;

    console.log('📦 Creating Razorpay order for user:', userId || 'anonymous');
    console.log('📦 Amount:', amount);
    console.log('📦 Receipt:', receipt);

    // Validate amount
    if (!amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid amount',
        error: 'Amount must be greater than 0',
      });
    }

    // Check if Razorpay is initialized
    if (!razorpay) {
      console.error('❌ Razorpay not initialized');
      return res.status(500).json({
        success: false,
        message: 'Payment gateway not available',
        error: 'Razorpay is not initialized. Check your credentials.',
        details: {
          hasKeyId: Boolean(process.env.RAZORPAY_KEY_ID),
          hasKeySecret: Boolean(process.env.RAZORPAY_KEY_SECRET),
        }
      });
    }

    // Check if Razorpay credentials are configured
    if (!process.env.RAZORPAY_KEY_ID || !process.env.RAZORPAY_KEY_SECRET) {
      console.error('❌ Razorpay credentials missing');
      return res.status(500).json({
        success: false,
        message: 'Payment gateway is not configured',
        error: 'RAZORPAY_KEY_ID or RAZORPAY_KEY_SECRET is missing in environment variables',
        details: {
          hasKeyId: Boolean(process.env.RAZORPAY_KEY_ID),
          hasKeySecret: Boolean(process.env.RAZORPAY_KEY_SECRET),
        }
      });
    }

    // Razorpay receipt max length is 40 chars — truncate safely
    const safeReceipt = (receipt || `rcpt_${Date.now()}`).substring(0, 40);

    const options = {
      amount: Math.round(amount * 100), // convert rupees to paise
      currency: currency || 'INR',
      receipt: safeReceipt,
      notes: notes || {},
      payment_capture: 1,
    };

    console.log('📤 Sending order request to Razorpay:', {
      amount: options.amount,
      currency: options.currency,
      receipt: options.receipt,
    });

    const order = await razorpay.orders.create(options);
    console.log('✅ Razorpay order created:', order.id);

    res.status(200).json({
      success: true,
      id: order.id,
      entity: order.entity,
      amount: order.amount,
      amount_paid: order.amount_paid,
      amount_due: order.amount_due,
      currency: order.currency,
      receipt: order.receipt,
      status: order.status,
      attempts: order.attempts,
      notes: order.notes,
      created_at: order.created_at,
    });
    
  } catch (error) {
    console.error('❌ Razorpay order creation error:', error);
    
    // Enhanced error handling with proper structure
    let statusCode = 500;
    let errorMessage = 'Failed to create Razorpay order';
    let errorDetails = null;

    // Check if it's a Razorpay error
    if (error && error.error) {
      // Razorpay error structure
      const razorpayError = error.error;
      statusCode = error.statusCode || 500;
      errorMessage = razorpayError.description || razorpayError.message || errorMessage;
      errorDetails = {
        code: razorpayError.code,
        field: razorpayError.field,
        source: razorpayError.source,
        step: razorpayError.step,
        reason: razorpayError.reason,
        metadata: razorpayError.metadata,
      };
    } else if (error && error.message) {
      // Generic error
      errorMessage = error.message;
      
      // Check for common Razorpay initialization errors
      if (error.message.includes('key_id') || error.message.includes('key_secret')) {
        errorMessage = 'Razorpay credentials are invalid or missing';
        errorDetails = {
          suggestion: 'Check your RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET in .env file',
          hasKeyId: Boolean(process.env.RAZORPAY_KEY_ID),
          hasKeySecret: Boolean(process.env.RAZORPAY_KEY_SECRET),
        };
      } else if (error.message.includes('timeout') || error.message.includes('ETIMEDOUT')) {
        errorMessage = 'Razorpay API request timed out';
        errorDetails = {
          suggestion: 'Check your internet connection and try again',
        };
      } else if (error.message.includes('ECONNREFUSED')) {
        errorMessage = 'Could not connect to Razorpay servers';
        errorDetails = {
          suggestion: 'Check your network connection and firewall settings',
        };
      } else if (error.message.includes('Invalid amount')) {
        errorMessage = 'Invalid amount specified';
        errorDetails = {
          suggestion: 'Amount must be a positive number',
          providedAmount: req.body.amount,
        };
      }
    }

    res.status(statusCode).json({
      success: false,
      message: errorMessage,
      error: error.message || 'Unknown error',
      details: errorDetails,
    });
  }
};

// ✅ 4. Verify Razorpay Payment and Create Booking (FIXED)
exports.verifyRazorpayPayment = async (req, res) => {
  try {
    const {
      razorpay_order_id,
      razorpay_payment_id,
      razorpay_signature,
      productId,
      activityId,
      amount,
      guests = 1,
      checkIn,
      checkOut,
    } = req.body;
    const userId = req.user && req.user.id ? req.user.id : null;

    console.log('🔐 Verifying Razorpay payment for user:', userId || 'anonymous');
    console.log('🔐 Order ID:', razorpay_order_id);
    console.log('🔐 Payment ID:', razorpay_payment_id);

    // Validate required fields
    if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
      return res.status(400).json({
        success: false,
        message: 'Missing required payment fields',
        error: 'razorpay_order_id, razorpay_payment_id, and razorpay_signature are required',
      });
    }

    // Check if Razorpay key secret is available
    if (!process.env.RAZORPAY_KEY_SECRET) {
      console.error('❌ RAZORPAY_KEY_SECRET not set');
      return res.status(500).json({
        success: false,
        message: 'Payment verification failed',
        error: 'Razorpay key secret is missing',
      });
    }

    // Verify signature
    const body = razorpay_order_id + '|' + razorpay_payment_id;
    const expectedSignature = crypto
      .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
      .update(body)
      .digest('hex');

    if (expectedSignature !== razorpay_signature) {
      console.error('❌ Invalid signature');
      console.error('Expected:', expectedSignature);
      console.error('Received:', razorpay_signature);
      return res.status(400).json({
        success: false,
        message: 'Invalid signature',
        error: 'Payment verification failed - signature mismatch',
      });
    }

    console.log('✅ Signature verified successfully');

    // ✅ Create booking ONLY after successful payment verification
    let booking = null;
    let itemName = 'Package';
    let itemImage = null;
    let itemLocation = '';

    if (!productId && !activityId) {
      return res.status(400).json({
        success: false,
        message: 'Product ID or Activity ID is required',
        error: 'Cannot create booking without item reference',
      });
    }

    try {
      const Booking = require('../models/Booking');
      const Product = require('../models/Product');
      const Activity = require('../models/Activity');

      // Get item details
      let item = null;
      if (productId) {
        item = await Product.findById(productId);
        if (item) {
          itemName = item.name || 'Package';
          itemLocation = item.location || '';
          itemImage = item.images && item.images.length > 0 ? item.images[0] : null;
        }
      } else if (activityId) {
        item = await Activity.findById(activityId);
        if (item) {
          itemName = item.name || 'Activity';
          itemLocation = item.location || '';
          itemImage = item.images && item.images.length > 0 ? item.images[0] : null;
        }
      }

      // Create booking with confirmed status
      booking = new Booking({
        userId,
        productId: productId || null,
        activityId: activityId || null,
        guests: guests || 1,
        checkIn: checkIn ? new Date(checkIn) : new Date(),
        checkOut: checkOut ? new Date(checkOut) : new Date(Date.now() + 86400000 * 3), // 3 days from now
        totalAmount: amount || 0,
        status: 'confirmed', // ✅ Confirmed from the start
        paymentStatus: 'paid', // ✅ Paid from the start
        itemType: productId ? 'product' : 'activity',
      });

      await booking.save();
      console.log('✅ Booking created after payment:', booking._id);

    } catch (bookingError) {
      console.error('❌ Error creating booking:', bookingError);
      // Payment is valid but booking failed - still return success for payment
      // but notify about booking issue
      return res.status(500).json({
        success: false,
        message: 'Payment successful but booking creation failed',
        error: bookingError.message,
        payment: {
          transactionId: razorpay_payment_id,
          amount: amount,
          status: 'completed',
        },
      });
    }

    // Save payment record
    const Payment = require('../models/Payment');
    const payment = new Payment({
      userId,
      bookingId: booking._id,
      amount: amount || 0,
      currency: 'INR',
      method: 'razorpay',
      status: 'completed',
      transactionId: razorpay_payment_id,
      razorpayDetails: {
        orderId: razorpay_order_id,
        paymentId: razorpay_payment_id,
        signature: razorpay_signature,
      },
      paymentDate: new Date(),
    });

    await payment.save();
    console.log('✅ Payment saved:', payment._id);

    // Update booking with payment ID
    booking.paymentId = payment._id;
    await booking.save();

    // Create payment notification
    try {
      const { createNotification } = require('../utils/createNotification');
      await createNotification(
        userId,
        '💰 Payment Successful',
        `Your payment of ₹${amount || 0} for ${itemName} was successful!`,
        'payment',
        payment._id,
        itemImage,
        {
          paymentId: payment._id,
          bookingId: booking._id,
          amount: amount || 0,
          method: 'razorpay',
          itemName,
          razorpayPaymentId: razorpay_payment_id,
          razorpayOrderId: razorpay_order_id,
        }
      );
      console.log('✅ Payment notification created');
    } catch (notifError) {
      console.error('⚠️ Notification error (non-fatal):', notifError);
    }

    // Send booking confirmation email
    try {
      const User = require('../models/User');
      const { sendBookingConfirmationEmail } = require('../services/emailService');
      const user = await User.findById(userId);
      if (user) {
        await sendBookingConfirmationEmail(user, booking, { 
          name: itemName, 
          location: itemLocation 
        });
        console.log('✅ Booking confirmation email sent');
      }
    } catch (emailError) {
      console.error('⚠️ Email error (non-fatal):', emailError);
    }

    res.status(200).json({
      success: true,
      message: 'Payment verified and booking created successfully',
      payment: {
        id: payment._id,
        transactionId: payment.transactionId,
        amount: payment.amount,
        status: payment.status,
        razorpayPaymentId: razorpay_payment_id,
        razorpayOrderId: razorpay_order_id,
      },
      booking: {
        id: booking._id,
        status: booking.status,
        paymentStatus: booking.paymentStatus,
        bookingReference: booking.bookingReference,
      },
    });
    
  } catch (error) {
    console.error('❌ Payment verification error:', error);
    res.status(500).json({
      success: false,
      message: 'Payment verification failed',
      error: error.message,
      details: error.stack,
    });
  }
};

// ✅ 5. Check environment variables (Utility)
exports.checkEnvironment = async (req, res) => {
  try {
    const envVars = {
      razorpayKeyId: process.env.RAZORPAY_KEY_ID ? '✓ Set' : '✗ Missing',
      razorpayKeySecret: process.env.RAZORPAY_KEY_SECRET ? '✓ Set' : '✗ Missing',
      nodeEnv: process.env.NODE_ENV || 'not set',
      port: process.env.PORT || 'not set',
      mongoUri: process.env.MONGODB_URI ? '✓ Set' : '✗ Missing',
    };

    res.status(200).json({
      success: true,
      environment: envVars,
      razorpayInitialized: razorpay !== null,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to check environment',
      error: error.message,
    });
  }
};