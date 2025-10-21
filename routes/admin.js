const express = require('express');
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const { body, query } = require('express-validator');
const User = require('../models/User');
const Hotel = require('../models/Hotel');
const Room = require('../models/Room');
const Booking = require('../models/Booking');
const Review = require('../models/Review');
const { authenticate, authorize } = require('../middleware/auth');
const { validate, asyncHandler } = require('../middleware/validation');

const router = express.Router();

// @desc    Get dashboard statistics
// @route   GET /api/admin/dashboard
// @access  Private (Admin only)
router.get('/dashboard', authenticate, authorize('admin'), asyncHandler(async (req, res) => {
  // Get total counts
  const totalUsers = await User.countDocuments();
  const totalCustomers = await User.countDocuments({ role: 'customer' });
  const totalHotelOwners = await User.countDocuments({ role: 'hotel_owner' });
  const totalHotels = await Hotel.countDocuments();
  const approvedHotels = await Hotel.countDocuments({ isApproved: true });
  const pendingHotels = await Hotel.countDocuments({ isApproved: false });
  const totalRooms = await Room.countDocuments();
  const totalBookings = await Booking.countDocuments();
  const totalReviews = await Review.countDocuments();
  
  // Get recent statistics
  const last30Days = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
  const recentUsers = await User.countDocuments({ createdAt: { $gte: last30Days } });
  const recentBookings = await Booking.countDocuments({ createdAt: { $gte: last30Days } });
  const recentRevenue = await Booking.aggregate([
    { $match: { createdAt: { $gte: last30Days }, paymentStatus: 'paid' } },
    { $group: { _id: null, total: { $sum: '$totalAmount' } } }
  ]);
  
  // Get booking status distribution
  const bookingStats = await Booking.aggregate([
    {
      $group: {
        _id: '$status',
        count: { $sum: 1 }
      }
    }
  ]);
  
  // Get monthly revenue for the last 12 months
  const monthlyRevenue = await Booking.aggregate([
    { 
      $match: { 
        createdAt: { $gte: new Date(Date.now() - 365 * 24 * 60 * 60 * 1000) },
        paymentStatus: 'paid'
      } 
    },
    {
      $group: {
        _id: {
          year: { $year: '$createdAt' },
          month: { $month: '$createdAt' }
        },
        revenue: { $sum: '$totalAmount' },
        bookings: { $sum: 1 }
      }
    },
    { $sort: { '_id.year': 1, '_id.month': 1 } }
  ]);
  
  // Get top performing hotels
  const topHotels = await Hotel.aggregate([
    { $match: { isApproved: true } },
    {
      $lookup: {
        from: 'bookings',
        localField: '_id',
        foreignField: 'hotel',
        as: 'bookings'
      }
    },
    {
      $addFields: {
        totalRevenue: {
          $sum: {
            $map: {
              input: '$bookings',
              as: 'booking',
              in: {
                $cond: [
                  { $eq: ['$$booking.paymentStatus', 'paid'] },
                  '$$booking.totalAmount',
                  0
                ]
              }
            }
          }
        },
        totalBookings: { $size: '$bookings' }
      }
    },
    { $sort: { totalRevenue: -1 } },
    { $limit: 5 },
    { $project: { name: 1, totalRevenue: 1, totalBookings: 1, averageRating: 1 } }
  ]);
  
  res.json({
    overview: {
      totalUsers,
      totalCustomers,
      totalHotelOwners,
      totalHotels,
      approvedHotels,
      pendingHotels,
      totalRooms,
      totalBookings,
      totalReviews
    },
    recent: {
      newUsers: recentUsers,
      newBookings: recentBookings,
      revenue: recentRevenue[0]?.total || 0
    },
    bookingStats,
    monthlyRevenue,
    topHotels
  });
}));

// @desc    Get all users (Admin management)
// @route   GET /api/admin/users
// @access  Private (Admin only)
router.get('/users', authenticate, authorize('admin'), [
  query('page').optional().isInt({ min: 1 }),
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('role').optional().isIn(['customer', 'hotel_owner', 'admin']),
  query('isActive').optional().isBoolean(),
  query('isApproved').optional().isBoolean(),
  query('isEmailVerified').optional().isBoolean(),
  query('search').optional().trim()
], validate, asyncHandler(async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 20;
  const skip = (page - 1) * limit;
  
  let query = {};
  
  if (req.query.role) query.role = req.query.role;
  if (req.query.isActive !== undefined) query.isActive = req.query.isActive === 'true';
  if (req.query.isApproved !== undefined) query.isApproved = req.query.isApproved === 'true';
  if (req.query.isEmailVerified !== undefined) query.isEmailVerified = req.query.isEmailVerified === 'true';
  
  if (req.query.search) {
    query.$or = [
      { firstName: { $regex: req.query.search, $options: 'i' } },
      { lastName: { $regex: req.query.search, $options: 'i' } },
      { email: { $regex: req.query.search, $options: 'i' } }
    ];
  }
  
  const users = await User.find(query)
    .select('-password -refreshToken')
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit);
  
  const total = await User.countDocuments(query);
  
  res.json({
    users,
    pagination: {
      page,
      limit,
      total,
      pages: Math.ceil(total / limit)
    }
  });
}));

