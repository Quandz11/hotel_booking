const express = require('express');
const { body } = require('express-validator');
const Room = require('../models/Room');
const Hotel = require('../models/Hotel');
const { authenticate, authorize, requireApprovedHotelOwner } = require('../middleware/auth');
const { validate, asyncHandler } = require('../middleware/validation');

const router = express.Router();

// Room validation rules
const roomValidation = [
  body('hotel').isMongoId().withMessage('Valid hotel ID is required'),
  body('name').notEmpty().trim().withMessage('Room name is required'),
  body('type').isIn(['standard', 'deluxe', 'suite', 'executive', 'presidential']).withMessage('Invalid room type'),
  body('maxGuests').isInt({ min: 1 }).withMessage('Max guests must be at least 1'),
  body('bedType').isIn(['single', 'double', 'queen', 'king', 'twin']).withMessage('Invalid bed type'),
  body('bedCount').isInt({ min: 1 }).withMessage('Bed count must be at least 1'),
  body('basePrice').isNumeric({ min: 0 }).withMessage('Base price must be a positive number'),
  body('weekendPrice').isNumeric({ min: 0 }).withMessage('Weekend price must be a positive number'),
  body('totalRooms').isInt({ min: 1 }).withMessage('Total rooms must be at least 1')
];

// @desc    Get rooms by hotel
// @route   GET /api/rooms/hotel/:hotelId
// @access  Public
router.get('/hotel/:hotelId', asyncHandler(async (req, res) => {
  const { hotelId } = req.params;
  const { checkIn, checkOut, guests = 1 } = req.query;
  
  const hotel = await Hotel.findById(hotelId);
  if (!hotel || !hotel.isApproved || !hotel.isActive) {
    return res.status(404).json({ message: 'Hotel not found' });
  }
  
  const rooms = await Room.find({ hotel: hotelId, isActive: true })
    .sort({ basePrice: 1 });
  
  // If dates provided, check availability for each room
  if (checkIn && checkOut) {
    const roomsWithAvailability = [];
    
    for (let room of rooms) {
      const availability = await room.checkAvailability(checkIn, checkOut, guests);
      const pricing = room.calculatePrice(checkIn, checkOut);
      
      roomsWithAvailability.push({
        ...room.toObject(),
        availability,
        pricing
      });
    }
    
    return res.json({ rooms: roomsWithAvailability });
  }
  
  res.json({ rooms });
}));

// @desc    Get all rooms for authenticated hotel owner
// @route   GET /api/rooms/my-rooms
// @access  Private (Hotel Owner)
router.get('/my-rooms', authenticate, authorize('hotel_owner'), requireApprovedHotelOwner, asyncHandler(async (req, res) => {
  // Get all hotels owned by the user
  const ownedHotels = await Hotel.find({ owner: req.user._id, isActive: true });
  const hotelIds = ownedHotels.map(hotel => hotel._id);
  
  // Get all rooms for owned hotels
  const rooms = await Room.find({ hotel: { $in: hotelIds } })
    .populate('hotel', 'name location')
    .sort({ 'hotel.name': 1, name: 1 });
  
  res.json({
    success: true,
    count: rooms.length,
    data: rooms
  });
}));

// @desc    Get room by ID
// @route   GET /api/rooms/:id
// @access  Public
router.get('/:id', asyncHandler(async (req, res) => {
  const room = await Room.findById(req.params.id)
    .populate('hotel', 'name address starRating amenities checkInTime checkOutTime cancellationPolicy');
  
  if (!room || !room.isActive) {
    return res.status(404).json({ message: 'Room not found' });
  }
  
  if (!room.hotel.isApproved || !room.hotel.isActive) {
    return res.status(404).json({ message: 'Room not available' });
  }
  
  res.json({ room });
}));

