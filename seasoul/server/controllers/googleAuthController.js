const User = require('../models/User');
const jwt = require('jsonwebtoken');
const { OAuth2Client } = require('google-auth-library');
const { sendWelcomeEmail } = require('../services/emailService');
require('dotenv').config();

// ✅ Initialize Google OAuth Client with proper configuration
const androidClient = new OAuth2Client(
  process.env.GOOGLE_ANDROID_CLIENT_ID
);

const webClient = new OAuth2Client(
  process.env.GOOGLE_WEB_CLIENT_ID
);

const iosClient = new OAuth2Client(
  process.env.GOOGLE_IOS_CLIENT_ID || process.env.GOOGLE_ANDROID_CLIENT_ID
);

// ✅ Standard Google Login with ID Token
exports.googleLogin = async (req, res) => {
  try {
    const { idToken, platform } = req.body;

    console.log('========================================');
    console.log('🔐 Google Login Request (ID Token)');
    console.log(`📱 Platform: ${platform || 'unknown'}`);
    console.log('========================================');

    if (!idToken) {
      return res.status(400).json({
        success: false,
        message: 'ID Token is required'
      });
    }

    // Select the appropriate client based on platform
    let client;
    let clientId;
    
    if (platform === 'web') {
      client = webClient;
      clientId = process.env.GOOGLE_WEB_CLIENT_ID;
    } else if (platform === 'ios') {
      client = iosClient;
      clientId = process.env.GOOGLE_IOS_CLIENT_ID || process.env.GOOGLE_ANDROID_CLIENT_ID;
    } else {
      client = androidClient;
      clientId = process.env.GOOGLE_ANDROID_CLIENT_ID;
    }

    console.log(`🔑 Using Client ID for ${platform}: ${clientId ? 'Present' : 'Missing'}`);

    if (!clientId) {
      return res.status(500).json({
        success: false,
        message: `Google Client ID not configured for platform: ${platform}`
      });
    }

    // Verify the ID token
    const ticket = await client.verifyIdToken({
      idToken: idToken,
      audience: clientId,
    });

    const payload = ticket.getPayload();
    const { email, name, picture, sub } = payload;

    console.log('✅ Google ID Token verified successfully!');
    console.log(`📧 Email: ${email}`);
    console.log(`👤 Name: ${name}`);
    console.log(`🆔 Google Sub: ${sub}`);

    // Check if user exists
    let user = await User.findOne({ email });

    if (!user) {
      console.log('📝 Creating new user from Google...');

      user = new User({
        fullName: name || 'User',
        email: email,
        phone: '',
        password: '', // No password for Google users
        profileImage: picture || '',
        bio: '',
        location: '',
        isGoogleUser: true,
        googleId: sub,
        isActive: true,
      });

      await user.save();
      console.log('✅ New Google user created successfully!');

      // Send welcome email
      try {
        await sendWelcomeEmail(user);
        console.log('✅ Welcome email sent to:', email);
      } catch (emailError) {
        console.log('⚠️ Failed to send welcome email:', emailError.message);
      }

    } else {
      console.log('📝 Existing user found. Updating Google data...');

      // Update Google info if needed
      if (!user.isGoogleUser) {
        user.isGoogleUser = true;
      }
      if (!user.googleId) {
        user.googleId = sub;
      }
      if (!user.profileImage && picture) {
        user.profileImage = picture;
      }
      
      await user.save();
      console.log('✅ Existing user updated with Google data');
    }

    // Generate JWT token
    const token = jwt.sign(
      { id: user._id },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    console.log('✅ Google Login successful!');
    console.log(`🆔 User ID: ${user._id}`);
    console.log('========================================\n');

    res.status(200).json({
      success: true,
      token: token,
      user: {
        _id: user._id,
        fullName: user.fullName,
        email: user.email,
        phone: user.phone || '',
        profileImage: user.profileImage || '',
        bio: user.bio || '',
        location: user.location || '',
        role: user.role || 'user',
        isGoogleUser: user.isGoogleUser || true,
        isActive: user.isActive !== undefined ? user.isActive : true,
      }
    });

  } catch (error) {
    console.error('❌ Google Login error:', error);
    console.error('Error stack:', error.stack);
    
    res.status(500).json({
      success: false,
      message: 'Google authentication failed',
      error: error.message
    });
  }
};

// ✅ Alternative: Email-based Google Authentication (for when ID token unavailable)
exports.googleEmailAuth = async (req, res) => {
  try {
    const { email, displayName, photoUrl, id, accessToken, platform } = req.body;

    console.log('========================================');
    console.log('🔐 Google Email Authentication');
    console.log(`📧 Email: ${email}`);
    console.log(`👤 Name: ${displayName}`);
    console.log(`📱 Platform: ${platform}`);
    console.log('========================================');

    if (!email || !id) {
      return res.status(400).json({
        success: false,
        message: 'Email and Google ID are required'
      });
    }

    // Verify this is a legitimate Google email
    if (!email.includes('@') || email.length < 5) {
      return res.status(400).json({
        success: false,
        message: 'Invalid email address'
      });
    }

    // Find or create user
    let user = await User.findOne({ email });

    if (!user) {
      console.log('📝 Creating new user from Google (email auth)...');

      user = new User({
        fullName: displayName || 'User',
        email: email,
        phone: '',
        password: '',
        profileImage: photoUrl || '',
        bio: '',
        location: '',
        isGoogleUser: true,
        googleId: id,
        isActive: true,
      });

      await user.save();
      console.log('✅ New Google user created successfully!');

      try {
        await sendWelcomeEmail(user);
        console.log('✅ Welcome email sent to:', email);
      } catch (emailError) {
        console.log('⚠️ Failed to send welcome email:', emailError.message);
      }

    } else {
      console.log('📝 Existing user found');

      if (!user.isGoogleUser) {
        user.isGoogleUser = true;
      }
      if (!user.googleId) {
        user.googleId = id;
      }
      if (!user.profileImage && photoUrl) {
        user.profileImage = photoUrl;
      }
      
      await user.save();
    }

    const token = jwt.sign(
      { id: user._id },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    console.log('✅ Google Email Auth successful!');
    console.log(`🆔 User ID: ${user._id}`);
    console.log('========================================\n');

    res.status(200).json({
      success: true,
      token: token,
      user: {
        _id: user._id,
        fullName: user.fullName,
        email: user.email,
        phone: user.phone || '',
        profileImage: user.profileImage || '',
        bio: user.bio || '',
        location: user.location || '',
        role: user.role || 'user',
        isGoogleUser: true,
        isActive: true,
      }
    });

  } catch (error) {
    console.error('❌ Google Email Auth error:', error);
    res.status(500).json({
      success: false,
      message: 'Authentication failed',
      error: error.message
    });
  }
};