// @desc    Update user status
// @route   PATCH /api/admin/users/:id/status
// @access  Private (Admin only)
router.patch('/users/:id/status', authenticate, authorize('admin'), [
  body('isActive').optional().isBoolean(),
  body('isApproved').optional().isBoolean()
], validate, asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { isActive, isApproved } = req.body;
  
  const user = await User.findById(id);
  if (!user) {
    return res.status(404).json({ message: 'User not found' });
  }
  
  if (isActive !== undefined) user.isActive = isActive;
  if (isApproved !== undefined) user.isApproved = isApproved;
  
  await user.save();
  
  res.json({
    message: 'User status updated successfully',
    user: {
      id: user._id,
      email: user.email,
      isActive: user.isActive,
      isApproved: user.isApproved
    }
  });
}));

// @desc    Get user by ID with statistics
// @route   GET /api/admin/users/:id
// @access  Private (Admin only)
router.get('/users/:id', authenticate, authorize('admin'), asyncHandler(async (req, res) => {
  const { id } = req.params;
  
  const user = await User.findById(id).select('-password -refreshToken');
  if (!user) {
    return res.status(404).json({ message: 'User not found' });
  }

  // Calculate statistics based on user role
  let statistics = {};
  
  if (user.role === 'hotel_owner') {
    // Get hotel owner statistics
    const hotels = await Hotel.find({ owner: id });
    const approvedHotels = hotels.filter(hotel => hotel.isApproved);
    
    // Get total rooms count
    const totalRooms = await Room.countDocuments({ 
      hotel: { $in: hotels.map(h => h._id) } 
    });
    
    // Calculate total revenue from bookings of their hotels
    const revenue = await Booking.aggregate([
      {
        $lookup: {
          from: 'rooms',
          localField: 'room',
          foreignField: '_id',
          as: 'roomInfo'
        }
      },
      {
        $lookup: {
          from: 'hotels',
          localField: 'roomInfo.hotel',
          foreignField: '_id',
          as: 'hotelInfo'
        }
      },
      {
        $match: {
          'hotelInfo.owner': new mongoose.Types.ObjectId(id),
          paymentStatus: 'paid'
        }
      },
      {
        $group: {
          _id: null,
          totalRevenue: { $sum: '$totalAmount' }
        }
      }
    ]);
    
    statistics = {
      totalHotels: hotels.length,
      approvedHotels: approvedHotels.length,
      totalRooms: totalRooms,
      totalRevenue: revenue.length > 0 ? revenue[0].totalRevenue : 0
    };
    
  } else if (user.role === 'customer') {
    // Get customer statistics
    const bookings = await Booking.find({ user: id });
    const paidBookings = bookings.filter(b => b.paymentStatus === 'paid');
    
    const totalSpent = paidBookings.reduce((sum, booking) => sum + booking.totalAmount, 0);
    
    // Get reviews count and average rating
    const reviews = await Review.find({ user: id });
    const averageRating = reviews.length > 0 
      ? reviews.reduce((sum, review) => sum + review.rating, 0) / reviews.length 
      : 0;
    
    statistics = {
      totalBookings: bookings.length,
      totalSpent: totalSpent,
      totalReviews: reviews.length,
      averageRating: Math.round(averageRating * 10) / 10 // Round to 1 decimal
    };
  }
  
  // Add statistics to user object
  const userWithStats = {
    ...user.toObject(),
    ...statistics
  };
  
  res.json({ user: userWithStats });
}));

