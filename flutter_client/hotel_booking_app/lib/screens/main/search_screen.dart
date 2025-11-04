import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/hotel.dart';
import '../../services/api_service.dart';
import '../hotel/hotel_detail_screen.dart';
import 'chatbot_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _guests = 1;
  int _rooms = 1;
  bool _isLoading = false;
  List<Hotel> _searchResults = [];
  List<Hotel> _allResults = [];
  bool _hasSearched = false;

  // Filter variables
  RangeValues _priceRange = const RangeValues(0, 10000000);
  double _minRating = 0;
  String _sortBy = 'relevance'; // relevance, price_low, price_high, rating
  List<String> _selectedAmenities = [];
  
  // Filter constants
  static const double _maxPrice = 10000000;
  static const List<String> _availableAmenities = [
    'WiFi',
    'Pool',
    'Spa',
    'Gym',
    'Restaurant',
    'Bar',
    'Parking',
    'Pet Friendly',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.search),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Filter button
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_alt),
                if (_hasActiveFilters())
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showFilterDialog,
            tooltip: 'Filters',
          ),
          // Chatbot button
          IconButton(
            icon: const Icon(Icons.smart_toy),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatbotScreen(),
                ),
              );
            },
            tooltip: l10n.chatbot,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search form
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.searchForHotels,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Location search
                  TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: l10n.destination,
                      hintText: l10n.enterDestination,
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Date selection
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectCheckInDate(context),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[400]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.checkIn,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _checkInDate != null
                                      ? '${_checkInDate!.day}/${_checkInDate!.month}/${_checkInDate!.year}'
                                      : l10n.selectDate,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectCheckOutDate(context),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[400]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.checkOut,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _checkOutDate != null
                                      ? '${_checkOutDate!.day}/${_checkOutDate!.month}/${_checkOutDate!.year}'
                                      : l10n.selectDate,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Guests and rooms
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[400]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.guests,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$_guests',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: _guests > 1 ? () {
                                          setState(() {
                                            _guests--;
                                          });
                                        } : null,
                                        icon: const Icon(Icons.remove),
                                        iconSize: 16,
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _guests++;
                                          });
                                        },
                                        icon: const Icon(Icons.add),
                                        iconSize: 16,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[400]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.rooms,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$_rooms',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: _rooms > 1 ? () {
                                          setState(() {
                                            _rooms--;
                                          });
                                        } : null,
                                        icon: const Icon(Icons.remove),
                                        iconSize: 16,
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _rooms++;
                                          });
                                        },
                                        icon: const Icon(Icons.add),
                                        iconSize: 16,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Search button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _performSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              l10n.searchHotels,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Search results or suggestions
            if (_hasSearched) _buildSearchResults() else _buildPopularDestinations(),
          ],
        ),
      ),
      // Floating action button for chatbot
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChatbotScreen(),
            ),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.smart_toy, color: Colors.white),
        tooltip: l10n.chatbot,
      ),
    );
  }

  Widget _buildSearchResults() {
    final l10n = AppLocalizations.of(context)!;

    if (_searchResults.isEmpty && _allResults.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Column(
          children: [
            Icon(
              Icons.filter_alt_off,
              size: 48,
              color: Colors.orange[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hotels match your filters',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filter criteria',
              style: TextStyle(
                color: Colors.orange[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[400],
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hotels found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search criteria',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results header with count and active filters
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_searchResults.length} hotels found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_hasActiveFilters())
              GestureDetector(
                onTap: _showFilterDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_alt,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Filtered',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Active filters summary
        if (_hasActiveFilters()) _buildActiveFilters(),
        
        const SizedBox(height: 16),
        
        // Hotels list
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final hotel = _searchResults[index];
            return _buildHotelCard(hotel);
          },
        ),
      ],
    );
  }

  Widget _buildActiveFilters() {
    List<Widget> filterChips = [];

    if (_sortBy != 'relevance') {
      String sortLabel = '';
      switch (_sortBy) {
        case 'price_low': sortLabel = 'Price ↑'; break;
        case 'price_high': sortLabel = 'Price ↓'; break;
        case 'rating': sortLabel = 'Rating ↓'; break;
      }
      filterChips.add(_buildFilterChip(sortLabel, () {
        setState(() {
          _sortBy = 'relevance';
          _applyFiltersAndSort();
        });
      }));
    }

    if (_priceRange.start > 0 || _priceRange.end < _maxPrice) {
      filterChips.add(_buildFilterChip(
        '${_formatPrice(_priceRange.start)} - ${_formatPrice(_priceRange.end)}',
        () {
          setState(() {
            _priceRange = const RangeValues(0, _maxPrice);
            _applyFiltersAndSort();
          });
        },
      ));
    }

    if (_minRating > 0) {
      filterChips.add(_buildFilterChip('${_minRating.toInt()}+ stars', () {
        setState(() {
          _minRating = 0;
          _applyFiltersAndSort();
        });
      }));
    }

    for (String amenity in _selectedAmenities) {
      filterChips.add(_buildFilterChip(amenity, () {
        setState(() {
          _selectedAmenities.remove(amenity);
          _applyFiltersAndSort();
        });
      }));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: filterChips,
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      deleteIconColor: Theme.of(context).primaryColor,
      side: BorderSide(
        color: Theme.of(context).primaryColor.withOpacity(0.3),
      ),
    );
  }

  Widget _buildHotelCard(Hotel hotel) {
    return Consumer2<AuthProvider, FavoritesProvider>(
      builder: (context, authProvider, favoritesProvider, _) {
        final canFavorite = authProvider.currentUser?.role == 'customer';
        final isFavorite = favoritesProvider.isFavorite(hotel.id);
        final l10n = AppLocalizations.of(context)!;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HotelDetailScreen(hotel: hotel),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hotel image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: hotel.images.isNotEmpty
                            ? Image.network(
                                hotel.images.first.url,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.hotel),
                                  );
                                },
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[300],
                                child: const Icon(Icons.hotel),
                              ),
                      ),
                      const SizedBox(width: 16),
                      // Hotel details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hotel.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${hotel.address.city}, ${hotel.address.country}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      index < (hotel.averageRating).round()
                                          ? Icons.star
                                          : Icons.star_border,
                                      size: 16,
                                      color: Colors.amber,
                                    );
                                  }),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${hotel.averageRating.toStringAsFixed(1)} (${hotel.totalReviews} reviews)',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              hotel.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '${_formatPrice(hotel.startingPrice)} ${hotel.currency.isNotEmpty ? hotel.currency : 'VND'}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '/ ${l10n.night}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (canFavorite)
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      favoritesProvider.toggleFavorite(hotel.id).then((result) {
                        if (result == null &&
                            favoritesProvider.errorMessage != null &&
                            context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(favoritesProvider.errorMessage!),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      });
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPopularDestinations() {
    final l10n = AppLocalizations.of(context)!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.popularDestinations,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Search for hotels above',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Or use our AI chatbot for personalized recommendations',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _performSearch() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasSearched = false;
    });

    try {
      final query = _searchController.text.trim();
      final results = await ApiService().getHotels(
        city: query.isNotEmpty ? query : null,
        limit: 50, // Get more results for filtering
      );

      setState(() {
        _allResults = results;
        _applyFiltersAndSort();
        _hasSearched = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _allResults = [];
        _hasSearched = true;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _hasActiveFilters() {
    return _priceRange.start > 0 || 
           _priceRange.end < _maxPrice ||
           _minRating > 0 ||
           _selectedAmenities.isNotEmpty ||
           _sortBy != 'relevance';
  }

  void _clearFilters() {
    setState(() {
      _priceRange = const RangeValues(0, _maxPrice);
      _minRating = 0;
      _sortBy = 'relevance';
      _selectedAmenities.clear();
      if (_hasSearched) {
        _applyFiltersAndSort();
      }
    });
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterDialog(),
    );
  }

  Widget _buildFilterDialog() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _clearFilters();
                        setModalState(() {});
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              ),

              // Filter content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sort by section
                      const Text(
                        'Sort by',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSortOptions(setModalState),
                      
                      const SizedBox(height: 24),
                      
                      // Price range section
                      const Text(
                        'Price Range (VND)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPriceFilter(setModalState),
                      
                      const SizedBox(height: 24),
                      
                      // Rating section
                      const Text(
                        'Minimum Rating',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildRatingFilter(setModalState),
                      
                      const SizedBox(height: 24),
                      
                      // Amenities section
                      const Text(
                        'Amenities',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildAmenitiesFilter(setModalState),
                    ],
                  ),
                ),
              ),

              // Apply button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        if (_hasSearched) {
                          _applyFiltersAndSort();
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOptions(StateSetter setModalState) {
    final options = [
      {'value': 'relevance', 'label': 'Relevance'},
      {'value': 'price_low', 'label': 'Price: Low to High'},
      {'value': 'price_high', 'label': 'Price: High to Low'},
      {'value': 'rating', 'label': 'Rating: High to Low'},
    ];

    return Column(
      children: options.map((option) {
        return RadioListTile<String>(
          title: Text(option['label']!),
          value: option['value']!,
          groupValue: _sortBy,
          onChanged: (value) {
            setModalState(() {
              _sortBy = value!;
            });
          },
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }

  Widget _buildPriceFilter(StateSetter setModalState) {
    return Column(
      children: [
        RangeSlider(
          values: _priceRange,
          min: 0,
          max: _maxPrice,
          divisions: 20,
          labels: RangeLabels(
            _formatPrice(_priceRange.start),
            _formatPrice(_priceRange.end),
          ),
          onChanged: (values) {
            setModalState(() {
              _priceRange = values;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formatPrice(_priceRange.start)),
            Text(_formatPrice(_priceRange.end)),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingFilter(StateSetter setModalState) {
    return Row(
      children: List.generate(5, (index) {
        final rating = index + 1;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setModalState(() {
                _minRating = _minRating == rating ? 0 : rating.toDouble();
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: _minRating >= rating 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _minRating >= rating 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey[300]!,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star,
                    size: 16,
                    color: _minRating >= rating ? Colors.white : Colors.grey,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '$rating+',
                    style: TextStyle(
                      color: _minRating >= rating ? Colors.white : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAmenitiesFilter(StateSetter setModalState) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableAmenities.map((amenity) {
        final isSelected = _selectedAmenities.contains(amenity);
        return FilterChip(
          label: Text(amenity),
          selected: isSelected,
          onSelected: (selected) {
            setModalState(() {
              if (selected) {
                _selectedAmenities.add(amenity);
              } else {
                _selectedAmenities.remove(amenity);
              }
            });
          },
          selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
          checkmarkColor: Theme.of(context).primaryColor,
        );
      }).toList(),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    } else {
      return price.toStringAsFixed(0);
    }
  }

  void _applyFiltersAndSort() {
    List<Hotel> filtered = List.from(_allResults);

    // Apply price filter
    filtered = filtered.where((hotel) {
      return hotel.startingPrice >= _priceRange.start && hotel.startingPrice <= _priceRange.end;
    }).toList();

    // Apply rating filter
    if (_minRating > 0) {
      filtered = filtered.where((hotel) => hotel.averageRating >= _minRating).toList();
    }

    // Apply amenities filter
    if (_selectedAmenities.isNotEmpty) {
      filtered = filtered.where((hotel) {
        return _selectedAmenities.every((amenity) => 
          hotel.amenities.any((hotelAmenity) => 
            hotelAmenity.toLowerCase().contains(amenity.toLowerCase())
          )
        );
      }).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'price_low':
        filtered.sort((a, b) => a.startingPrice.compareTo(b.startingPrice));
        break;
      case 'price_high':
        filtered.sort((a, b) => b.startingPrice.compareTo(a.startingPrice));
        break;
      case 'rating':
        filtered.sort((a, b) => b.averageRating.compareTo(a.averageRating));
        break;
      case 'relevance':
      default:
        // Keep original order for relevance
        break;
    }

    _searchResults = filtered;
  }

  Future<void> _selectCheckInDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _checkInDate) {
      setState(() {
        _checkInDate = picked;
        // Reset checkout date if it's before checkin
        if (_checkOutDate != null && _checkOutDate!.isBefore(picked)) {
          _checkOutDate = null;
        }
      });
    }
  }

  Future<void> _selectCheckOutDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate?.add(const Duration(days: 1)) ?? DateTime.now(),
      firstDate: _checkInDate?.add(const Duration(days: 1)) ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _checkOutDate) {
      setState(() {
        _checkOutDate = picked;
      });
    }
  }
}
