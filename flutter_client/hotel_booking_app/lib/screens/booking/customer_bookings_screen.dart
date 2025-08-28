import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/booking.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../services/payment_service.dart';
import '../../l10n/app_localizations.dart';

class CustomerBookingsScreen extends StatefulWidget {
  const CustomerBookingsScreen({super.key});

  @override
  State<CustomerBookingsScreen> createState() => _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends State<CustomerBookingsScreen> {
  final ApiService _apiService = ApiService();
  final PaymentService _paymentService = PaymentService();
  
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getCustomerBookings();
      final bookings = response.map((data) => Booking.fromJson(data)).toList();
      
      setState(() {
        _bookings = bookings;
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
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myBookingsTitle),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!Provider.of<AuthProvider>(context).isAuthenticated) {
      return _buildNotLoggedIn();
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildError();
    }

    if (_bookings.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _bookings.length,
        itemBuilder: (context, index) {
          final booking = _bookings[index];
          return _buildBookingCard(booking);
        },
      ),
    );
  }

  Widget _buildNotLoggedIn() {
    final l10n = AppLocalizations.of(context)!;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.login,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.pleaseLoginToViewBookings,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Navigate to login
              Navigator.pushNamed(context, '/login');
            },
            child: Text(l10n.loginToView),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    final l10n = AppLocalizations.of(context)!;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            '${l10n.error}: $_error',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
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

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.hotel_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noBookingsYet,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Navigate to hotels
              Navigator.pushNamed(context, '/');
            },
            child: Text(l10n.exploreHotels),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final l10n = AppLocalizations.of(context)!;
    final paymentStatusInfo = _paymentService.getPaymentStatusInfo(booking.paymentStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showBookingDetails(booking),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with booking number and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking.bookingNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(booking.status),
                ],
              ),
              const SizedBox(height: 12),

              // Hotel and room info
              Text(
                booking.hotelName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                booking.roomName,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),

              // Dates and guests
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.calendar_today,
                      l10n.checkIn,
                      _formatDate(booking.checkIn),
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.calendar_today,
                      l10n.checkOut,
                      _formatDate(booking.checkOut),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.hotel,
                      l10n.nights,
                      l10n.formatDuration(booking.nights),
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.people,
                      l10n.guests,
                      _getGuestDescription(booking),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Payment info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        paymentStatusInfo['icon'],
                        size: 16,
                        color: paymentStatusInfo['color'],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        paymentStatusInfo['name'],
                        style: TextStyle(
                          fontSize: 12,
                          color: paymentStatusInfo['color'],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _paymentService.formatCurrency(booking.totalAmount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),

              // Actions for pending payments
              if (booking.paymentStatus == 'pending') ...[
                const SizedBox(height: 12),
                if (!_paymentService.isPaymentExpired(booking.createdAt)) 
                  // Payment not expired - show continue payment button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _continuePayment(booking),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(l10n.continuePayment),
                    ),
                  )
                else
                  // Payment expired - show expired message
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.red.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            l10n.paymentExpired,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.red.shade700,
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
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final l10n = AppLocalizations.of(context)!;
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'confirmed':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        label = l10n.statusConfirmed;
        break;
      case 'pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        label = l10n.statusPending;
        break;
      case 'cancelled':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        label = l10n.statusCancelled;
        break;
      case 'checked_in':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        label = l10n.statusCheckedIn;
        break;
      case 'checked_out':
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        label = l10n.statusCheckedOut;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showBookingDetails(Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildBookingDetailsSheet(booking),
    );
  }

  Widget _buildBookingDetailsSheet(Booking booking) {
    final l10n = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.bookingDetailsTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Booking info
                      _buildDetailSection(l10n.bookingInfo, [
                        _buildDetailRow(l10n.bookingId, booking.bookingNumber),
                        _buildDetailRow(l10n.hotel, booking.hotelName),
                        _buildDetailRow(l10n.room, booking.roomName),
                        _buildDetailRow(l10n.bookingStatus, _getStatusText(booking.status)),
                      ]),

                      const SizedBox(height: 16),

                      // Date info
                      _buildDetailSection(l10n.timeInfo, [
                        _buildDetailRow(l10n.checkInDate, _formatDate(booking.checkIn)),
                        _buildDetailRow(l10n.checkOutDate, _formatDate(booking.checkOut)),
                        _buildDetailRow(l10n.nightsCount, '${booking.nights} ${l10n.nights}'),
                        _buildDetailRow(l10n.bookedAt, _formatDateTime(booking.createdAt)),
                      ]),

                      const SizedBox(height: 16),

                      // Guest info
                      _buildDetailSection(l10n.guestInfo, [
                        _buildDetailRow(l10n.adultsCount, '${booking.adults}'),
                        _buildDetailRow(l10n.childrenCount, '${booking.children}'),
                        _buildDetailRow(l10n.guestName, booking.customerName),
                        _buildDetailRow(l10n.guestEmail, booking.customerEmail),
                      ]),

                      const SizedBox(height: 16),

                      // Payment info
                      _buildDetailSection(l10n.paymentInfo, [
                        _buildDetailRow(l10n.paymentStatusLabel, _paymentService.getPaymentStatusInfo(booking.paymentStatus)['name']),
                        _buildDetailRow(l10n.paymentMethodLabel, _paymentService.getPaymentMethodName(booking.paymentMethod)),
                        _buildDetailRow(l10n.totalAmountLabel, _paymentService.formatCurrency(booking.totalAmount)),
                      ]),

                      const SizedBox(height: 24),

                      // Action buttons
                      _buildActionButtons(booking),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(Booking booking) {
    final l10n = AppLocalizations.of(context)!;
    List<Widget> buttons = [];

    // Continue payment button for unpaid bookings (not expired)
    if (booking.paymentStatus == 'pending' && booking.status != 'cancelled') {
      if (!_paymentService.isPaymentExpired(booking.createdAt)) {
        // Payment not expired - show continue payment button
        buttons.add(
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _continuePayment(booking),
              icon: const Icon(Icons.payment),
              label: Text(l10n.continuePayment),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        );
        buttons.add(const SizedBox(height: 8));
      } else {
        // Payment expired - show expired message
        buttons.add(
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: Colors.red.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.paymentExpired,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                      Text(
                        l10n.paymentExpiredMessage,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        buttons.add(const SizedBox(height: 8));
      }
    }

    // Cancel button for cancellable bookings
    if (_canCancelBooking(booking)) {
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showCancelConfirmation(booking),
            icon: const Icon(Icons.cancel),
            label: Text(l10n.cancelBooking),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      );
    }

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.actions,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...buttons,
      ],
    );
  }

  bool _canCancelBooking(Booking booking) {
    // Can cancel if not already cancelled, checked in, or checked out
    return booking.status != 'cancelled' && 
           booking.status != 'checked_in' && 
           booking.status != 'checked_out' &&
           booking.checkIn.isAfter(DateTime.now()); // Can't cancel past bookings
  }

  void _showCancelConfirmation(Booking booking) {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmCancelBooking),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l10n.cancelBookingMessage} ${booking.bookingNumber}?'),
            const SizedBox(height: 16),
            Text(
              l10n.cancelBookingNote,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.no),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelBooking(booking);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.cancelBooking),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking(Booking booking) async {
    final l10n = AppLocalizations.of(context)!;
    
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await _apiService.cancelBooking(booking.id);
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Close booking detail sheet
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.bookingCancelledSuccess),
          backgroundColor: Colors.green,
        ),
      );

      // Reload bookings
      _loadBookings();
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.errorCancellingBooking}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _continuePayment(Booking booking) {
    final l10n = AppLocalizations.of(context)!;
    
    // Check if payment is expired
    if (_paymentService.isPaymentExpired(booking.createdAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.paymentExpiredMessage),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Close the booking detail sheet if it's open
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    
    // Navigate to payment screen
    Navigator.pushNamed(
      context, 
      '/payment',
      arguments: {
        'booking': booking,
        'paymentMethod': booking.paymentMethod,
        'isRetry': true,
      },
    );
  }

  String _getGuestDescription(Booking booking) {
    final l10n = AppLocalizations.of(context)!;
    String description = '${booking.adults} ${l10n.adults}';
    if (booking.children > 0) {
      description += ', ${booking.children} ${l10n.children}';
    }
    return description;
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status.toLowerCase()) {
      case 'confirmed':
        return l10n.statusConfirmed;
      case 'pending':
        return l10n.statusPending;
      case 'cancelled':
        return l10n.statusCancelled;
      case 'checked_in':
        return l10n.statusCheckedIn;
      case 'checked_out':
        return l10n.statusCheckedOut;
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
