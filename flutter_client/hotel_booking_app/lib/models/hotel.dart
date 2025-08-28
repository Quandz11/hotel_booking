class Hotel {
  final String id;
  final String name;
  final String description;
  final HotelAddress address;
  final List<HotelImage> images;
  final List<String> amenities;
  final HotelPolicies policies;
  final HotelContact contact;
  final double averageRating;
  final int totalReviews;
  final double startingPrice;
  final String currency;
  final bool isActive;
  final String slug;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int starRating; // Add starRating field

  const Hotel({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.images,
    required this.amenities,
    required this.policies,
    required this.contact,
    required this.averageRating,
    required this.totalReviews,
    required this.startingPrice,
    required this.currency,
    required this.isActive,
    required this.slug,
    required this.createdAt,
    required this.updatedAt,
    required this.starRating, // Add to constructor
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    // Handle both new format (with contact/policies objects) and old format (direct fields)
    Map<String, dynamic> contactData = {};
    Map<String, dynamic> policiesData = {};
    
    if (json['contact'] != null) {
      contactData = json['contact'];
    } else {
      // Fallback to direct fields for backward compatibility
      contactData = {
        'phone': json['phone'] ?? '',
        'email': json['email'] ?? '',
        'website': json['website'] ?? '',
      };
    }
    
    if (json['policies'] != null) {
      policiesData = json['policies'];
    } else {
      // Fallback to direct fields for backward compatibility
      policiesData = {
        'checkIn': json['checkInTime'] ?? '14:00',
        'checkOut': json['checkOutTime'] ?? '12:00',
        'cancellation': json['cancellationPolicy'] ?? 'moderate',
      };
    }

    return Hotel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      address: HotelAddress.fromJson(json['address'] ?? {}),
      images: (json['images'] as List<dynamic>?)
          ?.map((img) => HotelImage.fromJson(img as Map<String, dynamic>))
          .toList() ?? [],
      amenities: List<String>.from(json['amenities'] ?? []),
      policies: HotelPolicies.fromJson(policiesData),
      contact: HotelContact.fromJson(contactData),
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      startingPrice: (json['startingPrice'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'VND',
      isActive: json['isActive'] ?? true,
      slug: json['slug'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      starRating: json['starRating'] ?? 3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'address': address.toJson(),
      'images': images.map((img) => img.toJson()).toList(),
      'amenities': amenities,
      'policies': policies.toJson(),
      'contact': contact.toJson(),
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'startingPrice': startingPrice,
      'currency': currency,
      'isActive': isActive,
      'slug': slug,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'starRating': starRating,
    };
  }
}

class HotelAddress {
  final String street;
  final String city;
  final String state;
  final String country;
  final String zipCode;
  final HotelCoordinates coordinates;

  const HotelAddress({
    required this.street,
    required this.city,
    required this.state,
    required this.country,
    required this.zipCode,
    required this.coordinates,
  });

  factory HotelAddress.fromJson(Map<String, dynamic> json) {
    return HotelAddress(
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      zipCode: json['zipCode'] ?? '',
      coordinates: HotelCoordinates.fromJson(json['coordinates'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'country': country,
      'zipCode': zipCode,
      'coordinates': coordinates.toJson(),
    };
  }
}

class HotelCoordinates {
  final double latitude;
  final double longitude;

  const HotelCoordinates({
    required this.latitude,
    required this.longitude,
  });

  factory HotelCoordinates.fromJson(Map<String, dynamic> json) {
    return HotelCoordinates(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class HotelPolicies {
  final String checkIn;
  final String checkOut;
  final String cancellation;
  final List<String> houseRules;
  final bool allowPets;
  final bool allowSmoking;

  const HotelPolicies({
    required this.checkIn,
    required this.checkOut,
    required this.cancellation,
    required this.houseRules,
    required this.allowPets,
    required this.allowSmoking,
  });

  factory HotelPolicies.fromJson(Map<String, dynamic> json) {
    return HotelPolicies(
      checkIn: json['checkIn'] ?? '',
      checkOut: json['checkOut'] ?? '',
      cancellation: json['cancellation'] ?? '',
      houseRules: List<String>.from(json['houseRules'] ?? []),
      allowPets: json['allowPets'] ?? false,
      allowSmoking: json['allowSmoking'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'checkIn': checkIn,
      'checkOut': checkOut,
      'cancellation': cancellation,
      'houseRules': houseRules,
      'allowPets': allowPets,
      'allowSmoking': allowSmoking,
    };
  }
}

class HotelContact {
  final String phone;
  final String email;
  final String website;

  const HotelContact({
    required this.phone,
    required this.email,
    required this.website,
  });

  factory HotelContact.fromJson(Map<String, dynamic> json) {
    return HotelContact(
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      website: json['website'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'email': email,
      'website': website,
    };
  }
}

class HotelImage {
  final String url;
  final String caption;
  final bool isPrimary;

  const HotelImage({
    required this.url,
    required this.caption,
    required this.isPrimary,
  });

  factory HotelImage.fromJson(Map<String, dynamic> json) {
    return HotelImage(
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
