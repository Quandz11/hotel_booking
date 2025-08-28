import 'package:flutter/material.dart';

class Booking {
  final String id;
  final String bookingNumber;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String hotelId;
  final String hotelName;
  final String roomId;
  final String roomName;
  final DateTime checkIn;
  final DateTime checkOut;
  final int nights;
  final int adults;
  final int children;
  final double totalAmount;
  final String currency;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final DateTime createdAt;
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;
  final String? specialRequests;

  const Booking({
    required this.id,
    required this.bookingNumber,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.hotelId,
    required this.hotelName,
    required this.roomId,
    required this.roomName,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.adults,
    required this.children,
    required this.totalAmount,
    required this.currency,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.createdAt,
    this.checkedInAt,
    this.checkedOutAt,
    this.specialRequests,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    try {
      print('🔄 Parsing booking JSON: ${json['_id']}');
      
      // Handle hotel field - can be String ID or Object
      String hotelId = '';
      String hotelName = '';
      try {
        if (json['hotel'] is String) {
          hotelId = json['hotel'];
          hotelName = 'Hotel'; // Default name when only ID is available
        } else if (json['hotel'] is Map<String, dynamic>) {
          hotelId = json['hotel']['_id'] ?? '';
          hotelName = json['hotel']['name'] ?? '';
        }
      } catch (e) {
        print('❌ Error parsing hotel: $e');
        hotelId = '';
        hotelName = 'Hotel';
      }
      
      // Handle room field - can be String ID or Object
      String roomId = '';
      String roomName = '';
      try {
        if (json['room'] is String) {
          roomId = json['room'];
          roomName = 'Room'; // Default name when only ID is available
        } else if (json['room'] is Map<String, dynamic>) {
          roomId = json['room']['_id'] ?? '';
          roomName = json['room']['name'] ?? '';
        }
      } catch (e) {
        print('❌ Error parsing room: $e');
        roomId = '';
        roomName = 'Room';
      }

      // Parse dates safely with better error handling
      DateTime checkInDate = DateTime.now();
      DateTime checkOutDate = DateTime.now().add(const Duration(days: 1));
      
      try {
        if (json['checkIn'] is String && json['checkIn'].isNotEmpty) {
          checkInDate = DateTime.parse(json['checkIn']);
        } else if (json['checkInDate'] is String && json['checkInDate'].isNotEmpty) {
          checkInDate = DateTime.parse(json['checkInDate']);
        }
      } catch (e) {
        print('❌ Error parsing checkIn date: $e');
        checkInDate = DateTime.now();
      }
      
      try {
        if (json['checkOut'] is String && json['checkOut'].isNotEmpty) {
          checkOutDate = DateTime.parse(json['checkOut']);
        } else if (json['checkOutDate'] is String && json['checkOutDate'].isNotEmpty) {
          checkOutDate = DateTime.parse(json['checkOutDate']);
        }
      } catch (e) {
        print('❌ Error parsing checkOut date: $e');
        checkOutDate = DateTime.now().add(const Duration(days: 1));
      }

      // Parse createdAt safely
      DateTime createdAtDate = DateTime.now();
      try {
        if (json['createdAt'] is String && json['createdAt'].isNotEmpty) {
          createdAtDate = DateTime.parse(json['createdAt']);
        }
      } catch (e) {
        print('❌ Error parsing createdAt date: $e');
        createdAtDate = DateTime.now();
      }
      
      // Parse customer info safely
      String customerId = '';
      String customerName = 'Guest';
      String customerEmail = '';
      
      try {
        if (json['customer'] is String) {
          customerId = json['customer'];
        } else if (json['customer'] is Map<String, dynamic>) {
          customerId = json['customer']['_id'] ?? '';
          if (json['customer']['firstName'] != null) {
            customerName = '${json['customer']['firstName']} ${json['customer']['lastName'] ?? ''}';
          }
          customerEmail = json['customer']['email'] ?? '';
        }
        
        // Fallback to guestInfo if customer info not available
        if (customerName == 'Guest' && json['guestInfo'] is Map<String, dynamic>) {
          if (json['guestInfo']['firstName'] != null) {
            customerName = '${json['guestInfo']['firstName']} ${json['guestInfo']['lastName'] ?? ''}';
          }
          if (customerEmail.isEmpty) {
            customerEmail = json['guestInfo']['email'] ?? '';
          }
        }
      } catch (e) {
        print('❌ Error parsing customer info: $e');
      }

      // Parse numeric fields safely
      int nights = 1;
      int adults = 1;
      int children = 0;
      double totalAmount = 0.0;
      
      try {
        nights = int.tryParse(json['nights']?.toString() ?? '1') ?? 1;
      } catch (e) {
        print('❌ Error parsing nights: $e');
        nights = 1;
      }
      
      try {
        adults = int.tryParse(json['guests']?['adults']?.toString() ?? json['adults']?.toString() ?? '1') ?? 1;
      } catch (e) {
        print('❌ Error parsing adults: $e');
        adults = 1;
      }
      
      try {
        children = int.tryParse(json['guests']?['children']?.toString() ?? json['children']?.toString() ?? '0') ?? 0;
      } catch (e) {
        print('❌ Error parsing children: $e');
        children = 0;
      }
      
      try {
        totalAmount = double.tryParse(
          (json['totalAmount'] ?? json['total'] ?? json['totalPrice'] ?? 0.0).toString()
        ) ?? 0.0;
      } catch (e) {
        print('❌ Error parsing totalAmount: $e');
        totalAmount = 0.0;
      }
      
      return Booking(
        id: json['_id']?.toString() ?? '',
        bookingNumber: json['bookingNumber']?.toString() ?? json['_id']?.toString() ?? '',
        customerId: customerId,
        customerName: customerName,
        customerEmail: customerEmail,
        hotelId: hotelId,
        hotelName: hotelName,
        roomId: roomId,
        roomName: roomName,
        checkIn: checkInDate,
        checkOut: checkOutDate,
        nights: nights,
        adults: adults,
        children: children,
        totalAmount: totalAmount,
        currency: json['currency']?.toString() ?? 'VND',
        status: json['status']?.toString() ?? 'confirmed',
        paymentStatus: json['paymentStatus']?.toString() ?? json['paymentDetails']?['status']?.toString() ?? 'paid',
        paymentMethod: json['paymentMethod']?.toString() ?? '',
        createdAt: createdAtDate,
        checkedInAt: json['checkedInAt'] is String && json['checkedInAt'].isNotEmpty
            ? DateTime.parse(json['checkedInAt'])
            : null,
        checkedOutAt: json['checkedOutAt'] is String && json['checkedOutAt'].isNotEmpty
            ? DateTime.parse(json['checkedOutAt'])
            : null,
        specialRequests: json['guestInfo']?['specialRequests']?.toString() ?? json['specialRequests']?.toString(),
      );
    } catch (e) {
      print('❌ Error parsing booking JSON: $e');
      print('📄 JSON data: $json');
      rethrow;
    }
  }

  // Helper methods
  bool get isUpcoming => status == 'confirmed' && DateTime.now().isBefore(checkIn);
  bool get isActive => status == 'checked_in';
  bool get isCompleted => status == 'checked_out';
  bool get isCancelled => status == 'cancelled';
  bool get isPending => status == 'pending';
  
  String get statusDisplayText {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'checked_in':
        return 'Checked In';
      case 'checked_out':
        return 'Checked Out';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'checked_in':
        return Colors.green;
      case 'checked_out':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class DashboardStats {
  final int totalBookings;
  final int pendingBookings;
  final int activeBookings;
  final int completedBookings;
  final int totalRooms;
  final int availableRooms;
  final int occupiedRooms;
  final double monthlyRevenue;
  final double totalRevenue;
  final double occupancyRate;

  const DashboardStats({
    this.totalBookings = 0,
    this.pendingBookings = 0,
    this.activeBookings = 0,
    this.completedBookings = 0,
    this.totalRooms = 0,
    this.availableRooms = 0,
    this.occupiedRooms = 0,
    this.monthlyRevenue = 0.0,
    this.totalRevenue = 0.0,
    this.occupancyRate = 0.0,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalBookings: json['totalBookings'] ?? 0,
      pendingBookings: json['pendingBookings'] ?? 0,
      activeBookings: json['activeBookings'] ?? 0,
      completedBookings: json['completedBookings'] ?? 0,
      totalRooms: json['totalRooms'] ?? 0,
      availableRooms: json['availableRooms'] ?? 0,
      occupiedRooms: json['occupiedRooms'] ?? 0,
      monthlyRevenue: (json['monthlyRevenue'] ?? 0.0).toDouble(),
      totalRevenue: (json['totalRevenue'] ?? 0.0).toDouble(),
      occupancyRate: (json['occupancyRate'] ?? 0.0).toDouble(),
    );
  }

  factory DashboardStats.fromBookings(List<Booking> bookings) {
    return DashboardStats(
      totalBookings: bookings.length,
      pendingBookings: bookings.where((b) => b.isPending).length,
      activeBookings: bookings.where((b) => b.isActive).length,
      completedBookings: bookings.where((b) => b.isCompleted).length,
    );
  }
}
