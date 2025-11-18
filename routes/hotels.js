const express = require('express');
const { body, query } = require('express-validator');
const Hotel = require('../models/Hotel');
const Room = require('../models/Room');
const Review = require('../models/Review');
const { authenticate, authorize, requireApprovedHotelOwner } = require('../middleware/auth');
const { validate, asyncHandler } = require('../middleware/validation');

const router = express.Router();

// Hotel validation rules
const hotelValidation = [
  body('name').notEmpty().trim().withMessage('Hotel name is required'),
  body('description').notEmpty().trim().withMessage('Description is required'),
  body('starRating').isInt({ min: 3, max: 5 }).withMessage('Star rating must be between 3 and 5'),
  body('address.street').notEmpty().withMessage('Street address is required'),
  body('address.city').notEmpty().withMessage('City is required'),
  body('address.country').notEmpty().withMessage('Country is required'),
  body('phone').isMobilePhone().withMessage('Valid phone number is required'),
  body('email').isEmail().withMessage('Valid email is required')
];

// Additional validation for admin creating hotels
const adminHotelValidation = [
  ...hotelValidation,
  body('owner').optional().isMongoId().withMessage('Owner must be a valid user ID'),
  body('isApproved').optional().isBoolean().withMessage('isApproved must be a boolean')
];

// @desc    Get all hotels
// @route   GET /api/hotels
// @access  Public
router.get('/', [
  query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 50 }).withMessage('Limit must be between 1 and 50'),
  query('search').optional().trim(),
  query('city').optional().trim(),
  query('starRating').optional().isInt({ min: 3, max: 5 }),
  query('minPrice').optional().isNumeric(),
  query('maxPrice').optional().isNumeric(),
  query('amenities').optional(),
  query('sortBy').optional().isIn(['price_low', 'price_high', 'rating', 'name', 'relevance'])
], validate, asyncHandler(async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10;
  const skip = (page - 1) * limit;
  const minPrice = req.query.minPrice ? parseFloat(req.query.minPrice) : null;
  const maxPrice = req.query.maxPrice ? parseFloat(req.query.maxPrice) : null;
  const minRating = req.query.minRating ? parseFloat(req.query.minRating) : null;
  const amenitiesFilter = req.query.amenities
    ? req.query.amenities.split(',').map(a => a.trim().toLowerCase()).filter(Boolean)
    : [];
  
  // Build query
  let query = { isApproved: true, isActive: true };
  
  // Search by name or description
  if (req.query.search) {
    const searchRegex = { $regex: req.query.search, $options: 'i' };
    query.$or = [
      { name: searchRegex },
      { description: searchRegex },
      { 'address.city': searchRegex },
      { 'address.country': searchRegex }
    ];
  }
  
  // Filter by city
  if (req.query.city) {
    query['address.city'] = { $regex: req.query.city, $options: 'i' };
  }
  
  // Filter by star rating
  if (req.query.starRating) {
    query.starRating = parseInt(req.query.starRating);
  }

  if (minRating !== null && !isNaN(minRating)) {
    query.averageRating = {
      ...(query.averageRating || {}),
      $gte: minRating
    };
  }
  
  // Filter by amenities
  if (amenitiesFilter.length) {
    query.amenities = { $all: amenitiesFilter };
  }
  
  // Sort options
  let sort = { createdAt: -1 };
  let priceSort = null;
  switch (req.query.sortBy) {
    case 'rating':
      sort = { averageRating: -1 };
      break;
    case 'name':
      sort = { name: 1 };
      break;
    case 'price_low':
      priceSort = 'asc';
      break;
    case 'price_high':
      priceSort = 'desc';
      break;
    default:
      sort = { createdAt: -1 };
  }
  
  const hotels = await Hotel.find(query)
    .populate('owner', 'firstName lastName')
    .sort(sort)
    .lean();
  
  // Get room price range for each hotel
  for (let hotel of hotels) {
    const rooms = await Room.find({ hotel: hotel._id, isActive: true })
      .select('basePrice weekendPrice currency')
      .sort({ basePrice: 1 });
    
    if (rooms.length > 0) {
      hotel.priceRange = {
        min: rooms[0].basePrice,
        max: rooms[rooms.length - 1].basePrice
      };
      hotel.startingPrice = rooms[0].basePrice;
      hotel.currency = rooms[0].currency || hotel.currency || 'VND';
    } else {
      hotel.startingPrice = 0;
      hotel.currency = hotel.currency || 'VND';
    }
  }

  let filteredHotels = hotels;
  if ((minPrice !== null && !isNaN(minPrice)) || (maxPrice !== null && !isNaN(maxPrice))) {
    filteredHotels = filteredHotels.filter(hotel => {
      const price = typeof hotel.startingPrice === 'number' ? hotel.startingPrice : 0;
      if (minPrice !== null && !isNaN(minPrice) && price < minPrice) {
        return false;
      }
      if (maxPrice !== null && !isNaN(maxPrice) && price > maxPrice) {
        return false;
      }
      return true;
    });
  }

  if (priceSort) {
    filteredHotels.sort((a, b) => {
      const priceA = typeof a.startingPrice === 'number' ? a.startingPrice : 0;
      const priceB = typeof b.startingPrice === 'number' ? b.startingPrice : 0;
      return priceSort === 'asc' ? priceA - priceB : priceB - priceA;
    });
  }

  const total = filteredHotels.length;
  const paginatedHotels = filteredHotels.slice(skip, skip + limit);
  
  res.json({
    success: true,
    data: paginatedHotels,
    pagination: {
      page,
      limit,
      total,
      pages: Math.ceil(total / limit)
    }
  });
}));

