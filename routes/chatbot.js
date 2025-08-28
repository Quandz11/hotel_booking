const express = require('express');
const { body } = require('express-validator');
const Hotel = require('../models/Hotel');
const Room = require('../models/Room');
const { authenticate } = require('../middleware/auth');
const { validate, asyncHandler } = require('../middleware/validation');

const router = express.Router();

// Note: For this implementation, we'll create a simple chatbot that can help with hotel searches
// In a real implementation, you would integrate with Google's Gemini API

// @desc    Chat with bot
// @route   POST /api/chatbot/chat
// @access  Public
router.post('/chat', [
  body('message').notEmpty().trim().withMessage('Message is required'),
  body('context').optional().isObject()
], validate, asyncHandler(async (req, res) => {
  const { message, context = {} } = req.body;
  
  try {
    // Simple keyword-based responses (In production, use Gemini API)
    const response = await processMessage(message.toLowerCase(), context);
    
    res.json({
      message: 'Response generated successfully',
      response,
      context: response.context || context
    });
  } catch (error) {
    console.error('Chatbot error:', error);
    res.status(500).json({ 
      message: 'Sorry, I encountered an error. Please try again.',
      response: {
        text: 'I apologize, but I\'m having trouble processing your request right now. Please try again later or contact our support team.',
        type: 'error'
      }
    });
  }
}));

// @desc    Get chatbot suggestions
// @route   GET /api/chatbot/suggestions
// @access  Public
router.get('/suggestions', asyncHandler(async (req, res) => {
  const suggestions = [
    'Find hotels in Ho Chi Minh City',
    'Show me 5-star hotels',
    'Hotels with swimming pool',
    'Budget hotels under 1 million VND',
    'Hotels near the airport',
    'What are your cancellation policies?',
    'How do I make a booking?',
    'What payment methods do you accept?'
  ];
  
  res.json({ suggestions });
}));

// @desc    Get popular search queries
// @route   GET /api/chatbot/popular-queries
// @access  Public
router.get('/popular-queries', asyncHandler(async (req, res) => {
  // In a real app, you'd track and analyze user queries
  const popularQueries = [
    {
      query: 'Hotels in Da Nang',
      count: 156,
      category: 'location'
    },
    {
      query: 'Hotels with breakfast included',
      count: 143,
      category: 'amenities'
    },
    {
      query: 'Pet-friendly hotels',
      count: 89,
      category: 'amenities'
    },
    {
      query: 'Hotels near beach',
      count: 234,
      category: 'location'
    },
    {
      query: 'Luxury hotels',
      count: 198,
      category: 'type'
    }
  ];
  
  res.json({ popularQueries });
}));

// Message processing function (simplified chatbot logic)
async function processMessage(message, context) {
  // Location-based queries
  if (message.includes('hotel') && (message.includes('in') || message.includes('near'))) {
    return await handleLocationQuery(message, context);
  }
  
  // Price-based queries
  if (message.includes('price') || message.includes('cost') || message.includes('budget')) {
    return await handlePriceQuery(message, context);
  }
  
  // Amenity-based queries
  if (message.includes('pool') || message.includes('gym') || message.includes('wifi') || 
      message.includes('breakfast') || message.includes('parking')) {
    return await handleAmenityQuery(message, context);
  }
  
  // Star rating queries
  if (message.includes('star') || message.includes('luxury') || message.includes('budget')) {
    return await handleStarRatingQuery(message, context);
  }
  
  // Booking help
  if (message.includes('book') || message.includes('reservation') || message.includes('how to')) {
    return handleBookingHelp(message, context);
  }
  
  // Payment queries
  if (message.includes('payment') || message.includes('pay') || message.includes('credit card')) {
    return handlePaymentQuery(message, context);
  }
  
  // Cancellation queries
  if (message.includes('cancel') || message.includes('refund')) {
    return handleCancellationQuery(message, context);
  }
  
  // Default greeting/help
  if (message.includes('hello') || message.includes('hi') || message.includes('help')) {
    return {
      text: 'Hello! I\'m here to help you find the perfect hotel. I can assist you with:\n\n' +
            '🏨 Finding hotels by location\n' +
            '💰 Budget-friendly options\n' +
            '⭐ Luxury accommodations\n' +
            '🏊 Hotels with specific amenities\n' +
            '📅 Booking assistance\n' +
            '💳 Payment information\n\n' +
            'What would you like to know?',
      type: 'greeting',
      suggestions: [
        'Find hotels in Ho Chi Minh City',
        'Show me budget hotels',
        'Hotels with swimming pool',
        'How do I make a booking?'
      ]
    };
  }
  
  // Default response
  return {
    text: 'I\'m sorry, I didn\'t quite understand that. Could you please rephrase your question? I can help you with:\n\n' +
          '• Finding hotels by location\n' +
          '• Hotel prices and budgets\n' +
          '• Hotel amenities and facilities\n' +
          '• Booking and reservation help\n' +
          '• Payment and cancellation policies',
    type: 'clarification',
    suggestions: [
      'Find hotels in a specific city',
      'Show me hotel prices',
      'What amenities are available?',
      'How do I make a booking?'
    ]
  };
}

