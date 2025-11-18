import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/hotel_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/hotel_card.dart';
import '../../widgets/language_switch_button.dart';
import '../hotel/hotel_detail_screen.dart';
import '../main/search_screen.dart';
import '../booking/customer_bookings_screen.dart';
import 'favorite_hotels_screen.dart';
import 'hotels_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch featured hotels when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HotelProvider>().fetchFeaturedHotels();
      final authProvider = context.read<AuthProvider>();
      if (authProvider.currentUser?.role == 'customer') {
        context.read<FavoritesProvider>().ensureLoaded();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.home),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: const [
          LanguageSwitchButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.welcomeMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.findYourPerfectStay,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quick actions
            Text(
              l10n.quickActions,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildActionCard(
                  context,
                  icon: Icons.search,
                  title: l10n.searchHotels,
                  onTap: () => _navigateToSearch(),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.favorite,
                  title: l10n.favorites,
                  onTap: () => _showFavorites(),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.history,
                  title: l10n.recentBookings,
                  onTap: () => _navigateToBookings(),
                ),
                _buildActionCard(
                  context,
                  icon: Icons.location_on,
                  title: l10n.nearbyHotels,
                  onTap: () => _showNearbyHotels(),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Featured hotels section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.featuredHotels,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _navigateToAllHotels(),
                  child: Text(l10n.seeAll),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Featured hotels list
            Consumer<HotelProvider>(
              builder: (context, hotelProvider, child) {
                if (hotelProvider.isLoadingFeatured) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                if (hotelProvider.errorMessage != null) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Error loading hotels',
                            style: TextStyle(
                              color: Colors.red[600],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              hotelProvider.fetchFeaturedHotels();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[400],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                if (hotelProvider.featuredHotels.isEmpty) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.hotel_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No featured hotels available',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => _navigateToSearch(),
                            icon: const Icon(Icons.search),
                            label: const Text('Search Hotels'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                return Consumer2<AuthProvider, FavoritesProvider>(
                  builder: (context, authProvider, favoritesProvider, _) {
                    final canFavorite = authProvider.currentUser?.role == 'customer';

                    return SizedBox(
                      height: 280,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: hotelProvider.featuredHotels.length,
                        itemBuilder: (context, index) {
                          final hotel = hotelProvider.featuredHotels[index];
                          return Container(
                            width: 250,
                            margin: EdgeInsets.only(
                              right: index < hotelProvider.featuredHotels.length - 1 ? 16 : 0,
                            ),
                            child: HotelCard(
                              hotel: hotel,
                              onTap: () => _navigateToHotelDetail(hotel),
                              showFavoriteButton: canFavorite,
                              isFavorite: favoritesProvider.isFavorite(hotel.id),
                              onToggleFavorite: () {
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
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
                    size: 32,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SearchScreen(),
      ),
    );
  }

  void _showFavorites() {
    final authProvider = context.read<AuthProvider>();

    if (authProvider.currentUser?.role != 'customer') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login as a customer to view favorites.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    context.read<FavoritesProvider>().ensureLoaded();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FavoriteHotelsScreen(),
      ),
    );
  }

  void _navigateToBookings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomerBookingsScreen(),
      ),
    );
  }

  void _showNearbyHotels() {
    final l10n = AppLocalizations.of(context)!;
    // Navigate to search with location filter
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SearchScreen(),
      ),
    );
    
    // Show info about nearby hotels
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${l10n.searchHotels} - ${l10n.nearbyHotels}'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  void _navigateToAllHotels() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HotelsListScreen(),
      ),
    );
  }

  void _navigateToHotelDetail(hotel) {
    // Set selected hotel in provider
    context.read<HotelProvider>().setSelectedHotel(hotel);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HotelDetailScreen(hotel: hotel),
      ),
    );
  }
}