// @desc    Create new user (TEST - NO AUTH)
// @route   POST /api/admin/users/test
// @access  Public (for debugging)
router.post('/users/test', [
  body('firstName').notEmpty().trim().withMessage('First name is required'),
  body('lastName').notEmpty().trim().withMessage('Last name is required'),
  body('email').isEmail().normalizeEmail().withMessage('Please provide a valid email'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  body('role').isIn(['customer', 'hotel_owner', 'admin']).withMessage('Invalid role'),
  body('phone').optional().trim(),
  body('isActive').optional().isBoolean(),
  body('isApproved').optional().isBoolean()
], validate, asyncHandler(async (req, res) => {
  
  const { 
    firstName, 
    lastName, 
    email, 
    password, 
    role, 
    phone, 
    isActive = true, 
    isApproved = true 
  } = req.body;
  
  // Check if user already exists
  const existingUser = await User.findOne({ email });
  if (existingUser) {
    return res.status(400).json({ message: 'User with this email already exists' });
  }

  // Hash password
  const hashedPassword = await bcrypt.hash(password, 12);

  // Create user
  const user = new User({
    firstName,
    lastName,
    email,
    password: hashedPassword,
    role,
    phone,
    isActive,
    isApproved,
    isEmailVerified: true // Admin created users are auto-verified
  });

  await user.save();

  // Remove password from response
  const userResponse = user.toObject();
  delete userResponse.password;
  delete userResponse.refreshToken;

  res.status(201).json({
    message: 'User created successfully',
    user: userResponse
  });
}));

// @desc    Create new user
// @route   POST /api/admin/users
// @access  Private (Admin only)
router.post('/users', authenticate, authorize('admin'), [
  body('firstName').notEmpty().trim().withMessage('First name is required'),
  body('lastName').notEmpty().trim().withMessage('Last name is required'),
  body('email').isEmail().normalizeEmail().withMessage('Please provide a valid email'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  body('role').isIn(['customer', 'hotel_owner', 'admin']).withMessage('Invalid role'),
  body('phone').optional().trim(),
  body('isActive').optional().isBoolean(),
  body('isApproved').optional().isBoolean(),
  body('isEmailVerified').optional().isBoolean()
], validate, asyncHandler(async (req, res) => {
  const {
    firstName,
    lastName,
    email,
    password,
    role,
    phone,
    isActive = true,
    isApproved = role === 'hotel_owner' ? false : true,
    isEmailVerified = true,
    address,
    dateOfBirth,
    gender,
    bio
  } = req.body;

  // Check if user already exists
  const existingUser = await User.findOne({ email });
  if (existingUser) {
    return res.status(400).json({
      message: 'Validation failed',
      errors: [{ field: 'email', message: 'Email already in use', value: email }]
    });
  }

  // Hash password
  const hashedPassword = await bcrypt.hash(password, 12);

  // Create user document
  const user = new User({
    firstName,
    lastName,
    email,
    password: hashedPassword,
    role,
    phone,
    isActive,
    isApproved,
    isEmailVerified,
    address,
    // Optional extra fields not defined in schema will be ignored by Mongoose default strict mode
    dateOfBirth,
    gender,
    bio
  });

  await user.save();

  const userResponse = user.toObject();
  delete userResponse.password;
  delete userResponse.refreshToken;

  res.status(201).json({
    message: 'User created successfully',
    user: userResponse
  });
}));

// @desc    Update user
// @route   PUT /api/admin/users/:id
// @access  Private (Admin only)
router.put('/users/:id', authenticate, authorize('admin'), [
  body('firstName').optional().trim(),
  body('lastName').optional().trim(),
  body('email').optional().isEmail().normalizeEmail(),
  body('role').optional().isIn(['customer', 'hotel_owner', 'admin']),
  body('phone').optional().trim(),
  body('isActive').optional().isBoolean(),
  body('isApproved').optional().isBoolean()
], validate, asyncHandler(async (req, res) => {
  const updateData = { ...req.body };
  
  // Don't allow password updates through this endpoint
  delete updateData.password;
  delete updateData.refreshToken;
  
  // Check if email is being updated and if it's already taken
  if (updateData.email) {
    const existingUser = await User.findOne({ 
      email: updateData.email, 
      _id: { $ne: req.params.id } 
    });
    if (existingUser) {
      return res.status(400).json({ message: 'Email already in use' });
    }
  }
  
  const user = await User.findByIdAndUpdate(
    req.params.id,
    updateData,
    { new: true }
  ).select('-password -refreshToken');
  
  if (!user) {
    return res.status(404).json({ message: 'User not found' });
  }
  
  res.json({
    message: 'User updated successfully',
    user
  });
})); 

// @desc    Delete user
// @route   DELETE /api/admin/users/:id
// @access  Private (Admin only)
router.delete('/users/:id', authenticate, authorize('admin'), asyncHandler(async (req, res) => {
  const { id } = req.params;
  
  // Prevent admin from deleting themselves
  if (id === req.user.id) {
    return res.status(400).json({ message: 'You cannot delete your own account' });
  }
  
  const user = await User.findById(id);
  if (!user) {
    return res.status(404).json({ message: 'User not found' });
  }
  
  // Check if user has active bookings
  const activeBookings = await require('../models/Booking').countDocuments({ 
    user: id, 
    status: { $in: ['confirmed', 'checked-in'] } 
  });
  
  if (activeBookings > 0) {
    return res.status(400).json({ 
      message: 'Cannot delete user with active bookings. Please cancel or complete bookings first.' 
    });
  }
  
  await User.findByIdAndDelete(id);
  
  res.json({ message: 'User deleted successfully' });
}));

// @desc    Update user password (Admin only)
// @route   PATCH /api/admin/users/:id/password
// @access  Private (Admin only)
router.patch('/users/:id/password', authenticate, authorize('admin'), [
  body('newPassword').isLength({ min: 6 }).withMessage('Password must be at least 6 characters')
], validate, asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { newPassword } = req.body;
  
  const user = await User.findById(id);
  if (!user) {
    return res.status(404).json({ message: 'User not found' });
  }
  
  // Hash new password
  const hashedPassword = await bcrypt.hash(newPassword, 12);
  user.password = hashedPassword;
  
  // Clear any existing refresh tokens to force re-login
  user.refreshToken = undefined;
  
  await user.save();
  
  res.json({ message: 'Password updated successfully' });
}));

