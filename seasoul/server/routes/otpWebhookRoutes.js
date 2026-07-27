// ⚠️ DEPRECATED - This file is no longer used
// Migration to Firebase Phone Authentication completed
// MSG91 webhooks are no longer needed with Firebase
// See FIREBASE_SETUP.md for details

// routes/otpWebhookRoutes.js - DEPRECATED - DO NOT USE
const express = require('express');
const router = express.Router();
const User = require('../models/User');
const OTP = require('../models/OTP');

// ⚠️ DEPRECATED Webhook - No longer used with Firebase
// ✅ MSG91 Webhook endpoint (DEPRECATED)
// This received events from MSG91 when OTP is sent, verified, etc.
router.post('/otp-webhook', async (req, res) => {
  try {
    console.log('📥 MSG91 Webhook Received:');
    console.log('📥 Headers:', req.headers);
    console.log('📥 Body:', req.body);

    const { event, data } = req.body;

    // Handle different event types
    switch (event) {
      case 'otp_sent':
        console.log(`✅ OTP sent event for: ${data.identifier}`);
        // Log OTP sent event
        break;

      case 'otp_verified':
        console.log(`✅ OTP verified event for: ${data.identifier}`);
        // Update user verification status if needed
        break;

      case 'otp_failed':
        console.log(`❌ OTP failed for: ${data.identifier}`);
        console.log(`❌ Reason: ${data.reason}`);
        break;

      case 'otp_expired':
        console.log(`⏰ OTP expired for: ${data.identifier}`);
        break;

      default:
        console.log(`📌 Unknown event: ${event}`);
    }

    // ✅ Always respond with 200 to acknowledge receipt
    res.status(200).json({
      success: true,
      message: 'Webhook received successfully'
    });

  } catch (error) {
    console.error('❌ Webhook error:', error);
    // Even on error, send 200 to prevent MSG91 from retrying
    res.status(200).json({
      success: false,
      message: 'Webhook processed with errors'
    });
  }
});

// ✅ Verify token from MSG91 (for server-side verification)
router.post('/otp-verify-token', async (req, res) => {
  try {
    const { token, identifier } = req.body;

    console.log('🔍 Verifying OTP token:', token);
    console.log('📱 Identifier:', identifier);

    // This is where you'd verify the token with MSG91
    // Or verify from your database

    res.status(200).json({
      success: true,
      verified: true,
      user: {
        id: 'user_id',
        phone: identifier
      }
    });

  } catch (error) {
    console.error('❌ Token verification error:', error);
    res.status(400).json({
      success: false,
      message: 'Invalid token'
    });
  }
});

module.exports = router;