const mongoose = require('mongoose');
require('dotenv').config();

const connectDB = async () => {
  try {
    const mongoURI = process.env.MONGODB_URI;
    
    if (!mongoURI) {
      console.error('❌ MONGODB_URI is not defined');
      process.exit(1);
    }

    console.log(`📦 Connecting to MongoDB...`);
    await mongoose.connect(mongoURI);
    
    console.log('✅ MongoDB Connected Successfully');
    console.log(`📦 Database: ${mongoose.connection.name}`);
    console.log(`🔗 Host: ${mongoose.connection.host}`);

    // ✅ FIX: Drop and recreate phone index to fix sparse index issue
    try {
      const collection = mongoose.connection.collection('users');
      const indexes = await collection.indexes();
      const phoneIndex = indexes.find(idx => idx.name === 'phone_1');
      
      if (phoneIndex) {
        console.log('🗑️ Dropping old phone_1 index...');
        await collection.dropIndex('phone_1');
        console.log('✅ Old phone_1 index dropped');
      }
      
      console.log('📋 Current indexes:', indexes.map(i => i.name));
    } catch (indexError) {
      console.log('⚠️ Index operation:', indexError.message);
    }

  } catch (error) {
    console.error('❌ MongoDB Connection Error:', error.message);
    process.exit(1);
  }
};

module.exports = connectDB;