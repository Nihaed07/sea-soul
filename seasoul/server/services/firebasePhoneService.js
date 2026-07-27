// services/firebasePhoneService.js - Firebase Phone Authentication Service
require('dotenv').config();

// Import firebase-admin only if available
let admin;
try {
  admin = require('firebase-admin');
} catch (error) {
  console.log('⚠️ firebase-admin not installed. Run: npm install firebase-admin');
  admin = null;
}

class FirebasePhoneService {
  constructor() {
    // Check if firebase-admin is available
    if (!admin) {
      console.log('⚠️ Firebase Admin SDK not available');
      console.log('Please install: npm install firebase-admin');
      return;
    }

    // Initialize Firebase Admin SDK
    // You need to add service account credentials to .env
    if (!admin.apps || admin.apps.length === 0) {
      try {
        // Option 1: Using service account JSON file
        const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
        
        if (serviceAccount) {
          admin.initializeApp({
            credential: admin.credential.cert(require(serviceAccount)),
          });
          console.log('✅ Firebase Admin initialized with service account file');
        } else {
          // Option 2: Using environment variables
          const projectId = process.env.FIREBASE_PROJECT_ID || 'seasoul-4393e';
          const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
          const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');
          
          if (clientEmail && privateKey) {
            admin.initializeApp({
              credential: admin.credential.cert({
                projectId,
                clientEmail,
                privateKey,
              }),
            });
            console.log('✅ Firebase Admin initialized with environment variables');
          } else {
            console.log('⚠️ Firebase Admin not initialized - credentials missing');
            console.log('Please add FIREBASE_CLIENT_EMAIL and FIREBASE_PRIVATE_KEY to .env');
          }
        }
      } catch (error) {
        console.error('❌ Firebase Admin initialization error:', error.message);
      }
    }
    
    console.log('========================================');
    console.log('🔧 Firebase Phone Service Initialized');
    console.log('========================================');
  }

  /**
   * Verify Firebase ID Token from client
   * The actual OTP sending happens on the Flutter client side
   * Backend only verifies the token after user completes phone verification
   */
  async verifyPhoneToken(idToken) {
    try {
      console.log('🔍 Verifying Firebase ID Token...');
      
      if (!admin || !admin.apps || admin.apps.length === 0) {
        throw new Error('Firebase Admin not initialized. Please configure Firebase credentials in .env');
      }

      const decodedToken = await admin.auth().verifyIdToken(idToken);
      console.log('✅ Token verified for phone:', decodedToken.phone_number);
      
      return {
        success: true,
        phoneNumber: decodedToken.phone_number,
        uid: decodedToken.uid,
        decodedToken
      };
    } catch (error) {
      console.error('❌ Token verification error:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Get user by phone number
   */
  async getUserByPhoneNumber(phoneNumber) {
    try {
      if (!admin || !admin.apps || admin.apps.length === 0) {
        throw new Error('Firebase Admin not initialized. Please configure Firebase credentials in .env');
      }

      const userRecord = await admin.auth().getUserByPhoneNumber(phoneNumber);
      return {
        success: true,
        user: userRecord
      };
    } catch (error) {
      if (error.code === 'auth/user-not-found') {
        return { success: false, error: 'User not found' };
      }
      console.error('❌ Get user error:', error.message);
      return { success: false, error: error.message };
    }
  }

  /**
   * Delete Firebase user
   */
  async deleteUser(uid) {
    try {
      if (!admin || !admin.apps || admin.apps.length === 0) {
        throw new Error('Firebase Admin not initialized. Please configure Firebase credentials in .env');
      }

      await admin.auth().deleteUser(uid);
      return { success: true };
    } catch (error) {
      console.error('❌ Delete user error:', error.message);
      return { success: false, error: error.message };
    }
  }

  /**
   * Clean phone number format
   */
  _cleanPhoneNumber(phone) {
    if (!phone) return null;
    
    let clean = phone.replace(/\s/g, '');
    
    // Ensure it starts with +
    if (!clean.startsWith('+')) {
      if (clean.startsWith('91')) {
        clean = '+' + clean;
      } else if (clean.startsWith('0')) {
        clean = '+91' + clean.substring(1);
      } else if (clean.length === 10) {
        clean = '+91' + clean;
      }
    }
    
    return clean;
  }
}

module.exports = new FirebasePhoneService();
