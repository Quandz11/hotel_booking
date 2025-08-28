import 'package:flutter/foundation.dart';
import '../models/hotel.dart';
import '../models/room.dart';
import '../services/api_service.dart';

class HotelProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Hotel> _hotels = [];
  List<Hotel> _featuredHotels = [];
  Hotel? _selectedHotel;
  List<Room> _hotelRooms = [];
  
  bool _isLoadingHotels = false;
  bool _isLoadingFeatured = false;
  bool _isLoadingHotelDetails = false;
  bool _isLoadingRooms = false;
  
  String? _errorMessage;

  // Getters
  List<Hotel> get hotels => _hotels;
  List<Hotel> get featuredHotels => _featuredHotels;
  Hotel? get selectedHotel => _selectedHotel;
  List<Room> get hotelRooms => _hotelRooms;
  
  bool get isLoadingHotels => _isLoadingHotels;
  bool get isLoadingFeatured => _isLoadingFeatured;
  bool get isLoadingHotelDetails => _isLoadingHotelDetails;
  bool get isLoadingRooms => _isLoadingRooms;
  
  String? get errorMessage => _errorMessage;

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Fetch all hotels
  Future<void> fetchHotels({
    String? city,
    String? country,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    int? limit,
    int? page,
  }) async {
    _isLoadingHotels = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _hotels = await _apiService.getHotels(
        city: city,
        country: country,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minRating: minRating,
        limit: limit,
        page: page,
      );
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Error in fetchHotels: $e');
    } finally {
      _isLoadingHotels = false;
      notifyListeners();
    }
  }

  // Fetch featured hotels
  Future<void> fetchFeaturedHotels({int limit = 5}) async {
    _isLoadingFeatured = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _featuredHotels = await _apiService.getFeaturedHotels(limit: limit);
      print('🏨 Featured hotels fetched: ${_featuredHotels.length}');
      for (var hotel in _featuredHotels) {
        print('🏨 Hotel: ${hotel.name}, startingPrice: ${hotel.startingPrice}');
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Error in fetchFeaturedHotels: $e');
    } finally {
      _isLoadingFeatured = false;
      notifyListeners();
    }
  }

  // Fetch hotel by ID
  Future<void> fetchHotelById(String hotelId) async {
    _isLoadingHotelDetails = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedHotel = await _apiService.getHotelById(hotelId);
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Error in fetchHotelById: $e');
    } finally {
      _isLoadingHotelDetails = false;
      notifyListeners();
    }
  }

  // Search hotels
  Future<void> searchHotels(String query, {
    int? limit,
    int? page,
  }) async {
    _isLoadingHotels = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _hotels = await _apiService.searchHotels(
        query,
        limit: limit,
        page: page,
      );
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Error in searchHotels: $e');
    } finally {
      _isLoadingHotels = false;
      notifyListeners();
    }
  }

  // Fetch rooms for a hotel
  Future<void> fetchHotelRooms(String hotelId, {
    DateTime? checkIn,
    DateTime? checkOut,
    int? guests,
  }) async {
    _isLoadingRooms = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _hotelRooms = await _apiService.getHotelRooms(
        hotelId,
        checkIn: checkIn,
        checkOut: checkOut,
        guests: guests,
      );
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Error in fetchHotelRooms: $e');
    } finally {
      _isLoadingRooms = false;
      notifyListeners();
    }
  }

  // Set selected hotel
  void setSelectedHotel(Hotel hotel) {
    _selectedHotel = hotel;
    notifyListeners();
  }

  // Clear selected hotel
  void clearSelectedHotel() {
    _selectedHotel = null;
    _hotelRooms.clear();
    notifyListeners();
  }

  // Get hotels by city
  List<Hotel> getHotelsByCity(String city) {
    return _hotels.where((hotel) => 
      hotel.address.city.toLowerCase().contains(city.toLowerCase())
    ).toList();
  }

  // Get top rated hotels
  List<Hotel> getTopRatedHotels({int limit = 10}) {
    final sortedHotels = List<Hotel>.from(_hotels);
    sortedHotels.sort((a, b) => b.averageRating.compareTo(a.averageRating));
    return sortedHotels.take(limit).toList();
  }

  // Filter hotels by price range
  List<Hotel> filterHotelsByPrice(double minPrice, double maxPrice) {
    return _hotels.where((hotel) => 
      hotel.startingPrice >= minPrice && hotel.startingPrice <= maxPrice
    ).toList();
  }

  // Filter hotels by rating
  List<Hotel> filterHotelsByRating(double minRating) {
    return _hotels.where((hotel) => 
      hotel.averageRating >= minRating
    ).toList();
  }
}
