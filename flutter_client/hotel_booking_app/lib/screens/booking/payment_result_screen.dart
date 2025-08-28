import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../models/payment.dart';
import '../../services/payment_service.dart';
import '../main/main_screen.dart';

class PaymentResultScreen extends StatefulWidget {
  final PaymentResult result;
  final Booking booking;

  const PaymentResultScreen({
    super.key,
    required this.result,
    required this.booking,
  });

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  final PaymentService _paymentService = PaymentService();
  PaymentStatus? _paymentStatus;
  bool _isLoadingStatus = true;

  @override
  void initState() {
    super.initState();
    _verifyPaymentAndLoadStatus();
  }

  Future<void> _verifyPaymentAndLoadStatus() async {
    try {
      // If payment was successful, verify it first
      if (widget.result.isSuccess && widget.result.txnRef != null) {
        await _paymentService.verifyVNPayPayment(
          bookingId: widget.booking.id,
          vnpTxnRef: widget.result.txnRef!,
          vnpResponseCode: widget.result.responseCode ?? '00',
          vnpTransactionStatus: '00',
        );
      }
      
      // Then load payment status
      final status = await _paymentService.getPaymentStatus(widget.booking.id);
      setState(() {
        _paymentStatus = status;
        _isLoadingStatus = false;
      });
    } catch (e) {
      print('Error verifying payment and loading status: $e');
      setState(() {
        _isLoadingStatus = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      appBar: AppBar(
        title: const Text('Kết quả thanh toán'),
        backgroundColor: _getBackgroundColor(),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _isLoadingStatus
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  
                  // Status Icon
                  _buildStatusIcon(),
                  const SizedBox(height: 24),
                  
                  // Status Title
                  _buildStatusTitle(),
                  const SizedBox(height: 8),
                  
                  // Status Message
                  _buildStatusMessage(),
                  const SizedBox(height: 32),
                  
                  // Payment Details Card
                  _buildPaymentDetailsCard(),
                  const SizedBox(height: 16),
                  
                  // Booking Details Card
                  _buildBookingDetailsCard(),
                  const SizedBox(height: 32),
                  
                  // Action Buttons
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Color _getBackgroundColor() {
    if (widget.result.isSuccess) {
      return Colors.green.shade600;
    } else if (widget.result.isFailed) {
      return Colors.red.shade600;
    } else {
      return Colors.orange.shade600;
    }
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color iconColor;
    
    if (widget.result.isSuccess) {
      icon = Icons.check_circle;
      iconColor = Colors.green.shade100;
    } else if (widget.result.isFailed) {
      icon = Icons.error;
      iconColor = Colors.red.shade100;
    } else {
      icon = Icons.warning;
      iconColor = Colors.orange.shade100;
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: iconColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 60,
        color: _getBackgroundColor(),
      ),
    );
  }

  Widget _buildStatusTitle() {
    String title;
    
    if (widget.result.isSuccess) {
      title = 'Thanh toán thành công!';
    } else if (widget.result.isFailed) {
      title = 'Thanh toán thất bại';
    } else {
      title = 'Thanh toán không hợp lệ';
    }

    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStatusMessage() {
    String message;
    
    if (widget.result.isSuccess) {
      message = 'Đặt phòng của bạn đã được xác nhận.\nChúng tôi đã gửi email xác nhận đến bạn.';
    } else if (widget.result.isFailed) {
      message = 'Giao dịch thanh toán không thành công.\nVui lòng thử lại hoặc chọn phương thức thanh toán khác.';
    } else {
      message = 'Có lỗi xảy ra trong quá trình thanh toán.\nVui lòng liên hệ hỗ trợ khách hàng.';
    }

    return Text(
      message,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.white,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPaymentDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chi tiết thanh toán',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Mã giao dịch', widget.result.txnRef ?? 'N/A'),
            _buildDetailRow('Trạng thái', _getPaymentStatusText()),
            if (widget.result.responseCode != null)
              _buildDetailRow('Mã phản hồi', widget.result.responseCode!),
            if (_paymentStatus != null) ...[
              _buildDetailRow('Phương thức', _paymentService.getPaymentMethodName(_paymentStatus!.paymentMethod)),
              _buildDetailRow('Số tiền', _paymentService.formatCurrency(_paymentStatus!.totalAmount)),
              if (_paymentStatus!.paidAt != null)
                _buildDetailRow('Thời gian thanh toán', _formatDateTime(_paymentStatus!.paidAt!)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBookingDetailsCard() {
    // Use payment status data if available, otherwise fallback to original booking
    final bookingNumber = _paymentStatus?.bookingNumber ?? widget.booking.bookingNumber;
    final hotelName = widget.booking.hotelName; // This should come from original booking
    final roomName = widget.booking.roomName; // This should come from original booking
    final checkIn = widget.booking.checkIn;
    final checkOut = widget.booking.checkOut;
    final nights = checkOut.difference(checkIn).inDays;
    final adults = widget.booking.adults;
    final children = widget.booking.children;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin đặt phòng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Mã đặt phòng', bookingNumber),
            _buildDetailRow('Khách sạn', hotelName),
            _buildDetailRow('Phòng', roomName),
            _buildDetailRow('Check-in', _formatDate(checkIn)),
            _buildDetailRow('Check-out', _formatDate(checkOut)),
            _buildDetailRow('Số đêm', '$nights đêm'),
            _buildDetailRow('Khách', '$adults người lớn${children > 0 ? ', $children trẻ em' : ''}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
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

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MainScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _getBackgroundColor(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Về trang chủ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        if (widget.result.isSuccess) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                // Navigate to booking details or my bookings
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MainScreen(initialIndex: 2)), // Assuming 2 is bookings tab
                  (route) => false,
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Xem đặt phòng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
        
        if (widget.result.isFailed) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context); // Go back to payment screen
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Thử lại',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _getPaymentStatusText() {
    if (widget.result.isSuccess) {
      return 'Thành công';
    } else if (widget.result.isFailed) {
      return 'Thất bại';
    } else {
      return 'Không hợp lệ';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
