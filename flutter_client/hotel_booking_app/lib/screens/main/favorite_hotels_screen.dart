import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/hotel_card.dart';
import '../hotel/hotel_detail_screen.dart';

class FavoriteHotelsScreen extends StatefulWidget {
  const FavoriteHotelsScreen({super.key});

  @override
  State<FavoriteHotelsScreen> createState() => _FavoriteHotelsScreenState();
}

class _FavoriteHotelsScreenState extends State<FavoriteHotelsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesProvider>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.favorites),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer2<AuthProvider, FavoritesProvider>(
        builder: (context, authProvider, favoritesProvider, _) {
          final user = authProvider.currentUser;

          if (user == null || user.role != 'customer') {
            return _buildMessage(
              context,
              'Please login as a customer to manage favorite hotels.',
              icon: Icons.lock_outline,
            );
          }

          if (favoritesProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (favoritesProvider.favoriteHotels.isEmpty) {
            return _buildMessage(
              context,
              'You have not added any hotels to your favorites yet.',
              icon: Icons.favorite_border,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: favoritesProvider.favoriteHotels.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final hotel = favoritesProvider.favoriteHotels[index];
              return HotelCard(
                hotel: hotel,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HotelDetailScreen(hotel: hotel),
                    ),
                  );
                },
                showFavoriteButton: true,
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
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMessage(BuildContext context, String message, {IconData? icon}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(
                icon,
                size: 48,
                color: Colors.grey[400],
              ),
            if (icon != null) const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
