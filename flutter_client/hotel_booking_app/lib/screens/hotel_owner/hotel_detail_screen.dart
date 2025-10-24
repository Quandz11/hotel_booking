import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/hotel.dart';
import '../../providers/hotel_owner_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/loading_widget.dart';
import 'hotel_form_screen.dart';
import 'room_management_screen.dart';

class HotelDetailScreen extends StatefulWidget {
  final String hotelId;
  
  const HotelDetailScreen({super.key, required this.hotelId});

  @override
  State<HotelDetailScreen> createState() => _HotelDetailScreenState();
}

class _HotelDetailScreenState extends State<HotelDetailScreen> {
  Hotel? _hotel;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHotelDetails();
    });
  }

  Future<void> _loadHotelDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final provider = Provider.of<HotelOwnerProvider>(context, listen: false);
      final hotel = await provider.getHotelById(widget.hotelId);
      
      setState(() {
        _hotel = hotel;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.hotelDetails),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const LoadingWidget(),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.hotelDetails),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                l10n.errorLoadingHotel,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadHotelDetails,
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_hotel == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.hotelDetails),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Text(l10n.hotelNotFound),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_hotel!.name),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (Provider.of<HotelOwnerProvider>(context, listen: false)
              .isOwnedHotelId(widget.hotelId)) ...[
            IconButton(
              icon: const Icon(Icons.hotel),
              onPressed: () => _navigateToRoomManagement(),
              tooltip: 'Manage Rooms',
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editHotel(),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'delete':
                    _confirmDeleteHotel();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(l10n.delete),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadHotelDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageGallery(),
              const SizedBox(height: 24),
              _buildBasicInfo(),
              const SizedBox(height: 24),
              _buildAddressInfo(),
              const SizedBox(height: 24),
              _buildContactInfo(),
              const SizedBox(height: 24),
              _buildHotelDetails(),
              const SizedBox(height: 24),
              _buildAmenities(),
              const SizedBox(height: 24),
              _buildStatistics(),
              const SizedBox(height: 24),
              _buildRoomManagementSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    if (_hotel!.images.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, size: 64, color: Colors.grey[500]),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.noImages,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 250,
      child: PageView.builder(
        itemCount: _hotel!.images.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _hotel!.images[index].url,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 64),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBasicInfo() {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _hotel!.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    ...List.generate(_hotel!.starRating, (index) => 
                      const Icon(Icons.star, color: Colors.amber, size: 20)),
                    const SizedBox(width: 4),
                    Text('${_hotel!.starRating} ${l10n.stars}'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _hotel!.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _hotel!.isActive ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _hotel!.isActive ? l10n.active : l10n.inactive,
                style: TextStyle(
                  color: _hotel!.isActive ? Colors.green[800] : Colors.red[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressInfo() {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.address,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_hotel!.address.street),
                      Text('${_hotel!.address.city}, ${_hotel!.address.state}'),
                      Text('${_hotel!.address.country} ${_hotel!.address.zipCode}'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo() {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.contactInformation,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildContactItem(
              Icons.phone,
              _hotel!.contact.phone,
              () => _launchUrl('tel:${_hotel!.contact.phone}'),
            ),
            const SizedBox(height: 8),
            _buildContactItem(
              Icons.email,
              _hotel!.contact.email,
              () => _launchUrl('mailto:${_hotel!.contact.email}'),
            ),
            if (_hotel!.contact.website.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildContactItem(
                Icons.language,
                _hotel!.contact.website,
                () => _launchUrl(_hotel!.contact.website),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelDetails() {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.hotelDetails,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    l10n.checkInTime,
                    _hotel!.policies.checkIn,
                    Icons.login,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    l10n.checkOutTime,
                    _hotel!.policies.checkOut,
                    Icons.logout,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailItem(
              l10n.cancellationPolicy,
              _getCancellationPolicyName(_hotel!.policies.cancellation),
              Icons.policy,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmenities() {
    final l10n = AppLocalizations.of(context)!;

    if (_hotel!.amenities.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.amenities,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.noAmenities,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.amenities,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _hotel!.amenities.map((amenity) {
                return Chip(
                  label: Text(_getAmenityName(amenity)),
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.statistics,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    l10n.averageRating,
                    _hotel!.averageRating.toStringAsFixed(1),
                    Icons.star,
                    Colors.amber,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    l10n.totalReviews,
                    _hotel!.totalReviews.toString(),
                    Icons.rate_review,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    l10n.totalRooms,
                    "0", // Default since totalRooms not in model
                    Icons.hotel,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    l10n.totalBookings,
                    "0", // Default since totalBookings not in model
                    Icons.book_online,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getAmenityName(String amenity) {
    final amenityNames = {
      'wifi': 'WiFi',
      'parking': 'Parking',
      'pool': 'Swimming Pool',
      'gym': 'Fitness Center',
      'spa': 'Spa',
      'restaurant': 'Restaurant',
      'bar': 'Bar',
      'room_service': 'Room Service',
      'concierge': 'Concierge',
      'laundry': 'Laundry',
      'airport_shuttle': 'Airport Shuttle',
      'business_center': 'Business Center',
      'conference_room': 'Conference Room',
      'pet_friendly': 'Pet Friendly',
    };
    return amenityNames[amenity] ?? amenity;
  }

  String _getCancellationPolicyName(String policy) {
    final l10n = AppLocalizations.of(context)!;
    switch (policy) {
      case 'flexible':
        return l10n.flexible;
      case 'moderate':
        return l10n.moderate;
      case 'strict':
        return l10n.strict;
      default:
        return policy;
    }
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  Widget _buildRoomManagementSection() {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.hotel,
                  size: 24,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.roomManagement,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[600],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.manageHotelRooms,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _navigateToRoomManagement,
                icon: const Icon(Icons.hotel),
                label: Text(l10n.manageRooms),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToRoomManagement() {
    final provider = Provider.of<HotelOwnerProvider>(context, listen: false);
    if (_hotel != null && provider.isOwnedHotelId(_hotel!.id)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RoomManagementScreen(hotel: _hotel!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn không có quyền quản lý khách sạn này')),
      );
    }
  }

  Future<void> _editHotel() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HotelFormScreen(hotel: _hotel),
      ),
    );

    if (result == true) {
      // Refresh hotel details after edit
      _loadHotelDetails();
    }
  }

  Future<void> _confirmDeleteHotel() async {
    final l10n = AppLocalizations.of(context)!;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.confirmDeleteHotelMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteHotel();
    }
  }

  Future<void> _deleteHotel() async {
    final l10n = AppLocalizations.of(context)!;
    
    try {
      final provider = Provider.of<HotelOwnerProvider>(context, listen: false);
      await provider.deleteHotel(_hotel!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.hotelDeletedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return to hotel list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
