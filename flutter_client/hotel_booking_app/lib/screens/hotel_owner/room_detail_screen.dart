import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/room.dart';
import '../../providers/hotel_owner_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/loading_widget.dart';
import 'room_form_screen.dart';

class RoomDetailScreen extends StatefulWidget {
  final Room room;

  const RoomDetailScreen({super.key, required this.room});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  late Room _currentRoom;

  @override
  void initState() {
    super.initState();
    _currentRoom = widget.room;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentRoom.name),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(l10n.edit),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(
                      _currentRoom.isActive ? Icons.visibility_off : Icons.visibility,
                      color: _currentRoom.isActive ? Colors.orange : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(_currentRoom.isActive ? l10n.deactivate : l10n.activate),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(),
            _buildBasicInfoSection(),
            _buildPricingSection(),
            _buildRoomDetailsSection(),
            _buildAmenitiesSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToEditRoom,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildImageSection() {
    if (_currentRoom.images.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        color: Colors.grey[300],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              'No Images',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: _currentRoom.images.length,
        itemBuilder: (context, index) {
          final image = _currentRoom.images[index];
          return Stack(
            children: [
              Image.network(
                image.url,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 64),
                  );
                },
              ),
              if (image.caption.isNotEmpty)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Text(
                      image.caption,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              if (image.isPrimary)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Primary',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${index + 1}/${_currentRoom.images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentRoom.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getRoomTypeName(_currentRoom.type),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _currentRoom.isActive ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _currentRoom.isActive ? l10n.active : l10n.inactive,
                  style: TextStyle(
                    color: _currentRoom.isActive ? Colors.green[700] : Colors.red[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _currentRoom.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection() {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pricing',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPriceItem(
                    l10n.basePrice,
                    _currentRoom.formatPrice(_currentRoom.basePrice),
                    Colors.green,
                    Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPriceItem(
                    l10n.weekendPrice,
                    _currentRoom.formatPrice(_currentRoom.weekendPrice),
                    Colors.orange,
                    Icons.weekend,
                  ),
                ),
              ],
            ),
            if (_currentRoom.discountPercentage > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_offer, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    Text(
                      '${l10n.discount}: ${_currentRoom.discountPercentage}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_currentRoom.specialOfferDescription?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.blue[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currentRoom.specialOfferDescription!,
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceItem(String label, String price, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomDetailsSection() {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.roomInfo,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailItem(
              Icons.people,
              l10n.maxGuests,
              '${_currentRoom.maxGuests} ${l10n.guests}',
              Colors.blue,
            ),
            _buildDetailItem(
              Icons.bed,
              l10n.bedInfo,
              '${_currentRoom.bedCount} ${_getBedTypeName(_currentRoom.bedType)}',
              Colors.green,
            ),
            if (_currentRoom.size != null)
              _buildDetailItem(
                Icons.square_foot,
                l10n.roomSize,
                '${_currentRoom.size!.toInt()} m²',
                Colors.orange,
              ),
            _buildDetailItem(
              Icons.hotel,
              l10n.totalRooms,
              '${_currentRoom.totalRooms} ${l10n.available}',
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection() {
    final l10n = AppLocalizations.of(context)!;

    if (_currentRoom.amenities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.roomAmenities,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _currentRoom.amenities.map((amenity) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getAmenityIcon(amenity),
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getAmenityName(amenity),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoomTypeName(String type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case 'standard':
        return l10n.standardRoom;
      case 'deluxe':
        return l10n.deluxeRoom;
      case 'suite':
        return l10n.suiteRoom;
      case 'executive':
        return l10n.executiveRoom;
      case 'presidential':
        return l10n.presidentialRoom;
      default:
        return type;
    }
  }

  String _getBedTypeName(String type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case 'single':
        return l10n.singleBed;
      case 'double':
        return l10n.doubleBed;
      case 'queen':
        return l10n.queenBed;
      case 'king':
        return l10n.kingBed;
      case 'twin':
        return l10n.twinBed;
      default:
        return type;
    }
  }

  String _getAmenityName(String amenity) {
    final l10n = AppLocalizations.of(context)!;
    switch (amenity) {
      case 'wifi':
        return l10n.wifi;
      case 'air_conditioning':
        return l10n.airConditioning;
      case 'tv':
        return l10n.tv;
      case 'minibar':
        return l10n.minibar;
      case 'safe':
        return l10n.safe;
      case 'balcony':
        return l10n.balcony;
      case 'city_view':
        return l10n.cityView;
      case 'ocean_view':
        return l10n.oceanView;
      case 'mountain_view':
        return l10n.mountainView;
      case 'kitchenette':
        return l10n.kitchenette;
      case 'bathtub':
        return l10n.bathtub;
      case 'shower':
        return l10n.shower;
      case 'hairdryer':
        return l10n.hairdryer;
      case 'coffee_maker':
        return l10n.coffeeMaker;
      case 'telephone':
        return l10n.telephone;
      case 'desk':
        return l10n.desk;
      case 'sofa':
        return l10n.sofa;
      default:
        return amenity.replaceAll('_', ' ');
    }
  }

  IconData _getAmenityIcon(String amenity) {
    switch (amenity) {
      case 'wifi':
        return Icons.wifi;
      case 'air_conditioning':
        return Icons.ac_unit;
      case 'tv':
        return Icons.tv;
      case 'minibar':
        return Icons.local_bar;
      case 'safe':
        return Icons.security;
      case 'balcony':
        return Icons.balcony;
      case 'city_view':
      case 'ocean_view':
      case 'mountain_view':
        return Icons.landscape;
      case 'kitchenette':
        return Icons.kitchen;
      case 'bathtub':
        return Icons.bathtub;
      case 'shower':
        return Icons.shower;
      case 'hairdryer':
        return Icons.dry;
      case 'coffee_maker':
        return Icons.coffee;
      case 'telephone':
        return Icons.phone;
      case 'desk':
        return Icons.desk;
      case 'sofa':
        return Icons.weekend;
      default:
        return Icons.check;
    }
  }

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'edit':
        _navigateToEditRoom();
        break;
      case 'toggle':
        await _toggleRoomStatus();
        break;
    }
  }

  Future<void> _navigateToEditRoom() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomFormScreen(room: _currentRoom),
      ),
    );

    if (result == true) {
      // Refresh room data - you might want to reload the room data here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Room updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _toggleRoomStatus() async {
    final provider = Provider.of<HotelOwnerProvider>(context, listen: false);
    final success = await provider.toggleRoomStatus(_currentRoom.id);
    
    if (success) {
      setState(() {
        _currentRoom = _currentRoom.copyWith(isActive: !_currentRoom.isActive);
      });
      
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _currentRoom.isActive 
                ? l10n.roomActivatedSuccess 
                : l10n.roomDeactivatedSuccess,
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error.isNotEmpty ? provider.error : 'Failed to update room status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
