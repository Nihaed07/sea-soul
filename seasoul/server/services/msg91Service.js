// ⚠️ DEPRECATED - This file is no longer used
// Migration to Firebase Phone Authentication completed
// See FIREBASE_SETUP.md for details

// services/msg91Service.js - DEPRECATED - DO NOT USE
// This service has been replaced by Firebase Phone Authentication
// Keep for reference only

const axios = require('axios');
require('dotenv').config();

class MSG91Service {
  constructor() {
    // ✅ Only AuthKey needed for Direct SMS
    this.authKey = process.env.MSG91_AUTH_KEY;
    this.senderId = process.env.MSG91_SENDER_ID || 'SEASOUL';
    
    console.log('========================================');
    console.log('🔧 MSG91 Service Initialized (Direct SMS)');
    console.log(`📌 Auth Key: ${this.authKey ? '✅ Present' : '❌ Missing'}`);
    console.log(`📌 Sender ID: ${this.senderId}`);
    console.log('========================================');
  }

  /**
   * ✅ Send OTP via Direct SMS
   */
  async sendOTP(phoneNumber) {
    try {
      console.log('========================================');
      console.log('📤 MSG91: Sending OTP via Direct SMS');
      console.log(`📱 Phone: ${phoneNumber}`);
      console.log('========================================');

      // Clean phone number
      let mobile = this._cleanPhoneNumber(phoneNumber);
      if (!mobile) {
        return { success: false, error: 'Invalid phone number' };
      }

      // ✅ Generate 4-digit OTP
      const otp = Math.floor(1000 + Math.random() * 9000).toString();
      console.log(`🔑 Generated OTP: ${otp}`);

      // ✅ Create SMS message
      const message = `Your SeaSoul verification code is ${otp}. Valid for 10 minutes.`;

      // ✅ Send via Direct SMS API
      const response = await axios.get(
        'https://api.msg91.com/api/sendhttp.php',
        {
          params: {
            authkey: this.authKey,
            mobiles: `91${mobile}`,
            message: message,
            sender: this.senderId,
            route: '1',              // ✅ Transactional Route
            country: '91',
            response: 'json'
          },
          timeout: 30000
        }
      );

      console.log('📥 Direct SMS Response:', response.data);

      // ✅ Check response
      if (response.data) {
        if (response.data.type === 'success') {
          console.log(`✅ SMS sent successfully! OTP: ${otp}`);
          return { 
            success: true, 
            data: response.data,
            otp: otp,
            method: 'direct'
          };
        } else {
          console.error('❌ SMS failed:', response.data);
          return { 
            success: false, 
            error: response.data.message || 'SMS sending failed' 
          };
        }
      }

      return { success: false, error: 'No response from MSG91' };

    } catch (error) {
      console.error('❌ MSG91 Error:', error.message);
      if (error.response) {
        console.error('   Status:', error.response.status);
        console.error('   Data:', error.response.data);
      }
      return { success: false, error: error.message };
    }
  }

  /**
   * ✅ Verify OTP - Check local database
   */
  async verifyOTP(phoneNumber, otp) {
    // Verification is handled by database, not MSG91
    console.log(`🔍 Verifying OTP locally for ${phoneNumber}`);
    return { success: true, verified: true };
  }

  /**
   * ✅ Resend OTP
   */
  async resendOTP(phoneNumber) {
    try {
      console.log(`📤 Resending OTP to ${phoneNumber}...`);

      let mobile = this._cleanPhoneNumber(phoneNumber);
      if (!mobile) {
        return { success: false, error: 'Invalid phone number' };
      }

      const otp = Math.floor(1000 + Math.random() * 9000).toString();
      const message = `Your SeaSoul verification code is ${otp}. Valid for 10 minutes.`;

      const response = await axios.get(
        'https://api.msg91.com/api/sendhttp.php',
        {
          params: {
            authkey: this.authKey,
            mobiles: `91${mobile}`,
            message: message,
            sender: this.senderId,
            route: '1',
            country: '91',
            response: 'json'
          },
          timeout: 30000
        }
      );

      if (response.data && response.data.type === 'success') {
        return { 
          success: true, 
          data: response.data,
          otp: otp
        };
      }

      return { success: false, error: response.data?.message || 'Failed' };

    } catch (error) {
      console.error('❌ Resend Error:', error.message);
      return { success: false, error: error.message };
    }
  }

  /**
   * ✅ Clean phone number
   */
  _cleanPhoneNumber(phone) {
    if (!phone) return null;
    
    let clean = phone.replace(/\s/g, '');
    
    if (clean.startsWith('+91')) {
      clean = clean.substring(3);
    } else if (clean.startsWith('91')) {
      clean = clean.substring(2);
    } else if (clean.startsWith('0')) {
      clean = clean.substring(1);
    }
    
    if (!/^[0-9]{10}$/.test(clean)) {
      console.error(`❌ Invalid phone: ${clean}`);
      return null;
    }
    
    return clean;
  }
}

module.exports = new MSG91Service();