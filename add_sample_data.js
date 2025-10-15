const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('./models/User');
const Hotel = require('./models/Hotel');
const Room = require('./models/Room');
const Booking = require('./models/Booking');
const Review = require('./models/Review');

// Load environment variables
require('dotenv').config();

// MongoDB connection
const MONGODB_URI = process.env.MONGODB_URI;

async function connectDB() {
  try {
    await mongoose.connect(MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('✅ Connected to MongoDB');
  } catch (error) {
    console.error('❌ MongoDB connection error:', error);
    process.exit(1);
  }
}

async function clearData() {
  console.log('🗑️ Clearing existing data...');
  await Review.deleteMany({});
  await Booking.deleteMany({});
  await Room.deleteMany({});
  await Hotel.deleteMany({});
  await User.deleteMany({});
  console.log('✅ Data cleared');
}

async function addSampleUsers() {
  console.log('👥 Adding sample users...');
  
  const users = [
    // Admin
    {
      email: 'admin@hotel.com',
      password: await bcrypt.hash('admin123', 12),
      firstName: 'Admin',
      lastName: 'System',
      role: 'admin',
      isEmailVerified: true,
      membershipTier: 'diamond',
      isApproved: true,
      phone: '+84901234567',
      address: {
        street: '123 Admin St',
        city: 'Ho Chi Minh City',
        state: 'Ho Chi Minh',
        country: 'Vietnam',
        zipCode: '70000'
      }
    },
    
    // Hotel Owners
    {
      email: 'owner1@hotel.com',
      password: await bcrypt.hash('owner123', 12),
      firstName: 'Nguyen',
      lastName: 'Van A',
      role: 'hotel_owner',
      isEmailVerified: true,
      isApproved: true,
      businessLicense: 'BL001234567',
      identityDocument: 'ID001234567',
      phone: '+84902345678',
      address: {
        street: '456 Business Ave',
        city: 'Ho Chi Minh City',
        state: 'Ho Chi Minh',
        country: 'Vietnam',
        zipCode: '70000'
      }
    },
    {
      email: 'owner2@hotel.com',
      password: await bcrypt.hash('owner123', 12),
      firstName: 'Tran',
      lastName: 'Thi B',
      role: 'hotel_owner',
      isEmailVerified: true,
      isApproved: true,
      businessLicense: 'BL002345678',
      identityDocument: 'ID002345678',
      phone: '+84903456789',
      address: {
        street: '789 Resort Rd',
        city: 'Da Nang',
        state: 'Da Nang',
        country: 'Vietnam',
        zipCode: '50000'
      }
    },
    
    // Customers
    {
      email: 'customer1@gmail.com',
      password: await bcrypt.hash('customer123', 12),
      firstName: 'Le',
      lastName: 'Van C',
      role: 'customer',
      isEmailVerified: true,
      membershipTier: 'gold',
      totalSpent: 5000000,
      phone: '+84904567890',
      address: {
        street: '101 Customer St',
        city: 'Hanoi',
        state: 'Hanoi',
        country: 'Vietnam',
        zipCode: '10000'
      }
    },
    {
      email: 'customer2@gmail.com',
      password: await bcrypt.hash('customer123', 12),
      firstName: 'Pham',
      lastName: 'Thi D',
      role: 'customer',
      isEmailVerified: true,
      membershipTier: 'silver',
      totalSpent: 2000000,
      phone: '+84905678901',
      address: {
        street: '202 Guest Ave',
        city: 'Ho Chi Minh City',
        state: 'Ho Chi Minh',
        country: 'Vietnam',
        zipCode: '70000'
      }
    },
    {
      email: 'customer3@gmail.com',
      password: await bcrypt.hash('customer123', 12),
      firstName: 'Hoang',
      lastName: 'Van E',
      role: 'customer',
      isEmailVerified: true,
      membershipTier: 'bronze',
      totalSpent: 500000,
      phone: '+84906789012',
      address: {
        street: '303 Tourist Blvd',
        city: 'Nha Trang',
        state: 'Khanh Hoa',
        country: 'Vietnam',
        zipCode: '57000'
      }
    }
  ];
  
  const createdUsers = await User.insertMany(users);
  console.log(`✅ Created ${createdUsers.length} users`);
  return createdUsers;
}

async function addSampleHotels(users) {
  console.log('🏨 Adding sample hotels...');
  
  const owner1 = users.find(u => u.email === 'owner1@hotel.com');
  const owner2 = users.find(u => u.email === 'owner2@hotel.com');
  
  const hotels = [
    {
      name: 'Grand Saigon Hotel',
      description: 'Luxury 5-star hotel in the heart of Ho Chi Minh City with exceptional service and modern amenities.',
      owner: owner1._id,
      slug: 'grand-saigon-hotel',
      address: {
        street: '123 Nguyen Hue Boulevard',
        city: 'Ho Chi Minh City',
        state: 'Ho Chi Minh',
        country: 'Vietnam',
        zipCode: '70000',
        coordinates: {
          latitude: 10.7769,
          longitude: 106.7009
        }
      },
      starRating: 5,
      images: [
        {
          url: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800',
          caption: 'Hotel Exterior',
          isPrimary: true
        },
        {
          url: 'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?w=800',
          caption: 'Lobby'
        }
      ],
      amenities: ['wifi', 'parking', 'pool', 'gym', 'spa', 'restaurant', 'bar', 'room_service', 'concierge', 'laundry'],
      checkInTime: '14:00',
      checkOutTime: '12:00',
      cancellationPolicy: 'moderate',
      phone: '+84288888888',
      email: 'info@grandsaigon.com',
      website: 'https://grandsaigon.com',
      isApproved: true,
      isActive: true,
      totalRooms: 200,
      averageRating: 4.5,
      totalReviews: 150
    },
    {
      name: 'Beachside Resort Da Nang',
      description: 'Beautiful beachfront resort with stunning ocean views and world-class facilities.',
      owner: owner2._id,
      slug: 'beachside-resort-da-nang',
      address: {
        street: '456 My Khe Beach',
        city: 'Da Nang',
        state: 'Da Nang',
        country: 'Vietnam',
        zipCode: '50000',
        coordinates: {
          latitude: 16.0544,
          longitude: 108.2022
        }
      },
      starRating: 4,
      images: [
        {
          url: 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=800',
          caption: 'Ocean View',
          isPrimary: true
        },
        {
          url: 'https://images.unsplash.com/photo-1544966503-7cc5ac882d5a?w=800',
          caption: 'Pool Area'
        }
      ],
      amenities: ['wifi', 'parking', 'pool', 'gym', 'spa', 'restaurant', 'bar', 'airport_shuttle'],
      checkInTime: '15:00',
      checkOutTime: '11:00',
      cancellationPolicy: 'flexible',
      phone: '+84236666666',
      email: 'info@beachsidedanang.com',
      website: 'https://beachsidedanang.com',
      isApproved: true,
      isActive: true,
      totalRooms: 150,
      averageRating: 4.2,
      totalReviews: 89
    },
    {
      name: 'City Center Business Hotel',
      description: 'Modern business hotel perfect for corporate travelers with excellent meeting facilities.',
      owner: owner1._id,
      slug: 'city-center-business-hotel',
      address: {
        street: '789 Le Loi Street',
        city: 'Ho Chi Minh City',
        state: 'Ho Chi Minh',
        country: 'Vietnam',
        zipCode: '70000',
        coordinates: {
          latitude: 10.7769,
          longitude: 106.6885
        }
      },
      starRating: 4,
      images: [
        {
          url: 'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=800',
          caption: 'Business Center',
          isPrimary: true
        }
      ],
      amenities: ['wifi', 'parking', 'gym', 'restaurant', 'business_center', 'conference_room', 'laundry'],
      checkInTime: '14:00',
      checkOutTime: '12:00',
      cancellationPolicy: 'strict',
      phone: '+84288777777',
      email: 'info@citycenter.com',
      isApproved: true,
      isActive: true,
      totalRooms: 120,
      averageRating: 4.0,
      totalReviews: 67
    }
  ];
  
  const createdHotels = await Hotel.insertMany(hotels);
  console.log(`✅ Created ${createdHotels.length} hotels`);
  return createdHotels;
}

async function addSampleRooms(hotels) {
  console.log('🛏️ Adding sample rooms...');
  
  const rooms = [];
  
  // Rooms for Grand Saigon Hotel
  const grandSaigon = hotels.find(h => h.name === 'Grand Saigon Hotel');
  rooms.push(
    {
      hotel: grandSaigon._id,
      name: 'Deluxe City View',
      type: 'deluxe',
      description: 'Spacious room with panoramic city views and modern amenities.',
      maxGuests: 4,
      bedType: 'king',
      bedCount: 1,
      basePrice: 2500000,
      weekendPrice: 3000000,
      currency: 'VND',
      size: 35,
      amenities: ['wifi', 'air_conditioning', 'tv', 'minibar', 'safe', 'city_view', 'bathtub', 'hairdryer'],
      images: [
        {
          url: 'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800',
          caption: 'City View Room',
          isPrimary: true
        }
      ],
      totalRooms: 50,
      isActive: true
    },
    {
      hotel: grandSaigon._id,
      name: 'Executive Suite',
      type: 'suite',
      description: 'Luxurious suite with separate living area and premium amenities.',
      maxGuests: 4,
      bedType: 'king',
      bedCount: 1,
      basePrice: 5000000,
      weekendPrice: 6000000,
      currency: 'VND',
      size: 65,
      amenities: ['wifi', 'air_conditioning', 'tv', 'minibar', 'safe', 'city_view', 'bathtub', 'sofa', 'desk'],
      images: [
        {
          url: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800',
          caption: 'Executive Suite',
          isPrimary: true
        }
      ],
      totalRooms: 20,
      isActive: true
    }
  );
  
  // Rooms for Beachside Resort Da Nang
  const beachsideResort = hotels.find(h => h.name === 'Beachside Resort Da Nang');
  rooms.push(
    {
      hotel: beachsideResort._id,
      name: 'Ocean View Standard',
      type: 'standard',
      description: 'Comfortable room with beautiful ocean views.',
      maxGuests: 4,
      bedType: 'queen',
      bedCount: 1,
      basePrice: 1800000,
      weekendPrice: 2200000,
      currency: 'VND',
      size: 30,
      amenities: ['wifi', 'air_conditioning', 'tv', 'minibar', 'ocean_view', 'balcony', 'shower'],
      images: [
        {
          url: 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=800',
          caption: 'Ocean View',
          isPrimary: true
        }
      ],
      totalRooms: 80,
      isActive: true,
      discountPercentage: 15,
      specialOfferDescription: 'Early bird discount - Book 30 days in advance'
    },
    {
      hotel: beachsideResort._id,
      name: 'Beachfront Villa',
      type: 'suite',
      description: 'Private villa directly on the beach with exclusive amenities.',
      maxGuests: 6,
      bedType: 'king',
      bedCount: 2,
      basePrice: 8000000,
      weekendPrice: 10000000,
      currency: 'VND',
      size: 120,
      amenities: ['wifi', 'air_conditioning', 'tv', 'minibar', 'safe', 'ocean_view', 'balcony', 'kitchenette', 'bathtub'],
      images: [
        {
          url: 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800',
          caption: 'Beachfront Villa',
          isPrimary: true
        }
      ],
      totalRooms: 10,
      isActive: true
    }
  );
  
  // Rooms for City Center Business Hotel
  const cityCenter = hotels.find(h => h.name === 'City Center Business Hotel');
  rooms.push(
    {
      hotel: cityCenter._id,
      name: 'Business Standard',
      type: 'standard',
      description: 'Efficient room designed for business travelers.',
      maxGuests: 2,
      bedType: 'double',
      bedCount: 1,
      basePrice: 1500000,
      weekendPrice: 1800000,
      currency: 'VND',
      size: 25,
      amenities: ['wifi', 'air_conditioning', 'tv', 'safe', 'desk', 'coffee_maker', 'telephone'],
      images: [
        {
          url: 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=800',
          caption: 'Business Room',
          isPrimary: true
        }
      ],
      totalRooms: 100,
      isActive: true
    }
  );
  
  const createdRooms = await Room.insertMany(rooms);
  console.log(`✅ Created ${createdRooms.length} rooms`);
  return createdRooms;
}

async function addSampleBookings(users, hotels, rooms) {
  console.log('📅 Adding sample bookings...');
  
  const customer1 = users.find(u => u.email === 'customer1@gmail.com');
  const customer2 = users.find(u => u.email === 'customer2@gmail.com');
  const customer3 = users.find(u => u.email === 'customer3@gmail.com');
  
  const grandSaigon = hotels.find(h => h.name === 'Grand Saigon Hotel');
  const beachsideResort = hotels.find(h => h.name === 'Beachside Resort Da Nang');
  
  const deluxeRoom = rooms.find(r => r.name === 'Deluxe City View');
  const oceanRoom = rooms.find(r => r.name === 'Ocean View Standard');
  const villa = rooms.find(r => r.name === 'Beachfront Villa');
  
  const now = new Date();
  const bookings = [
    {
      customer: customer1._id,
      hotel: grandSaigon._id,
      room: deluxeRoom._id,
      bookingNumber: 'BK001' + Date.now(),
      checkIn: new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000), // 7 days from now
      checkOut: new Date(now.getTime() + 10 * 24 * 60 * 60 * 1000), // 10 days from now
      guests: {
        adults: 2,
        children: 0
      },
      guestInfo: {
        firstName: 'Le',
        lastName: 'Van C',
        email: 'customer1@gmail.com',
        phone: '+84904567890',
        specialRequests: 'High floor room if available'
      },
      roomPrice: 2500000,
      nights: 3,
      subtotal: 7500000,
      discountAmount: 375000,
      discountPercentage: 5, // Gold member discount
      taxAmount: 750000,
      totalAmount: 7875000,
      currency: 'VND',
      status: 'confirmed',
      paymentStatus: 'paid',
      paymentMethod: 'vnpay',
      paymentDetails: {
        transactionId: 'VNP' + Date.now(),
        paymentDate: new Date(),
        paymentGatewayResponse: { status: 'success' }
      },
      confirmedAt: new Date()
    },
    // Pending booking to test acceptance (Grand Saigon)
    {
      customer: customer1._id,
      hotel: grandSaigon._id,
      room: deluxeRoom._id,
      bookingNumber: 'BK004' + Date.now(),
      checkIn: new Date(now.getTime() + 21 * 24 * 60 * 60 * 1000),
      checkOut: new Date(now.getTime() + 24 * 24 * 60 * 60 * 1000),
      guests: { adults: 2, children: 0 },
      guestInfo: {
        firstName: 'Le',
        lastName: 'Van C',
        email: 'customer1@gmail.com',
        phone: '+84904567890',
        specialRequests: 'Near elevator if possible'
      },
      roomPrice: 2500000,
      nights: 3,
      subtotal: 7500000,
      discountAmount: 375000,
      discountPercentage: 5,
      taxAmount: 750000,
      totalAmount: 7875000,
      currency: 'VND',
      status: 'pending',
      paymentStatus: 'pending',
      paymentMethod: 'vnpay'
    },
    // Another pending booking (Beachside Resort)
    {
      customer: customer2._id,
      hotel: beachsideResort._id,
      room: oceanRoom._id,
      bookingNumber: 'BK005' + Date.now(),
      checkIn: new Date(now.getTime() + 28 * 24 * 60 * 60 * 1000),
      checkOut: new Date(now.getTime() + 32 * 24 * 60 * 60 * 1000),
      guests: { adults: 2, children: 1 },
      guestInfo: {
        firstName: 'Pham',
        lastName: 'Thi D',
        email: 'customer2@gmail.com',
        phone: '+84905678901',
        specialRequests: 'Quiet room preferred'
      },
      roomPrice: 1800000,
      nights: 4,
      subtotal: 7200000,
      discountAmount: 1080000,
      discountPercentage: 15,
      taxAmount: 612000,
      totalAmount: 6732000,
      currency: 'VND',
      status: 'pending',
      paymentStatus: 'pending',
      paymentMethod: 'vnpay'
    },
    {
      customer: customer2._id,
      hotel: beachsideResort._id,
      room: oceanRoom._id,
      bookingNumber: 'BK002' + Date.now(),
      checkIn: new Date(now.getTime() + 14 * 24 * 60 * 60 * 1000), // 14 days from now
      checkOut: new Date(now.getTime() + 18 * 24 * 60 * 60 * 1000), // 18 days from now
      guests: {
        adults: 2,
        children: 1
      },
      guestInfo: {
        firstName: 'Pham',
        lastName: 'Thi D',
        email: 'customer2@gmail.com',
        phone: '+84905678901',
        specialRequests: 'Extra bed for child'
      },
      roomPrice: 1800000,
      nights: 4,
      subtotal: 7200000,
      discountAmount: 1080000, // 15% early bird discount
      discountPercentage: 15,
      taxAmount: 612000,
      totalAmount: 6732000,
      currency: 'VND',
      status: 'pending',
      paymentStatus: 'pending',
      paymentMethod: 'vnpay'
    },
    {
      customer: customer3._id,
      hotel: beachsideResort._id,
      room: villa._id,
      bookingNumber: 'BK003' + Date.now(),
      checkIn: new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000), // 7 days ago (past booking)
      checkOut: new Date(now.getTime() - 4 * 24 * 60 * 60 * 1000), // 4 days ago
      guests: {
        adults: 4,
        children: 2
      },
      guestInfo: {
        firstName: 'Hoang',
        lastName: 'Van E',
        email: 'customer3@gmail.com',
        phone: '+84906789012',
        specialRequests: 'Anniversary celebration setup'
      },
      roomPrice: 8000000,
      nights: 3,
      subtotal: 24000000,
      discountAmount: 0,
      discountPercentage: 0,
      taxAmount: 2400000,
      totalAmount: 26400000,
      currency: 'VND',
      status: 'checked_out',
      paymentStatus: 'paid',
      paymentMethod: 'stripe',
      paymentDetails: {
        transactionId: 'STR' + Date.now(),
        paymentDate: new Date(now.getTime() - 8 * 24 * 60 * 60 * 1000),
        paymentGatewayResponse: { status: 'success' }
      },
      confirmedAt: new Date(now.getTime() - 8 * 24 * 60 * 60 * 1000),
      checkedInAt: new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000),
      checkedOutAt: new Date(now.getTime() - 4 * 24 * 60 * 60 * 1000)
    }
  ];
  
  const createdBookings = await Booking.insertMany(bookings);
  console.log(`✅ Created ${createdBookings.length} bookings`);
  return createdBookings;
}