// @desc    Create new room
// @route   POST /api/rooms
// @access  Private (Hotel Owner)
router.post('/', authenticate, authorize('hotel_owner', 'admin'), roomValidation, validate, asyncHandler(async (req, res) => {
  const { hotel: hotelId } = req.body;
  
  // Verify hotel ownership
  const hotel = await Hotel.findById(hotelId);
  if (!hotel) {
    return res.status(404).json({ message: 'Hotel not found' });
  }
  
  // If admin: allow creating room for any hotel
  if (req.user.role !== 'admin') {
    if (hotel.owner.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Access denied. You can only add rooms to your own hotels.' });
    }
    if (!req.user.isApproved) {
      return res.status(403).json({ message: 'Your hotel owner account is pending approval.' });
    }
  }
  
  const room = new Room(req.body);
  await room.save();
  
  // Update hotel room count
  await hotel.updateRoomCount();
  
  res.status(201).json({
    message: 'Room created successfully',
    room
  });
}));

// @desc    Update room
// @route   PUT /api/rooms/:id
// @access  Private (Hotel Owner/Admin)
router.put('/:id', authenticate, roomValidation, validate, asyncHandler(async (req, res) => {
  const room = await Room.findById(req.params.id).populate('hotel');
  
  if (!room) {
    return res.status(404).json({ message: 'Room not found' });
  }
  
  // Check authorization
  const isHotelOwner = req.user.role === 'hotel_owner' && room.hotel.owner.toString() === req.user._id.toString();
  const isAdmin = req.user.role === 'admin';
  
  if (!isHotelOwner && !isAdmin) {
    return res.status(403).json({ message: 'Access denied' });
  }
  
  const updatedRoom = await Room.findByIdAndUpdate(
    req.params.id,
    req.body,
    { new: true, runValidators: true }
  );
  
  res.json({
    message: 'Room updated successfully',
    room: updatedRoom
  });
}));

// @desc    Delete room
// @route   DELETE /api/rooms/:id
// @access  Private (Hotel Owner/Admin)
router.delete('/:id', authenticate, asyncHandler(async (req, res) => {
  const room = await Room.findById(req.params.id).populate('hotel');
  
  if (!room) {
    return res.status(404).json({ message: 'Room not found' });
  }
  
  // Check authorization
  const isHotelOwner = req.user.role === 'hotel_owner' && room.hotel.owner.toString() === req.user._id.toString();
  const isAdmin = req.user.role === 'admin';
  
  if (!isHotelOwner && !isAdmin) {
    return res.status(403).json({ message: 'Access denied' });
  }
  
  // Soft delete
  room.isActive = false;
  await room.save();
  
  // Update hotel room count
  await room.hotel.updateRoomCount();
  
  res.json({ message: 'Room deleted successfully' });
}));

// @desc    Check room availability
// @route   POST /api/rooms/:id/availability
// @access  Public
router.post('/:id/availability', [
  body('checkIn').isISO8601().withMessage('Valid check-in date is required'),
  body('checkOut').isISO8601().withMessage('Valid check-out date is required'),
  body('guests').optional().isInt({ min: 1 }).withMessage('Guests must be at least 1')
], validate, asyncHandler(async (req, res) => {
  const { checkIn, checkOut, guests = 1 } = req.body;
  
  const room = await Room.findById(req.params.id);
  if (!room || !room.isActive) {
    return res.status(404).json({ message: 'Room not found' });
  }
  
  const availability = await room.checkAvailability(checkIn, checkOut, guests);
  const pricing = room.calculatePrice(checkIn, checkOut);
  
  res.json({
    availability,
    pricing,
    room: {
      id: room._id,
      name: room.name,
      type: room.type,
      maxGuests: room.maxGuests
    }
  });
}));

// @desc    Get rooms by owner
// @route   GET /api/rooms/owner/my
// @access  Private (Hotel Owner)
router.get('/owner/my', authenticate, authorize('hotel_owner'), asyncHandler(async (req, res) => {
  // Get all hotels owned by the user
  const hotels = await Hotel.find({ owner: req.user._id });
  const hotelIds = hotels.map(hotel => hotel._id);
  
  const rooms = await Room.find({ hotel: { $in: hotelIds } })
    .populate('hotel', 'name address')
    .sort({ 'hotel.name': 1, name: 1 });
  
  res.json({ rooms });
}));

