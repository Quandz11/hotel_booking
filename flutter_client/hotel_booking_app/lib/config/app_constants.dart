class AppConstants {
  // App Info
  static const String appName = 'Hotel Booking';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserData = 'user_data';
  static const String keyLanguage = 'app_language';
  static const String keyIsFirstTime = 'is_first_time';
  static const String keyFavoriteHotels = 'favorite_hotels';
  
  // User Roles
  static const String roleCustomer = 'customer';
  static const String roleHotelOwner = 'hotel_owner';
  static const String roleAdmin = 'admin';
  
  // User Tiers
  static const String tierSilver = 'silver';
  static const String tierGold = 'gold';
  static const String tierDiamond = 'diamond';
  
  // Hotel Star Ratings
  static const int minStarRating = 1;
  static const int maxStarRating = 5;
  
  // Booking Status
  static const String bookingPending = 'pending';
  static const String bookingConfirmed = 'confirmed';
  static const String bookingCancelled = 'cancelled';
  static const String bookingCompleted = 'completed';
  
  // Payment Status
  static const String paymentPending = 'pending';
  static const String paymentPaid = 'paid';
  static const String paymentFailed = 'failed';
  static const String paymentRefunded = 'refunded';
  
  // Room Types
  static const String roomStandard = 'standard';
  static const String roomDeluxe = 'deluxe';
  static const String roomSuite = 'suite';
  static const String roomPenthouse = 'penthouse';
  
  // Supported Languages
  static const String languageEnglish = 'en';
  static const String languageVietnamese = 'vi';
  
  // Image Constraints
  static const int maxImageSizeMB = 5;
  static const int maxImagesPerUpload = 10;
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  
  // Diamond Tier Discount
  static const double diamondDiscountPercent = 5.0;
  
  // Tier Thresholds (VND)
  static const double goldTierThreshold = 10000000; // 10 million VND
  static const double diamondTierThreshold = 50000000; // 50 million VND
}