async function addSampleReviews(users, hotels, bookings) {
  console.log('⭐ Adding sample reviews...');
  
  const customer3 = users.find(u => u.email === 'customer3@gmail.com');
  const beachsideResort = hotels.find(h => h.name === 'Beachside Resort Da Nang');
  const completedBooking = bookings.find(b => b.status === 'checked_out');
  const hotelOwner2 = users.find(u => u.email === 'owner2@hotel.com');
  
  const reviews = [
    {
      customer: customer3._id,
      hotel: beachsideResort._id,
      booking: completedBooking._id,
      rating: 5,
      title: 'Amazing beachfront experience!',
      comment: 'Absolutely loved our stay at the Beachfront Villa. The ocean view was breathtaking, staff was incredibly helpful, and the amenities were top-notch. Perfect for our anniversary celebration. Will definitely come back!',
      ratings: {
        cleanliness: 5,
        service: 5,
        location: 5,
        value: 4,
        amenities: 5
      },
      images: [
        {
          url: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
          caption: 'Beautiful sunset view'
        }
      ],
      isVerified: true,
      helpfulCount: 12,
      hotelResponse: {
        message: 'Thank you for your wonderful review! We are delighted that you enjoyed your anniversary celebration with us. Looking forward to welcoming you back soon!',
        respondedAt: new Date(),
        respondedBy: hotelOwner2._id
      }
    }
  ];
  
  const createdReviews = await Review.insertMany(reviews);
  console.log(`✅ Created ${createdReviews.length} reviews`);
  return createdReviews;
}

