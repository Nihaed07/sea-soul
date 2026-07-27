const express = require('express');
const cors = require('cors');
const connectDB = require('./config/db');
const path = require('path');
require('dotenv').config();

const app = express();

// ✅ CORS Configuration
app.use(cors({
  origin: '*',
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept'],
}));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ✅ Connect to MongoDB
connectDB();

// ✅ Serve uploaded images
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
app.use('/assets', express.static(path.join(__dirname, '../assets')));

// ==================== ENVIRONMENT VALIDATION ====================
function validateEnvironment() {
  console.log('🔍 Validating environment variables...');
  
  const required = [
    'RAZORPAY_KEY_ID',
    'RAZORPAY_KEY_SECRET',
    'JWT_SECRET',
    'MONGODB_URI',
  ];
  
  const missing = required.filter(key => !process.env[key]);
  
  if (missing.length > 0) {
    console.error('❌ Missing required environment variables:', missing.join(', '));
    console.error('Please create a .env file with these variables');
    console.error('Check .env.example for reference');
    // Don't exit, just warn - allow server to start for debugging
    // process.exit(1);
  } else {
    console.log('✅ All required environment variables are set');
  }
  
  // Validate Razorpay keys format
  const keyId = process.env.RAZORPAY_KEY_ID;
  if (keyId) {
    if (!keyId.startsWith('rzp_')) {
      console.warn('⚠️ Warning: RAZORPAY_KEY_ID does not start with "rzp_"');
      console.warn('This might indicate an invalid key format');
    }
    
    const isTestKey = keyId.startsWith('rzp_test_');
    const isLiveKey = keyId.startsWith('rzp_live_');
    
    console.log(`🔑 Razorpay Mode: ${isTestKey ? 'TEST' : isLiveKey ? 'LIVE' : 'UNKNOWN'}`);
    console.log(`🔑 Key ID: ${keyId.slice(0, 8)}...${keyId.slice(-4)}`);
  } else {
    console.warn('⚠️ RAZORPAY_KEY_ID is not set');
  }
  
  console.log(`🔐 Key Secret: ${process.env.RAZORPAY_KEY_SECRET ? '✓ Set' : '✗ Missing'}`);
  
  return true;
}

// ✅ Call validation
validateEnvironment();

// ==================== ROUTES ====================

// ✅ Import Routes
const authRoutes = require('./routes/authRoutes');
const productRoutes = require('./routes/productRoutes');
const profileRoutes = require('./routes/profileRoutes');
const adminRoutes = require('./routes/adminRoutes');
const activityRoutes = require('./routes/activityRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const bookingRoutes = require('./routes/bookingRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const reviewRoutes = require('./routes/reviewRoutes');
const categoryRoutes = require('./routes/categoryRoutes');
const razorpayRoutes = require('./routes/razorpayRoutes');

// ✅ API Routes
app.use('/api/auth', authRoutes);
app.use('/api', productRoutes);
app.use('/api', profileRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api', activityRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/categories', categoryRoutes);

// ✅ Razorpay Routes
app.use('/api/razorpay', razorpayRoutes);

// ==================== HEALTH CHECK ENDPOINTS ====================

// ✅ Health check
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'Server is running',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
    razorpayConfigured: Boolean(process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET),
  });
});

// ✅ Environment check
app.get('/api/env-check', (req, res) => {
  res.json({
    success: true,
    environment: {
      razorpayKeyId: process.env.RAZORPAY_KEY_ID ? '✓ Set' : '✗ Missing',
      razorpayKeySecret: process.env.RAZORPAY_KEY_SECRET ? '✓ Set' : '✗ Missing',
      nodeEnv: process.env.NODE_ENV || 'not set',
      port: process.env.PORT || 'not set',
      mongoUri: process.env.MONGODB_URI ? '✓ Set' : '✗ Missing',
    },
    timestamp: new Date().toISOString(),
  });
});


// ==================== ERROR HANDLING ====================

// ✅ 404 Handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Route not found: ${req.originalUrl}`,
  });
});

// ✅ Global Error Handler
app.use((err, req, res, next) => {
  console.error('❌ Error:', err.stack);
  
  // Check if it's a Razorpay error
  if (err.error && err.error.description) {
    return res.status(err.statusCode || 500).json({
      success: false,
      message: err.error.description,
      error: err.error,
    });
  }
  
  res.status(500).json({
    success: false,
    message: err.message || 'Something went wrong!',
    error: process.env.NODE_ENV === 'development' ? err.stack : undefined,
  });
});

// ==================== START SERVER ====================

const PORT = process.env.PORT || 5000;
const server = app.listen(PORT, () => {
  const ip = getLocalIP();
  console.log('\n=================================');
  console.log(`✅ Server running on port ${PORT}`);
  console.log(`🌐 Local: http://localhost:${PORT}`);
  console.log(`🌐 Network: http://${ip}:${PORT}`);
  console.log('=================================');
  console.log(`📍 Admin API: http://localhost:${PORT}/api/admin`);
  console.log(`📍 Payments API: http://localhost:${PORT}/api/payments`);
  console.log(`📍 Razorpay API: http://localhost:${PORT}/api/razorpay`);
  console.log(`📍 Health Check: http://localhost:${PORT}/api/health`);
  console.log(`📍 Env Check: http://localhost:${PORT}/api/env-check`);
  console.log(`📁 Uploads: http://localhost:${PORT}/uploads`);
  console.log('=================================\n');
});

// ✅ Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
  });
});

// ✅ Get local IP address
function getLocalIP() {
  const { networkInterfaces } = require('os');
  const nets = networkInterfaces();
  for (const name of Object.keys(nets)) {
    for (const net of nets[name]) {
      if (net.family === 'IPv4' && !net.internal) {
        return net.address;
      }
    }
  }
  return 'localhost';
}