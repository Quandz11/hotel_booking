import 'package:flutter/foundation.dart';
import '../models/hotel.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class FavoritesProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  AuthProvider? _authProvider;

  final Set<String> _favoriteHotelIds = {};
  List<Hotel> _favoriteHotels = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _initialized = false;

  void updateAuth(AuthProvider authProvider) {
    final previousUserId = _authProvider?.currentUser?.id;
    _authProvider = authProvider;
    final currentUserId = authProvider.currentUser?.id;

    if (previousUserId != currentUserId) {
      _favoriteHotelIds.clear();
      _favoriteHotels = [];
      _isLoading = false;
      _errorMessage = null;
      _initialized = false;

      if (authProvider.currentUser != null &&
          authProvider.currentUser!.role == 'customer') {
        loadFavorites();
      } else {
        notifyListeners();
      }
    }
  }

  List<Hotel> get favoriteHotels => List.unmodifiable(_favoriteHotels);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isFavorite(String hotelId) => _favoriteHotelIds.contains(hotelId);

  Future<void> ensureLoaded() async {
    if (_initialized) return;
    await loadFavorites();
  }

  Future<void> loadFavorites() async {
    final user = _authProvider?.currentUser;
    if (user == null || user.role != 'customer') {
      _favoriteHotelIds.clear();
      _favoriteHotels = [];
      _initialized = true;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final favorites = await _apiService.getFavoriteHotels(user.id);
      _favoriteHotels = favorites;
      _favoriteHotelIds
        ..clear()
        ..addAll(favorites.map((hotel) => hotel.id));
      _initialized = true;
    } catch (e) {
      _errorMessage = 'Failed to load favorite hotels';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool?> toggleFavorite(String hotelId) async {
    final user = _authProvider?.currentUser;
    if (user == null || user.role != 'customer') {
      _errorMessage =
          'You must be logged in as a customer to manage favorite hotels.';
      notifyListeners();
      return null;
    }

    _errorMessage = null;
    final wasFavorite = _favoriteHotelIds.contains(hotelId);

    if (wasFavorite) {
      _favoriteHotelIds.remove(hotelId);
      _favoriteHotels.removeWhere((hotel) => hotel.id == hotelId);
    } else {
      _favoriteHotelIds.add(hotelId);
    }
    notifyListeners();

    try {
      await _apiService.toggleFavoriteHotel(user.id, hotelId);
      await loadFavorites();
      return !wasFavorite;
    } catch (e) {
      if (wasFavorite) {
        _favoriteHotelIds.add(hotelId);
      } else {
        _favoriteHotelIds.remove(hotelId);
      }
      _errorMessage = 'Failed to update favorite hotel';
      notifyListeners();
      return null;
    }
  }

  void clear() {
    _favoriteHotelIds.clear();
    _favoriteHotels = [];
    _isLoading = false;
    _errorMessage = null;
    _initialized = false;
    notifyListeners();
  }
}