async function handleLocationQuery(message, context) {
  // Extract location from message
  let location = '';
  const locationPatterns = [
    /hotels? in ([^,]+)/i,
    /hotels? near ([^,]+)/i,
    /([^,]+) hotels?/i
  ];
  
  for (const pattern of locationPatterns) {
    const match = message.match(pattern);
    if (match) {
      location = match[1].trim();
      break;
    }
  }
  
  if (!location) {
    return {
      text: 'I\'d be happy to help you find hotels! Could you please specify the location you\'re interested in?',
      type: 'location_clarification',
      suggestions: [
        'Hotels in Ho Chi Minh City',
        'Hotels in Hanoi',
        'Hotels in Da Nang',
        'Hotels in Nha Trang'
      ]
    };
  }
  
  // Search for hotels
  const hotels = await Hotel.find({
    isApproved: true,
    isActive: true,
    $or: [
      { 'address.city': { $regex: location, $options: 'i' } },
      { 'address.state': { $regex: location, $options: 'i' } },
      { name: { $regex: location, $options: 'i' } }
    ]
  }).limit(5).populate('owner', 'firstName lastName');
  
  if (hotels.length === 0) {
    return {
      text: `I couldn't find any hotels in "${location}". Here are some popular destinations you might be interested in:`,
      type: 'no_results',
      suggestions: [
        'Hotels in Ho Chi Minh City',
        'Hotels in Hanoi',
        'Hotels in Da Nang',
        'Show me all available hotels'
      ]
    };
  }
  
  let response = `I found ${hotels.length} hotels in ${location}:\n\n`;
  
  hotels.forEach((hotel, index) => {
    response += `${index + 1}. **${hotel.name}**\n`;
    response += `   ⭐ ${hotel.starRating} stars\n`;
    response += `   📍 ${hotel.address.city}\n`;
    if (hotel.averageRating > 0) {
      response += `   💝 ${hotel.averageRating.toFixed(1)}/5 (${hotel.totalReviews} reviews)\n`;
    }
    response += '\n';
  });
  
  return {
    text: response,
    type: 'hotel_list',
    data: hotels,
    context: { location, searchType: 'location' },
    suggestions: [
      'Show me room prices',
      'Hotels with swimming pool',
      'More details about these hotels',
      'Search in another city'
    ]
  };
}

