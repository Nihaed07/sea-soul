// ⚠️ DEPRECATED - This file is no longer used
// Migration to Firebase Phone Authentication completed
// See FIREBASE_SETUP.md for details

// services/smsService.js - DEPRECATED - DO NOT USE
// This service has been replaced by Firebase Phone Authentication
// Keep for reference only

const msg91Service = require('./msg91Service');

class SMSService {
  // ✅ Use MSG91 Widget for OTP
  async sendOTP(phoneNumber, otp) {
    try {
      console.log(`📤 Sending OTP to ${phoneNumber}...`);
      
      // Clean phone number
      let mobile = phoneNumber.replace(/\s/g, '');
      if (mobile.startsWith('+91')) {
        mobile = mobile.substring(3);
      } else if (mobile.startsWith('91')) {
        mobile = mobile.substring(2);
      }
      
      if (mobile.length !== 10) {
        console.error(`❌ Invalid phone: ${mobile}`);
        return { success: false, error: 'Invalid phone number' };
      }

      // ✅ Use MSG91 Widget API for OTP
      return await msg91Service.sendOTP(phoneNumber);
      
    } catch (error) {
      console.error('❌ SMS Error:', error.message);
      return { success: false, error: error.message };
    }
  }

  // ✅ Verify OTP using MSG91
  async verifyOTP(phoneNumber, otp) {
    return await msg91Service.verifyOTP(phoneNumber, otp);
  }

  // ✅ Resend OTP
  async resendOTP(phoneNumber) {
    return await msg91Service.resendOTP(phoneNumber);
  }

  // ✅ Fallback: Send generic SMS
  async sendSMS(phoneNumber, message) {
    try {
      console.log(`📤 Sending SMS to ${phoneNumber}...`);
      
      let mobile = phoneNumber.replace(/\s/g, '');
      if (mobile.startsWith('+91')) {
        mobile = mobile.substring(3);
      } else if (mobile.startsWith('91')) {
        mobile = mobile.substring(2);
      }
      
      if (mobile.length !== 10) {
        return { success: false, error: 'Invalid phone number' };
      }

      // Use direct SMS for non-OTP messages
      return await msg91Service.sendSMSDirect(phoneNumber, message);
      
    } catch (error) {
      console.error('❌ SMS Error:', error.message);
      return { success: false, error: error.message };
    }
  }
}

module.exports = new SMSService();