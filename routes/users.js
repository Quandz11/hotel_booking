const express = require('express');
const { body, query } = require('express-validator');
const User = require('../models/User');
const Hotel = require('../models/Hotel');
const Room = require('../models/Room');
const { authenticate, authorize, authorizeOwnerOrAdmin } = require('../middleware/auth');
const { validate, asyncHandler } = require('../middleware/validation');

const router = express.Router();

// @desc    Get user profile
// @route   GET /api/users/:id
// @access  Private (Own profile or Admin)
router.get('/:id', authenticate, asyncHandler(async (req, res) => {
  const { id } = req.params;
  
  // Check authorization
  if (req.user.role !== 'admin' && req.user._id.toString() !== id) {
    return res.status(403).json({ message: 'Access denied' });
  }
  
  const user = await User.findById(id).select('-password -refreshToken');
  
  if (!user) {
    return res.status(404).json({ message: 'User not found' });
  }
  
  res.json({ user });
}));

// @desc    Update user profile
// @route   PUT /api/users/:id
// @access  Private (Own profile or Admin)
router.put('/:id', authenticate, [
  body('firstName').optional().notEmpty().trim(),
  body('lastName').optional().notEmpty().trim(),
  body('phone')
    .optional({ checkFalsy: true })
    .matches(/^\+?[0-9\s\-\(\)]+$/)
    .withMessage('Please provide a valid phone number'),
  body('address.street').optional().trim(),
  body('address.city').optional().trim(),
  body('address.state').optional().trim(),
  body('address.country').optional().trim(),
  body('address.zipCode').optional().trim()
], validate, asyncHandler(async (req, res) => {
  const { id } = req.params;
  
  // Check authorization
  if (req.user.role !== 'admin' && req.user._id.toString() !== id) {
    return res.status(403).json({ message: 'Access denied' });
  }
  
  const user = await User.findById(id);
  
  if (!user) {
    return res.status(404).json({ message: 'User not found' });
  }
  
  // Only allow certain fields to be updated
  const allowedUpdates = ['firstName', 'lastName', 'phone', 'address', 'avatar'];
  const updates = {};
  
  Object.keys(req.body).forEach(key => {
    if (allowedUpdates.includes(key)) {
      updates[key] = req.body[key];
    }
  });
  
  const updatedUser = await User.findByIdAndUpdate(
    id,
    updates,
    { new: true, runValidators: true }
  ).select('-password -refreshToken');
  
  res.json({
    message: 'Profile updated successfully',
    user: updatedUser
  });
}));

// @desc    Change password
// @route   PUT /api/users/:id/password
// @access  Private (Own profile only)
router.put('/:id/password', authenticate, [
  body('currentPassword').notEmpty().withMessage('Current password is required'),
  body('newPassword').isLength({ min: 6 }).withMessage('New password must be at least 6 characters')
], validate, asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { currentPassword, newPassword } = req.body;
  
  // Check authorization - only own password
  if (req.user._id.toString() !== id) {
    return res.status(403).json({ message: 'Access denied' });
  }
  
  const user = await User.findById(id).select('+password');
  
  if (!user) {
    return res.status(404).json({ message: 'User not found' });
  }
  
  // Verify current password
  const isMatch = await user.comparePassword(currentPassword);
  if (!isMatch) {
    return res.status(400).json({ message: 'Current password is incorrect' });
  }
  
  // Update password
  user.password = newPassword;
  await user.save();
  
  res.json({ message: 'Password updated successfully' });
}));

