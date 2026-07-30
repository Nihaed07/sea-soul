const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const UserSchema = new mongoose.Schema(
  {
    fullName: {
      type: String,
      required: true,
      trim: true,
    },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    phone: {
      type: String,
      required: false,
      default: null,        // ✅ FIX: null instead of ''
      sparse: true,         // ✅ Now skips null values properly
    },
    password: {
      type: String,
      required: false,
      default: '',
    },
    profileImage: {
      type: String,
      default: 'https://res.cloudinary.com/demo/image/upload/v1/default-avatar.png',
    },
    bio: {
      type: String,
      default: '',
      maxlength: 500,
    },
    location: {
      type: String,
      default: '',
    },
    role: {
      type: String,
      enum: ['user', 'admin'],
      default: 'user',
    },
    resetPasswordOTP: {
      type: String,
      default: null,
    },
    resetPasswordExpires: {
      type: Date,
      default: null,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    isGoogleUser: {
      type: Boolean,
      default: false,
    },
    googleId: {
      type: String,
      default: null,
      sparse: true,
    },
  },
  { timestamps: true }
);

// ✅ Only hash password if it exists and modified
UserSchema.pre('save', async function() {
  if (!this.password || !this.isModified('password')) {
    return;
  }
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
});

UserSchema.methods.comparePassword = async function(enteredPassword) {
  if (!this.password) return false;
  return await bcrypt.compare(enteredPassword, this.password);
};

module.exports = mongoose.model('User', UserSchema);