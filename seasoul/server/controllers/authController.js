// controllers/authController.js - Firebase Phone Authentication
const User = require('../models/User');
const OTP = require('../models/OTP');
const jwt = require('jsonwebtoken');
const firebasePhoneService = require('../services/firebasePhoneService');
const { 
  sendPasswordResetOTPEmail, 
  sendPasswordChangedEmail,
  sendWelcomeEmail
} = require('../services/emailService');
require('dotenv').config();

const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: '30d' });
};

// ==================== Helper Functions ====================
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

const generateOTP = () => {
  // ✅ 4-digit OTP
  const otp = Math.floor(1000 + Math.random() * 9000).toString();
  console.log('Generated OTP:', otp);
  return otp;
};

// ==================== REGISTER ====================
exports.register = async (req, res) => {
  try {
    const { fullName, email, phone, password } = req.body;

    console.log('========================================');
    console.log('📝 Registering User');
    console.log(`👤 Name: ${fullName}`);
    console.log(`📧 Email: ${email}`);
    console.log(`📱 Phone: ${phone}`);
    console.log('========================================');

    if (!fullName || !email || !phone || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please fill all fields'
      });
    }

    // Validate email
    const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        success: false,
        message: 'Please enter a valid email address'
      });
    }

    // Validate phone
    const phoneRegex = /^[0-9]{10}$/;
    const cleanPhone = formatPhoneNumber(phone);
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
    const userExists = await User.findOne({ email });
    if (userExists) {
      console.log('❌ Email already registered:', email);
      return res.status(400).json({
        success: false,
        message: 'This email is already registered. Please login or use another email.'
      });
    }

    const phoneExists = await User.findOne({ phone: cleanPhone });
    if (phoneExists) {
      console.log('❌ Phone already registered:', phone);
      return res.status(400).json({
        success: false,
        message: 'This phone number is already registered. Please login or use another number.'
      });
    }

    // ✅ Check OTP verification
    const otpRecord = await OTP.findOne({ 
      phone: cleanPhone,
      verified: true 
    });
    
    if (!otpRecord) {
      console.log('❌ OTP not verified');
      return res.status(400).json({
        success: false,
        message: 'OTP not verified. Please verify OTP first.'
      });
    }

    // Create user
    const user = new User({
      fullName,
      email,
      phone: cleanPhone || null,
      password,
    });

    await user.save();
    await OTP.deleteMany({ phone: cleanPhone });

    console.log('✅ User Registered Successfully!');
    console.log(`🆔 User ID: ${user._id}`);

    // ✅ Send welcome email
    try {
      await sendWelcomeEmail(user);
      console.log('✅ Welcome email sent to:', user.email);
    } catch (emailError) {
      console.log('⚠️ Welcome email failed:', emailError.message);
    }

    const token = generateToken(user._id);

    res.status(201).json({
      success: true,
      _id: user._id,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      profileImage: user.profileImage,
      bio: user.bio,
      location: user.location,
      token: token,
    });

  } catch (error) {
    console.error('❌ Error in register:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// ==================== LOGIN ====================
exports.login = async (req, res) => {
  try {
    const { identifier, password } = req.body;

    console.log('========================================');
    console.log('🔐 Login Request');
    console.log(`📧 Identifier: ${identifier}`);
    console.log('========================================');

    if (!identifier || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide identifier and password'
      });
    }

    // Check if identifier is email or phone
    const isEmail = identifier.includes('@');
    let query = {};

    if (isEmail) {
      query = { email: identifier.toLowerCase() };
    } else {
      const cleanPhone = formatPhoneNumber(identifier);
      query = { phone: cleanPhone };
    }

    const user = await User.findOne(query);

    if (!user) {
      console.log('❌ User not found');
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    const isPasswordMatch = await user.comparePassword(password);
    if (!isPasswordMatch) {
      console.log('❌ Password mismatch');
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    const token = generateToken(user._id);

    console.log('✅ Login successful!');
    console.log(`👤 User: ${user.fullName} (${user.email})`);

    res.status(200).json({
      success: true,
      _id: user._id,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      profileImage: user.profileImage,
      bio: user.bio,
      location: user.location,
      token: token,
    });

  } catch (error) {
    console.error('❌ Error in login:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// ==================== FORGOT PASSWORD ====================
exports.forgotPassword = async (req, res) => {
  try {
    const { phone } = req.body;

    console.log('========================================');
    console.log('🔑 Forgot Password Request (Firebase)');
    console.log(`📱 Phone: ${phone}`);
    console.log('========================================');

    if (!phone) {
      return res.status(400).json({
        success: false,
        message: 'Phone number is required'
      });
    }

    // Validate phone
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

    // Find user by phone
    const user = await User.findOne({ phone: cleanPhone });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'No user found with this phone number'
      });
    }

    // ✅ Firebase handles OTP on client side
    // Store a temporary marker for password reset
    const resetToken = generateOTP();
    const otpExpiry = Date.now() + 10 * 60 * 1000;

    user.resetPasswordOTP = resetToken;
    user.resetPasswordExpires = otpExpiry;
    await user.save();

    console.log('✅ Password reset ready for Firebase verification');

    // ✅ Send notification email (NOT OTP)
    try {
      await sendPasswordResetOTPEmail(user.email, resetToken);
      console.log('✅ Password reset notification email sent to:', user.email);
    } catch (emailError) {
      console.log('⚠️ Email send failed:', emailError.message);
    }

    res.status(200).json({
      success: true,
      message: 'Ready for Firebase phone verification',
      method: 'firebase'
    });

  } catch (error) {
    console.error('❌ Error in forgotPassword:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// ==================== RESET PASSWORD ====================
exports.resetPassword = async (req, res) => {
  try {
    const { phone, firebaseToken, newPassword } = req.body;

    console.log('========================================');
    console.log('🔑 Reset Password Request (Firebase)');
    console.log(`📱 Phone: ${phone}`);
    console.log('========================================');

    if (!phone || !firebaseToken || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Phone, Firebase token and new password are required'
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 6 characters'
      });
    }

    const cleanPhone = formatPhoneNumber(phone);

    // ✅ Verify Firebase Token
    console.log(`🔍 Verifying Firebase token for: ${cleanPhone}`);
    const verifyResult = await firebasePhoneService.verifyPhoneToken(firebaseToken);

    if (!verifyResult.success) {
      console.log('❌ Firebase verification failed');
      return res.status(400).json({
        success: false,
        message: 'Invalid phone verification'
      });
    }

    // Verify phone number matches
    const firebasePhone = verifyResult.phoneNumber;
    const phoneMatch = firebasePhone.includes(cleanPhone.substring(cleanPhone.length - 10));
    
    if (!phoneMatch) {
      console.log('❌ Phone number mismatch');
      return res.status(400).json({
        success: false,
        message: 'Phone number verification mismatch'
      });
    }

    // Find user by phone
    const user = await User.findOne({ phone: cleanPhone });
    if (!user) {
      return res.status(400).json({
        success: false,
        message: 'User not found'
      });
    }

    // ✅ Reset password
    user.password = newPassword;
    user.resetPasswordOTP = null;
    user.resetPasswordExpires = null;
    await user.save();

    console.log('✅ Password reset successfully for:', user.email);

    // ✅ Send confirmation email
    try {
      await sendPasswordChangedEmail(user.email);
      console.log('✅ Password change confirmation email sent to:', user.email);
    } catch (emailError) {
      console.log('⚠️ Email send failed:', emailError.message);
    }

    res.status(200).json({
      success: true,
      message: 'Password reset successfully'
    });

  } catch (error) {
    console.error('❌ Error in resetPassword:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};

// ==================== CHANGE PASSWORD ====================
exports.changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    const userId = req.user.id;

    console.log('========================================');
    console.log('🔑 Change Password Request');
    console.log(`👤 User ID: ${userId}`);
    console.log('========================================');

    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Current password and new password are required'
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'New password must be at least 6 characters'
      });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const isPasswordMatch = await user.comparePassword(currentPassword);
    if (!isPasswordMatch) {
      return res.status(401).json({
        success: false,
        message: 'Current password is incorrect'
      });
    }

    user.password = newPassword;
    await user.save();

    console.log('✅ Password changed successfully for:', user.email);

    // ✅ Send confirmation email (NOT OTP)
    try {
      await sendPasswordChangedEmail(user.email);
      console.log('✅ Password change confirmation email sent to:', user.email);
    } catch (emailError) {
      console.log('⚠️ Email send failed:', emailError.message);
    }

    res.status(200).json({
      success: true,
      message: 'Password changed successfully'
    });

  } catch (error) {
    console.error('❌ Error in changePassword:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message
    });
  }
};