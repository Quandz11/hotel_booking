const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema({
  // References
  customer: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  hotel: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Hotel',
    required: true
  },
  booking: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Booking',
    required: true
  },
  
  // Review content
  rating: {
    type: Number,
    required: true,
    min: 1,
    max: 5
  },
  title: {
    type: String,
    required: true,
    maxlength: 100
  },
  comment: {
    type: String,
    required: true,
    maxlength: 1000
  },
  
  // Detailed ratings
  ratings: {
    cleanliness: {
      type: Number,
      min: 1,
      max: 5
    },
    service: {
      type: Number,
      min: 1,
      max: 5
    },
    location: {
      type: Number,
      min: 1,
      max: 5
    },
    facilities: {
      type: Number,
      min: 1,
      max: 5
    },
    valueForMoney: {
      type: Number,
      min: 1,
      max: 5
    }
  },
  
  // Images
  images: [{
    url: String,
    caption: String
  }],
  
  // Status
  isApproved: {
    type: Boolean,
    default: true
  },
  isVisible: {
    type: Boolean,
    default: true
  },
  
  // Hotel response
  hotelResponse: {
    message: String,
    respondedAt: Date,
    respondedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    }
  },
  
  // Helpful votes
  helpfulVotes: [{
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    isHelpful: Boolean,
    votedAt: {
      type: Date,
      default: Date.now
    }
  }],
  
  // Flags/Reports
  flags: [{
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    reason: {
      type: String,
      enum: ['inappropriate', 'spam', 'fake', 'offensive', 'other']
    },
    description: String,
    flaggedAt: {
      type: Date,
      default: Date.now
    }
  }]
}, {
  timestamps: true
});

// Ensure one review per booking
reviewSchema.index({ booking: 1 }, { unique: true });

// Update hotel rating when review is saved
reviewSchema.post('save', async function(doc) {
  const Hotel = mongoose.model('Hotel');
  const hotel = await Hotel.findById(doc.hotel);
  if (hotel) {
    await hotel.updateRating();
  }
});

// Update hotel rating when review is removed
reviewSchema.post('remove', async function(doc) {
  const Hotel = mongoose.model('Hotel');
  const hotel = await Hotel.findById(doc.hotel);
  if (hotel) {
    await hotel.updateRating();
  }
});

// Calculate helpful score
reviewSchema.virtual('helpfulScore').get(function() {
  const helpful = this.helpfulVotes.filter(vote => vote.isHelpful).length;
  const notHelpful = this.helpfulVotes.filter(vote => !vote.isHelpful).length;
  return helpful - notHelpful;
});

// Check if user can review (must have completed booking)
reviewSchema.statics.canUserReview = async function(userId, bookingId) {
  const Booking = mongoose.model('Booking');
  const booking = await Booking.findOne({
    _id: bookingId,
    customer: userId,
    status: 'checked_out'
  });
  
  if (!booking) return false;
  
  // Check if review already exists
  const existingReview = await this.findOne({ booking: bookingId });
  return !existingReview;
};

module.exports = mongoose.model('Review', reviewSchema);
