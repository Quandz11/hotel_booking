import 'package:flutter/material.dart';
import 'dart:io';
import '../models/hotel.dart';
import '../models/room.dart';
import '../models/booking.dart';
import '../services/api_service.dart';

class HotelOwnerProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Hotel> _ownedHotels = [];
  List<Room> _allRooms = [];
  List<Booking> _allBookings = [];
  DashboardStats? _stats;
  
  bool _isLoading = false;
  String _error = '';

  // Getters
  List<Hotel> get ownedHotels => _ownedHotels;
  List<Room> get allRooms => _allRooms;
  List<Booking> get allBookings => _allBookings;
  DashboardStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String get error => _error;

  // Get rooms for specific hotel
  List<Room> getRoomsForHotel(String hotelId) {
    return _allRooms.where((room) => room.hotelId == hotelId).toList();
  }

  // Ownership helpers
  bool isOwnedHotelId(String hotelId) {
    return _ownedHotels.any((h) => h.id == hotelId);
  }

  bool isOwnedRoom(Room room) {
    return isOwnedHotelId(room.hotelId);
  }

  // Get bookings for specific hotel
  List<Booking> getBookingsForHotel(String hotelId) {
    return _allBookings.where((booking) => booking.hotelId == hotelId).toList();
  }

  // Get hotel bookings for reports
  List<Booking> get hotelBookings => _allBookings;

  // Get recent bookings (last 10)
  List<Booking> get recentBookings {
    final sorted = List<Booking>.from(_allBookings);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(10).toList();
  }

  // Get pending bookings
  List<Booking> get pendingBookings {
    return _allBookings.where((booking) => booking.isPending).toList();
  }

  // Get active bookings
  List<Booking> get activeBookings {
    return _allBookings.where((booking) => booking.isActive).toList();
  }

  Future<void> loadDashboardData() async {
    _setLoading(true);
    _error = '';

    try {
      // Load all data in parallel
      await Future.wait([
        loadOwnedHotels(),
        loadAllRooms(),
        loadAllBookings(),
        loadDashboardStats(),
      ]);
    } catch (e) {
      _error = 'Failed to load dashboard data: $e';
      print('Dashboard load error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadOwnedHotels() async {
    try {
      _ownedHotels = await _apiService.getOwnedHotels();
      notifyListeners();
    } catch (e) {
      throw 'Failed to load hotels: $e';
    }
  }

  Future<void> loadAllRooms() async {
    try {
      _allRooms = await _apiService.getMyRooms();
      notifyListeners();
    } catch (e) {
      throw 'Failed to load rooms: $e';
    }
  }

  Future<void> loadAllBookings() async {
    try {
      _allBookings = [];
      for (final hotel in _ownedHotels) {
        final bookings = await _apiService.getBookingsForHotel(hotel.id);
        _allBookings.addAll(bookings);
      }
      notifyListeners();
    } catch (e) {
      throw 'Failed to load bookings: $e';
    }
  }

  Future<void> loadHotelBookings(String hotelId) async {
    try {
      _setLoading(true);
      final bookings = await _apiService.getBookingsForHotel(hotelId);
      // Update bookings for this specific hotel
      _allBookings.removeWhere((b) => b.hotelId == hotelId);
      _allBookings.addAll(bookings);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load hotel bookings: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadDashboardStats() async {
    try {
      _stats = await _apiService.getDashboardStats();
      notifyListeners();
    } catch (e) {
      throw 'Failed to load stats: $e';
    }
  }

  // Hotel Management
  Future<bool> createHotel(Map<String, dynamic> hotelData, List<File> images) async {
    try {
      _setLoading(true);
      print('HotelOwnerProvider: Creating hotel with data: $hotelData');
      print('HotelOwnerProvider: Images count: ${images.length}');
      
      final newHotel = await _apiService.createHotel(hotelData, images);
      print('HotelOwnerProvider: Hotel created successfully: ${newHotel.id}');
      
      _ownedHotels.add(newHotel);
      notifyListeners();
      return true;
    } catch (e) {
      print('HotelOwnerProvider: Error creating hotel: $e');
      _error = 'Failed to create hotel: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateHotel(String hotelId, Map<String, dynamic> hotelData, List<File> newImages) async {
    try {
      _setLoading(true);
      final updatedHotel = await _apiService.updateHotel(hotelId, hotelData, newImages);
      final index = _ownedHotels.indexWhere((h) => h.id == hotelId);
      if (index != -1) {
        _ownedHotels[index] = updatedHotel;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'Failed to update hotel: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<Hotel?> getHotelById(String hotelId) async {
    try {
      final hotel = await _apiService.getHotelById(hotelId);
      return hotel;
    } catch (e) {
      print('HotelOwnerProvider: Error getting hotel: $e');
      throw e; // Re-throw để screen có thể handle
    }
  }

  Future<bool> toggleHotelStatus(String hotelId) async {
    try {
      _setLoading(true);
      final updatedHotel = await _apiService.toggleHotelStatus(hotelId);
      
      // Update hotel in list
      final index = _ownedHotels.indexWhere((h) => h.id == hotelId);
      if (index != -1) {
        _ownedHotels[index] = updatedHotel;
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _error = 'Failed to toggle hotel status: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteHotel(String hotelId) async {
    try {
      _setLoading(true);
      await _apiService.deleteHotel(hotelId);
      _ownedHotels.removeWhere((h) => h.id == hotelId);
      _allRooms.removeWhere((r) => r.hotelId == hotelId);
      _allBookings.removeWhere((b) => b.hotelId == hotelId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete hotel: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Room Management
  Future<bool> createRoom(String hotelId, Map<String, dynamic> roomData, List<File> images) async {
    try {
      _setLoading(true);
      final newRoom = await _apiService.createRoom(hotelId, roomData, images);
      _allRooms.add(newRoom);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to create room: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateRoom(String roomId, Map<String, dynamic> roomData, List<File> newImages) async {
    try {
      _setLoading(true);
      final updatedRoom = await _apiService.updateRoom(roomId, roomData, newImages);
      final index = _allRooms.indexWhere((r) => r.id == roomId);
      if (index != -1) {
        _allRooms[index] = updatedRoom;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'Failed to update room: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> toggleRoomStatus(String roomId) async {
    try {
      _setLoading(true);
      final updatedRoom = await _apiService.toggleRoomStatus(roomId);
      
      // Update room in list
      final index = _allRooms.indexWhere((r) => r.id == roomId);
      if (index != -1) {
        _allRooms[index] = updatedRoom;
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _error = 'Failed to toggle room status: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteRoom(String roomId) async {
    try {
      _setLoading(true);
      await _apiService.deleteRoom(roomId);
      _allRooms.removeWhere((r) => r.id == roomId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete room: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<Room?> getRoomById(String roomId) async {
    try {
      final room = await _apiService.getRoomById(roomId);
      return room;
    } catch (e) {
      print('HotelOwnerProvider: Error getting room: $e');
      throw e;
    }
  }

  Future<List<Room>> getRoomsByHotel(String hotelId, {String? checkIn, String? checkOut, int? guests}) async {
    try {
      // Only return rooms that belong to the current owner's hotels
      if (_allRooms.isEmpty) {
        await loadAllRooms();
      }
      return _allRooms.where((r) => r.hotelId == hotelId).toList();
    } catch (e) {
      print('HotelOwnerProvider: Error getting rooms: $e');
      throw e;
    }
  }

  // Booking Management
  Future<bool> updateBookingStatus(String bookingId, String status) async {
    try {
      _setLoading(true);
      final updatedBooking = await _apiService.updateBookingStatus(bookingId, status);
      final index = _allBookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _allBookings[index] = updatedBooking;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'Failed to update booking status: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> checkInGuest(String bookingId) async {
    return updateBookingStatus(bookingId, 'checked_in');
  }

  Future<bool> checkOutGuest(String bookingId) async {
    return updateBookingStatus(bookingId, 'checked_out');
  }

  Future<bool> confirmBooking(String bookingId) async {
    return updateBookingStatus(bookingId, 'confirmed');
  }

  Future<bool> cancelBooking(String bookingId) async {
    return updateBookingStatus(bookingId, 'cancelled');
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