// @desc    Update room availability calendar
// @route   PATCH /api/rooms/:id/calendar
// @access  Private (Hotel Owner)
router.patch('/:id/calendar', authenticate, authorize('hotel_owner'), [
  body('dates').isArray().withMessage('Dates must be an array'),
  body('dates.*.date').isISO8601().withMessage('Invalid date format'),
  body('dates.*.available').isBoolean().withMessage('Available must be boolean'),
  body('dates.*.price').optional().isNumeric().withMessage('Price must be numeric')
], validate, asyncHandler(async (req, res) => {
  const { dates } = req.body;
  
  const room = await Room.findById(req.params.id).populate('hotel');
  
  if (!room) {
    return res.status(404).json({ message: 'Room not found' });
  }
  
  // Check authorization
  if (room.hotel.owner.toString() !== req.user._id.toString()) {
    return res.status(403).json({ message: 'Access denied' });
  }
  
  // Note: For simplicity, we're not implementing a separate calendar model
  // In a real application, you would have a RoomAvailability model
  // to track daily availability and pricing
  
  res.json({
    message: 'Room calendar updated successfully',
    note: 'Calendar functionality requires additional implementation'
  });
}));

// @desc    Bulk update room prices
// @route   PATCH /api/rooms/bulk/prices
// @access  Private (Hotel Owner)
router.patch('/bulk/prices', authenticate, authorize('hotel_owner'), [
  body('roomIds').isArray().withMessage('Room IDs must be an array'),
  body('roomIds.*').isMongoId().withMessage('Invalid room ID'),
  body('priceUpdate.type').isIn(['percentage', 'fixed']).withMessage('Price update type must be percentage or fixed'),
  body('priceUpdate.value').isNumeric().withMessage('Price update value must be numeric'),
  body('priceUpdate.applyTo').isIn(['base', 'weekend', 'both']).withMessage('Apply to must be base, weekend, or both')
], validate, asyncHandler(async (req, res) => {
  const { roomIds, priceUpdate } = req.body;
  
  // Verify all rooms belong to the user
  const rooms = await Room.find({ 
    _id: { $in: roomIds },
    isActive: true 
  }).populate('hotel');
  
  const unauthorizedRooms = rooms.filter(room => 
    room.hotel.owner.toString() !== req.user._id.toString()
  );
  
  if (unauthorizedRooms.length > 0) {
    return res.status(403).json({ message: 'Access denied to some rooms' });
  }
  
  // Update prices
  const updates = {};
  const { type, value, applyTo } = priceUpdate;
  
  if (applyTo === 'base' || applyTo === 'both') {
    if (type === 'percentage') {
      updates.$mul = { basePrice: 1 + (value / 100) };
    } else {
      updates.$inc = { basePrice: value };
    }
  }
  
  if (applyTo === 'weekend' || applyTo === 'both') {
    if (type === 'percentage') {
      updates.$mul = { ...updates.$mul, weekendPrice: 1 + (value / 100) };
    } else {
      updates.$inc = { ...updates.$inc, weekendPrice: value };
    }
  }
  
  await Room.updateMany(
    { _id: { $in: roomIds } },
    updates
  );
  
  res.json({
    message: `Successfully updated prices for ${roomIds.length} rooms`,
    updatedRooms: roomIds.length
  });
}));

// @desc    Toggle room status (active/inactive)
// @route   PATCH /api/rooms/:id/toggle-status
// @access  Private (Hotel Owner)
router.patch('/:id/toggle-status', authenticate, authorize('hotel_owner'), asyncHandler(async (req, res) => {
  const room = await Room.findById(req.params.id).populate('hotel');
  
  if (!room) {
    return res.status(404).json({ message: 'Room not found' });
  }
  
  // Check if user owns the hotel
  if (room.hotel.owner.toString() !== req.user._id.toString()) {
    return res.status(403).json({ message: 'Access denied' });
  }
  
  // Toggle the status
  room.isActive = !room.isActive;
  await room.save();
  
  res.json({
    message: `Room ${room.isActive ? 'activated' : 'deactivated'} successfully`,
    room: room
  });
}));

module.exports = router;