// @desc    Add/Remove hotel from favorites
// @route   POST /api/users/:id/favorites/:hotelId
// @access  Private (Own profile only)
router.post('/:id/favorites/:hotelId', authenticate, asyncHandler(async (req, res) => {
  const { id, hotelId } = req.params;
  
  // Check authorization
  if (req.user._id.toString() !== id || req.user.role !== 'customer') {
    return res.status(403).json({ message: 'Access denied' });
  }
  
  const hotel = await Hotel.findById(hotelId);
  if (!hotel || !hotel.isApproved || !hotel.isActive) {
    return res.status(404).json({ message: 'Hotel not found' });
  }
  
  const user = await User.findById(id);
  const hotelIndex = user.favoriteHotels.indexOf(hotelId);
  
  if (hotelIndex > -1) {
    // Remove from favorites
    user.favoriteHotels.splice(hotelIndex, 1);
    await user.save();
    
    res.json({ 
      message: 'Hotel removed from favorites',
      action: 'removed',
      favoriteHotels: user.favoriteHotels
    });
  } else {
    // Add to favorites
    user.favoriteHotels.push(hotelId);
    await user.save();
    
    res.json({ 
      message: 'Hotel added to favorites',
      action: 'added',
      favoriteHotels: user.favoriteHotels
    });
  }
}));

// @desc    Get user's favorite hotels
// @route   GET /api/users/:id/favorites
// @access  Private (Own profile only)
router.get('/:id/favorites', authenticate, asyncHandler(async (req, res) => {
  const { id } = req.params;
  
  // Check authorization
  if (req.user._id.toString() !== id || req.user.role !== 'customer') {
    return res.status(403).json({ message: 'Access denied' });
  }
  
  const user = await User.findById(id)
    .populate({
      path: 'favoriteHotels',
      match: { isApproved: true, isActive: true },
      select: 'name description address starRating images averageRating totalReviews startingPrice currency',
      options: { lean: true },
    })
    .lean();

  if (!user) {
    return res.status(404).json({ message: 'User not found' });
  }

  const favoriteHotels = user.favoriteHotels || [];

  for (const hotel of favoriteHotels) {
    if (!hotel) continue;

    const room = await Room.findOne({ hotel: hotel._id, isActive: true })
      .select('basePrice currency')
      .sort({ basePrice: 1 })
      .lean();

    if (room) {
      hotel.startingPrice = room.basePrice;
      hotel.currency = room.currency || hotel.currency || 'VND';
    } else {
      hotel.startingPrice = hotel.startingPrice || 0;
      hotel.currency = hotel.currency || 'VND';
    }
  }
  
  res.json({ favoriteHotels });
}));

// @desc    Get user statistics
// @route   GET /api/users/:id/stats
// @access  Private (Own profile or Admin)
router.get('/:id/stats', authenticate, asyncHandler(async (req, res) => {
  const { id } = req.params;
  
  // Check authorization
  if (req.user.role !== 'admin' && req.user._id.toString() !== id) {
    return res.status(403).json({ message: 'Access denied' });
  }
  
  const user = await User.findById(id);
  if (!user) {
    return res.status(404).json({ message: 'User not found' });
  }
  
  let stats = {};
  
  if (user.role === 'customer') {
    const Booking = require('../models/Booking');
    const Review = require('../models/Review');
    
    const bookingStats = await Booking.aggregate([
      { $match: { customer: user._id } },
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 },
          totalAmount: { $sum: '$totalAmount' }
        }
      }
    ]);
    
    const totalReviews = await Review.countDocuments({ customer: user._id });
    
    stats = {
      membershipTier: user.membershipTier,
      totalSpent: user.totalSpent,
      favoriteHotelsCount: user.favoriteHotels.length,
      bookingStats,
      totalReviews
    };
  } else if (user.role === 'hotel_owner') {
    const Room = require('../models/Room');
    const Booking = require('../models/Booking');
    
    const hotels = await Hotel.find({ owner: user._id });
    const hotelIds = hotels.map(h => h._id);
    
    const totalRooms = await Room.countDocuments({ 
      hotel: { $in: hotelIds }, 
      isActive: true 
    });
    
    const bookingStats = await Booking.aggregate([
      { $match: { hotel: { $in: hotelIds } } },
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 },
          totalRevenue: { $sum: '$totalAmount' }
        }
      }
    ]);
    
    stats = {
      totalHotels: hotels.length,
      approvedHotels: hotels.filter(h => h.isApproved).length,
      totalRooms,
      bookingStats
    };
  }
  
  res.json({ stats });
}));