// @desc    Get featured hotels
// @route   GET /api/hotels/featured
// @access  Public
router.get('/featured', asyncHandler(async (req, res) => {
  const limit = parseInt(req.query.limit) || 8;
  
  const featuredHotels = await Hotel.find({
    isApproved: true,
    isActive: true,
    averageRating: { $gte: 4.0 }
  })
  .sort({ averageRating: -1, totalReviews: -1 })
  .limit(limit)
  .populate('owner', 'firstName lastName')
  .lean(); // Add .lean() to get plain objects
  
  // Add starting price for each hotel
  for (let hotel of featuredHotels) {
    const rooms = await Room.find({ hotel: hotel._id, isActive: true })
      .select('basePrice')
      .sort({ basePrice: 1 });
    
    if (rooms.length > 0) {
      hotel.startingPrice = rooms[0].basePrice;
      hotel.priceRange = {
        min: rooms[0].basePrice,
        max: rooms[rooms.length - 1].basePrice
      };
    } else {
      hotel.startingPrice = 0;
      hotel.priceRange = { min: 0, max: 0 };
    }
  }
  
  res.json({ 
    success: true,
    data: featuredHotels,
    count: featuredHotels.length
  });
}));

// @desc    Get hotels owned by current user
// @route   GET /api/hotels/my-hotels
// @access  Private (Hotel Owner only)
router.get('/my-hotels', authenticate, authorize('hotel_owner'), asyncHandler(async (req, res) => {
  const hotels = await Hotel.find({ owner: req.user.id })
    .populate('owner', 'firstName lastName email')
    .sort({ createdAt: -1 });
  
  // Calculate additional stats for each hotel
  const hotelsWithStats = await Promise.all(hotels.map(async (hotel) => {
    const hotelObj = hotel.toObject();
    
    // Get room count
    const roomCount = await Room.countDocuments({ hotel: hotel._id });
    
    // Get average rating
    const ratingData = await Review.aggregate([
      { $match: { hotel: hotel._id } },
      { $group: { _id: null, avgRating: { $avg: '$rating' }, totalReviews: { $sum: 1 } } }
    ]);
    
    hotelObj.roomCount = roomCount;
    hotelObj.averageRating = ratingData.length > 0 ? ratingData[0].avgRating : 0;
    hotelObj.totalReviews = ratingData.length > 0 ? ratingData[0].totalReviews : 0;
    
    return hotelObj;
  }));
  
  res.json({
    success: true,
    data: hotelsWithStats
  });
}));