async function handlePriceQuery(message, context) {
  // Extract price range if mentioned
  const priceMatch = message.match(/(\d+(?:,\d+)*(?:\.\d+)?)/g);
  let maxPrice = null;
  
  if (priceMatch) {
    maxPrice = parseInt(priceMatch[0].replace(/,/g, ''));
  }
  
  let query = { isApproved: true, isActive: true };
  
  // If we have context from previous location search
  if (context.location) {
    query.$or = [
      { 'address.city': { $regex: context.location, $options: 'i' } },
      { 'address.state': { $regex: context.location, $options: 'i' } }
    ];
  }
  
  const hotels = await Hotel.find(query).limit(10);
  
  // Get rooms for price filtering
  const hotelIds = hotels.map(h => h._id);
  const rooms = await Room.find({ 
    hotel: { $in: hotelIds }, 
    isActive: true,
    ...(maxPrice && { basePrice: { $lte: maxPrice } })
  }).populate('hotel', 'name starRating address');
  
  if (rooms.length === 0) {
    return {
      text: maxPrice 
        ? `I couldn't find any rooms under ${maxPrice.toLocaleString()} VND. Would you like to see options in a higher price range?`
        : 'I can help you find hotels within your budget! Could you please specify your price range?',
      type: 'price_clarification',
      suggestions: [
        'Under 500,000 VND per night',
        'Under 1,000,000 VND per night',
        'Under 2,000,000 VND per night',
        'Show me all available rooms'
      ]
    };
  }
  
  let response = maxPrice 
    ? `Here are rooms under ${maxPrice.toLocaleString()} VND per night:\n\n`
    : 'Here are some room options with prices:\n\n';
  
  rooms.slice(0, 5).forEach((room, index) => {
    response += `${index + 1}. **${room.name}** at ${room.hotel.name}\n`;
    response += `   💰 ${room.basePrice.toLocaleString()} VND/night\n`;
    response += `   🛏️ ${room.type} room, max ${room.maxGuests} guests\n`;
    response += `   ⭐ ${room.hotel.starRating} star hotel\n\n`;
  });
  
  return {
    text: response,
    type: 'price_list',
    data: rooms.slice(0, 5),
    suggestions: [
      'Show me hotel amenities',
      'How do I book a room?',
      'Show me cheaper options',
      'Show me luxury options'
    ]
  };
}

async function handleAmenityQuery(message, context) {
  const amenityMap = {
    'pool': 'pool',
    'swimming': 'pool',
    'gym': 'gym',
    'fitness': 'gym',
    'wifi': 'wifi',
    'internet': 'wifi',
    'breakfast': 'restaurant',
    'parking': 'parking',
    'spa': 'spa',
    'restaurant': 'restaurant'
  };
  
  let requestedAmenity = '';
  for (const [keyword, amenity] of Object.entries(amenityMap)) {
    if (message.includes(keyword)) {
      requestedAmenity = amenity;
      break;
    }
  }
  
  if (!requestedAmenity) {
    return {
      text: 'I can help you find hotels with specific amenities! What amenities are you looking for?',
      type: 'amenity_clarification',
      suggestions: [
        'Hotels with swimming pool',
        'Hotels with gym',
        'Hotels with free WiFi',
        'Hotels with parking'
      ]
    };
  }
  
  const hotels = await Hotel.find({
    isApproved: true,
    isActive: true,
    amenities: requestedAmenity
  }).limit(5);
  
  if (hotels.length === 0) {
    return {
      text: `I couldn't find any hotels with ${requestedAmenity}. Here are some popular amenities you might be interested in:`,
      type: 'no_amenity_results',
      suggestions: [
        'Hotels with swimming pool',
        'Hotels with restaurant',
        'Hotels with parking',
        'Show me all amenities'
      ]
    };
  }
  
  const amenityNames = {
    'pool': 'swimming pool',
    'gym': 'fitness center',
    'wifi': 'free WiFi',
    'parking': 'parking',
    'spa': 'spa services',
    'restaurant': 'restaurant'
  };
  
  let response = `Here are hotels with ${amenityNames[requestedAmenity]}:\n\n`;
  
  hotels.forEach((hotel, index) => {
    response += `${index + 1}. **${hotel.name}**\n`;
    response += `   ⭐ ${hotel.starRating} stars\n`;
    response += `   📍 ${hotel.address.city}\n`;
    response += `   🏨 ${hotel.amenities.length} amenities available\n\n`;
  });
  
  return {
    text: response,
    type: 'amenity_list',
    data: hotels,
    suggestions: [
      'Show me room prices',
      'More amenities available',
      'How do I book?',
      'Show me hotel details'
    ]
  };
}

