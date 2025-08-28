import 'package:flutter/material.dart';

class Room {
  final String id;
  final String hotelId;
  final String name;
  final String type;
  final String description;
  final int maxGuests;
  final String bedType;
  final int bedCount;
  final double basePrice;
  final double weekendPrice;
  final String currency;
  final double? size;
  final List<String> amenities;
  final List<RoomImage> images;
  final int totalRooms;
  final bool isActive;
  final double discountPercentage;
  final String? specialOfferDescription;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Additional fields for availability and pricing
  final RoomAvailability? availability;
  final RoomPricing? pricing;

  const Room({
    required this.id,
    required this.hotelId,
    required this.name,
    required this.type,
    this.description = '',
    required this.maxGuests,
    required this.bedType,
    required this.bedCount,
    required this.basePrice,
    required this.weekendPrice,
    this.currency = 'VND',
    this.size,
    this.amenities = const [],
    this.images = const [],
    required this.totalRooms,
    this.isActive = true,
    this.discountPercentage = 0,
    this.specialOfferDescription,
    required this.createdAt,
    required this.updatedAt,
    this.availability,
    this.pricing,
  });

  // Convenience getters for compatibility
  double get pricePerNight => basePrice;
  double get price => basePrice;
  int get beds => bedCount;

  factory Room.fromJson(Map<String, dynamic> json) {
    // Handle hotel field - can be either a string ID or populated object
    String extractHotelId(dynamic hotel) {
      if (hotel is String) return hotel;
      if (hotel is Map<String, dynamic>) return hotel['_id'] ?? '';
      return '';
    }

    // Parse images from either old format (List<String>) or new format (List<RoomImage>)
    List<RoomImage> parseImages(dynamic images) {
      if (images == null) return [];
      if (images is List) {
        return images.map<RoomImage>((image) {
          if (image is String) {
            return RoomImage(url: image, caption: '', isPrimary: false);
          }
          if (image is Map<String, dynamic>) {
            return RoomImage.fromJson(image);
          }
          return RoomImage(url: '', caption: '', isPrimary: false);
        }).where((img) => img.url.isNotEmpty).toList();
      }
      return [];
    }

    return Room(
      id: json['_id'] ?? '',
      hotelId: extractHotelId(json['hotel']),
      name: json['name'] ?? '',
      type: json['type'] ?? 'standard',
      description: json['description'] ?? '',
      maxGuests: json['maxGuests'] ?? 1,
      bedType: json['bedType'] ?? 'single',
      bedCount: json['bedCount'] ?? 1,
      basePrice: (json['basePrice'] ?? json['price'] ?? 0).toDouble(),
      weekendPrice: (json['weekendPrice'] ?? json['price'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'VND',
      size: json['size']?.toDouble(),
      amenities: List<String>.from(json['amenities'] ?? []),
      images: parseImages(json['images']),
      totalRooms: json['totalRooms'] ?? 1,
      isActive: json['isActive'] ?? true,
      discountPercentage: (json['discountPercentage'] ?? 0).toDouble(),
      specialOfferDescription: json['specialOfferDescription'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      availability: json['availability'] != null 
          ? RoomAvailability.fromJson(json['availability'])
          : null,
      pricing: json['pricing'] != null 
          ? RoomPricing.fromJson(json['pricing'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'hotel': hotelId,
      'name': name,
      'type': type,
      'description': description,
      'maxGuests': maxGuests,
      'bedType': bedType,
      'bedCount': bedCount,
      'basePrice': basePrice,
      'weekendPrice': weekendPrice,
      'currency': currency,
      'size': size,
      'amenities': amenities,
      'images': images.map((img) => img.toJson()).toList(),
      'totalRooms': totalRooms,
      'isActive': isActive,
      'discountPercentage': discountPercentage,
      'specialOfferDescription': specialOfferDescription,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get formattedBasePrice {
    if (currency == 'VND') {
      return '${basePrice.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )} ₫';
    }
    return '${currency} ${basePrice.toStringAsFixed(2)}';
  }

  String get formattedWeekendPrice {
    if (currency == 'VND') {
      return '${weekendPrice.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )} ₫';
    }
    return '${currency} ${weekendPrice.toStringAsFixed(2)}';
  }

  String get guestCapacity {
    return maxGuests == 1 ? '1 guest' : '$maxGuests guests';
  }

  String get bedInfo {
    return '$bedCount $bedType bed${bedCount > 1 ? 's' : ''}';
  }

  String get sizeInfo {
    return size != null ? '${size!.toStringAsFixed(0)} m²' : '';
  }

  Color get statusColor {
    return isActive ? Colors.green : Colors.grey;
  }

  String get statusText {
    return isActive ? 'Active' : 'Inactive';
  }

  // Helper method to get room type icon
  IconData get typeIcon {
    switch (type.toLowerCase()) {
      case 'deluxe':
        return Icons.hotel;
      case 'suite':
        return Icons.apartment;
      case 'standard':
        return Icons.bed;
      case 'executive':
        return Icons.business;
      case 'presidential':
        return Icons.castle;
      default:
        return Icons.room;
    }
  }

  Room copyWith({
    String? id,
    String? hotelId,
    String? name,
    String? type,
    String? description,
    int? maxGuests,
    String? bedType,
    int? bedCount,
    double? basePrice,
    double? weekendPrice,
    String? currency,
    double? size,
    List<String>? amenities,
    List<RoomImage>? images,
    int? totalRooms,
    bool? isActive,
    double? discountPercentage,
    String? specialOfferDescription,
    DateTime? createdAt,
    DateTime? updatedAt,
    RoomAvailability? availability,
    RoomPricing? pricing,
  }) {
    return Room(
      id: id ?? this.id,
      hotelId: hotelId ?? this.hotelId,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      maxGuests: maxGuests ?? this.maxGuests,
      bedType: bedType ?? this.bedType,
      bedCount: bedCount ?? this.bedCount,
      basePrice: basePrice ?? this.basePrice,
      weekendPrice: weekendPrice ?? this.weekendPrice,
      currency: currency ?? this.currency,
      size: size ?? this.size,
      amenities: amenities ?? this.amenities,
      images: images ?? this.images,
      totalRooms: totalRooms ?? this.totalRooms,
      isActive: isActive ?? this.isActive,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      specialOfferDescription: specialOfferDescription ?? this.specialOfferDescription,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      availability: availability ?? this.availability,
      pricing: pricing ?? this.pricing,
    );
  }
}

class RoomImage {
  final String url;
  final String caption;
  final bool isPrimary;

  const RoomImage({
    required this.url,
    required this.caption,
    required this.isPrimary,
  });

  factory RoomImage.fromJson(Map<String, dynamic> json) {
    return RoomImage(
      url: json['url'] ?? '',
      caption: json['caption'] ?? '',
      isPrimary: json['isPrimary'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'caption': caption,
      'isPrimary': isPrimary,
    };
  }
}

class RoomAvailability {
  final bool available;
  final int? availableRooms;
  final int? totalRooms;
  final String? reason;

  const RoomAvailability({
    required this.available,
    this.availableRooms,
    this.totalRooms,
    this.reason,
  });

  factory RoomAvailability.fromJson(Map<String, dynamic> json) {
    return RoomAvailability(
      available: json['available'] ?? false,
      availableRooms: json['availableRooms'],
      totalRooms: json['totalRooms'],
      reason: json['reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'available': available,
      'availableRooms': availableRooms,
      'totalRooms': totalRooms,
      'reason': reason,
    };
  }
}

class RoomPricing {
  final double totalPrice;
  final int nights;
  final double averagePerNight;

  const RoomPricing({
    required this.totalPrice,
    required this.nights,
    required this.averagePerNight,
  });

  factory RoomPricing.fromJson(Map<String, dynamic> json) {
    return RoomPricing(
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      nights: json['nights'] ?? 0,
      averagePerNight: (json['averagePerNight'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPrice': totalPrice,
      'nights': nights,
      'averagePerNight': averagePerNight,
    };
  }
}