// @desc    Get all hotels (Admin management)
// @route   GET /api/admin/hotels
// @access  Private (Admin only)
router.get('/hotels', authenticate, authorize('admin'), [
  query('page').optional().isInt({ min: 1 }),
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('isApproved').optional().isBoolean(),
  query('isActive').optional().isBoolean(),
  query('starRating').optional().isInt({ min: 3, max: 5 }),
  query('search').optional().trim()
], validate, asyncHandler(async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 20;
  const skip = (page - 1) * limit;
  
  let query = {};
  
  if (req.query.isApproved !== undefined) query.isApproved = req.query.isApproved === 'true';
  if (req.query.isActive !== undefined) query.isActive = req.query.isActive === 'true';
  if (req.query.starRating !== undefined) query.starRating = parseInt(req.query.starRating);
  
  if (req.query.search) {
    query.$or = [
      { name: { $regex: req.query.search, $options: 'i' } },
      { 'address.city': { $regex: req.query.search, $options: 'i' } }
    ];
  }
  
  const hotels = await Hotel.find(query)
    .populate('owner', 'firstName lastName email')
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit);
  
  const total = await Hotel.countDocuments(query);
  
  res.json({
    hotels,
    pagination: {
      page,
      limit,
      total,
      pages: Math.ceil(total / limit)
    }
  });
}));

// @desc    Get rooms for a hotel (Admin)
// @route   GET /api/admin/hotels/:id/rooms
// @access  Private (Admin only)
router.get('/hotels/:id/rooms', authenticate, authorize('admin'), asyncHandler(async (req, res) => {
  const hotelId = req.params.id;
  const hotel = await Hotel.findById(hotelId);
  if (!hotel) {
    return res.status(404).json({ message: 'Hotel not found' });
  }
  const rooms = await require('../models/Room').find({ hotel: hotelId }).sort({ name: 1 });
  res.json({ rooms });
}));

// @desc    Approve/Reject hotel
// @route   PATCH /api/admin/hotels/:id/approval
// @access  Private (Admin only)
router.patch('/hotels/:id/approval', authenticate, authorize('admin'), [
  body('isApproved').isBoolean().withMessage('Approval status is required'),
  body('rejectionReason').optional().trim()
], validate, asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { isApproved, rejectionReason } = req.body;
  
  const hotel = await Hotel.findById(id).populate('owner', 'firstName lastName email');
  if (!hotel) {
    return res.status(404).json({ message: 'Hotel not found' });
  }
  
  hotel.isApproved = isApproved;
  
  if (!isApproved && rejectionReason) {
    // Could store rejection reason in a separate field or notification system
    console.log(`Hotel ${hotel.name} rejected. Reason: ${rejectionReason}`);
  }
  
  await hotel.save();
  
  // Here you would typically send an email notification to the hotel owner
  
  res.json({
    message: `Hotel ${isApproved ? 'approved' : 'rejected'} successfully`,
    hotel: {
      id: hotel._id,
      name: hotel.name,
      isApproved: hotel.isApproved,
      owner: hotel.owner
    }
  });
}));

