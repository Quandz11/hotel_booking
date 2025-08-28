const mongoose = require('mongoose');

const hotelSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true
  },
  description: {
    type: String,
    required: true
  },
  owner: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  
  // Location
  address: {
    street: String,
    city: String,
    state: String,
    country: String,
    zipCode: String,
    coordinates: {
      latitude: Number,
      longitude: Number
    }
  },
  
  // Hotel info
  starRating: {
    type: Number,
    min: 3,
    max: 5,
    required: true
  },
  images: [{
    url: String,
    caption: String,
    isPrimary: {
      type: Boolean,
      default: false
    }
  }],
  
  // Amenities and services
  amenities: [{
    type: String,
    enum: [
      'wifi', 'parking', 'pool', 'gym', 'spa', 'restaurant', 
      'bar', 'room_service', 'concierge', 'laundry', 
      'business_center', 'conference_room', 'airport_shuttle',
      'pet_friendly', 'air_conditioning', 'elevator'
    ]
  }],
  
  // Policies
  checkInTime: {
    type: String,
    default: '14:00'
  },
  checkOutTime: {
    type: String,
    default: '12:00'
  },
  cancellationPolicy: {
    type: String,
    enum: ['flexible', 'moderate', 'strict'],
    default: 'moderate'
  },
  
  // Contact
  phone: String,
  email: String,
  website: String,
  
  // Status
  isApproved: {
    type: Boolean,
    default: false
  },
  isActive: {
    type: Boolean,
    default: true
  },
  
  // Stats
  totalRooms: {
    type: Number,
    default: 0
  },
  averageRating: {
    type: Number,
    default: 0,
    min: 0,
    max: 5
  },
  totalReviews: {
    type: Number,
    default: 0
  },
  
  // SEO
  slug: {
    type: String,
    unique: true
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true, transform: transformHotel }
});

// Transform function to structure the output
function transformHotel(doc, ret) {
  // Restructure for frontend compatibility
  ret.contact = {
    phone: ret.phone || '',
    email: ret.email || '',
    website: ret.website || ''
  };
  
  ret.policies = {
    checkIn: ret.checkInTime || '14:00',
    checkOut: ret.checkOutTime || '12:00',
    cancellation: ret.cancellationPolicy || 'moderate'
  };
  
  // Remove the old fields
  delete ret.phone;
  delete ret.email;
  delete ret.website;
  delete ret.checkInTime;
  delete ret.checkOutTime;
  delete ret.cancellationPolicy;
  
  return ret;
}

// Create slug from name
hotelSchema.pre('save', function(next) {
  if (this.isModified('name')) {
    this.slug = this.name
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)/g, '');
  }
  next();
});

// Virtual for rooms
hotelSchema.virtual('rooms', {
  ref: 'Room',
  localField: '_id',
  foreignField: 'hotel'
});

// Update total rooms count
hotelSchema.methods.updateRoomCount = async function() {
  const Room = mongoose.model('Room');
  this.totalRooms = await Room.countDocuments({ hotel: this._id, isActive: true });
  await this.save();
};

// Update rating
hotelSchema.methods.updateRating = async function() {
  const Review = mongoose.model('Review');
  const reviews = await Review.find({ hotel: this._id });
  
  if (reviews.length > 0) {
    const sum = reviews.reduce((acc, review) => acc + review.rating, 0);
    this.averageRating = sum / reviews.length;
    this.totalReviews = reviews.length;
  } else {
    this.averageRating = 0;
    this.totalReviews = 0;
  }
  
  await this.save();
};

module.exports = mongoose.model('Hotel', hotelSchema);
