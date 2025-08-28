const express = require('express');
const { body, query } = require('express-validator');
const Review = require('../models/Review');
const Booking = require('../models/Booking');
const Hotel = require('../models/Hotel');
const { authenticate, authorize } = require('../middleware/auth');
const { validate, asyncHandler } = require('../middleware/validation');

const router = express.Router();

// Review validation rules
const reviewValidation = [
  body('booking').isMongoId().withMessage('Valid booking ID is required'),
  body('rating').isInt({ min: 1, max: 5 }).withMessage('Rating must be between 1 and 5'),
  body('title').notEmpty().trim().isLength({ max: 100 }).withMessage('Title is required and must be less than 100 characters'),
  body('comment').notEmpty().trim().isLength({ max: 1000 }).withMessage('Comment is required and must be less than 1000 characters'),
  body('ratings.cleanliness').optional().isInt({ min: 1, max: 5 }),
  body('ratings.service').optional().isInt({ min: 1, max: 5 }),
  body('ratings.location').optional().isInt({ min: 1, max: 5 }),
  body('ratings.facilities').optional().isInt({ min: 1, max: 5 }),
  body('ratings.valueForMoney').optional().isInt({ min: 1, max: 5 })
];

// @desc    Create review
// @route   POST /api/reviews
// @access  Private (Customer)
router.post('/', authenticate, authorize('customer'), reviewValidation, validate, asyncHandler(async (req, res) => {
  const { booking: bookingId, rating, title, comment, ratings, images } = req.body;
  
  // Check if user can review this booking
  const canReview = await Review.canUserReview(req.user._id, bookingId);
  if (!canReview) {
    return res.status(400).json({ 
      message: 'You cannot review this booking. Either booking not found, not completed, or already reviewed.' 
    });
  }
  
  // Get booking details
  const booking = await Booking.findById(bookingId)
    .populate('hotel', '_id name')
    .populate('customer', '_id');
  
  if (!booking || booking.customer._id.toString() !== req.user._id.toString()) {
    return res.status(404).json({ message: 'Booking not found or access denied' });
  }
  
  // Create review
  const review = new Review({
    customer: req.user._id,
    hotel: booking.hotel._id,
    booking: bookingId,
    rating,
    title,
    comment,
    ratings,
    images: images || []
  });
  
  await review.save();
  
  // Populate review for response
  await review.populate('customer', 'firstName lastName');
  
  res.status(201).json({
    message: 'Review created successfully',
    review
  });
}));

// @desc    Get reviews for hotel
// @route   GET /api/reviews/hotel/:hotelId
// @access  Public
router.get('/hotel/:hotelId', [
  query('page').optional().isInt({ min: 1 }),
  query('limit').optional().isInt({ min: 1, max: 50 }),
  query('rating').optional().isInt({ min: 1, max: 5 }),
  query('sortBy').optional().isIn(['newest', 'oldest', 'highest', 'lowest', 'helpful'])
], validate, asyncHandler(async (req, res) => {
  const { hotelId } = req.params;
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10;
  const skip = (page - 1) * limit;
  
  // Check if hotel exists
  const hotel = await Hotel.findById(hotelId);
  if (!hotel) {
    return res.status(404).json({ message: 'Hotel not found' });
  }
  
  let query = { hotel: hotelId, isVisible: true, isApproved: true };
  
  // Filter by rating
  if (req.query.rating) {
    query.rating = parseInt(req.query.rating);
  }
  
  // Sort options
  let sort = {};
  switch (req.query.sortBy) {
    case 'oldest':
      sort = { createdAt: 1 };
      break;
    case 'highest':
      sort = { rating: -1, createdAt: -1 };
      break;
    case 'lowest':
      sort = { rating: 1, createdAt: -1 };
      break;
    case 'helpful':
      // Note: This would need aggregation for proper helpful score sorting
      sort = { createdAt: -1 };
      break;
    default: // newest
      sort = { createdAt: -1 };
  }
  
  const reviews = await Review.find(query)
    .populate('customer', 'firstName lastName')
    .populate('hotelResponse.respondedBy', 'firstName lastName')
    .sort(sort)
    .skip(skip)
    .limit(limit);
  
  const total = await Review.countDocuments(query);
  
  // Get rating distribution
  const ratingDistribution = await Review.aggregate([
    { $match: { hotel: hotel._id, isVisible: true, isApproved: true } },
    {
      $group: {
        _id: '$rating',
        count: { $sum: 1 }
      }
    },
    { $sort: { _id: -1 } }
  ]);
  
  // Get average detailed ratings
  const averageRatings = await Review.aggregate([
    { $match: { hotel: hotel._id, isVisible: true, isApproved: true } },
    {
      $group: {
        _id: null,
        avgCleanliness: { $avg: '$ratings.cleanliness' },
        avgService: { $avg: '$ratings.service' },
        avgLocation: { $avg: '$ratings.location' },
        avgFacilities: { $avg: '$ratings.facilities' },
        avgValueForMoney: { $avg: '$ratings.valueForMoney' }
      }
    }
  ]);
  
  res.json({
    reviews,
    pagination: {
      page,
      limit,
      total,
      pages: Math.ceil(total / limit)
    },
    statistics: {
      averageRating: hotel.averageRating,
      totalReviews: hotel.totalReviews,
      ratingDistribution,
      averageRatings: averageRatings[0] || {}
    }
  });
}));

