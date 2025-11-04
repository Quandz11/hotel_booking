class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String role; // customer, hotel_owner, admin
  final String? address;
  final String? avatar;
  final bool isActive;
  final bool isApproved;
  final bool isEmailVerified;
  final String tier; // silver, gold, diamond
  final double totalSpent;
  final bool emailNotifications;
  final bool smsNotifications;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> favoriteHotelIds;
  
  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.role,
    this.address,
    this.avatar,
    this.isActive = true,
    this.isApproved = true,
    this.isEmailVerified = false,
    this.tier = 'silver',
    this.totalSpent = 0.0,
    this.emailNotifications = true,
    this.smsNotifications = false,
    required this.createdAt,
    required this.updatedAt,
    this.favoriteHotelIds = const [],
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'customer',
      address: _parseAddress(json['address']),
      avatar: json['avatar'],
      isActive: json['isActive'] ?? true,
      isApproved: json['isApproved'] ?? true,
      isEmailVerified: json['isEmailVerified'] ?? false,
      tier: json['tier'] ?? json['membershipTier'] ?? 'silver',
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
      emailNotifications: json['emailNotifications'] ?? true,
      smsNotifications: json['smsNotifications'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      favoriteHotelIds: (json['favoriteHotels'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'role': role,
      'address': address,
      'avatar': avatar,
      'isActive': isActive,
      'isApproved': isApproved,
      'isEmailVerified': isEmailVerified,
      'tier': tier,
      'totalSpent': totalSpent,
      'emailNotifications': emailNotifications,
      'smsNotifications': smsNotifications,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'favoriteHotels': favoriteHotelIds,
    };
  }
  
  String get fullName => '$firstName $lastName';
  
  String? get profileImageUrl => avatar;
  
  bool get isCustomer => role == 'customer';
  bool get isHotelOwner => role == 'hotel_owner';
  bool get isAdmin => role == 'admin';
  
  bool get isSilverTier => tier == 'silver';
  bool get isGoldTier => tier == 'gold';
  bool get isDiamondTier => tier == 'diamond';
  
  double get discountPercent {
    if (isDiamondTier) return 5.0;
    return 0.0;
  }
  
  User copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? role,
    String? address,
    String? avatar,
    bool? isActive,
    bool? isApproved,
    bool? isEmailVerified,
    String? tier,
    double? totalSpent,
    bool? emailNotifications,
    bool? smsNotifications,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? favoriteHotelIds,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      address: address ?? this.address,
      avatar: avatar ?? this.avatar,
      isActive: isActive ?? this.isActive,
      isApproved: isApproved ?? this.isApproved,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      tier: tier ?? this.tier,
      totalSpent: totalSpent ?? this.totalSpent,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      favoriteHotelIds: favoriteHotelIds ?? this.favoriteHotelIds,
    );
  }

  // Helper method to parse address from different formats
  static String? _parseAddress(dynamic address) {
    if (address == null) return null;
    
    if (address is String) {
      return address;
    }
    
    if (address is Map<String, dynamic>) {
      // Convert address object to string format
      List<String> addressParts = [];
      
      if (address['street'] != null) {
        addressParts.add(address['street'].toString());
      }
      if (address['city'] != null) {
        addressParts.add(address['city'].toString());
      }
      if (address['state'] != null) {
        addressParts.add(address['state'].toString());
      }
      if (address['country'] != null) {
        addressParts.add(address['country'].toString());
      }
      if (address['zipCode'] != null) {
        addressParts.add(address['zipCode'].toString());
      }
      
      return addressParts.isNotEmpty ? addressParts.join(', ') : null;
    }
    
    return address.toString();
  }
}
