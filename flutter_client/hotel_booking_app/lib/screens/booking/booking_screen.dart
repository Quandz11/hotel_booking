import 'package:flutter/material.dart';
import 'package:hotel_booking_app/screens/booking/payment_screen.dart';
import 'package:provider/provider.dart';
import '../../models/hotel.dart';
import '../../models/room.dart';
import '../../models/booking.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../utils/date_utils.dart';
import '../booking/payment_screen.dart';
import '../../l10n/app_localizations.dart';

class BookingScreen extends StatefulWidget {
  final Hotel hotel;
  final Room room;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int? adults;
  final int? children;

  const BookingScreen({
    super.key,
    required this.hotel,
    required this.room,
    this.checkIn,
    this.checkOut,
    this.adults,
    this.children,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specialRequestsController = TextEditingController();

  bool _isLoading = false;
  String _selectedPaymentMethod = 'vnpay';

  // Date handling - add mutable state variables
  late DateTime _checkInDate;
  late DateTime _checkOutDate;
  late int _adultsCount;
  late int _childrenCount;

  // Date handling
  DateTime get checkInDate => _checkInDate;
  DateTime get checkOutDate => _checkOutDate;
  int get adultsCount => _adultsCount;
  int get childrenCount => _childrenCount;

  int get _nights {
    return checkOutDate.difference(checkInDate).inDays;
  }

  double get _roomPrice {
    return widget.room.pricePerNight * _nights;
  }

  double get _taxAmount {
    return _roomPrice * 0.1; // 10% tax
  }

  double get _totalAmount {
    return _roomPrice + _taxAmount;
  }

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    
    // Initialize date and guest variables
    _checkInDate = widget.checkIn ?? DateTime.now().add(const Duration(days: 1));
    _checkOutDate = widget.checkOut ?? DateTime.now().add(const Duration(days: 2));
    _adultsCount = widget.adults ?? 1;
    _childrenCount = widget.children ?? 0;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  void _loadUserInfo() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
    }
  }