// @desc    Get user's reviews
// @route   GET /api/reviews/my
// @access  Private (Customer)
router.get('/my', authenticate, authorize('customer'), [
  query('page').optional().isInt({ min: 1 }),
  query('limit').optional().isInt({ min: 1, max: 50 })
], validate, asyncHandler(async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10;
  const skip = (page - 1) * limit;
  
  const reviews = await Review.find({ customer: req.user._id })
    .populate('hotel', 'name images')
    .populate('booking', 'bookingNumber checkIn checkOut')
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit);
  
  const total = await Review.countDocuments({ customer: req.user._id });
  
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

// @desc    Update review
// @route   PUT /api/reviews/:id
// @access  Private (Customer - own reviews only)
router.put('/:id', authenticate, authorize('customer'), reviewValidation, validate, asyncHandler(async (req, res) => {
  const review = await Review.findById(req.params.id);
  
  if (!review) {
    return res.status(404).json({ message: 'Review not found' });
  }
  
  // Check authorization
  if (review.customer.toString() !== req.user._id.toString()) {
    return res.status(403).json({ message: 'Access denied' });
  }
  
  // Update review
  const { rating, title, comment, ratings, images } = req.body;
  
  review.rating = rating;
  review.title = title;
  review.comment = comment;
  review.ratings = ratings || review.ratings;
  review.images = images || review.images;
  
  await review.save();
  
  res.json({
    message: 'Review updated successfully',
    review
  });
}));

// @desc    Delete review
// @route   DELETE /api/reviews/:id
// @access  Private (Customer - own reviews only)
router.delete('/:id', authenticate, authorize('customer'), asyncHandler(async (req, res) => {
  const review = await Review.findById(req.params.id);
  
  if (!review) {
    return res.status(404).json({ message: 'Review not found' });
  }
  
  // Check authorization
  if (review.customer.toString() !== req.user._id.toString()) {
    return res.status(403).json({ message: 'Access denied' });
  }
  
  await Review.findByIdAndDelete(req.params.id);
  
  res.json({ message: 'Review deleted successfully' });
}));

// @desc    Add hotel response to review
// @route   POST /api/reviews/:id/response
// @access  Private (Hotel Owner)
router.post('/:id/response', authenticate, authorize('hotel_owner'), [
  body('message').notEmpty().trim().isLength({ max: 500 }).withMessage('Response message is required and must be less than 500 characters')
], validate, asyncHandler(async (req, res) => {
  const { message } = req.body;
  
  const review = await Review.findById(req.params.id)
    .populate('hotel', 'owner');
  
  if (!review) {
    return res.status(404).json({ message: 'Review not found' });
  }
  
  // Check authorization - only hotel owner can respond
  if (review.hotel.owner.toString() !== req.user._id.toString()) {
    return res.status(403).json({ message: 'Access denied' });
  }
  
  // Check if already responded
  if (review.hotelResponse && review.hotelResponse.message) {
    return res.status(400).json({ message: 'Review already has a response' });
  }
  
  review.hotelResponse = {
    message,
    respondedAt: new Date(),
    respondedBy: req.user._id
  };
  
  await review.save();
  
  res.json({
    message: 'Response added successfully',
    review
  });
}));

// @desc    Vote on review helpfulness
// @route   POST /api/reviews/:id/vote
// @access  Private
router.post('/:id/vote', authenticate, [
  body('isHelpful').isBoolean().withMessage('isHelpful must be a boolean')
], validate, asyncHandler(async (req, res) => {
  const { isHelpful } = req.body;
  
  const review = await Review.findById(req.params.id);
  
  if (!review) {
    return res.status(404).json({ message: 'Review not found' });
  }
  
  // Check if user already voted
  const existingVoteIndex = review.helpfulVotes.findIndex(
    vote => vote.user.toString() === req.user._id.toString()
  );
  
  if (existingVoteIndex > -1) {
    // Update existing vote
    review.helpfulVotes[existingVoteIndex].isHelpful = isHelpful;
    review.helpfulVotes[existingVoteIndex].votedAt = new Date();
  } else {
    // Add new vote
    review.helpfulVotes.push({
      user: req.user._id,
      isHelpful,
      votedAt: new Date()
    });
  }
  
  await review.save();
  
  res.json({
    message: 'Vote recorded successfully',
    helpfulScore: review.helpfulScore
  });
}));

// @desc    Flag review
// @route   POST /api/reviews/:id/flag
// @access  Private
router.post('/:id/flag', authenticate, [
  body('reason').isIn(['inappropriate', 'spam', 'fake', 'offensive', 'other']).withMessage('Invalid flag reason'),
  body('description').optional().trim().isLength({ max: 200 }).withMessage('Description must be less than 200 characters')
], validate, asyncHandler(async (req, res) => {
  const { reason, description } = req.body;
  
  const review = await Review.findById(req.params.id);
  
  if (!review) {
    return res.status(404).json({ message: 'Review not found' });
  }
  
  // Check if user already flagged this review
  const existingFlag = review.flags.find(
    flag => flag.user.toString() === req.user._id.toString()
  );
  
  if (existingFlag) {
    return res.status(400).json({ message: 'You have already flagged this review' });
  }
  
  review.flags.push({
    user: req.user._id,
    reason,
    description,
    flaggedAt: new Date()
  });
  
  await review.save();
  
  res.json({ message: 'Review flagged successfully' });
}));

// @desc    Get reviews for hotel owner
// @route   GET /api/reviews/hotel-owner/my
// @access  Private (Hotel Owner)
router.get('/hotel-owner/my', authenticate, authorize('hotel_owner'), [
  query('page').optional().isInt({ min: 1 }),
  query('limit').optional().isInt({ min: 1, max: 50 }),
  query('rating').optional().isInt({ min: 1, max: 5 }),
  query('responded').optional().isBoolean()
], validate, asyncHandler(async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10;
  const skip = (page - 1) * limit;
  
  // Get hotels owned by user
  const hotels = await Hotel.find({ owner: req.user._id });
  const hotelIds = hotels.map(hotel => hotel._id);
  
  let query = { hotel: { $in: hotelIds }, isVisible: true };
  
  // Filter by rating
  if (req.query.rating) {
    query.rating = parseInt(req.query.rating);
  }
  
  // Filter by response status
  if (req.query.responded !== undefined) {
    if (req.query.responded === 'true') {
      query['hotelResponse.message'] = { $exists: true, $ne: null };
    } else {
      query.$or = [
        { 'hotelResponse.message': { $exists: false } },
        { 'hotelResponse.message': null }
      ];
    }
  }
  
  const reviews = await Review.find(query)
    .populate('customer', 'firstName lastName')
    .populate('hotel', 'name')
    .populate('booking', 'bookingNumber')
    .sort({ createdAt: -1 })
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

module.exports = router;