// @desc    Upload user documents (for hotel owners)
// @route   POST /api/users/:id/documents
// @access  Private (Hotel Owner - own profile only)
router.post('/:id/documents', authenticate, authorize('hotel_owner'), [
  body('businessLicense').optional().isURL().withMessage('Business license must be a valid URL'),
  body('identityDocument').optional().isURL().withMessage('Identity document must be a valid URL')
], validate, asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { businessLicense, identityDocument } = req.body;
  
  // Check authorization
  if (req.user._id.toString() !== id) {
    return res.status(403).json({ message: 'Access denied' });
  }
  
  const user = await User.findById(id);
  if (!user) {
    return res.status(404).json({ message: 'User not found' });
  }
  
  // Update documents
  if (businessLicense) user.businessLicense = businessLicense;
  if (identityDocument) user.identityDocument = identityDocument;
  
  // Reset approval status when documents are updated
  user.isApproved = false;
  
  await user.save();
  
  res.json({
    message: 'Documents uploaded successfully. Pending admin approval.',
    user: {
      id: user._id,
      businessLicense: user.businessLicense,
      identityDocument: user.identityDocument,
      isApproved: user.isApproved
    }
  });
}));

// @desc    Deactivate user account
// @route   PATCH /api/users/:id/deactivate
// @access  Private (Own profile or Admin)
router.patch('/:id/deactivate', authenticate, asyncHandler(async (req, res) => {
  const { id } = req.params;
  
  // Check authorization
  if (req.user.role !== 'admin' && req.user._id.toString() !== id) {
    return res.status(403).json({ message: 'Access denied' });
  }
  
  const user = await User.findById(id);
  if (!user) {
    return res.status(404).json({ message: 'User not found' });
  }
  
  user.isActive = false;
  user.refreshToken = undefined; // Log out user
  await user.save();
  
  res.json({ message: 'User account deactivated successfully' });
}));

// @desc    Reactivate user account
// @route   PATCH /api/users/:id/reactivate
// @access  Private (Admin only)
router.patch('/:id/reactivate', authenticate, authorize('admin'), asyncHandler(async (req, res) => {
  const { id } = req.params;
  
  const user = await User.findById(id);
  if (!user) {
    return res.status(404).json({ message: 'User not found' });
  }
  
  user.isActive = true;
  await user.save();
  
  res.json({ message: 'User account reactivated successfully' });
}));

// @desc    Search users (Admin only)
// @route   GET /api/users/search
// @access  Private (Admin only)
router.get('/search', authenticate, authorize('admin'), [
  query('q').optional().trim(),
  query('role').optional().isIn(['customer', 'hotel_owner', 'admin']),
  query('isActive').optional().isBoolean(),
  query('isApproved').optional().isBoolean(),
  query('page').optional().isInt({ min: 1 }),
  query('limit').optional().isInt({ min: 1, max: 100 })
], validate, asyncHandler(async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 20;
  const skip = (page - 1) * limit;
  
  let query = {};
  
  // Search by name or email
  if (req.query.q) {
    query.$or = [
      { firstName: { $regex: req.query.q, $options: 'i' } },
      { lastName: { $regex: req.query.q, $options: 'i' } },
      { email: { $regex: req.query.q, $options: 'i' } }
    ];
  }
  
  // Filter by role
  if (req.query.role) {
    query.role = req.query.role;
  }
  
  // Filter by active status
  if (req.query.isActive !== undefined) {
    query.isActive = req.query.isActive === 'true';
  }
  
  // Filter by approval status
  if (req.query.isApproved !== undefined) {
    query.isApproved = req.query.isApproved === 'true';
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

module.exports = router;

