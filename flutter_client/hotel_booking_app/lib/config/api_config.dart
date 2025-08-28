class ApiConfig {
  // Base URL cho API
  static const String baseUrl = 'http://10.0.2.2:5000/api';
  
  // Auth endpoints
  static const String authLogin = '$baseUrl/auth/login';
  static const String authRegister = '$baseUrl/auth/register';
  static const String authVerifyOtp = '$baseUrl/auth/verify-otp';
  static const String authResendOtp = '$baseUrl/auth/resend-otp';
  static const String authForgotPassword = '$baseUrl/auth/forgot-password';
  static const String authResetPassword = '$baseUrl/auth/reset-password';
  static const String authRefreshToken = '$baseUrl/auth/refresh-token';
  static const String authMe = '$baseUrl/auth/me';
  
  // User endpoints
  static const String userProfile = '$baseUrl/users/profile';
  static const String userUpdate = '$baseUrl/users/profile';
  static const String userChangePassword = '$baseUrl/users/change-password';
  
  // Hotel endpoints
  static const String hotels = '$baseUrl/hotels';
  static const String hotelSearch = '$baseUrl/hotels/search';
  static const String hotelsByOwner = '$baseUrl/hotels/owner';
  
  // Room endpoints
  static const String rooms = '$baseUrl/rooms';
  static const String roomsByHotel = '$baseUrl/rooms/hotel';
  
  // Booking endpoints
  static const String bookings = '$baseUrl/bookings';
  static const String bookingsByUser = '$baseUrl/bookings/user';
  static const String bookingsByHotel = '$baseUrl/bookings/hotel';
  
  // Review endpoints
  static const String reviews = '$baseUrl/reviews';
  static const String reviewsByHotel = '$baseUrl/reviews/hotel';
  
  // Upload endpoints
  static const String uploadImage = '$baseUrl/upload/image';
  
  // Chatbot endpoints
  static const String chatbot = '$baseUrl/chatbot';
  
  // Payment endpoints
  static const String paymentVnpay = '$baseUrl/payments/vnpay';
  static const String paymentStripe = '$baseUrl/payments/stripe';
  
  // Timeout settings
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