  Future<void> _selectCheckInDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _checkInDate) {
      setState(() {
        _checkInDate = picked;
        if (_checkOutDate.isBefore(_checkInDate.add(const Duration(days: 1)))) {
          _checkOutDate = _checkInDate.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _selectCheckOutDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkOutDate,
      firstDate: _checkInDate.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _checkOutDate) {
      setState(() {
        _checkOutDate = picked;
      });
    }
  }

  void _updateGuestCount(String type, int change) {
    setState(() {
      if (type == 'adults') {
        _adultsCount = (_adultsCount + change).clamp(1, 10);
      } else if (type == 'children') {
        _childrenCount = (_childrenCount + change).clamp(0, 10);
      }
    });
  }

  Future<void> _createBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final bookingData = {
        'room': widget.room.id,
        'checkIn': checkInDate.toIso8601String(),
        'checkOut': checkOutDate.toIso8601String(),
        'guests': {
          'adults': adultsCount,
          'children': childrenCount,
        },
        'guestInfo': {
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'specialRequests': _specialRequestsController.text.trim(),
        },
        'paymentMethod': _selectedPaymentMethod,
      };

      print('🎯 Creating booking with data: $bookingData');

      final response = await _apiService.createBooking(bookingData);

      if (response['success'] == true) {
        final booking = Booking.fromJson(response['data']);
        
        if (mounted) {
          // Navigate to payment screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentScreen(
                booking: booking,
                paymentMethod: _selectedPaymentMethod,
              ),
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to create booking');
      }
    } catch (e) {
      print('❌ Error creating booking: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        
        String errorMessage = l10n.createBookingFailed;
        
        // Extract meaningful error message from DioException
        if (e.toString().contains('DioException')) {
          if (e.toString().contains('Room is not available')) {
            errorMessage = 'Room is not available for the selected dates or guest count';
          } else if (e.toString().contains('Exceeds maximum guest capacity')) {
            errorMessage = 'Number of guests exceeds room capacity. Please select a larger room or reduce guest count.';
          } else {
            errorMessage = 'Failed to create booking. Please try again.';
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.booking),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hotel and Room Info
              _buildHotelInfoCard(),
              const SizedBox(height: 16),

              // Booking Details
              _buildBookingDetailsCard(),
              const SizedBox(height: 16),

              // Guest Information
              _buildGuestInfoCard(),
              const SizedBox(height: 16),

              // Payment Method
              _buildPaymentMethodCard(),
              const SizedBox(height: 16),

              // Price Summary
              _buildPriceSummaryCard(),
              const SizedBox(height: 24),

              // Book Now Button
              _buildBookNowButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHotelInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.hotel.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${widget.hotel.address.street}, ${widget.hotel.address.city}, ${widget.hotel.address.country}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.hotel, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.room.name} - ${widget.room.type}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingDetailsCard() {
    final l10n = AppLocalizations.of(context)!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.bookingDetails,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildEditableDateRow(l10n.checkIn, AppDateUtils.formatDate(checkInDate), () => _selectCheckInDate()),
            _buildEditableDateRow(l10n.checkOut, AppDateUtils.formatDate(checkOutDate), () => _selectCheckOutDate()),
            _buildDetailRow(l10n.nights, '$_nights ${l10n.nights}'),
            _buildEditableGuestRow(l10n.adults, _adultsCount, 'adults'),
            if (_childrenCount > 0) _buildEditableGuestRow(l10n.children, _childrenCount, 'children'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildEditableDateRow(String label, String value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(width: 4),
                  const Icon(Icons.calendar_today, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableGuestRow(String label, int count, String type) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: (type == 'adults' && count > 1) || (type == 'children' && count > 0) 
                    ? () => _updateGuestCount(type, -1) 
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                iconSize: 20,
              ),
              Text('$count', style: const TextStyle(fontWeight: FontWeight.w500)),
              IconButton(
                onPressed: (count + (type == 'adults' ? _childrenCount : _adultsCount)) < widget.room.maxGuests 
                    ? () => _updateGuestCount(type, 1) 
                    : null,
                icon: const Icon(Icons.add_circle_outline),
                iconSize: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuestInfoCard() {
    final l10n = AppLocalizations.of(context)!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.guestInformation,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: '${l10n.lastName} *',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.pleaseEnterFirstName;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: '${l10n.firstName} *',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.pleaseEnterLastName;
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: '${l10n.emailAddress} *',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.pleaseEnterEmail;
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return l10n.invalidEmailFormat;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: '${l10n.phoneNumber} *',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.pleaseEnterPhoneNumber;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _specialRequestsController,
              decoration: InputDecoration(
                labelText: l10n.specialRequestsHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    final l10n = AppLocalizations.of(context)!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.paymentMethod,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            RadioListTile<String>(
              title: Row(
                children: [
                  Image.asset(
                    'assets/images/vnpay_logo.png',
                    width: 40,
                    height: 20,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.payment, color: Colors.blue);
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(l10n.vnpay),
                ],
              ),
              subtitle: const Text('Thanh toán qua VNPay (ATM, QR, Ví điện tử)'),
              value: 'vnpay',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
            ), 
            // RadioListTile<String>(
            //   title: Row(
            //     children: [
            //       const Icon(Icons.credit_card, color: Colors.purple),
            //       const SizedBox(width: 8),
            //       Text(l10n.stripe),
            //     ],
            //   ),
            //   subtitle: const Text('Thanh toán qua thẻ tín dụng quốc tế'),
            //   value: 'stripe',
            //   groupValue: _selectedPaymentMethod,
            //   onChanged: (value) {
            //     setState(() {
            //       _selectedPaymentMethod = value!;
            //     });
            //   },
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummaryCard() {
    final l10n = AppLocalizations.of(context)!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.paymentSummary,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildPriceRow('${widget.room.name} x $_nights ${l10n.nights}', _roomPrice),
            _buildPriceRow(l10n.taxesAndFees, _taxAmount),
            const Divider(),
            _buildPriceRow(
              l10n.total,
              _totalAmount,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} đ',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Theme.of(context).primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookNowButton() {
    final l10n = AppLocalizations.of(context)!;
    
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                l10n.bookNow,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
