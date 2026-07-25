// routes/authRoutes.js
const express = require('express');
const router = express.Router();

const { 
  register, 
  login, 
  forgotPassword, 
  resetPassword,
  changePassword 
} = require('../controllers/authController');

const { 
  sendOTP, 
  verifyOTP, 
  resendOTP 
} = require('../controllers/otpController');

const { googleLogin, googleEmailAuth, googleSimpleAuth } = require('../controllers/googleAuthController');
const { protect } = require('../middleware/authMiddleware');

// Test Route
router.get('/test', (req, res) => {
  res.json({ success: true, message: 'Auth API is working!' });
});

// Auth Routes
router.post('/register', register);
router.post('/login', login);

// OTP Routes
router.post('/send-otp', sendOTP);
router.post('/verify-otp', verifyOTP);
router.post('/resend-otp', resendOTP);

// Password Management
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);
router.post('/change-password', protect, changePassword);

// Google Login
router.post('/google', googleLogin);
router.post('/google/email-auth', googleEmailAuth);
router.post('/google/simple', googleSimpleAuth);

module.exports = router;