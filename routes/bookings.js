const express = require('express');
const { body, query } = require('express-validator');
const Booking = require('../models/Booking');
const Room = require('../models/Room');
const Hotel = require('../models/Hotel');
const User = require('../models/User');
const { authenticate, authorize } = require('../middleware/auth');
const { validate, asyncHandler } = require('../middleware/validation');
const { sendBookingConfirmation } = require('../utils/email');

const router = express.Router();

// Booking validation rules
const bookingValidation = [
  body('room').isMongoId().withMessage('Valid room ID is required'),
  body('checkIn').isISO8601().withMessage('Valid check-in date is required'),
  body('checkOut').isISO8601().withMessage('Valid check-out date is required'),
  body('guests.adults').isInt({ min: 1 }).withMessage('At least 1 adult guest is required'),
  body('guests.children').optional().isInt({ min: 0 }).withMessage('Children count must be non-negative'),
  body('guestInfo.firstName').notEmpty().trim().withMessage('Guest first name is required'),
  body('guestInfo.lastName').notEmpty().trim().withMessage('Guest last name is required'),
  body('guestInfo.email').isEmail().withMessage('Valid guest email is required'),
  body('guestInfo.phone').isMobilePhone().withMessage('Valid phone number is required'),
  body('paymentMethod').isIn(['vnpay', 'stripe']).withMessage('Valid payment method is required')
];

// @desc    Create booking
// @route   POST /api/bookings
// @access  Private (Customer)
router.post('/', authenticate, authorize('customer'), asyncHandler(async (req, res) => {
  console.log('=== BOOKING REQUEST ===');
  console.log('Body:', JSON.stringify(req.body, null, 2));
  console.log('======================');
  
  // Support both old and new format for backwards compatibility
  const {
    room: roomId,
    checkIn: checkInFromNew,
    checkOut: checkOutFromNew,
    checkInDate: checkInFromOld,
    checkOutDate: checkOutFromOld,
    guests: guestsFromNew,
    adults: adultsFromOld,
    children: childrenFromOld,
    guestInfo: guestInfoFromBody,
    paymentMethod,
    specialRequests
  } = req.body;
  
  // Use new format if available, fallback to old format
  const checkIn = checkInFromNew || checkInFromOld;
  const checkOut = checkOutFromNew || checkOutFromOld;
  
  let guests;
  if (guestsFromNew) {
    guests = guestsFromNew;
  } else {
    guests = {
      adults: adultsFromOld || 1,
      children: childrenFromOld || 0
    };
  }
  
  let guestInfo;
  if (Array.isArray(guestInfoFromBody)) {
    guestInfo = guestInfoFromBody[0] || {};
  } else {
    guestInfo = guestInfoFromBody || {};
  }
  
  // Basic validation
  if (!roomId) {
    return res.status(400).json({ 
      success: false,
      message: 'Room ID is required' 
    });
  }
  
  if (!checkIn || !checkOut) {
    return res.status(400).json({ 
      success: false,
      message: 'Check-in and check-out dates are required' 
    });
  }
  
  if (!guests.adults || guests.adults < 1) {
    return res.status(400).json({ 
      success: false,
      message: 'At least 1 adult guest is required' 
    });
  }
  
  if (!paymentMethod) {
    return res.status(400).json({ 
      success: false,
      message: 'Payment method is required' 
    });
  }
  
  // Validate dates
  const checkInDate = new Date(checkIn);
  const checkOutDate = new Date(checkOut);
  const now = new Date();
  
  // Allow check-in for today (same day) but not for past dates
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const checkInDay = new Date(checkInDate.getFullYear(), checkInDate.getMonth(), checkInDate.getDate());
  
  if (checkInDay < today) {
    return res.status(400).json({ message: 'Check-in date cannot be in the past' });
  }
  
  if (checkOutDate <= checkInDate) {
    return res.status(400).json({ message: 'Check-out date must be after check-in date' });
  }
  
  // Find room and hotel
  const room = await Room.findById(roomId).populate('hotel');
  if (!room || !room.isActive) {
    return res.status(404).json({ message: 'Room not found or unavailable' });
  }
  
  if (!room.hotel.isApproved || !room.hotel.isActive) {
    return res.status(400).json({ message: 'Hotel is not available for booking' });
  }
  
  // Check availability
  const totalGuests = guests.adults + (guests.children || 0);
  const availability = await room.checkAvailability(checkIn, checkOut, totalGuests);
  
  if (!availability.available) {
    return res.status(400).json({ 
      message: 'Room is not available for the selected dates',
      reason: availability.reason 
    });
  }
  
  // Calculate pricing
  const pricing = room.calculatePrice(checkIn, checkOut);
  const customer = await User.findById(req.user._id);
  
  // Apply membership discount
  const discountPercentage = customer.getDiscountPercentage();
  const discountAmount = pricing.totalPrice * (discountPercentage / 100);
  const subtotal = pricing.totalPrice - discountAmount;
  const taxAmount = subtotal * 0.1; // 10% tax
  const totalAmount = subtotal + taxAmount;
  
  // Generate booking number
  const bookingCount = await Booking.countDocuments();
  const bookingNumber = `HB${Date.now()}${String(bookingCount + 1).padStart(4, '0')}`;
  
  // Create booking
  console.log('Creating booking with data:', {
    customer: req.user._id,
    hotel: room.hotel._id,
    room: roomId,
    checkIn: checkInDate,
    checkOut: checkOutDate,
    guests,
    guestInfo,
    roomPrice: pricing.averagePerNight,
    nights: pricing.nights,
    subtotal: pricing.totalPrice,
    paymentMethod,
    bookingNumber
  });
  
  const booking = new Booking({
    bookingNumber,
    customer: req.user._id,
    hotel: room.hotel._id,
    room: roomId,
    checkIn: checkInDate,
    checkOut: checkOutDate,
    guests,
    guestInfo: {
      ...guestInfo,
      specialRequests
    },
    roomPrice: pricing.averagePerNight,
    nights: pricing.nights,
    subtotal: pricing.totalPrice,
    discountAmount,
    discountPercentage,
    taxAmount,
    totalAmount,
    paymentMethod,
    cancellationPolicy: room.hotel.cancellationPolicy
  });
  
  console.log('About to save booking...');
  await booking.save();
  console.log('Booking saved successfully with number:', booking.bookingNumber);
  
  // Populate booking for response
  await booking.populate([
    { path: 'hotel', select: 'name address phone email' },
    { path: 'room', select: 'name type' },
    { path: 'customer', select: 'firstName lastName email' }
  ]);
  
  res.status(201).json({
    success: true,
    message: 'Booking created successfully',
    data: booking,
    paymentRequired: true,
    paymentAmount: totalAmount
  });
}));