// @desc    Get all bookings (Admin management)
// @route   GET /api/admin/bookings
// @access  Private (Admin only)
router.get('/bookings', authenticate, authorize('admin'), [
  query('page').optional().isInt({ min: 1 }),
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('status').optional().isIn(['pending', 'confirmed', 'cancelled', 'checked_in', 'checked_out', 'no_show']),
  query('paymentStatus').optional().isIn(['pending', 'paid', 'failed', 'refunded', 'partial_refund']),
  query('startDate').optional().isISO8601(),
  query('endDate').optional().isISO8601(),
  query('search').optional().trim()
], validate, asyncHandler(async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 20;
  const skip = (page - 1) * limit;
  
  let query = {};
  
  if (req.query.status) query.status = req.query.status;
  if (req.query.paymentStatus) query.paymentStatus = req.query.paymentStatus;
  
  if (req.query.startDate && req.query.endDate) {
    query.checkIn = {
      $gte: new Date(req.query.startDate),
      $lte: new Date(req.query.endDate)
    };
  }
  
  // Basic search on bookingNumber or transactionId (booking/customer/hotel text requires aggregation)
  if (req.query.search) {
    const regex = new RegExp(req.query.search, 'i');
    query.$or = [
      { bookingNumber: { $regex: regex } },
      { transactionId: { $regex: regex } }
    ];
  }

  const bookings = await Booking.find(query)
    .populate('customer', 'firstName lastName email')
    .populate('hotel', 'name')
    .populate('room', 'name type')
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit);
  
  const total = await Booking.countDocuments(query);
  
  res.json({
    bookings,
    pagination: {
      page,
      limit,
      total,
      pages: Math.ceil(total / limit)
    }
  });
}));

// @desc    Get all reviews (Admin management)
// @route   GET /api/admin/reviews
// @access  Private (Admin only)
router.get('/reviews', authenticate, authorize('admin'), [
  query('page').optional().isInt({ min: 1 }),
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('isApproved').optional().isBoolean(),
  query('isVisible').optional().isBoolean(),
  query('flagged').optional().isBoolean(),
  query('rating').optional().isInt({ min: 1, max: 5 }),
  query('search').optional().trim(),
  query('sortBy').optional().isIn(['newest','oldest','highest_rating','lowest_rating'])
], validate, asyncHandler(async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 20;
  const skip = (page - 1) * limit;
  
  let query = {};
  
  if (req.query.isApproved !== undefined) query.isApproved = req.query.isApproved === 'true';
  if (req.query.isVisible !== undefined) query.isVisible = req.query.isVisible === 'true';
  if (req.query.flagged === 'true') query.flags = { $exists: true, $not: { $size: 0 } };
  if (req.query.rating !== undefined) query.rating = parseInt(req.query.rating);
  if (req.query.search) {
    const regex = new RegExp(req.query.search, 'i');
    query.$or = [
      { title: { $regex: regex } },
      { comment: { $regex: regex } }
    ];
  }

  let sort = { createdAt: -1 };
  switch (req.query.sortBy) {
    case 'oldest':
      sort = { createdAt: 1 };
      break;
    case 'highest_rating':
      sort = { rating: -1 };
      break;
    case 'lowest_rating':
      sort = { rating: 1 };
      break;
    default:
      sort = { createdAt: -1 };
  }

  const reviews = await Review.find(query)
    .populate('customer', 'firstName lastName')
    .populate('hotel', 'name')
    .sort(sort)
    .skip(skip)
    .limit(limit);
  
  const total = await Review.countDocuments(query);
  
  res.json({
    reviews,
    pagination: {
      page,
      limit,
      total,
      pages: Math.ceil(total / limit)
    }
  });
}));

// @desc    Moderate review
// @route   PATCH /api/admin/reviews/:id/moderate
// @access  Private (Admin only)
router.patch('/reviews/:id/moderate', authenticate, authorize('admin'), [
  body('isApproved').optional().isBoolean(),
  body('isVisible').optional().isBoolean(),
  body('moderationNote').optional().trim()
], validate, asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { isApproved, isVisible, moderationNote } = req.body;
  
  const review = await Review.findById(id);
  if (!review) {
    return res.status(404).json({ message: 'Review not found' });
  }
  
  if (isApproved !== undefined) review.isApproved = isApproved;
  if (isVisible !== undefined) review.isVisible = isVisible;
  
  await review.save();
  
  res.json({
    message: 'Review moderated successfully',
    review: {
      id: review._id,
      isApproved: review.isApproved,
      isVisible: review.isVisible
    }
  });
}));

