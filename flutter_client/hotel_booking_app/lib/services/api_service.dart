import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../config/app_constants.dart';
import '../models/auth.dart';
import '../models/user.dart';
import '../models/hotel.dart';
import '../models/room.dart';
import '../models/booking.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  
  late Dio _dio;
  String? _accessToken;
  String? _refreshToken;
  bool _initialized = false;
  
  void initialize() {
    if (_initialized) return; // Prevent multiple initialization
    
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    // Add request interceptor to include auth token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        
        // Don't set Content-Type for FormData (multipart uploads)
        if (options.data is FormData) {
          options.headers.remove('Content-Type');
        }
        
        print('🚀 REQUEST: ${options.method} ${options.path}');
        print('📤 Data: ${options.data}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
        print('📥 Data: ${response.data}');
        handler.next(response);
      },
      onError: (error, handler) async {
        print('❌ ERROR: ${error.response?.statusCode} ${error.requestOptions.path}');
        print('💥 Error data: ${error.response?.data}');
        
        // Handle token refresh
        if (error.response?.statusCode == 401 && _refreshToken != null) {
          try {
            await _refreshAccessToken();
            // Retry the original request
            final options = error.requestOptions;
            options.headers['Authorization'] = 'Bearer $_accessToken';
            final retryResponse = await _dio.fetch(options);
            handler.resolve(retryResponse);
            return;
          } catch (refreshError) {
            // Refresh failed, redirect to login
            await logout();
          }
        }
        
        handler.next(error);
      },
    ));
    
    _loadTokensFromStorage();
    _initialized = true;
  }
  
  Future<void> _loadTokensFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(AppConstants.keyAccessToken);
    _refreshToken = prefs.getString(AppConstants.keyRefreshToken);
  }
  
  Future<void> _saveTokensToStorage(String accessToken, String? refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyAccessToken, accessToken);
    _accessToken = accessToken;
    
    if (refreshToken != null) {
      await prefs.setString(AppConstants.keyRefreshToken, refreshToken);
      _refreshToken = refreshToken;
    }
  }
  
  Future<void> _refreshAccessToken() async {
    if (_refreshToken == null) throw Exception('No refresh token available');
    
    try {
      final response = await _dio.post(
        '/auth/refresh-token',
        data: {'refreshToken': _refreshToken},
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        await _saveTokensToStorage(data['accessToken'], data['refreshToken']);
      } else {
        throw Exception('Failed to refresh token');
      }
    } catch (e) {
      throw Exception('Token refresh failed: $e');
    }
  }
  
  // Auth Methods
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post('/auth/login', data: request.toJson());
      final authResponse = AuthResponse.fromJson(response.data);
      
      if (authResponse.success && authResponse.accessToken != null) {
        await _saveTokensToStorage(
          authResponse.accessToken!, 
          authResponse.refreshToken
        );
        
        // Save user data
        if (authResponse.user != null) {
          await _saveUserToStorage(authResponse.user!);
        }
      }
      
      return authResponse;
    } on DioException catch (e) {
      return AuthResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Login failed',
        errors: AuthResponse.parseErrors(e.response?.data['errors']),
      );
    }
  }
  
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _dio.post('/auth/register', data: request.toJson());
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      return AuthResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Registration failed',
        errors: AuthResponse.parseErrors(e.response?.data['errors']),
      );
    }
  }
  
  Future<AuthResponse> verifyOtp(VerifyOtpRequest request) async {
    try {
      final response = await _dio.post('/auth/verify-otp', data: request.toJson());
      final authResponse = AuthResponse.fromJson(response.data);
      
      if (authResponse.success && authResponse.accessToken != null) {
        await _saveTokensToStorage(
          authResponse.accessToken!, 
          authResponse.refreshToken
        );
        
        if (authResponse.user != null) {
          await _saveUserToStorage(authResponse.user!);
        }
      }
      
      return authResponse;
    } on DioException catch (e) {
      return AuthResponse(
        success: false,
        message: e.response?.data['message'] ?? 'OTP verification failed',
        errors: AuthResponse.parseErrors(e.response?.data['errors']),
      );
    }
  }
  
  Future<AuthResponse> resendOtp(String email) async {
    try {
      final response = await _dio.post('/auth/resend-otp', data: {'email': email});
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      return AuthResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Failed to resend OTP',
      );
    }
  }
  
  Future<AuthResponse> forgotPassword(ForgotPasswordRequest request) async {
    try {
      final response = await _dio.post('/auth/forgot-password', data: request.toJson());
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      return AuthResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Failed to send reset email',
      );
    }
  }
  
  Future<AuthResponse> verifyResetOtp(VerifyOtpRequest request) async {
    try {
      final response = await _dio.post('/auth/verify-reset-otp', data: request.toJson());
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      return AuthResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Failed to verify reset code',
      );
    }
  }
  
  Future<AuthResponse> resetPassword(ResetPasswordRequest request) async {
    try {
      final response = await _dio.post('/auth/reset-password', data: request.toJson());
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      return AuthResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Password reset failed',
        errors: AuthResponse.parseErrors(e.response?.data['errors']),
      );
    }
  }
  
  Future<User?> getCurrentUser() async {
    try {
      print('🔍 Calling /auth/me API...');
      final response = await _dio.get('/auth/me');
      print('🔍 getCurrentUser response status: ${response.statusCode}');
      print('🔍 getCurrentUser response data: ${response.data}');
      
      if (response.statusCode == 200) {
        final userData = response.data['user'];
        print('🔍 Parsing user data: $userData');
        final user = User.fromJson(userData);
        print('🔍 Parsed user: ${user.fullName}');
        await _saveUserToStorage(user);
        return user;
      }
      print('🔍 getCurrentUser: status code not 200');
      return null;
    } on DioException catch (e) {
      print('❌ Get current user failed: ${e.message}');
      return null;
    } catch (e) {
      print('❌ Get current user unexpected error: $e');
      return null;
    }
  }
  
  Future<void> logout() async {
    try {
      if (_refreshToken != null) {
        await _dio.post('/auth/logout', data: {'refreshToken': _refreshToken});
      }
    } catch (e) {
      print('Logout API call failed: $e');
    } finally {
      // Clear local storage regardless of API call result
      await _clearLocalStorage();
    }
  }
  
  Future<void> _saveUserToStorage(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyUserData, jsonEncode(user.toJson()));
  }
  
  Future<User?> getUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(AppConstants.keyUserData);
      if (userData != null) {
        return User.fromJson(jsonDecode(userData));
      }
      return null;
    } catch (e) {
      print('Failed to get user from storage: $e');
      return null;
    }
  }
  
  Future<void> _clearLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyAccessToken);
    await prefs.remove(AppConstants.keyRefreshToken);
    await prefs.remove(AppConstants.keyUserData);
    _accessToken = null;
    _refreshToken = null;
  }
  
  bool get isLoggedIn => _accessToken != null;
  
  void _ensureInitialized() {
    if (!_initialized) {
      initialize();
    }
  }

  // ========== HOTEL METHODS ==========

  /// Get all hotels with optional filters
  Future<List<Hotel>> getHotels({
    String? city,
    String? country,
    String? search,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    int? limit,
    int? page,
    List<String>? amenities,
    String? sortBy,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (city != null) queryParams['city'] = city;
      if (country != null) queryParams['country'] = country;
      if (search != null) queryParams['search'] = search;
      if (minPrice != null) queryParams['minPrice'] = minPrice;
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice;
      if (minRating != null) queryParams['minRating'] = minRating;
      if (limit != null) queryParams['limit'] = limit;
      if (page != null) queryParams['page'] = page;
      if (amenities != null && amenities.isNotEmpty) {
        queryParams['amenities'] = amenities.join(',');
      }
      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sortBy'] = sortBy;
      }

      final response = await _dio.get('/hotels', queryParameters: queryParams);
      
      if (response.data['success'] == true) {
        final List<dynamic> hotelData = response.data['data'];
        return hotelData.map((json) => Hotel.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch hotels');
      }
    } catch (e) {
      print('❌ Error fetching hotels: $e');
      rethrow;
    }
  }

  /// Get hotel by ID
  Future<Hotel> getHotelById(String hotelId) async {
    try {
      final response = await _dio.get('/hotels/$hotelId');
      
      if (response.data['success'] == true) {
        return Hotel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Hotel not found');
      }
    } catch (e) {
      print('❌ Error fetching hotel: $e');
      rethrow;
    }
  }

  /// Get featured/popular hotels
  Future<List<Hotel>> getFeaturedHotels({int limit = 10}) async {
    try {
      final response = await _dio.get('/hotels/featured', queryParameters: {
        'limit': limit,
      });
      
      if (response.data['success'] == true) {
        final List<dynamic> hotelData = response.data['data'];
        print('🏨 Raw hotel data sample: ${hotelData.first}');
        return hotelData.map((json) => Hotel.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch featured hotels');
      }
    } catch (e) {
      print('❌ Error fetching featured hotels: $e');
      rethrow;
    }
  }

  /// Search hotels by name or location
  Future<List<Hotel>> searchHotels(String query, {
    int? limit,
    int? page,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'search': query,
      };
      if (limit != null) queryParams['limit'] = limit;
      if (page != null) queryParams['page'] = page;

      final response = await _dio.get('/hotels/search', queryParameters: queryParams);
      
      if (response.data['success'] == true) {
        final List<dynamic> hotelData = response.data['data'];
        return hotelData.map((json) => Hotel.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to search hotels');
      }
    } catch (e) {
      print('❌ Error searching hotels: $e');
      rethrow;
    }
  }

  /// Get rooms for a specific hotel
  Future<List<Room>> getHotelRooms(String hotelId, {
    DateTime? checkIn,
    DateTime? checkOut,
    int? guests,
  }) async {
    try {
      print('🏨 Getting rooms for hotel: $hotelId');
      
      // Use get hotel by ID endpoint which returns rooms
      final response = await _dio.get('/hotels/$hotelId');
      
      print('📥 Hotel with rooms response: ${response.data}');
      
      if (response.data['success'] == true) {
        final List<dynamic> roomData = response.data['rooms'] ?? [];
        return roomData.map((json) => Room.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch rooms');
      }
    } catch (e) {
      print('❌ Error fetching hotel rooms: $e');
      rethrow;
    }
  }

  /// Get rooms for a hotel with availability and pricing for given dates/guests
  Future<List<Room>> getHotelRoomsWithAvailability(
    String hotelId, {
    required DateTime checkIn,
    required DateTime checkOut,
    int guests = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'checkIn': checkIn.toIso8601String(),
        'checkOut': checkOut.toIso8601String(),
        'guests': guests,
      };

      final response = await _dio.get('/rooms/hotel/$hotelId', queryParameters: queryParams);
      final List<dynamic> roomData = response.data['rooms'] ?? [];
      return roomData.map((json) => Room.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error fetching rooms with availability: $e');
      rethrow;
    }
  }

  // ========== HOTEL OWNER DASHBOARD METHODS ==========

  /// Get hotels owned by current user
  Future<List<Hotel>> getOwnedHotels() async {
    try {
      final response = await _dio.get('/hotels/my-hotels');
      
      if (response.data['success'] == true) {
        final List<dynamic> hotelData = response.data['data'];
        return hotelData.map((json) => Hotel.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch owned hotels');
      }
    } catch (e) {
      print('❌ Error fetching owned hotels: $e');
      rethrow;
    }
  }

  /// Get dashboard statistics
  Future<DashboardStats> getDashboardStats() async {
    try {
      final response = await _dio.get('/admin/dashboard/stats');
      
      if (response.data['success'] == true) {
        return DashboardStats.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch dashboard stats');
      }
    } catch (e) {
      print('❌ Error fetching dashboard stats: $e');
      rethrow;
    }
  }

  /// Get all rooms for authenticated hotel owner
  Future<List<Room>> getAllMyRooms() async {
    try {
      final response = await _dio.get('/rooms/my-rooms');
      
      if (response.data['success'] == true) {
        final List<dynamic> roomData = response.data['data'];
        return roomData.map((json) => Room.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch rooms');
      }
    } catch (e) {
      print('❌ Error fetching all rooms: $e');
      rethrow;
    }
  }

  /// Get rooms for a specific hotel (for hotel owner)
  Future<List<Room>> getRoomsForHotel(String hotelId) async {
    try {
      final response = await _dio.get('/rooms/hotel/$hotelId');
      
      if (response.data['success'] == true) {
        final List<dynamic> roomData = response.data['data'];
        return roomData.map((json) => Room.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch rooms');
      }
    } catch (e) {
      print('❌ Error fetching rooms for hotel: $e');
      rethrow;
    }
  }

  /// Get bookings for a specific hotel
  Future<List<Booking>> getBookingsForHotel(String hotelId) async {
    try {
      final response = await _dio.get('/bookings/hotel/$hotelId');
      
      // Handle different response formats
      List<dynamic> bookingData;
      if (response.data['success'] == true && response.data['data'] != null) {
        bookingData = response.data['data'];
      } else if (response.data['bookings'] != null) {
        bookingData = response.data['bookings'];
      } else {
        throw Exception('No booking data found in response');
      }
      
      return bookingData.map((json) => Booking.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error fetching bookings for hotel: $e');
      rethrow;
    }
  }

  // ========== HOTEL MANAGEMENT METHODS ==========

  /// Create a new hotel with image upload
  Future<Hotel> createHotel(Map<String, dynamic> hotelData, List<File> images) async {
    try {
      // First upload images if any
      List<String> imageUrls = [];
      if (images.isNotEmpty) {
        imageUrls = await _uploadImages(images);
      }
      
      // Convert image URLs to hotel image objects
      List<Map<String, dynamic>> hotelImages = imageUrls.asMap().entries.map((entry) {
        return {
          'url': entry.value,
          'caption': '',
          'isPrimary': entry.key == 0, // First image is primary
        };
      }).toList();
      
      // Add image objects to hotel data
      hotelData['images'] = hotelImages;
      
      final response = await _dio.post('/hotels', data: hotelData);
      
      if (response.data['success'] == true) {
        return Hotel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to create hotel');
      }
    } catch (e) {
      print('❌ Error creating hotel: $e');
      rethrow;
    }
  }

  /// Update hotel information with image upload
  Future<Hotel> updateHotel(String hotelId, Map<String, dynamic> hotelData, List<File> newImages) async {
    try {
      // Upload new images if any
      List<String> newImageUrls = [];
      if (newImages.isNotEmpty) {
        newImageUrls = await _uploadImages(newImages);
      }
      
      // Get existing images (should be in the correct format already)
      List<dynamic> existingImages = hotelData['existingImages'] ?? [];
      
      // Convert new image URLs to hotel image objects
      List<Map<String, dynamic>> newHotelImages = newImageUrls.map((url) {
        return {
          'url': url,
          'caption': '',
          'isPrimary': false, // New images are not primary by default
        };
      }).toList();
      
      // Combine existing and new images
      List<dynamic> allImages = [...existingImages, ...newHotelImages];
      
      // Update hotel data with all images
      hotelData['images'] = allImages;
      hotelData.remove('existingImages'); // Remove temporary key
      
      final response = await _dio.put('/hotels/$hotelId', data: hotelData);
      
      if (response.data['success'] == true) {
        return Hotel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update hotel');
      }
    } catch (e) {
      print('❌ Error updating hotel: $e');
      rethrow;
    }
  }

  /// Upload multiple images to Cloudinary
  Future<List<String>> _uploadImages(List<File> images) async {
    try {
      if (images.isEmpty) return [];
      
      // If only one image, use single upload endpoint
      if (images.length == 1) {
        String fileName = images[0].path.split('/').last;
        MultipartFile multipartFile = await MultipartFile.fromFile(
          images[0].path,
          filename: fileName,
        );
        
        final formData = FormData.fromMap({
          'image': multipartFile,
        });
        
        final response = await _dio.post('/upload/image', data: formData);
        
        if (response.data['message']?.contains('uploaded successfully') == true) {
          return [response.data['image']['url']];
        } else {
          throw Exception(response.data['message'] ?? 'Failed to upload image');
        }
      }
      
      // For multiple images, use bulk upload endpoint
      List<MultipartFile> multipartFiles = [];
      for (File image in images) {
        String fileName = image.path.split('/').last;
        MultipartFile multipartFile = await MultipartFile.fromFile(
          image.path,
          filename: fileName,
        );
        multipartFiles.add(multipartFile);
      }
      
      final formData = FormData.fromMap({
        'images': multipartFiles,
      });
      
      final response = await _dio.post('/upload/images', data: formData);
      
      if (response.data['message']?.contains('uploaded successfully') == true) {
        return (response.data['images'] as List)
            .map((img) => img['url'] as String)
            .toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to upload images');
      }
    } catch (e) {
      print('❌ Error uploading images: $e');
      rethrow;
    }
  }

  /// Toggle hotel status (active/inactive)
  Future<Hotel> toggleHotelStatus(String hotelId) async {
    try {
      final response = await _dio.patch('/hotels/$hotelId/toggle-status');
      
      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to toggle hotel status');
      }
      
      return Hotel.fromJson(response.data['data']);
    } catch (e) {
      print('❌ Error toggling hotel status: $e');
      rethrow;
    }
  }

  /// Delete hotel permanently
  Future<void> deleteHotel(String hotelId) async {
    try {
      final response = await _dio.delete('/hotels/$hotelId');
      
      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to delete hotel');
      }
    } catch (e) {
      print('❌ Error deleting hotel: $e');
      rethrow;
    }
  }

  // ========== ROOM MANAGEMENT METHODS ==========

  /// Create a new room with image upload
  Future<Room> createRoom(String hotelId, Map<String, dynamic> roomData, List<File> images) async {
    try {
      // First upload images if any
      List<String> imageUrls = [];
      if (images.isNotEmpty) {
        imageUrls = await _uploadImages(images);
      }
      
      // Convert image URLs to room image objects
      List<Map<String, dynamic>> roomImages = imageUrls.asMap().entries.map((entry) {
        return {
          'url': entry.value,
          'caption': '',
          'isPrimary': entry.key == 0, // First image is primary
        };
      }).toList();
      
      // Add room data
      roomData['hotel'] = hotelId;
      roomData['images'] = roomImages;
      
      final response = await _dio.post('/rooms', data: roomData);
      
      print('✅ RESPONSE: ${response.statusCode} /rooms');
      print('📥 Data: ${response.data}');
      
      // Handle different response formats
      if (response.statusCode == 201 || response.statusCode == 200) {
        // Backend returns: {message: "Room created successfully", room: {...}}
        if (response.data['room'] != null) {
          return Room.fromJson(response.data['room']);
        }
        // Alternative format: {success: true, data: {...}}
        else if (response.data['success'] == true && response.data['data'] != null) {
          return Room.fromJson(response.data['data']);
        }
        // Direct data format
        else if (response.data['_id'] != null) {
          return Room.fromJson(response.data);
        }
        else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception(response.data['message'] ?? 'Failed to create room');
      }
    } catch (e) {
      print('❌ Error creating room: $e');
      rethrow;
    }
  }

  /// Update room information with image upload
  Future<Room> updateRoom(String roomId, Map<String, dynamic> roomData, List<File> newImages) async {
    try {
      // Upload new images if any
      List<String> newImageUrls = [];
      if (newImages.isNotEmpty) {
        newImageUrls = await _uploadImages(newImages);
      }
      
      // Get existing images (should be in the correct format already)
      List<dynamic> existingImages = roomData['existingImages'] ?? [];
      
      // Convert new image URLs to room image objects
      List<Map<String, dynamic>> newRoomImages = newImageUrls.map((url) {
        return {
          'url': url,
          'caption': '',
          'isPrimary': false, // New images are not primary by default
        };
      }).toList();
      
      // Combine existing and new images
      List<dynamic> allImages = [...existingImages, ...newRoomImages];
      
      // Update room data with all images
      roomData['images'] = allImages;
      roomData.remove('existingImages'); // Remove temporary key
      
      final response = await _dio.put('/rooms/$roomId', data: roomData);
      
      print('✅ RESPONSE: ${response.statusCode} /rooms/$roomId');
      print('📥 Data: ${response.data}');
      
      // Handle different response formats
      if (response.statusCode == 200) {
        // Backend returns: {message: "Room updated successfully", room: {...}}
        if (response.data['room'] != null) {
          return Room.fromJson(response.data['room']);
        }
        // Alternative format: {success: true, data: {...}}
        else if (response.data['success'] == true && response.data['data'] != null) {
          return Room.fromJson(response.data['data']);
        }
        // Direct data format
        else if (response.data['_id'] != null) {
          return Room.fromJson(response.data);
        }
        else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update room');
      }
    } catch (e) {
      print('❌ Error updating room: $e');
      rethrow;
    }
  }

  /// Toggle room status (active/inactive)
  Future<Room> toggleRoomStatus(String roomId) async {
    try {
      final response = await _dio.patch('/rooms/$roomId/toggle-status');
      
      print('✅ RESPONSE: ${response.statusCode} /rooms/$roomId/toggle-status');
      print('📥 Data: ${response.data}');
      
      // Handle different response formats
      if (response.statusCode == 200) {
        // Backend returns: {message: "...", room: {...}}
        if (response.data['room'] != null) {
          return Room.fromJson(response.data['room']);
        }
        // Alternative format: {success: true, data: {...}}
        else if (response.data['success'] == true && response.data['data'] != null) {
          return Room.fromJson(response.data['data']);
        }
        // Direct data format
        else if (response.data['_id'] != null) {
          return Room.fromJson(response.data);
        }
        else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception(response.data['message'] ?? 'Failed to toggle room status');
      }
    } catch (e) {
      print('❌ Error toggling room status: $e');
      rethrow;
    }
  }

  /// Delete room permanently
  Future<void> deleteRoom(String roomId) async {
    try {
      final response = await _dio.delete('/rooms/$roomId');
      
      print('✅ RESPONSE: ${response.statusCode} DELETE /rooms/$roomId');
      print('📥 Data: ${response.data}');
      
      if (response.statusCode == 200) {
        return; // Successfully deleted
      } else {
        throw Exception(response.data['message'] ?? 'Failed to delete room');
      }
    } catch (e) {
      print('❌ Error deleting room: $e');
      rethrow;
    }
  }

  /// Get rooms by hotel ID
  Future<List<Room>> getRoomsByHotel(String hotelId, {String? checkIn, String? checkOut, int? guests}) async {
    try {
      Map<String, dynamic> queryParams = {};
      if (checkIn != null) queryParams['checkIn'] = checkIn;
      if (checkOut != null) queryParams['checkOut'] = checkOut;
      if (guests != null) queryParams['guests'] = guests.toString();

      final response = await _dio.get('/rooms/hotel/$hotelId', queryParameters: queryParams);
      
      print('✅ RESPONSE: ${response.statusCode} /rooms/hotel/$hotelId');
      print('📥 Data: ${response.data}');
      
      // Handle different response formats
      if (response.statusCode == 200) {
        List<dynamic> roomsData;
        
        // Backend returns: {rooms: [...]}
        if (response.data['rooms'] != null) {
          roomsData = response.data['rooms'];
        }
        // Alternative format: {success: true, data: [...]}
        else if (response.data['success'] == true && response.data['data'] != null) {
          roomsData = response.data['data'];
        }
        // Direct array format
        else if (response.data is List) {
          roomsData = response.data;
        }
        else {
          throw Exception('Unexpected response format');
        }
        
        return roomsData.map((room) => Room.fromJson(room)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to get rooms');
      }
    } catch (e) {
      print('❌ Error getting rooms: $e');
      rethrow;
    }
  }

  /// Get room by ID
  Future<Room> getRoomById(String roomId) async {
    try {
      final response = await _dio.get('/rooms/$roomId');
      
      print('✅ RESPONSE: ${response.statusCode} /rooms/$roomId');
      print('📥 Data: ${response.data}');
      
      if (response.statusCode == 200) {
        // Handle different response formats
        if (response.data['room'] != null) {
          return Room.fromJson(response.data['room']);
        } else if (response.data['success'] == true && response.data['data'] != null) {
          return Room.fromJson(response.data['data']);
        } else {
          return Room.fromJson(response.data);
        }
      } else {
        throw Exception(response.data['message'] ?? 'Failed to get room details');
      }
    } catch (e) {
      print('❌ Error getting room: $e');
      rethrow;
    }
  }

  /// Get rooms owned by current user
  Future<List<Room>> getMyRooms() async {
    try {
      final response = await _dio.get('/rooms/my-rooms');
      
      if (response.data['success'] == true) {
        final List<dynamic> roomsData = response.data['data'];
        return roomsData.map((room) => Room.fromJson(room)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to get my rooms');
      }
    } catch (e) {
      print('❌ Error getting my rooms: $e');
      rethrow;
    }
  }

  // ========== BOOKING MANAGEMENT METHODS ==========

  /// Update booking status
  Future<Booking> updateBookingStatus(String bookingId, String status) async {
    try {
      print('🔄 Updating booking $bookingId to status: $status');
      final response = await _dio.put('/bookings/$bookingId/status', data: {
        'status': status,
      });
      
      print('📥 Update booking response: ${response.data}');
      
      if (response.data['success'] == true) {
        return Booking.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update booking status');
      }
    } catch (e) {
      print('❌ Error updating booking status: $e');
      rethrow;
    }
  }

  // ========== CUSTOMER BOOKING METHODS ==========

  /// Create a new booking for customer
  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> bookingData) async {
    try {
      print('🏨 Creating booking with data: $bookingData');
      final response = await _dio.post('/bookings', data: bookingData);
      
      print('📥 Create booking response: ${response.data}');
      
      return response.data;
    } catch (e) {
      print('❌ Error creating booking: $e');
      rethrow;
    }
  }

  /// Get customer's bookings
  Future<List<dynamic>> getCustomerBookings() async {
    try {
      print('📋 Getting customer bookings');
      final response = await _dio.get('/bookings/my-bookings');
      
      print('📥 Customer bookings response: ${response.data}');
      
      if (response.data['success'] == true) {
        return response.data['data'] as List<dynamic>;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to get bookings');
      }
    } catch (e) {
      print('❌ Error getting customer bookings: $e');
      rethrow;
    }
  }

  /// Get booking by ID
  Future<Map<String, dynamic>> getBookingById(String bookingId) async {
    try {
      print('📋 Getting booking by ID: $bookingId');
      final response = await _dio.get('/bookings/$bookingId');
      
      print('📥 Booking response: ${response.data}');
      
      return response.data['booking'] as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error getting booking: $e');
      rethrow;
    }
  }

  /// Cancel a booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      print('❌ Cancelling booking: $bookingId');
      final response = await _dio.patch('/bookings/$bookingId/cancel');
      
      print('📥 Cancel booking response: ${response.data}');
      
      if (response.data['success'] != true && response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Failed to cancel booking');
      }
    } catch (e) {
      print('❌ Error cancelling booking: $e');
      rethrow;
    }
  }

  // ========== PAYMENT METHODS ==========

  /// Create VNPay payment - Updated for new API
  Future<Map<String, dynamic>> createVNPayPayment(String bookingId, String? bankCode, {String language = 'vn'}) async {
    try {
      print('💳 Creating VNPay payment for booking: $bookingId');
      final response = await _dio.post('/payments/vnpay/create', data: {
        'bookingId': bookingId,
        'bankCode': bankCode,
        'language': language,
      });
      
      print('📥 VNPay payment response: ${response.data}');
      
      if (response.data['success'] == true && response.data['data']['paymentUrl'] != null) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to create VNPay payment');
      }
    } catch (e) {
      print('❌ Error creating VNPay payment: $e');
      rethrow;
    }
  }

  /// Get payment status
  Future<Map<String, dynamic>> getPaymentStatus(String bookingId) async {
    try {
      print('📋 Getting payment status for booking: $bookingId');
      final response = await _dio.get('/payments/status/$bookingId');
      
      print('📥 Payment status response: ${response.data}');
      
      if (response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to get payment status');
      }
    } catch (e) {
      print('❌ Error getting payment status: $e');
      rethrow;
    }
  }

  /// Cancel payment
  Future<void> cancelPayment(String bookingId) async {
    try {
      print('❌ Cancelling payment for booking: $bookingId');
      final response = await _dio.post('/payments/cancel/$bookingId');
      
      print('📥 Cancel payment response: ${response.data}');
      
      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to cancel payment');
      }
    } catch (e) {
      print('❌ Error cancelling payment: $e');
      rethrow;
    }
  }

  /// Create Stripe payment
  Future<Map<String, dynamic>> createStripePayment(String bookingId) async {
    try {
      print('💳 Creating Stripe payment for booking: $bookingId');
      final response = await _dio.post('/payments/stripe/create', data: {
        'bookingId': bookingId,
      });
      
      print('📥 Stripe payment response: ${response.data}');
      
      if (response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to create Stripe payment');
      }
    } catch (e) {
      print('❌ Error creating Stripe payment: $e');
      rethrow;
    }
  }

  // ========== CHATBOT METHODS ==========

  /// Send message to chatbot
  Future<Map<String, dynamic>> sendChatMessage({
    required String message,
    required Map<String, dynamic> context,
  }) async {
    try {
      print('🤖 Sending chat message: $message');
      final response = await _dio.post('/chatbot/chat', data: {
        'message': message,
        'context': context,
      });
      
      print('📥 Chatbot response: ${response.data}');
      
      if (response.data['message'] != null) {
        return response.data;
      } else {
        throw Exception('Failed to get chatbot response');
      }
    } catch (e) {
      print('❌ Error sending chat message: $e');
      rethrow;
    }
  }

  Future<List<Hotel>> getFavoriteHotels(String userId) async {
    try {
      final response = await _dio.get('/users/$userId/favorites');
      final favorites = response.data['favoriteHotels'] as List<dynamic>? ?? [];
      return favorites.map((hotel) => Hotel.fromJson(hotel)).toList();
    } catch (e) {
      print('�?O Error fetching favorite hotels: $e');
      rethrow;
    }
  }

  Future<List<String>> toggleFavoriteHotel(String userId, String hotelId) async {
    try {
      final response = await _dio.post('/users/$userId/favorites/$hotelId');
      final ids = response.data['favoriteHotels'] as List<dynamic>? ?? [];
      return ids.map((id) => id.toString()).toList();
    } catch (e) {
      print('�?O Error toggling favorite hotel: $e');
      rethrow;
    }
  }

  /// Update user profile
  Future<User?> updateUserProfile(Map<String, dynamic> profileData, {dynamic profileImage}) async {
    try {
      print('🔄 Updating user profile');
      
      // Get current user to get the ID
      final currentUser = await getUserFromStorage();
      if (currentUser == null) {
        throw Exception('No current user found');
      }
      
      // If profile image is provided, upload it first and get the URL
      if (profileImage != null) {
        String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        MultipartFile multipartFile = await MultipartFile.fromFile(
          profileImage.path,
          filename: fileName,
        );
        
        final imageFormData = FormData.fromMap({
          'image': multipartFile,
        });
        
        final imageResponse = await _dio.post('/upload/image', data: imageFormData);
        
        if (imageResponse.data['message']?.contains('uploaded successfully') == true) {
          profileData['avatar'] = imageResponse.data['image']['url'];
        }
      }
      
      final response = await _dio.put('/users/${currentUser.id}', data: profileData);
      
      print('✅ RESPONSE: ${response.statusCode} /users/${currentUser.id}');
      print('📥 Data: ${response.data}');
      
      if (response.statusCode == 200) {
        User updatedUser;
        
        // Handle response format from backend: { message: "...", user: {...} }
        if (response.data['user'] != null) {
          updatedUser = User.fromJson(response.data['user']);
        } else {
          throw Exception('Invalid response format');
        }
        
        // Save updated user to storage
        await _saveUserToStorage(updatedUser);
        return updatedUser;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      print('❌ Error updating profile: $e');
      rethrow;
    }
  }

  /// Get chatbot suggestions
  Future<List<String>> getChatbotSuggestions() async {
    try {
      print('🤖 Getting chatbot suggestions');
      final response = await _dio.get('/chatbot/suggestions');
      
      print('📥 Chatbot suggestions: ${response.data}');
      
      if (response.data['suggestions'] != null) {
        return List<String>.from(response.data['suggestions']);
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Error getting chatbot suggestions: $e');
      return [];
    }
  }
}
