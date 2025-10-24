import 'package:flutter/material.dart';
import '../../models/hotel.dart';
import '../../models/room.dart';
import '../../services/api_service.dart';
import '../../l10n/app_localizations.dart';
import 'booking_screen.dart';

class RoomSelectionScreen extends StatefulWidget {
  final Hotel hotel;
  final List<Room> rooms;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int adults;
  final int children;

  const RoomSelectionScreen({
    super.key,
    required this.hotel,
    required this.rooms,
    this.checkIn,
    this.checkOut,
    this.adults = 1,
    this.children = 0,
  });

  @override
  State<RoomSelectionScreen> createState() => _RoomSelectionScreenState();
}

class _RoomSelectionScreenState extends State<RoomSelectionScreen> {
  DateTime _checkIn = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOut = DateTime.now().add(const Duration(days: 2));
  int _adults = 1;
  int _children = 0;
  final ApiService _apiService = ApiService();
  List<Room> _rooms = const [];
  bool _loadingRooms = false;

  @override
  void initState() {
    super.initState();
    if (widget.checkIn != null) _checkIn = widget.checkIn!;
    if (widget.checkOut != null) _checkOut = widget.checkOut!;
    _adults = widget.adults;
    _children = widget.children;
    _rooms = List<Room>.from(widget.rooms);
    // Initial fetch with current dates to include availability
    _updateRoomSearch();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Chọn phòng - ${widget.hotel.name}'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Date and Guest Selection
          _buildSelectionHeader(),
          
          // Room List
          Expanded(
            child: _loadingRooms
                ? const Center(child: CircularProgressIndicator())
                : _rooms.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rooms.length,
                    itemBuilder: (context, index) {
                      final room = _rooms[index];
                      return _buildRoomCard(room);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionHeader() {
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Date Selection
          Row(
            children: [
              Expanded(
                child: _buildDateSelector(
                  'Nhận phòng',
                  _checkIn,
                  _selectCheckInDate,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateSelector(
                  'Trả phòng',
                  _checkOut,
                  _selectCheckOutDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Guest Selection
          Row(
            children: [
              Expanded(
                child: _buildGuestSelector(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}/${date.month}/${date.year}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestSelector() {
    return InkWell(
      onTap: _showGuestSelector,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Khách',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_adults người lớn${_children > 0 ? ', $_children trẻ em' : ''}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  void _showGuestSelector() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int tempAdults = _adults;
        int tempChildren = _children;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Chọn số khách'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildGuestCounter(
                    'Người lớn',
                    tempAdults,
                    (value) => setDialogState(() => tempAdults = value),
                    min: 1,
                    max: 10,
                  ),
                  const SizedBox(height: 16),
                  _buildGuestCounter(
                    'Trẻ em',
                    tempChildren,
                    (value) => setDialogState(() => tempChildren = value),
                    min: 0,
                    max: 10,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _adults = tempAdults;
                      _children = tempChildren;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Xác nhận'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildGuestCounter(String label, int value, Function(int) onChanged, {int min = 0, int max = 10}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Row(
          children: [
            IconButton(
              onPressed: value > min ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              value.toString(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            IconButton(
              onPressed: value < max ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hotel_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Không có phòng nào khả dụng',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(Room room) {
    final nights = _checkOut.difference(_checkIn).inDays;
    final totalPrice = room.pricePerNight * nights;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room Image
          if (room.images.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                room.images.first.url,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(Icons.hotel, size: 50, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room Name and Type
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            room.type,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_formatCurrency(room.pricePerNight)}/đêm',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(totalPrice),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Room Details
                Row(
                  children: [
                    _buildRoomDetail(Icons.people, '${room.maxGuests} khách'),
                    const SizedBox(width: 16),
                    _buildRoomDetail(Icons.crop_free, '${room.size}m²'),
                    const SizedBox(width: 16),
                    _buildRoomDetail(Icons.bed, '${room.beds} giường'),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Amenities
                if (room.amenities.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: room.amenities.take(3).map((amenity) {
                      return Chip(
                        label: Text(
                          amenity,
                          style: const TextStyle(fontSize: 12),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Availability info
                if (room.availability != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        room.availability!.available
                            ? (room.availability!.availableRooms != null
                                ? 'Còn ${room.availability!.availableRooms} phòng'
                                : 'Còn phòng')
                            : 'Hết phòng',
                        style: TextStyle(
                          color: room.availability!.available ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (room.availability!.available && (room.availability!.availableRooms ?? 0) <= 3)
                        Text(
                          'Sắp hết!',
                          style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Book Button
                SizedBox(
                  width: double.infinity,
                  child: Builder(builder: (context) {
                    final capacityOk = (_adults + _children) <= room.maxGuests;
                    final availOk = room.availability == null
                        ? true
                        : (room.availability!.available && (room.availability!.availableRooms ?? 0) > 0);
                    final canBook = capacityOk && availOk;
                    return ElevatedButton(
                      onPressed: canBook ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingScreen(
                            hotel: widget.hotel,
                            room: room,
                            checkIn: _checkIn,
                            checkOut: _checkOut,
                            adults: _adults,
                            children: _children,
                          ),
                        ),
                      );
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canBook
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        canBook
                            ? 'Đặt phòng'
                            : (!capacityOk
                                ? 'Quá sức chứa (tối đa ${room.maxGuests} khách)'
                                : 'Hết phòng'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomDetail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )} đ';
  }

  Future<void> _updateRoomSearch() async {
    setState(() => _loadingRooms = true);
    try {
      final totalGuests = _adults + _children;
      final rooms = await _apiService.getHotelRoomsWithAvailability(
        widget.hotel.id,
        checkIn: _checkIn,
        checkOut: _checkOut,
        guests: totalGuests,
      );
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được danh sách phòng: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _loadingRooms = false);
    }
  }

  void _selectCheckInDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkIn,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _checkIn) {
      setState(() {
        _checkIn = picked;
        if (_checkOut.isBefore(_checkIn.add(const Duration(days: 1)))) {
          _checkOut = _checkIn.add(const Duration(days: 1));
        }
        _updateRoomSearch();
      });
    }
  }

  void _selectCheckOutDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkOut,
      firstDate: _checkIn.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _checkOut) {
      setState(() {
        _checkOut = picked;
        _updateRoomSearch();
      });
    }
  }
}
