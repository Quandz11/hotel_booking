import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/hotel.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/hotel_provider.dart';
import '../../widgets/hotel_card.dart';
import '../hotel/hotel_detail_screen.dart';

class HotelsListScreen extends StatefulWidget {
  const HotelsListScreen({super.key});

  @override
  State<HotelsListScreen> createState() => _HotelsListScreenState();
}

class _HotelsListScreenState extends State<HotelsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHotels();
    });
  }

  Future<void> _loadHotels() async {
    final hotelProvider = context.read<HotelProvider>();
    final favoritesProvider = context.read<FavoritesProvider>();
    final authProvider = context.read<AuthProvider>();

    await hotelProvider.fetchHotels();

    if (authProvider.currentUser?.role == 'customer') {
      await favoritesProvider.ensureLoaded();
    }
  }

  Future<void> _refreshHotels() async {
    await _loadHotels();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.allHotels),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer3<HotelProvider, FavoritesProvider, AuthProvider>(
        builder: (context, hotelProvider, favoritesProvider, authProvider, _) {
          if (hotelProvider.isLoadingHotels && hotelProvider.hotels.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (hotelProvider.errorMessage != null &&
              hotelProvider.hotels.isEmpty) {
            return _buildStatusMessage(
              context,
              icon: Icons.error_outline,
              title: l10n.noHotelsFound,
              subtitle: hotelProvider.errorMessage!,
              actionLabel: l10n.tryAgain,
              onAction: _loadHotels,
            );
          }

          if (hotelProvider.hotels.isEmpty) {
            return _buildStatusMessage(
              context,
              icon: Icons.hotel_outlined,
              title: l10n.noHotelsFound,
              subtitle: l10n.noHotelsYet,
              actionLabel: l10n.tryAgain,
              onAction: _loadHotels,
            );
          }

          final canFavorite = authProvider.currentUser?.role == 'customer';

          return RefreshIndicator(
            onRefresh: _refreshHotels,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: hotelProvider.hotels.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final hotel = hotelProvider.hotels[index];
                return HotelCard(
                  hotel: hotel,
                  onTap: () => _openHotelDetail(hotel),
                  showFavoriteButton: canFavorite,
                  isFavorite: favoritesProvider.isFavorite(hotel.id),
                  onToggleFavorite: canFavorite
                      ? () => _toggleFavorite(context, hotel.id)
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _openHotelDetail(Hotel hotel) {
    context.read<HotelProvider>().setSelectedHotel(hotel);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HotelDetailScreen(hotel: hotel),
      ),
    );
  }

  void _toggleFavorite(BuildContext context, String hotelId) {
    final favoritesProvider = context.read<FavoritesProvider>();
    favoritesProvider.toggleFavorite(hotelId).then((result) {
      if (result == null &&
          favoritesProvider.errorMessage != null &&
          mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(favoritesProvider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  Widget _buildStatusMessage(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: Colors.grey[500],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
