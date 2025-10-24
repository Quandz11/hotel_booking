const mongoose = require('mongoose');

const roomSchema = new mongoose.Schema({
  hotel: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Hotel',
    required: true
  },
  
  // Room info
  name: {
    type: String,
    required: true
  },
  type: {
    type: String,
    enum: ['standard', 'deluxe', 'suite', 'executive', 'presidential'],
    required: true
  },
  description: String,
  
  // Capacity
  maxGuests: {
    type: Number,
    required: true,
    min: 1
  },
  bedType: {
    type: String,
    enum: ['single', 'double', 'queen', 'king', 'twin'],
    required: true
  },
  bedCount: {
    type: Number,
    required: true,
    min: 1
  },
  
  // Pricing
  basePrice: {
    type: Number,
    required: true,
    min: 0
  },
  weekendPrice: {
    type: Number,
    required: true,
    min: 0
  },
  currency: {
    type: String,
    default: 'VND'
  },
  
  // Room features
  size: Number, // in square meters
  amenities: [{
    type: String,
    enum: [
      'wifi', 'air_conditioning', 'tv', 'minibar', 'safe', 
      'balcony', 'city_view', 'ocean_view', 'mountain_view',
      'kitchenette', 'bathtub', 'shower', 'hairdryer',
      'coffee_maker', 'telephone', 'desk', 'sofa'
    ]
  }],
  
  // Images
  images: [{
    url: String,
    caption: String,
    isPrimary: {
      type: Boolean,
      default: false
    }
  }],
  
  // Availability
  totalRooms: {
    type: Number,
    required: true,
    min: 1
  },
  
  // Status
  isActive: {
    type: Boolean,
    default: true
  },
  
  // Special offers
  discountPercentage: {
    type: Number,
    default: 0,
    min: 0,
    max: 100
  },
  specialOfferDescription: String
}, {
  timestamps: true
});

// Calculate price for date range
roomSchema.methods.calculatePrice = function(checkIn, checkOut) {
  const start = new Date(checkIn);
  const end = new Date(checkOut);
  const nights = Math.ceil((end - start) / (1000 * 60 * 60 * 24));
  
  let totalPrice = 0;
  let currentDate = new Date(start);
  
  for (let i = 0; i < nights; i++) {
    const isWeekend = currentDate.getDay() === 0 || currentDate.getDay() === 6;
    const nightPrice = isWeekend ? this.weekendPrice : this.basePrice;
    totalPrice += nightPrice;
    currentDate.setDate(currentDate.getDate() + 1);
  }
  
  // Apply discount if any
  if (this.discountPercentage > 0) {
    totalPrice = totalPrice * (1 - this.discountPercentage / 100);
  }
  
  return {
    totalPrice: Math.round(totalPrice),
    nights,
    averagePerNight: Math.round(totalPrice / nights)
  };
};

// Check availability for date range
roomSchema.methods.checkAvailability = async function(checkIn, checkOut, guestCount = 1) {
  const Booking = mongoose.model('Booking');
  
  // Check guest capacity
  if (guestCount > this.maxGuests) {
    return {
      available: false,
      reason: 'Exceeds maximum guest capacity'
    };
  }
  
  // Check overlapping bookings
  const checkInDate = new Date(checkIn);
  const checkOutDate = new Date(checkOut);
  const thirtyMinutesAgo = new Date(Date.now() - 30 * 60 * 1000);

  // Count bookings that overlap the requested period and consume inventory:
  // - confirmed or checked_in
  // - pending created within last 30 minutes (hold inventory temporarily)
  const overlappingBookings = await Booking.countDocuments({
    room: this._id,
    $and: [
      { checkIn: { $lt: checkOutDate } },
      { checkOut: { $gt: checkInDate } },
    ],
    $or: [
      { status: { $in: ['confirmed', 'checked_in'] } },
      { status: 'pending', createdAt: { $gte: thirtyMinutesAgo } }
    ]
  });
  
  const availableRooms = this.totalRooms - overlappingBookings;
  
  return {
    available: availableRooms > 0,
    availableRooms,
    totalRooms: this.totalRooms
  };
};

module.exports = mongoose.model('Room', roomSchema);
