// controllers/otpController.js - Firebase Phone Authentication
const OTP = require('../models/OTP');
const User = require('../models/User');
const firebasePhoneService = require('../services/firebasePhoneService');
require('dotenv').config();

const formatPhoneNumber = (phone) => {
  if (!phone) return '';
  let cleanPhone = phone.replace(/\s/g, '');
  
  if (cleanPhone.startsWith('+')) {
    cleanPhone = cleanPhone.substring(1);
  }
  if (cleanPhone.length === 10) {
    cleanPhone = '91' + cleanPhone;
  } else if (cleanPhone.length === 11 && cleanPhone.startsWith('0')) {
    cleanPhone = '91' + cleanPhone.substring(1);
  }
  
  return cleanPhone;
};

exports.sendOTP = async (req, res) => {
  try {
    const { phone } = req.body;

    console.log('========================================');
    console.log('📧 Send OTP Request (Firebase)');
    console.log(`📱 Phone: ${phone}`);
    console.log('========================================');

    if (!phone) {
      return res.status(400).json({
        success: false,
        message: 'Phone number is required'
      });
    }

    const cleanPhone = formatPhoneNumber(phone);
    const phoneRegex = /^[0-9]{10}$/;
    
    let phoneDigits = cleanPhone;
    if (phoneDigits.startsWith('91')) {
      phoneDigits = phoneDigits.substring(2);
    }
    
    if (!phoneRegex.test(phoneDigits)) {
      return res.status(400).json({
        success: false,
        message: 'Please enter a valid 10-digit phone number'
      });
    }

    // Check if user exists
    const existingUser = await User.findOne({ phone: cleanPhone });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'This phone number is already registered. Please login or use another.'
      });
    }

    // ✅ Firebase handles OTP sending on client side
    // Backend just acknowledges the request
    console.log(`✅ Phone number validated: ${cleanPhone}`);
    console.log('📱 Client will handle Firebase Phone Authentication');

    res.status(200).json({
      success: true,
      message: 'Ready for Firebase Phone Authentication',
      phone: cleanPhone,
      method: 'firebase'
    });

  } catch (error) {
    console.error('❌ Error in sendOTP:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

exports.verifyOTP = async (req, res) => {
  try {
    const { phone, firebaseToken } = req.body;

    console.log('========================================');
    console.log('🔍 Verifying Firebase Phone Token');
    console.log(`📱 Phone: ${phone}`);
    console.log('========================================');

    if (!firebaseToken) {
      return res.status(400).json({
        success: false,
        message: 'Firebase token is required'
      });
    }

    const cleanPhone = formatPhoneNumber(phone);

    // ✅ Verify Firebase ID Token
    console.log('🔍 Verifying with Firebase...');
    const verifyResult = await firebasePhoneService.verifyPhoneToken(firebaseToken);

    if (!verifyResult.success) {
      console.log('❌ Firebase verification failed');
      return res.status(400).json({
        success: false,
        message: 'Invalid phone verification. Please try again.'
      });
    }

    // Extract phone number from Firebase token
    const firebasePhone = verifyResult.phoneNumber;
    console.log(`✅ Firebase verified phone: ${firebasePhone}`);

    // Check if phone matches
    const phoneMatch = firebasePhone.includes(cleanPhone.substring(cleanPhone.length - 10));
    if (!phoneMatch) {
      console.log('❌ Phone number mismatch');
      return res.status(400).json({
        success: false,
        message: 'Phone number verification mismatch'
      });
    }

    // ✅ Store verification record
    await OTP.deleteMany({ phone: cleanPhone });
    await OTP.create({
      phone: cleanPhone,
      otp: 'firebase-verified',
      expiresAt: new Date(Date.now() + 10 * 60 * 1000),
      verified: true,
      isDemo: false,
      firebaseUid: verifyResult.uid
    });

    console.log('✅ Phone Verified Successfully with Firebase!');

    res.status(200).json({
      success: true,
      message: 'Phone verified successfully',
      verified: true,
      firebaseUid: verifyResult.uid
    });

  } catch (error) {
    console.error('❌ Error in verifyOTP:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

exports.resendOTP = async (req, res) => {
  try {
    const { phone } = req.body;

    if (!phone) {
      return res.status(400).json({
        success: false,
        message: 'Phone number is required'
      });
    }

    const cleanPhone = formatPhoneNumber(phone);

    console.log(`📱 Resend OTP request for: ${cleanPhone}`);
    console.log('✅ Client will handle Firebase Phone Authentication resend');

    // ✅ Firebase handles resend on client side
    res.status(200).json({
      success: true,
      message: 'Ready to resend OTP via Firebase',
      phone: cleanPhone,
      method: 'firebase'
    });

  } catch (error) {
    console.error('❌ Error in resendOTP:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};