// @desc    Get system reports
// @route   GET /api/admin/reports
// @access  Private (Admin only)
router.get('/reports', authenticate, authorize('admin'), [
  query('type').optional().isIn(['revenue', 'bookings', 'users', 'hotels']),
  query('period').optional().isIn(['week', 'month', 'quarter', 'year']),
  query('startDate').optional().isISO8601(),
  query('endDate').optional().isISO8601()
], validate, asyncHandler(async (req, res) => {
  const { type = 'revenue', period = 'month' } = req.query;
  
  let startDate, endDate;
  
  if (req.query.startDate && req.query.endDate) {
    startDate = new Date(req.query.startDate);
    endDate = new Date(req.query.endDate);
  } else {
    // Default to last month
    endDate = new Date();
    startDate = new Date();
    
    switch (period) {
      case 'week':
        startDate.setDate(startDate.getDate() - 7);
        break;
      case 'quarter':
        startDate.setMonth(startDate.getMonth() - 3);
        break;
      case 'year':
        startDate.setFullYear(startDate.getFullYear() - 1);
        break;
      default: // month
        startDate.setMonth(startDate.getMonth() - 1);
    }
  }
  
  let report = {};
  
  switch (type) {
    case 'revenue':
      report = await generateRevenueReport(startDate, endDate);
      break;
    case 'bookings':
      report = await generateBookingsReport(startDate, endDate);
      break;
    case 'users':
      report = await generateUsersReport(startDate, endDate);
      break;
    case 'hotels':
      report = await generateHotelsReport(startDate, endDate);
      break;
  }
  
  res.json({
    type,
    period: { startDate, endDate },
    report
  });
}));

// @desc    Get revenue reports
// @route   GET /api/admin/reports/revenue
// @access  Private (Admin only)
router.get('/reports/revenue', authenticate, authorize('admin'), [
  query('startDate').optional().isISO8601(),
  query('endDate').optional().isISO8601()
], validate, asyncHandler(async (req, res) => {
  let startDate, endDate;
  
  if (req.query.startDate && req.query.endDate) {
    startDate = new Date(req.query.startDate);
    endDate = new Date(req.query.endDate);
  } else {
    endDate = new Date();
    startDate = new Date();
    startDate.setMonth(startDate.getMonth() - 1);
  }
  
  const report = await generateRevenueReport(startDate, endDate);
  
  res.json({
    data: report.dailyBreakdown,
    summary: {
      totalRevenue: report.totalRevenue,
      totalBookings: report.totalBookings,
      averageBookingValue: report.averageBookingValue,
      growth: 0 // TODO: Calculate growth rate
    }
  });
}));

// @desc    Get bookings reports
// @route   GET /api/admin/reports/bookings
// @access  Private (Admin only)
router.get('/reports/bookings', authenticate, authorize('admin'), [
  query('startDate').optional().isISO8601(),
  query('endDate').optional().isISO8601()
], validate, asyncHandler(async (req, res) => {
  let startDate, endDate;
  
  if (req.query.startDate && req.query.endDate) {
    startDate = new Date(req.query.startDate);
    endDate = new Date(req.query.endDate);
  } else {
    endDate = new Date();
    startDate = new Date();
    startDate.setMonth(startDate.getMonth() - 1);
  }
  
  const report = await generateBookingsReport(startDate, endDate);
  
  // Calculate summary from report data
  const totalBookings = report.bookingsByStatus.reduce((sum, item) => sum + item.count, 0);
  const confirmedBookings = report.bookingsByStatus.find(item => item._id === 'confirmed')?.count || 0;
  const cancelledBookings = report.bookingsByStatus.find(item => item._id === 'cancelled')?.count || 0;
  const pendingBookings = report.bookingsByStatus.find(item => item._id === 'pending')?.count || 0;
  
  res.json({
    data: report.bookingsByStatus,
    summary: {
      totalBookings,
      confirmedBookings,
      cancelledBookings,
      pendingBookings
    }
  });
}));

// @desc    Get users reports
// @route   GET /api/admin/reports/users
// @access  Private (Admin only)
router.get('/reports/users', authenticate, authorize('admin'), [
  query('startDate').optional().isISO8601(),
  query('endDate').optional().isISO8601()
], validate, asyncHandler(async (req, res) => {
  let startDate, endDate;
  
  if (req.query.startDate && req.query.endDate) {
    startDate = new Date(req.query.startDate);
    endDate = new Date(req.query.endDate);
  } else {
    endDate = new Date();
    startDate = new Date();
    startDate.setMonth(startDate.getMonth() - 1);
  }
  
  const report = await generateUsersReport(startDate, endDate);
  
  // Calculate new users count  
  const newUsersCount = report.newUsers.reduce((sum, item) => sum + item.count, 0);
  
  res.json({
    data: report.newUsers,
    summary: {
      totalUsers: report.totalUsers,
      activeUsers: report.activeUsers,
      newUsers: newUsersCount,
      growth: 0 // TODO: Calculate growth rate
    }
  });
}));

