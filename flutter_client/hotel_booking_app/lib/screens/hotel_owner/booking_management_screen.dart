import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hotel_owner_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/booking.dart';

class BookingManagementScreen extends StatefulWidget {
  const BookingManagementScreen({super.key});

  @override
  State<BookingManagementScreen> createState() => _BookingManagementScreenState();
}

class _BookingManagementScreenState extends State<BookingManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedHotelId = '';
  String _selectedStatus = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    final provider = Provider.of<HotelOwnerProvider>(context, listen: false);
    await provider.loadAllBookings();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageBookings),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: l10n.all),
            Tab(text: l10n.pending),
            Tab(text: l10n.confirmed),
            Tab(text: 'Active'),
            Tab(text: l10n.completed),
          ],
        ),
      ),
      body: Consumer<HotelOwnerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    provider.error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadBookings,
                    child: Text(l10n.tryAgain),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Filter Section
              _buildFilterSection(provider),
              
              // Bookings List
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBookingsList(provider.allBookings),
                    _buildBookingsList(provider.pendingBookings),
                    _buildBookingsList(_getConfirmedBookings(provider.allBookings)),
                    _buildBookingsList(provider.activeBookings),
                    _buildBookingsList(_getCompletedBookings(provider.allBookings)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadBookings,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildFilterSection(HotelOwnerProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          Row(
            children: [
              // Hotel Filter
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _selectedHotelId.isEmpty ? null : _selectedHotelId,
                  decoration: InputDecoration(
                    labelText: l10n.selectHotel,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem<String>(
                      value: '',
                      child: Text(l10n.allHotels),
                    ),
                    ...provider.ownedHotels.map((hotel) => DropdownMenuItem<String>(
                      value: hotel.id,
                      child: Text(
                        hotel.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedHotelId = value ?? '';
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              
              // Status Filter
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus.isEmpty ? null : _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem<String>(
                      value: '',
                      child: Text(l10n.allStatuses),
                    ),
                    DropdownMenuItem<String>(
                      value: 'pending',
                      child: Text(l10n.pending),
                    ),
                    DropdownMenuItem<String>(
                      value: 'confirmed',
                      child: Text(l10n.confirmed),
                    ),
                    DropdownMenuItem<String>(
                      value: 'checked_in',
                      child: Text('Active'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'checked_out',
                      child: Text(l10n.completed),
                    ),
                    DropdownMenuItem<String>(
                      value: 'cancelled',
                      child: Text(l10n.cancelled),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value ?? '';
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList(List<Booking> bookings) {
    final l10n = AppLocalizations.of(context)!;
    
    // Apply filters
    List<Booking> filteredBookings = bookings;
    
    if (_selectedHotelId.isNotEmpty) {
      filteredBookings = filteredBookings
          .where((booking) => booking.hotelId == _selectedHotelId)
          .toList();
    }
    
    if (_selectedStatus.isNotEmpty) {
      filteredBookings = filteredBookings
          .where((booking) => booking.status == _selectedStatus)
          .toList();
    }

    if (filteredBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noBookingsFound,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredBookings.length,
        itemBuilder: (context, index) {
          final booking = filteredBookings[index];
          return _buildBookingCard(booking);
        },
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _showBookingDetails(booking),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.bookingNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking.customerName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: booking.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: booking.statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      booking.statusDisplayText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: booking.statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Room and Hotel Info
              Row(
                children: [
                  Icon(Icons.hotel, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${booking.hotelName} - ${booking.roomName}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Dates
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatDate(booking.checkIn)} - ${_formatDate(booking.checkOut)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${booking.nights} ${booking.nights == 1 ? 'night' : 'nights'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Guests and Amount
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${booking.adults} adults${booking.children > 0 ? ', ${booking.children} children' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatCurrency(booking.totalAmount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              
              if (booking.isPending || booking.status == 'confirmed') ...[
                const SizedBox(height: 12),
                const Divider(),
                
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (booking.isPending) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _confirmBooking(booking),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                            side: const BorderSide(color: Colors.green),
                          ),
                          child: const Text('Confirm'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _cancelBooking(booking),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ] else if (booking.status == 'confirmed') ...[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _checkInGuest(booking),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Check In'),
                        ),
                      ),
                    ],
                  ],
                ),
              ] else if (booking.isActive) ...[
                const SizedBox(height: 12),
                const Divider(),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _checkOutGuest(booking),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Check Out'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showBookingDetails(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => BookingDetailsDialog(booking: booking),
    );
  }

  Future<void> _confirmBooking(Booking booking) async {
    final provider = Provider.of<HotelOwnerProvider>(context, listen: false);
    final success = await provider.confirmBooking(booking.id);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking confirmed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${provider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelBooking(Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = Provider.of<HotelOwnerProvider>(context, listen: false);
      final success = await provider.cancelBooking(booking.id);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${provider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkInGuest(Booking booking) async {
    final provider = Provider.of<HotelOwnerProvider>(context, listen: false);
    final success = await provider.checkInGuest(booking.id);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Guest checked in successfully'),
          backgroundColor: Colors.blue,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${provider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _checkOutGuest(Booking booking) async {
    final provider = Provider.of<HotelOwnerProvider>(context, listen: false);
    final success = await provider.checkOutGuest(booking.id);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Guest checked out successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${provider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Booking> _getConfirmedBookings(List<Booking> bookings) {
    return bookings.where((booking) => booking.status == 'confirmed').toList();
  }

  List<Booking> _getCompletedBookings(List<Booking> bookings) {
    return bookings.where((booking) => booking.isCompleted).toList();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )} ₫';
  }
}

class BookingDetailsDialog extends StatelessWidget {
  final Booking booking;

  const BookingDetailsDialog({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Booking Details',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Booking Number', booking.bookingNumber),
                    _buildDetailRow('Status', booking.statusDisplayText),
                    _buildDetailRow('Customer', booking.customerName),
                    _buildDetailRow('Email', booking.customerEmail),
                    _buildDetailRow('Hotel', booking.hotelName),
                    _buildDetailRow('Room', booking.roomName),
                    _buildDetailRow('Check-in', _formatDate(booking.checkIn)),
                    _buildDetailRow('Check-out', _formatDate(booking.checkOut)),
                    _buildDetailRow('Nights', '${booking.nights}'),
                    _buildDetailRow('Guests', '${booking.adults} adults${booking.children > 0 ? ', ${booking.children} children' : ''}'),
                    _buildDetailRow('Total Amount', _formatCurrency(booking.totalAmount)),
                    _buildDetailRow('Payment Method', booking.paymentMethod),
                    _buildDetailRow('Payment Status', booking.paymentStatus),
                    _buildDetailRow('Created', _formatDateTime(booking.createdAt)),
                    
                    if (booking.checkedInAt != null)
                      _buildDetailRow('Checked In', _formatDateTime(booking.checkedInAt!)),
                    
                    if (booking.checkedOutAt != null)
                      _buildDetailRow('Checked Out', _formatDateTime(booking.checkedOutAt!)),
                    
                    if (booking.specialRequests != null && booking.specialRequests!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Special Requests',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          booking.specialRequests!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )} ₫';
  }
}
