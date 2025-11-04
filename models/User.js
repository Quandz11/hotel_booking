const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true
  },
  password: {
    type: String,
    required: true,
    minlength: 6
  },
  firstName: {
    type: String,
    required: true
  },
  lastName: {
    type: String,
    required: true
  },
  phone: {
    type: String,
    required: false
  },
  role: {
    type: String,
    enum: ['customer', 'hotel_owner', 'admin'],
    default: 'customer'
  },
  isEmailVerified: {
    type: Boolean,
    default: false
  },
  emailVerificationToken: String,
  emailVerificationOTP: String,
  emailVerificationOTPExpires: Date,
  passwordResetOTP: String,
  passwordResetOTPExpires: Date,
  
  // Customer specific fields
  membershipTier: {
    type: String,
    enum: ['bronze', 'silver', 'gold', 'diamond'],
    default: 'bronze'
  },
  totalSpent: {
    type: Number,
    default: 0
  },
  favoriteHotels: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Hotel'
  }],
  
  // Hotel owner specific fields
  businessLicense: String,
  identityDocument: String,
  isApproved: {
    type: Boolean,
    default: false
  },
  
  avatar: String,
  address: {
    street: String,
    city: String,
    state: String,
    country: String,
    zipCode: String
  },
  
  refreshToken: String,
  lastLogin: Date,
  isActive: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true
});

// Hash password before saving
userSchema.pre('save', async function(next) {
  // Skip hashing if password is not modified or already hashed
  if (!this.isModified('password')) return next();
  
  // Check if password is already hashed (bcrypt hashes start with $2a$, $2b$, or $2y$)
  if (this.password.match(/^\$2[abyxy]?\$/)) {
    return next();
  }
  
  try {
    const salt = await bcrypt.genSalt(12);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Compare password method
userSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

// Update membership tier based on total spent
userSchema.methods.updateMembershipTier = function() {
  if (this.totalSpent >= 50000000) { // 50M VND
    this.membershipTier = 'diamond';
  } else if (this.totalSpent >= 20000000) { // 20M VND
    this.membershipTier = 'gold';
  } else if (this.totalSpent >= 10000000) { // 10M VND
    this.membershipTier = 'silver';
  } else {
    this.membershipTier = 'bronze';
  }
};

// Get discount percentage based on membership tier
userSchema.methods.getDiscountPercentage = function() {
  switch (this.membershipTier) {
    case 'diamond':
      return 5;
    case 'gold':
      return 3;
    case 'silver':
      return 1;
    default:
      return 0;
  }
};

module.exports = mongoose.model('User', userSchema);