// @desc    Get hotels reports
// @route   GET /api/admin/reports/hotels
// @access  Private (Admin only)
router.get('/reports/hotels', authenticate, authorize('admin'), [
  query('startDate').optional().isISO8601(),
  query('endDate').optional().isISO8601()
], validate, asyncHandler(async (req, res) => {
  let startDate, endDate;
  
  if (req.query.startDate && req.query.endDate) {
    startDate = new Date(req.query.startDate);
    endDate = new Date(req.query.endDate);
  } else {
    endDate = new Date();
    startDate = new Date();
    startDate.setMonth(startDate.getMonth() - 1);
  }
  
  const report = await generateHotelsReport(startDate, endDate);
  
  // Get total rooms count
  const totalRooms = await Room.countDocuments();
  
  // Calculate average rating
  const avgRatingResult = await Review.aggregate([
    { $group: { _id: null, averageRating: { $avg: '$rating' } } }
  ]);
  const averageRating = avgRatingResult.length > 0 ? avgRatingResult[0].averageRating : 0;
  
  res.json({
    data: [{
      newHotels: report.newHotels,
      approvedHotels: report.approvedHotels,
      pendingHotels: report.pendingHotels
    }],
    summary: {
      totalHotels: report.totalHotels,
      activeHotels: report.approvedHotels,
      averageRating: Math.round(averageRating * 10) / 10,
      totalRooms: totalRooms
    }
  });
}));

// @desc    Get admin settings
// @route   GET /api/admin/settings
// @access  Private (Admin only)
router.get('/settings', authenticate, authorize('admin'), asyncHandler(async (req, res) => {
  // Mock settings data - you can implement actual settings storage later
  const settings = {
    site: {
      name: 'Hotel Booking System',
      description: 'Professional hotel booking platform',
      logo: null,
      favicon: null,
      contactEmail: 'admin@hotelbooking.com',
      supportEmail: 'support@hotelbooking.com'
    },
    booking: {
      allowCancellation: true,
      cancellationDeadline: 24, // hours
      requireEmailVerification: true,
      maxBookingDays: 365,
      autoConfirmBookings: false
    },
    payment: {
      currency: 'VND',
      taxRate: 10, // percentage
      servicesFee: 5, // percentage
      enableVNPay: true,
      enableStripe: true,
      enablePaypal: false
    },
    notification: {
      emailNotifications: true,
      smsNotifications: false,
      pushNotifications: true,
      bookingConfirmation: true,
      bookingReminder: true,
      cancellationNotification: true
    },
    maintenance: {
      maintenanceMode: false,
      maintenanceMessage: 'We are currently under maintenance. Please check back later.',
      allowedIPs: []
    }
  };
  
  res.json(settings);
}));

// @desc    Update admin settings
// @route   PUT /api/admin/settings
// @access  Private (Admin only)
router.put('/settings', authenticate, authorize('admin'), asyncHandler(async (req, res) => {
  // Mock settings update - implement actual storage later
  const updatedSettings = req.body;
  
  res.json({
    message: 'Settings updated successfully',
    settings: updatedSettings
  });
}));

// Helper functions for reports
async function generateRevenueReport(startDate, endDate) {
  const revenue = await Booking.aggregate([
    {
      $match: {
        createdAt: { $gte: startDate, $lte: endDate },
        paymentStatus: 'paid'
      }
    },
    {
      $group: {
        _id: {
          year: { $year: '$createdAt' },
          month: { $month: '$createdAt' },
          day: { $dayOfMonth: '$createdAt' }
        },
        totalRevenue: { $sum: '$totalAmount' },
        bookingCount: { $sum: 1 }
      }
    },
    { $sort: { '_id.year': 1, '_id.month': 1, '_id.day': 1 } }
  ]);
  
  const totalRevenue = revenue.reduce((sum, item) => sum + item.totalRevenue, 0);
  const totalBookings = revenue.reduce((sum, item) => sum + item.bookingCount, 0);
  
  return {
    totalRevenue,
    totalBookings,
    averageBookingValue: totalBookings > 0 ? totalRevenue / totalBookings : 0,
    dailyBreakdown: revenue
  };
}

async function generateBookingsReport(startDate, endDate) {
  const bookings = await Booking.aggregate([
    {
      $match: {
        createdAt: { $gte: startDate, $lte: endDate }
      }
    },
    {
      $group: {
        _id: '$status',
        count: { $sum: 1 }
      }
    }
  ]);
  
  const paymentStats = await Booking.aggregate([
    {
      $match: {
        createdAt: { $gte: startDate, $lte: endDate }
      }
    },
    {
      $group: {
        _id: '$paymentStatus',
        count: { $sum: 1 }
      }
    }
  ]);
  
  return {
    bookingsByStatus: bookings,
    paymentStats
  };
}