// @desc    Get hotel by ID or slug
// @route   GET /api/hotels/:id
// @access  Public (with optional authentication for owners)
router.get('/:id', (req, res, next) => {
  // Optional authentication - don't throw error if no token
  const authHeader = req.header('Authorization');
  if (authHeader && authHeader.startsWith('Bearer ')) {
    // Try to authenticate but don't fail if invalid
    const token = authHeader.substring(7);
    try {
      const jwt = require('jsonwebtoken');
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const User = require('../models/User');
      User.findById(decoded.id).select('-password').then(user => {
        req.user = user;
        next();
      }).catch(() => next()); // Continue without auth if user not found
    } catch (error) {
      next(); // Continue without auth if token invalid
    }
  } else {
    next(); // Continue without auth if no token
  }
}, asyncHandler(async (req, res) => {
  const { id } = req.params;
  
  // Try to find by ID first, then by slug
  let hotel = await Hotel.findById(id).populate('owner', 'firstName lastName email phone');
  
  if (!hotel) {
    hotel = await Hotel.findOne({ slug: id }).populate('owner', 'firstName lastName email phone');
  }
  
  if (!hotel) {
    return res.status(404).json({ 
      success: false,
      message: 'Hotel not found' 
    });
  }

  // Check if user is authenticated and is the owner or admin
  const isOwnerOrAdmin = req.user && 
    (req.user.role === 'admin' || 
     (req.user.role === 'hotel_owner' && hotel.owner._id.toString() === req.user._id.toString()));

  // For public access, only show approved and active hotels
  if (!isOwnerOrAdmin && (!hotel.isApproved || !hotel.isActive)) {
    return res.status(404).json({ 
      success: false,
      message: 'Hotel not found' 
    });
  }
  
  // Get rooms
  const rooms = await Room.find({ hotel: hotel._id, isActive: true })
    .sort({ basePrice: 1 });
  
  // Get reviews with pagination
  const reviews = await Review.find({ hotel: hotel._id, isVisible: true })
    .populate('customer', 'firstName lastName')
    .sort({ createdAt: -1 })
    .limit(10);
  
  res.json({
    success: true,
    data: hotel.toObject(),
    rooms,
    reviews
  });
}));

// @desc    Create hotel
// @route   POST /api/hotels
// @access  Private (Hotel Owner or Admin)
router.post('/', authenticate, authorize('hotel_owner', 'admin'), (req, res, next) => {
  // Use different validation based on user role
  const validationRules = req.user.role === 'admin' ? adminHotelValidation : hotelValidation;
  
  // Apply validation
  Promise.all(validationRules.map(validation => validation.run(req)))
    .then(() => validate(req, res, next))
    .catch(next);
}, asyncHandler(async (req, res) => {
  // For hotel_owner, check if approved (except admin)
  if (req.user.role === 'hotel_owner' && !req.user.isApproved) {
    return res.status(403).json({ 
      message: 'Your hotel owner account is pending approval.' 
    });
  }
  
  // Validate owner exists if specified by admin
  if (req.user.role === 'admin' && req.body.owner) {
    const User = require('../models/User');
    const ownerUser = await User.findById(req.body.owner);
    if (!ownerUser) {
      return res.status(400).json({ message: 'Specified owner user not found' });
    }
    if (ownerUser.role !== 'hotel_owner') {
      return res.status(400).json({ message: 'Specified user is not a hotel owner' });
    }
  }
  
  const hotelData = {
    ...req.body,
    owner: req.body.owner || req.user._id // Admin can specify owner, hotel_owner uses their own ID
  };
  
  // If admin creates hotel, it can be auto-approved
  if (req.user.role === 'admin') {
    hotelData.isApproved = req.body.isApproved !== undefined ? req.body.isApproved : true;
  }
  
  const hotel = new Hotel(hotelData);
  await hotel.save();
  
  const message = req.user.role === 'admin' 
    ? 'Hotel created successfully.' 
    : 'Hotel created successfully. Pending admin approval.';
  
  res.status(201).json({
    success: true,
    message,
    data: hotel
  });
}));

// @desc    Update hotel
// @route   PUT /api/hotels/:id
// @access  Private (Hotel Owner/Admin)
router.put('/:id', authenticate, hotelValidation, validate, asyncHandler(async (req, res) => {
  const hotel = await Hotel.findById(req.params.id);
  
  if (!hotel) {
    return res.status(404).json({ message: 'Hotel not found' });
  }
  
  // Check authorization
  if (req.user.role !== 'admin' && hotel.owner.toString() !== req.user._id.toString()) {
    return res.status(403).json({ message: 'Access denied' });
  }
  
  // If hotel owner is updating, reset approval status
  if (req.user.role === 'hotel_owner') {
    req.body.isApproved = false;
  }
  
  const updatedHotel = await Hotel.findByIdAndUpdate(
    req.params.id,
    req.body,
    { new: true, runValidators: true }
  );
  
  res.json({
    success: true,
    message: req.user.role === 'hotel_owner' 
      ? 'Hotel updated successfully. Pending admin approval.' 
      : 'Hotel updated successfully.',
    data: updatedHotel
  });
}));