async function updateHotelStats(hotels, reviews) {
  console.log('📊 Updating hotel statistics...');
  
  for (const hotel of hotels) {
    const hotelReviews = reviews.filter(r => r.hotel.toString() === hotel._id.toString());
    if (hotelReviews.length > 0) {
      const averageRating = hotelReviews.reduce((sum, review) => sum + review.rating, 0) / hotelReviews.length;
      await Hotel.findByIdAndUpdate(hotel._id, {
        averageRating: Math.round(averageRating * 10) / 10,
        totalReviews: hotelReviews.length
      });
    }
  }
  
  console.log('✅ Hotel statistics updated');
}

async function addSampleData() {
  try {
    await connectDB();
    
    // Clear existing data
    await clearData();
    
    // Add sample data
    const users = await addSampleUsers();
    const hotels = await addSampleHotels(users);
    const rooms = await addSampleRooms(hotels);
    const bookings = await addSampleBookings(users, hotels, rooms);
    const reviews = await addSampleReviews(users, hotels, bookings);
    
    // Update statistics
    await updateHotelStats(hotels, reviews);
    
    console.log('\n🎉 Sample data added successfully!');
    console.log('\n📋 Summary:');
    console.log(`   👥 Users: ${users.length}`);
    console.log(`   🏨 Hotels: ${hotels.length}`);
    console.log(`   🛏️ Rooms: ${rooms.length}`);
    console.log(`   📅 Bookings: ${bookings.length}`);
    console.log(`   ⭐ Reviews: ${reviews.length}`);
    
    console.log('\n🔑 Test Accounts:');
    console.log('   Admin: admin@hotel.com / admin123');
    console.log('   Hotel Owner 1: owner1@hotel.com / owner123');
    console.log('   Hotel Owner 2: owner2@hotel.com / owner123');
    console.log('   Customer 1: customer1@gmail.com / customer123 (Gold tier)');
    console.log('   Customer 2: customer2@gmail.com / customer123 (Silver tier)');
    console.log('   Customer 3: customer3@gmail.com / customer123 (Bronze tier)');
    
  } catch (error) {
    console.error('❌ Error adding sample data:', error);
  } finally {
    await mongoose.connection.close();
    console.log('✅ Database connection closed');
  }
}

// Run the script
if (require.main === module) {
  addSampleData();
}

module.exports = { addSampleData };
