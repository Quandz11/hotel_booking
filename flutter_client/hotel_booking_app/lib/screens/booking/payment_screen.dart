import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../models/booking.dart';
import '../../models/payment.dart';
import '../../services/payment_service.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import 'payment_result_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Booking booking;
  final String paymentMethod;
  final bool isRetry;

  const PaymentScreen({
    super.key,
    required this.booking,
    required this.paymentMethod,
    this.isRetry = false,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  
  bool _isLoading = false;
  String? _selectedBankCode;
  List<Bank> _banks = [];
  bool _isLoadingBanks = false;

  @override
  void initState() {
    super.initState();
    _initializePaymentService();
    
    // Bank selection removed for VNPay; skip loading banks
    // if (widget.paymentMethod == 'vnpay') {
    //   _loadBanks();
    // }
  }
  
  Future<void> _initializePaymentService() async {
    await _paymentService.initialize();
  }

  Future<void> _loadBanks() async {
    setState(() {
      _isLoadingBanks = true;
    });

    try {
      final banks = await _paymentService.getAvailableBanks();
      setState(() {
        _banks = banks;
      });
    } catch (e) {
      print('Error loading banks: $e');
    } finally {
      setState(() {
        _isLoadingBanks = false;
      });
    }
  }

  Future<void> _proceedToPayment() async {
    final l10n = AppLocalizations.of(context)!;
    
    // Only VNPay is supported; proceed without checking other methods

    setState(() {
      _isLoading = true;
    });

    try {
      final paymentRequest = PaymentRequest(
        bookingId: widget.booking.id,
        bankCode: null,
        language: 'vn',
      );

      final response = await _paymentService.createVNPayPayment(paymentRequest);

      if (response.success && response.paymentUrl != null) {
        // Navigate to WebView for payment
        _openPaymentWebView(response.paymentUrl!);
      } else {
        throw Exception(response.message ?? 'Failed to create payment');
      }
    } catch (e) {
      print('Error creating payment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: $e'),
            backgroundColor: Colors.red,
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

  void _openPaymentWebView(String paymentUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentWebViewScreen(
          paymentUrl: paymentUrl,
          booking: widget.booking,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isRetry ? 'Tiếp tục thanh toán' : l10n.payment),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Retry payment info
            if (widget.isRetry) ...[
              _buildRetryPaymentInfo(),
              const SizedBox(height: 16),
            ],

            // Booking Summary
            _buildBookingSummaryCard(),
            const SizedBox(height: 16),

            // Payment Method Info
            _buildPaymentMethodCard(),
            const SizedBox(height: 16),

            // Bank Selection removed for VNPay

            // Payment Instructions
            _buildPaymentInstructionsCard(),
            const SizedBox(height: 24),

            // Payment Button
            _buildPaymentButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildRetryPaymentInfo() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.orange.shade700,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tiếp tục thanh toán',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bạn đang thực hiện lại thanh toán cho đặt phòng ${widget.booking.bookingNumber}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade600,
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

  Widget _buildBookingSummaryCard() {
    final l10n = AppLocalizations.of(context)!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.bookingInformation,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text('${l10n.bookingNumber}: ${widget.booking.bookingNumber}'),
            const SizedBox(height: 4),
            Text('${l10n.hotelName}: ${widget.booking.hotelName}'),
            const SizedBox(height: 4),
            Text('${l10n.roomName}: ${widget.booking.roomName}'),
            const SizedBox(height: 4),
            Text('${l10n.checkIn}: ${_formatDate(widget.booking.checkIn)}'),
            const SizedBox(height: 4),
            Text('${l10n.checkOut}: ${_formatDate(widget.booking.checkOut)}'),
            const SizedBox(height: 4),
            Text('${l10n.nights}: ${widget.booking.nights}'),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l10n.totalAmount}:',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _paymentService.formatCurrency(widget.booking.totalAmount),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
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
            Row(
              children: [
                if (widget.paymentMethod == 'vnpay')
                  Image.asset(
                    'assets/images/vnpay_logo.png',
                    width: 40,
                    height: 20,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.payment, color: Colors.blue);
                    },
                  )
                else
                  const Icon(Icons.credit_card, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  _paymentService.getPaymentMethodName(widget.paymentMethod),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankSelectionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn ngân hàng (tùy chọn)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bỏ qua để chọn phương thức thanh toán tại VNPay',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoadingBanks)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                width: double.infinity,
                child: DropdownButtonFormField<String>(
                  value: _selectedBankCode,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Chọn ngân hàng',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text(
                        'Chọn tại VNPay',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ..._banks.map((bank) => DropdownMenuItem<String>(
                      value: bank.code,
                      child: Text(
                        bank.name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedBankCode = value;
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInstructionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hướng dẫn thanh toán',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.paymentMethod == 'vnpay') ...[
              const Text('1. Bấm "Thanh toán ngay" để chuyển đến trang VNPay'),
              const Text('2. Chọn phương thức thanh toán (ATM, QR, Ví điện tử)'),
              const Text('3. Nhập thông tin thanh toán theo hướng dẫn'),
              const Text('4. Xác nhận OTP để hoàn tất thanh toán'),
            ] else ...[
              const Text('1. Bấm "Thanh toán ngay" để chuyển đến trang Stripe'),
              const Text('2. Nhập thông tin thẻ tín dụng'),
              const Text('3. Xác nhận thanh toán'),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer, size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Thời gian thanh toán: 30 phút',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
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

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _proceedToPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Thanh toán ngay',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// WebView Screen for Payment Processing
class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final Booking booking;

  const PaymentWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.booking,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('Page started loading: $url');
            _checkForPaymentResult(url);
          },
          onPageFinished: (String url) {
            print('Page finished loading: $url');
            setState(() {
              _isLoading = false;
            });
            _checkForPaymentResult(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            print('Navigation request: ${request.url}');
            _checkForPaymentResult(request.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _checkForPaymentResult(String url) {
    // Check if this is VNPay return URL or contains payment result parameters
    if (url.contains('vnp_ResponseCode') && url.contains('vnp_TxnRef')) {
      final uri = Uri.parse(url);
      final params = uri.queryParameters;
      
      // Parse VNPay response directly from URL parameters
      final responseCode = params['vnp_ResponseCode'];
      final transactionStatus = params['vnp_TransactionStatus'];
      final txnRef = params['vnp_TxnRef'];
      
      final result = PaymentResult(
        status: responseCode == '00' && transactionStatus == '00' ? 'success' : 'failed',
        txnRef: txnRef,
        responseCode: responseCode,
        error: responseCode != '00' ? _getVNPayMessage(responseCode) : null,
      );
      
      // Navigate to result screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentResultScreen(
            result: result,
            booking: widget.booking,
          ),
        ),
      );
    }
  }
  
  String _getVNPayMessage(String? responseCode) {
    switch (responseCode) {
      case '00':
        return 'Giao dịch thành công';
      case '07':
        return 'Trừ tiền thành công. Giao dịch bị nghi ngờ (liên quan tới lừa đảo, giao dịch bất thường).';
      case '09':
        return 'Giao dịch không thành công do: Thẻ/Tài khoản của khách hàng chưa đăng ký dịch vụ InternetBanking tại ngân hàng.';
      case '10':
        return 'Giao dịch không thành công do: Khách hàng xác thực thông tin thẻ/tài khoản không đúng quá 3 lần';
      case '11':
        return 'Giao dịch không thành công do: Đã hết hạn chờ thanh toán. Xin quý khách vui lòng thực hiện lại giao dịch.';
      case '12':
        return 'Giao dịch không thành công do: Thẻ/Tài khoản của khách hàng bị khóa.';
      case '13':
        return 'Giao dịch không thành công do Quý khách nhập sai mật khẩu xác thực giao dịch (OTP).';
      case '24':
        return 'Giao dịch không thành công do: Khách hàng hủy giao dịch';
      case '51':
        return 'Giao dịch không thành công do: Tài khoản của quý khách không đủ số dư để thực hiện giao dịch.';
      case '65':
        return 'Giao dịch không thành công do: Tài khoản của Quý khách đã vượt quá hạn mức giao dịch trong ngày.';
      case '75':
        return 'Ngân hàng thanh toán đang bảo trì.';
      case '79':
        return 'Giao dịch không thành công do: KH nhập sai mật khẩu thanh toán quá số lần quy định.';
      default:
        return 'Giao dịch thất bại';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán VNPay'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _controller.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
