const mongoose = require('mongoose');

const ProductSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      required: true,
    },
    price: {
      type: Number,
      required: true,
    },
    discountedPrice: {
      type: Number,
      default: null,
    },
    category: {
      type: String,
      required: true,
      // ✅ REMOVED enum - now accepts any category name
    },
    location: {
      type: String,
      required: true,
    },
    rating: {
      type: Number,
      default: 4.5,
      min: 0,
      max: 5,
    },
    reviews: {
      type: Number,
      default: 0,
    },
    images: {
      type: [String],
      required: true,
    },
    duration: {
      type: String,
      default: '3 Nights / 4 Days',
    },
    isFeatured: {
      type: Boolean,
      default: false,
    },
    isTrending: {
      type: Boolean,
      default: false,
    },
    available: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Product', ProductSchema);