const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
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
  room: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Room',
    required: true
  },
  
  // Booking details
  bookingNumber: {
    type: String,
    unique: true,
    required: true
  },
  checkIn: {
    type: Date,
    required: true
  },
  checkOut: {
    type: Date,
    required: true
  },
  guests: {
    adults: {
      type: Number,
      required: true,
      min: 1
    },
    children: {
      type: Number,
      default: 0,
      min: 0
    }
  },
  
  // Guest information
  guestInfo: {
    firstName: String,
    lastName: String,
    email: String,
    phone: String,
    specialRequests: String
  },
  
  // Pricing
  roomPrice: {
    type: Number,
    required: true
  },
  nights: {
    type: Number,
    required: true
  },
  subtotal: {
    type: Number,
    required: true
  },
  discountAmount: {
    type: Number,
    default: 0
  },
  discountPercentage: {
    type: Number,
    default: 0
  },
  taxAmount: {
    type: Number,
    default: 0
  },
  totalAmount: {
    type: Number,
    required: true
  },
  currency: {
    type: String,
    default: 'VND'
  },
  
  // Status
  status: {
    type: String,
    enum: ['pending', 'confirmed', 'cancelled', 'checked_in', 'checked_out', 'no_show'],
    default: 'pending'
  },
  
  // Payment
  paymentStatus: {
    type: String,
    enum: ['pending', 'paid', 'failed', 'refunded', 'partial_refund'],
    default: 'pending'
  },
  paymentMethod: {
    type: String,
    enum: ['vnpay', 'stripe', 'cash'],
    required: true
  },
  transactionId: {
    type: String,
    index: true
  },
  paidAt: Date,
  paymentDetails: {
    vnp_Amount: String,
    vnp_BankCode: String,
    vnp_BankTranNo: String,
    vnp_CardType: String,
    vnp_OrderInfo: String,
    vnp_PayDate: String,
    vnp_ResponseCode: String,
    vnp_TmnCode: String,
    vnp_TransactionNo: String,
    vnp_TransactionStatus: String,
    vnp_TxnRef: String,
    vnp_SecureHash: String,
    rawResponse: mongoose.Schema.Types.Mixed
  },
  
  // Cancellation
  cancellationReason: String,
  cancellationDate: Date,
  cancellationPolicy: {
    type: String,
    enum: ['flexible', 'moderate', 'strict']
  },
  refundAmount: {
    type: Number,
    default: 0
  },
  
  // Timestamps
  confirmedAt: Date,
  checkedInAt: Date,
  checkedOutAt: Date,
  
  // Notes
  hotelNotes: String,
  adminNotes: String
}, {
  timestamps: true
});

// Generate booking number
bookingSchema.pre('save', async function(next) {
  if (this.isNew && !this.bookingNumber) {
    try {
      const count = await mongoose.model('Booking').countDocuments();
      this.bookingNumber = `HB${Date.now()}${String(count + 1).padStart(4, '0')}`;
      console.log('Generated booking number:', this.bookingNumber);
    } catch (error) {
      console.error('Error generating booking number:', error);
      return next(error);
    }
  }
  next();
});

// Calculate nights
bookingSchema.pre('save', function(next) {
  if (this.checkIn && this.checkOut) {
    const checkInDate = new Date(this.checkIn);
    const checkOutDate = new Date(this.checkOut);
    this.nights = Math.ceil((checkOutDate - checkInDate) / (1000 * 60 * 60 * 24));
  }
  next();
});

// Update customer total spent when booking is confirmed and paid
bookingSchema.post('save', async function(doc) {
  if (doc.status === 'confirmed' && doc.paymentStatus === 'paid') {
    const User = mongoose.model('User');
    const customer = await User.findById(doc.customer);
    if (customer) {
      customer.totalSpent += doc.totalAmount;
      customer.updateMembershipTier();
      await customer.save();
    }
  }
});

// Check if payment is expired (30 minutes)
bookingSchema.methods.isPaymentExpired = function() {
  const now = new Date();
  const createdAt = new Date(this.createdAt);
  const thirtyMinutes = 30 * 60 * 1000; // 30 minutes in milliseconds
  
  return this.paymentStatus === 'pending' && (now - createdAt) > thirtyMinutes;
};

// Get payment amount for VNPay (multiply by 100)
bookingSchema.methods.getVNPayAmount = function() {
  return Math.round(this.totalAmount * 100);
};

// Check if booking is confirmed and paid
bookingSchema.methods.isCompleted = function() {
  return this.status === 'confirmed' && this.paymentStatus === 'paid';
};

// Calculate cancellation fee
bookingSchema.methods.calculateCancellationFee = function() {
  const now = new Date();
  const checkInDate = new Date(this.checkIn);
  const daysUntilCheckIn = Math.ceil((checkInDate - now) / (1000 * 60 * 60 * 24));
  
  let feePercentage = 0;
  
  switch (this.cancellationPolicy) {
    case 'flexible':
      feePercentage = daysUntilCheckIn < 1 ? 100 : 0;
      break;
    case 'moderate':
      if (daysUntilCheckIn < 1) feePercentage = 100;
      else if (daysUntilCheckIn < 7) feePercentage = 50;
      else feePercentage = 0;
      break;
    case 'strict':
      if (daysUntilCheckIn < 1) feePercentage = 100;
      else if (daysUntilCheckIn < 7) feePercentage = 75;
      else if (daysUntilCheckIn < 14) feePercentage = 50;
      else feePercentage = 25;
      break;
  }
  
  const cancellationFee = this.totalAmount * (feePercentage / 100);
  const refundAmount = this.totalAmount - cancellationFee;
  
  return {
    feePercentage,
    cancellationFee,
    refundAmount
  };
};

// Check if booking can be cancelled
bookingSchema.methods.canBeCancelled = function() {
  const now = new Date();
  const checkInDate = new Date(this.checkIn);
  
  return this.status === 'confirmed' && 
         this.paymentStatus === 'paid' && 
         checkInDate > now;
};

module.exports = mongoose.model('Booking', bookingSchema);