async function generateUsersReport(startDate, endDate) {
  const newUsers = await User.aggregate([
    {
      $match: {
        createdAt: { $gte: startDate, $lte: endDate }
      }
    },
    {
      $group: {
        _id: '$role',
        count: { $sum: 1 }
      }
    }
  ]);
  
  const totalUsers = await User.countDocuments();
  const activeUsers = await User.countDocuments({ isActive: true });
  
  return {
    newUsers,
    totalUsers,
    activeUsers,
    inactiveUsers: totalUsers - activeUsers
  };
}

async function generateHotelsReport(startDate, endDate) {
  const newHotels = await Hotel.countDocuments({
    createdAt: { $gte: startDate, $lte: endDate }
  });
  
  const approvedHotels = await Hotel.countDocuments({ isApproved: true });
  const pendingHotels = await Hotel.countDocuments({ isApproved: false });
  
  return {
    newHotels,
    approvedHotels,
    pendingHotels,
    totalHotels: approvedHotels + pendingHotels
  };
}

// @desc    Get hotel owner dashboard statistics
// @route   GET /api/admin/dashboard/stats
// @access  Private (Hotel Owner only)
router.get('/dashboard/stats', authenticate, authorize('hotel_owner'), asyncHandler(async (req, res) => {
  const userId = req.user.id;
  
  // Get user's hotels
  const userHotels = await Hotel.find({ owner: userId });
  const hotelIds = userHotels.map(hotel => hotel._id);
  
  if (hotelIds.length === 0) {
    return res.json({
      success: true,
      data: {
        totalBookings: 0,
        pendingBookings: 0,
        confirmedBookings: 0,
        activeBookings: 0,
        completedBookings: 0,
        totalRevenue: 0,
        monthlyRevenue: 0,
        averageRating: 0,
        totalReviews: 0,
        totalHotels: 0,
        totalRooms: 0,
        occupancyRate: 0
      }
    });
  }
  
  // Get all rooms for user's hotels
  const rooms = await Room.find({ hotel: { $in: hotelIds } });
  const roomIds = rooms.map(room => room._id);
  
  // Get booking statistics
  const totalBookings = await Booking.countDocuments({ room: { $in: roomIds } });
  const pendingBookings = await Booking.countDocuments({ 
    room: { $in: roomIds }, 
    status: 'pending' 
  });
  const confirmedBookings = await Booking.countDocuments({ 
    room: { $in: roomIds }, 
    status: 'confirmed' 
  });
  const activeBookings = await Booking.countDocuments({ 
    room: { $in: roomIds }, 
    status: 'checked_in' 
  });
  const completedBookings = await Booking.countDocuments({ 
    room: { $in: roomIds }, 
    status: 'checked_out' 
  });
  
  // Get revenue statistics
  const revenueData = await Booking.aggregate([
    { $match: { room: { $in: roomIds }, paymentStatus: 'paid' } },
    { 
      $group: { 
        _id: null, 
        totalRevenue: { $sum: '$totalAmount' } 
      } 
    }
  ]);
  const totalRevenue = revenueData.length > 0 ? revenueData[0].totalRevenue : 0;
  
  // Get monthly revenue (current month)
  const startOfMonth = new Date();
  startOfMonth.setDate(1);
  startOfMonth.setHours(0, 0, 0, 0);
  
  const monthlyRevenueData = await Booking.aggregate([
    { 
      $match: { 
        room: { $in: roomIds }, 
        paymentStatus: 'paid',
        createdAt: { $gte: startOfMonth }
      } 
    },
    { 
      $group: { 
        _id: null, 
        monthlyRevenue: { $sum: '$totalAmount' } 
      } 
    }
  ]);
  const monthlyRevenue = monthlyRevenueData.length > 0 ? monthlyRevenueData[0].monthlyRevenue : 0;
  
  // Get review statistics
  const reviewData = await Review.aggregate([
    { $match: { hotel: { $in: hotelIds } } },
    { 
      $group: { 
        _id: null, 
        averageRating: { $avg: '$rating' },
        totalReviews: { $sum: 1 }
      } 
    }
  ]);
  const averageRating = reviewData.length > 0 ? reviewData[0].averageRating : 0;
  const totalReviews = reviewData.length > 0 ? reviewData[0].totalReviews : 0;
  
  // Calculate occupancy rate (simplified)
  const totalRooms = rooms.length;
  const occupancyRate = totalRooms > 0 ? (activeBookings / totalRooms) * 100 : 0;
  
  res.json({
    success: true,
    data: {
      totalBookings,
      pendingBookings,
      confirmedBookings,
      activeBookings,
      completedBookings,
      totalRevenue,
      monthlyRevenue,
      averageRating: Number(averageRating.toFixed(1)),
      totalReviews,
      totalHotels: userHotels.length,
      totalRooms,
      occupancyRate: Number(occupancyRate.toFixed(1))
    }
  });
}));

module.exports = router;