async function handleStarRatingQuery(message, context) {
  let starRating = null;
  
  if (message.includes('5 star') || message.includes('luxury') || message.includes('five star')) {
    starRating = 5;
  } else if (message.includes('4 star') || message.includes('four star')) {
    starRating = 4;
  } else if (message.includes('3 star') || message.includes('three star') || message.includes('budget')) {
    starRating = 3;
  }
  
  if (!starRating) {
    return {
      text: 'What type of hotel are you looking for?',
      type: 'rating_clarification',
      suggestions: [
        '5-star luxury hotels',
        '4-star hotels',
        '3-star budget hotels',
        'Show me all hotels'
      ]
    };
  }
  
  const hotels = await Hotel.find({
    isApproved: true,
    isActive: true,
    starRating: starRating
  }).limit(5);
  
  const ratingNames = {
    5: 'luxury 5-star',
    4: '4-star',
    3: 'budget-friendly 3-star'
  };
  
  let response = `Here are ${ratingNames[starRating]} hotels:\n\n`;
  
  hotels.forEach((hotel, index) => {
    response += `${index + 1}. **${hotel.name}**\n`;
    response += `   ⭐ ${hotel.starRating} stars\n`;
    response += `   📍 ${hotel.address.city}\n`;
    if (hotel.averageRating > 0) {
      response += `   💝 ${hotel.averageRating.toFixed(1)}/5 rating\n`;
    }
    response += '\n';
  });
  
  return {
    text: response,
    type: 'rating_list',
    data: hotels,
    suggestions: [
      'Show me prices',
      'Hotel amenities',
      'How to book',
      'Search other star ratings'
    ]
  };
}

function handleBookingHelp(message, context) {
  return {
    text: 'I\'d be happy to help you with booking! Here\'s how to make a reservation:\n\n' +
          '1. **Search & Select**: Find your preferred hotel and room\n' +
          '2. **Choose Dates**: Select your check-in and check-out dates\n' +
          '3. **Guest Details**: Provide guest information\n' +
          '4. **Payment**: Complete payment via VNPAY or international cards\n' +
          '5. **Confirmation**: Receive booking confirmation via email\n\n' +
          '💡 **Tips:**\n' +
          '• Book early for better rates\n' +
          '• Check cancellation policies\n' +
          '• Diamond members get 5% discount\n\n' +
          'Would you like help finding a specific hotel?',
    type: 'booking_help',
    suggestions: [
      'Find hotels for specific dates',
      'What payment methods are accepted?',
      'Cancellation policies',
      'Membership benefits'
    ]
  };
}

function handlePaymentQuery(message, context) {
  return {
    text: 'We accept multiple payment methods for your convenience:\n\n' +
          '🇻🇳 **For Vietnamese customers:**\n' +
          '• VNPAY (All Vietnamese banks)\n' +
          '• ATM cards\n' +
          '• Internet banking\n\n' +
          '🌍 **For international customers:**\n' +
          '• Visa, Mastercard, American Express\n' +
          '• Stripe secure payment\n\n' +
          '🔒 **Security:**\n' +
          '• All payments are encrypted\n' +
          '• PCI DSS compliant\n' +
          '• No card details stored\n\n' +
          '💰 **Payment is required upfront** to confirm your booking.',
    type: 'payment_info',
    suggestions: [
      'How do I get a refund?',
      'Is my payment secure?',
      'Booking cancellation policy',
      'How to make a booking?'
    ]
  };
}

function handleCancellationQuery(message, context) {
  return {
    text: 'Our cancellation policies vary by hotel, but here are the general guidelines:\n\n' +
          '🟢 **Flexible Policy:**\n' +
          '• Free cancellation until 24 hours before check-in\n' +
          '• Full refund if cancelled in time\n\n' +
          '🟡 **Moderate Policy:**\n' +
          '• Free cancellation up to 7 days before\n' +
          '• 50% charge if cancelled 1-7 days before\n' +
          '• No refund if cancelled within 24 hours\n\n' +
          '🔴 **Strict Policy:**\n' +
          '• 25% charge if cancelled 14+ days before\n' +
          '• 50% charge if cancelled 7-14 days before\n' +
          '• 75% charge if cancelled 1-7 days before\n' +
          '• No refund if cancelled within 24 hours\n\n' +
          '📋 Check specific hotel policy before booking!',
    type: 'cancellation_info',
    suggestions: [
      'How to cancel my booking?',
      'Refund processing time',
      'Change booking dates',
      'Contact customer support'
    ]
  };
}

module.exports = router;