// @desc    Get user bookings
// @route   GET /api/bookings/my
// @access  Private (Customer)
router.get('/my', authenticate, authorize('customer'), [
  query('status').optional().isIn(['pending', 'confirmed', 'cancelled', 'checked_in', 'checked_out', 'no_show']),
  query('page').optional().isInt({ min: 1 }),
  query('limit').optional().isInt({ min: 1, max: 50 })
], validate, asyncHandler(async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10;
  const skip = (page - 1) * limit;
  
  let query = { customer: req.user._id };
  
  if (req.query.status) {
    query.status = req.query.status;
  }
  
  const bookings = await Booking.find(query)
    .populate('hotel', 'name address images')
    .populate('room', 'name type images')
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

// @desc    Get customer's bookings
// @route   GET /api/bookings/my-bookings
// @access  Private (Customer)
router.get('/my-bookings', authenticate, authorize('customer'), asyncHandler(async (req, res) => {
  const bookings = await Booking.find({ customer: req.user._id })
    .populate('hotel', 'name address images phone email')
    .populate('room', 'name type images amenities')
    .sort({ createdAt: -1 });

  res.json({
    success: true,
    data: bookings
  });
}));

// @desc    Get booking by ID
// @route   GET /api/bookings/:id
// @access  Private
router.get('/:id', authenticate, asyncHandler(async (req, res) => {
  const booking = await Booking.findById(req.params.id)
    .populate('customer', 'firstName lastName email phone')
    .populate('hotel', 'name address phone email')
    .populate('room', 'name type amenities images');
  
  if (!booking) {
    return res.status(404).json({ message: 'Booking not found' });
  }
  
  // Check authorization
  const isCustomer = req.user.role === 'customer' && booking.customer._id.toString() === req.user._id.toString();
  const isHotelOwner = req.user.role === 'hotel_owner' && booking.hotel.owner.toString() === req.user._id.toString();
  const isAdmin = req.user.role === 'admin';
  
  if (!isCustomer && !isHotelOwner && !isAdmin) {
    return res.status(403).json({ message: 'Access denied' });
  }
  
  res.json({ booking });
}));

// @desc    Get booking payment status by ID  
// @route   GET /api/bookings/:id/payment-status
// @access  Private
router.get('/:id/payment-status', authenticate, asyncHandler(async (req, res) => {
  const booking = await Booking.findById(req.params.id)
    .select('paymentStatus status totalAmount paymentDetails customer');
  
  if (!booking) {
    return res.status(404).json({ message: 'Booking not found' });
  }
  
  // Check authorization - chỉ customer của booking mới được check
  if (req.user.role === 'customer' && booking.customer.toString() !== req.user._id.toString()) {
    return res.status(403).json({ message: 'Access denied' });
  }
  
  res.json({ 
    paymentStatus: booking.paymentStatus,
    status: booking.status,
    totalAmount: booking.totalAmount,
    paymentDetails: booking.paymentDetails
  });
}));

// @desc    Update booking status
// @route   PATCH /api/bookings/:id/status
// @access  Private (Hotel Owner/Admin)
router.patch('/:id/status', authenticate, [
  body('status').isIn(['confirmed', 'cancelled', 'checked_in', 'checked_out', 'no_show']).withMessage('Invalid status'),
  body('notes').optional().trim()
], validate, asyncHandler(async (req, res) => {
  const { status, notes } = req.body;
  
  const booking = await Booking.findById(req.params.id)
    .populate('customer', 'firstName lastName email')
    .populate('hotel', 'name owner')
    .populate('room', 'name');
  
  if (!booking) {
    return res.status(404).json({ message: 'Booking not found' });
  }
  
  // Check authorization
  const isHotelOwner = req.user.role === 'hotel_owner' && booking.hotel.owner.toString() === req.user._id.toString();
  const isAdmin = req.user.role === 'admin';
  
  if (!isHotelOwner && !isAdmin) {
    return res.status(403).json({ message: 'Access denied' });
  }
  
  // Validate status transition
  const validTransitions = {
    'pending': ['confirmed', 'cancelled'],
    'confirmed': ['checked_in', 'cancelled', 'no_show'],
    'checked_in': ['checked_out'],
    'cancelled': [],
    'checked_out': [],
    'no_show': []
  };
  
  if (!validTransitions[booking.status].includes(status)) {
    return res.status(400).json({ 
      message: `Cannot change status from ${booking.status} to ${status}` 
    });
  }
  
  // Update booking
  booking.status = status;
  
  if (status === 'confirmed') {
    booking.confirmedAt = new Date();
    // Send confirmation email
    try {
      await sendBookingConfirmation(booking, booking.customer.email, booking.customer.firstName);
    } catch (error) {
      console.error('Failed to send confirmation email:', error);
    }
  } else if (status === 'checked_in') {
    booking.checkedInAt = new Date();
  } else if (status === 'checked_out') {
    booking.checkedOutAt = new Date();
  }
  
  if (notes) {
    booking.hotelNotes = notes;
  }
  
  await booking.save();
  
  res.json({
    message: `Booking ${status} successfully`,
    booking
  });
}));

// @desc    Cancel booking
// @route   PATCH /api/bookings/:id/cancel
// @access  Private (Customer)
router.patch('/:id/cancel', authenticate, authorize('customer'), [
  body('reason').optional().trim()
], validate, asyncHandler(async (req, res) => {
  const { reason } = req.body;
  
  const booking = await Booking.findById(req.params.id);
  
  if (!booking) {
    return res.status(404).json({ message: 'Booking not found' });
  }
  
  // Check authorization
  if (booking.customer.toString() !== req.user._id.toString()) {
    return res.status(403).json({ message: 'Access denied' });
  }
  
  // Check if booking can be cancelled
  if (!booking.canBeCancelled()) {
    return res.status(400).json({ 
      message: 'Booking cannot be cancelled at this time' 
    });
  }
  
  // Calculate cancellation fee and refund
  const cancellation = booking.calculateCancellationFee();
  
  booking.status = 'cancelled';
  booking.cancellationReason = reason;
  booking.cancellationDate = new Date();
  booking.refundAmount = cancellation.refundAmount;
  
  await booking.save();
  
  res.json({
    message: 'Booking cancelled successfully',
    cancellationDetails: {
      cancellationFee: cancellation.cancellationFee,
      refundAmount: cancellation.refundAmount,
      feePercentage: cancellation.feePercentage
    }
  });
}));

// @desc    Get hotel bookings
// @route   GET /api/bookings/hotel/:hotelId
// @access  Private (Hotel Owner/Admin)
router.get('/hotel/:hotelId', authenticate, [
  query('status').optional().isIn(['pending', 'confirmed', 'cancelled', 'checked_in', 'checked_out', 'no_show']),
  query('startDate').optional().isISO8601(),
  query('endDate').optional().isISO8601(),
  query('page').optional().isInt({ min: 1 }),
  query('limit').optional().isInt({ min: 1, max: 50 })
], validate, asyncHandler(async (req, res) => {
  const { hotelId } = req.params;
  
  // Check authorization
  const hotel = await Hotel.findById(hotelId);
  if (!hotel) {
    return res.status(404).json({ message: 'Hotel not found' });
  }
  
  const isHotelOwner = req.user.role === 'hotel_owner' && hotel.owner.toString() === req.user._id.toString();
  const isAdmin = req.user.role === 'admin';
  
  if (!isHotelOwner && !isAdmin) {
    return res.status(403).json({ message: 'Access denied' });
  }
  
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10;
  const skip = (page - 1) * limit;
  
  let query = { hotel: hotelId };
  
  if (req.query.status) {
    query.status = req.query.status;
  }
  
  if (req.query.startDate && req.query.endDate) {
    query.checkIn = {
      $gte: new Date(req.query.startDate),
      $lte: new Date(req.query.endDate)
    };
  }
  
  const bookings = await Booking.find(query)
    .populate('customer', 'firstName lastName email phone')
    .populate('room', 'name type')
    .sort({ checkIn: -1 })
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

// @desc    Get booking statistics
// @route   GET /api/bookings/stats/summary
// @access  Private (Hotel Owner/Admin)
router.get('/stats/summary', authenticate, authorize('hotel_owner', 'admin'), asyncHandler(async (req, res) => {
  let matchQuery = {};
  
  // If hotel owner, only show their hotel bookings
  if (req.user.role === 'hotel_owner') {
    const hotels = await Hotel.find({ owner: req.user._id });
    matchQuery.hotel = { $in: hotels.map(h => h._id) };
  }
  
  const stats = await Booking.aggregate([
    { $match: matchQuery },
    {
      $group: {
        _id: null,
        totalBookings: { $sum: 1 },
        totalRevenue: { $sum: '$totalAmount' },
        confirmedBookings: {
          $sum: { $cond: [{ $eq: ['$status', 'confirmed'] }, 1, 0] }
        },
        cancelledBookings: {
          $sum: { $cond: [{ $eq: ['$status', 'cancelled'] }, 1, 0] }
        },
        completedBookings: {
          $sum: { $cond: [{ $eq: ['$status', 'checked_out'] }, 1, 0] }
        }
      }
    }
  ]);
  
  // Monthly revenue for the last 12 months
  const monthlyRevenue = await Booking.aggregate([
    { $match: { ...matchQuery, createdAt: { $gte: new Date(new Date().setMonth(new Date().getMonth() - 12)) } } },
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
  
  res.json({
    summary: stats[0] || {
      totalBookings: 0,
      totalRevenue: 0,
      confirmedBookings: 0,
      cancelledBookings: 0,
      completedBookings: 0
    },
    monthlyRevenue
  });
}));

// @desc    Update booking payment status
// @route   PATCH /api/bookings/:id/payment
// @access  Private (System/Payment Gateway)
router.patch('/:id/payment', [
  body('paymentStatus').isIn(['pending', 'paid', 'failed', 'refunded']).withMessage('Invalid payment status'),
  body('transactionId').optional().trim(),
  body('paymentDetails').optional().isObject()
], validate, asyncHandler(async (req, res) => {
  const { paymentStatus, transactionId, paymentDetails } = req.body;
  
  const booking = await Booking.findById(req.params.id);
  if (!booking) {
    return res.status(404).json({ message: 'Booking not found' });
  }
  
  // Update payment status
  booking.paymentStatus = paymentStatus;
  
  if (transactionId) {
    booking.transactionId = transactionId;
  }
  
  if (paymentDetails) {
    booking.paymentDetails = { ...booking.paymentDetails, ...paymentDetails };
  }
  
  // If payment is successful, confirm the booking
  if (paymentStatus === 'paid') {
    booking.status = 'confirmed';
    booking.confirmedAt = new Date();
    booking.paidAt = new Date();
    
    // Send confirmation email
    try {
      const customer = await User.findById(booking.customer);
      await sendBookingConfirmation(booking, customer.email, customer.firstName);
    } catch (error) {
      console.error('Failed to send confirmation email:', error);
    }
  }
  
  await booking.save();
  
  res.json({
    success: true,
    message: `Payment status updated to ${paymentStatus}`,
    data: booking
  });
}));

// @desc    Verify booking payment
// @route   GET /api/bookings/:id/verify-payment
// @access  Private
router.get('/:id/verify-payment', authenticate, asyncHandler(async (req, res) => {
  const booking = await Booking.findById(req.params.id)
    .select('paymentStatus status totalAmount paymentMethod transactionId customer')
    .populate('customer', 'firstName lastName email');
  
  if (!booking) {
    return res.status(404).json({ message: 'Booking not found' });
  }
  
  // Check authorization - customer hoặc system
  const isCustomer = req.user.role === 'customer' && booking.customer._id.toString() === req.user._id.toString();
  const isSystem = req.user.role === 'admin' || req.user.role === 'system';
  
  if (!isCustomer && !isSystem) {
    return res.status(403).json({ message: 'Access denied' });
  }
  
  res.json({
    success: true,
    data: {
      bookingId: booking._id,
      paymentStatus: booking.paymentStatus,
      bookingStatus: booking.status,
      totalAmount: booking.totalAmount,
      paymentMethod: booking.paymentMethod,
      transactionId: booking.transactionId,
      isPaid: booking.paymentStatus === 'paid'
    }
  });
}));

// @desc    Update booking status
// @route   PUT /api/bookings/:id/status
// @access  Private (Hotel Owner, Admin)
router.put('/:id/status', authenticate, authorize('hotel_owner', 'admin'), asyncHandler(async (req, res) => {
  const { status } = req.body;
  const bookingId = req.params.id;
  
  // Validate status
  const validStatuses = ['pending', 'confirmed', 'cancelled', 'checked_in', 'checked_out', 'no_show'];
  if (!status || !validStatuses.includes(status)) {
    return res.status(400).json({ 
      success: false, 
      message: 'Valid status is required. Allowed values: ' + validStatuses.join(', ') 
    });
  }
  
  const booking = await Booking.findById(bookingId)
    .populate('hotel', 'owner name')
    .populate('customer', 'firstName lastName email');
    
  if (!booking) {
    return res.status(404).json({ 
      success: false, 
      message: 'Booking not found' 
    });
  }
  
  // Check permission - only hotel owner or admin can update
  if (req.user.role === 'hotel_owner' && booking.hotel.owner.toString() !== req.user.id) {
    return res.status(403).json({ 
      success: false, 
      message: 'Access denied. You can only update bookings for your hotels.' 
    });
  }
  
  // Validate status transitions
  const currentStatus = booking.status;
  const validTransitions = {
    'pending': ['confirmed', 'cancelled'],
    'confirmed': ['cancelled', 'checked_in', 'no_show'],
    'checked_in': ['checked_out'],
    'cancelled': [], // Cannot change from cancelled
    'checked_out': [], // Cannot change from checked_out
    'no_show': [] // Cannot change from no_show
  };
  
  if (!validTransitions[currentStatus] || !validTransitions[currentStatus].includes(status)) {
    return res.status(400).json({ 
      success: false, 
      message: `Cannot change status from '${currentStatus}' to '${status}'` 
    });
  }
  
  // Update booking status
  const updateData = { status };
  
  // Add timestamps for specific status changes
  switch (status) {
    case 'confirmed':
      updateData.confirmedAt = new Date();
      break;
    case 'cancelled':
      updateData.cancelledAt = new Date();
      break;
    case 'checked_in':
      updateData.checkedInAt = new Date();
      break;
    case 'checked_out':
      updateData.checkedOutAt = new Date();
      break;
  }
  
  const updatedBooking = await Booking.findByIdAndUpdate(
    bookingId,
    updateData,
    { new: true, runValidators: true }
  ).populate([
    { path: 'customer', select: 'firstName lastName email phone' },
    { path: 'hotel', select: 'name address phone email' },
    { path: 'room', select: 'name type' }
  ]);
  
  // Send notification email for important status changes
  if (['confirmed', 'cancelled', 'checked_in'].includes(status)) {
    try {
      await sendBookingConfirmation(updatedBooking, status);
    } catch (emailError) {
      console.error('Email notification failed:', emailError);
      // Don't fail the request if email fails
    }
  }
  
  res.json({
    success: true,
    message: `Booking status updated to ${status}`,
    data: updatedBooking
  });
}));

module.exports = router;