// @desc    Toggle hotel status (active/inactive)
// @route   PATCH /api/hotels/:id/toggle-status
// @access  Private (Hotel Owner/Admin)
router.patch('/:id/toggle-status', authenticate, asyncHandler(async (req, res) => {
  const hotel = await Hotel.findById(req.params.id);
  
  if (!hotel) {
    return res.status(404).json({ message: 'Hotel not found' });
  }
  
  // Check authorization
  if (req.user.role !== 'admin' && hotel.owner.toString() !== req.user._id.toString()) {
    return res.status(403).json({ message: 'Access denied' });
  }
  
  // Toggle status
  hotel.isActive = !hotel.isActive;
  await hotel.save();
  
  res.json({ 
    success: true,
    message: `Hotel ${hotel.isActive ? 'activated' : 'deactivated'} successfully`,
    data: hotel
  });
}));

// @desc    Delete hotel permanently
// @route   DELETE /api/hotels/:id
// @access  Private (Hotel Owner/Admin)
router.delete('/:id', authenticate, asyncHandler(async (req, res) => {
  const hotel = await Hotel.findById(req.params.id);
  
  if (!hotel) {
    return res.status(404).json({ message: 'Hotel not found' });
  }
  
  // Check authorization
  if (req.user.role !== 'admin' && hotel.owner.toString() !== req.user._id.toString()) {
    return res.status(403).json({ message: 'Access denied' });
  }
  
  // Delete related data first
  await Room.deleteMany({ hotel: req.params.id });
  await Review.deleteMany({ hotel: req.params.id });
  
  // Delete hotel permanently
  await Hotel.findByIdAndDelete(req.params.id);
  
  res.json({ 
    success: true,
    message: 'Hotel deleted permanently' 
  });
}));

// @desc    Get hotels by owner
// @route   GET /api/hotels/owner/:userId
// @access  Private (Hotel Owner/Admin)
router.get('/owner/:userId', authenticate, asyncHandler(async (req, res) => {
  const { userId } = req.params;
  
  // Check authorization
  if (req.user.role !== 'admin' && req.user._id.toString() !== userId) {
    return res.status(403).json({ message: 'Access denied' });
  }
  
  const hotels = await Hotel.find({ owner: userId })
    .populate('owner', 'firstName lastName')
    .sort({ createdAt: -1 });
  
  res.json({ hotels });
}));

// @desc    Search hotels
// @route   GET /api/hotels/search/advanced
// @access  Public
router.get('/search/advanced', [
  query('checkIn').optional().isISO8601().withMessage('Invalid check-in date'),
  query('checkOut').optional().isISO8601().withMessage('Invalid check-out date'),
  query('guests').optional().isInt({ min: 1 }).withMessage('Guests must be at least 1'),
  query('location').optional().trim(),
  query('radius').optional().isNumeric()
], validate, asyncHandler(async (req, res) => {
  const { checkIn, checkOut, guests = 1, location, radius = 10 } = req.query;
  
  let hotelQuery = { isApproved: true, isActive: true };
  
  // Location-based search
  if (location) {
    hotelQuery.$or = [
      { 'address.city': { $regex: location, $options: 'i' } },
      { 'address.state': { $regex: location, $options: 'i' } },
      { 'address.country': { $regex: location, $options: 'i' } }
    ];
  }
  
  const hotels = await Hotel.find(hotelQuery)
    .populate('owner', 'firstName lastName');
  
  // If date range is provided, check room availability
  if (checkIn && checkOut) {
    const availableHotels = [];
    
    for (let hotel of hotels) {
      const rooms = await Room.find({ hotel: hotel._id, isActive: true });
      let hasAvailableRoom = false;
      
      for (let room of rooms) {
        const availability = await room.checkAvailability(checkIn, checkOut, guests);
        if (availability.available) {
          hasAvailableRoom = true;
          break;
        }
      }
      
      if (hasAvailableRoom) {
        availableHotels.push(hotel);
      }
    }
    
    return res.json({ hotels: availableHotels });
  }
  
  res.json({ hotels });
}));

module.exports = router;
