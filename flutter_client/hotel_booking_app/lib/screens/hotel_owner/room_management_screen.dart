import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/room.dart';
import '../../models/hotel.dart';
import '../../providers/hotel_owner_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/loading_widget.dart';
import 'room_form_screen.dart';
import 'room_detail_screen.dart';

class RoomManagementScreen extends StatefulWidget {
  final Hotel? hotel; // Make hotel optional

  const RoomManagementScreen({super.key, this.hotel});

  @override
  State<RoomManagementScreen> createState() => _RoomManagementScreenState();
}

class _RoomManagementScreenState extends State<RoomManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRooms();
    });
  }

  Future<void> _loadRooms() async {
    final provider = Provider.of<HotelOwnerProvider>(context, listen: false);
    // Always load only rooms owned by current user
    await provider.loadAllRooms();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hotel != null 
            ? '${l10n.rooms} - ${widget.hotel!.name}'
            : l10n.manageRooms),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadRooms,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Consumer<HotelOwnerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const LoadingWidget();
          }

          if (provider.error.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.error,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red[700]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadRooms,
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          final canManageThisHotel = widget.hotel == null
              ? true
              : Provider.of<HotelOwnerProvider>(context, listen: false)
                  .isOwnedHotelId(widget.hotel!.id);

          final rooms = widget.hotel != null
              ? provider.allRooms.where((room) => room.hotelId == widget.hotel!.id).toList()
              : provider.allRooms;

          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.hotel_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noRoomsYet,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.addRoomFirst,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: canManageThisHotel ? () => _navigateToAddRoom() : null,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addRoom),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canManageThisHotel
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadRooms,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[50],
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${l10n.totalRooms}: ${rooms.length}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        '${l10n.activeRooms}: ${rooms.where((r) => r.isActive).length}',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      return _buildRoomCard(room);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddRoom(),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRoomCard(Room room) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToRoomDetail(room),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
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
                          room.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getRoomTypeName(room.type),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: room.isActive ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      room.isActive ? l10n.active : l10n.inactive,
                      style: TextStyle(
                        color: room.isActive ? Colors.green[700] : Colors.red[700],
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(value, room),
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
                              room.isActive ? Icons.visibility_off : Icons.visibility,
                              color: room.isActive ? Colors.orange : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(room.isActive ? l10n.deactivate : l10n.activate),
                          ],
                        ),
                      ),
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
              ),
              const SizedBox(height: 12),
              Text(
                room.description,
                style: TextStyle(color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.people,
                    label: '${room.maxGuests} ${l10n.guests}',
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.bed,
                    label: '${room.bedCount} ${_getBedTypeName(room.bedType)}',
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  if (room.size != null)
                    _buildInfoChip(
                      icon: Icons.square_foot,
                      label: '${room.size!.toInt()}m²',
                      color: Colors.orange,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.basePrice,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          room.formatPrice(room.basePrice),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.weekendPrice,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          room.formatPrice(room.weekendPrice),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${room.totalRooms} ${l10n.available}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (room.amenities.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: room.amenities.take(3).map((amenity) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getAmenityName(amenity),
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList()
                    ..addAll(room.amenities.length > 3
                        ? [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '+${room.amenities.length - 3}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            )
                          ]
                        : []),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
      default:
        return amenity.replaceAll('_', ' ');
    }
  }

  void _handleMenuAction(String action, Room room) async {
    final l10n = AppLocalizations.of(context)!;
    
    switch (action) {
      case 'edit':
        _navigateToEditRoom(room);
        break;
      case 'toggle':
        await _toggleRoomStatus(room);
        break;
      case 'delete':
        _showDeleteConfirmation(room);
        break;
    }
  }

  Future<void> _navigateToAddRoom() async {
    if (widget.hotel != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RoomFormScreen(hotelId: widget.hotel!.id),
        ),
      );

      if (result == true) {
        _loadRooms();
      }
    } else {
      // Show hotel selection dialog or navigate to hotel selection
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a hotel first'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _navigateToEditRoom(Room room) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomFormScreen(room: room),
      ),
    );

    if (result == true) {
      _loadRooms();
    }
  }

  void _navigateToRoomDetail(Room room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomDetailScreen(room: room),
      ),
    );
  }

  Future<void> _toggleRoomStatus(Room room) async {
    final provider = Provider.of<HotelOwnerProvider>(context, listen: false);
    final success = await provider.toggleRoomStatus(room.id);
    
    if (success) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            room.isActive 
                ? l10n.roomDeactivatedSuccess 
                : l10n.roomActivatedSuccess,
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

  void _showDeleteConfirmation(Room room) {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteRoom),
        content: Text('${l10n.deleteRoomConfirmation} "${room.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRoom(room);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRoom(Room room) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<HotelOwnerProvider>(context, listen: false);
    
    final success = await provider.deleteRoom(room.id);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.roomDeletedSuccess),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error.isNotEmpty ? provider.error : l10n.deleteRoomFailed),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
