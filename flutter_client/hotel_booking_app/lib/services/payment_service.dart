import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/payment.dart';
import '../config/api_config.dart';
import '../config/app_constants.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  late Dio _dio;

  Future<void> initialize() async {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    // Load auth token from storage
    await _loadAuthToken();
  }
  
  Future<void> _loadAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyAccessToken);
      if (token != null) {
        _dio.options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      // Ignore errors, payment service can work without auth for some endpoints
    }
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Create VNPay payment URL
  Future<PaymentResponse> createVNPayPayment(PaymentRequest request) async {
    try {
      print('🚀 Creating VNPay payment for booking: ${request.bookingId}');
      
      final response = await _dio.post(
        '/payments/vnpay/create',
        data: request.toJson(),
      );

      print('✅ VNPay payment created successfully');
      return PaymentResponse.fromJson(response.data);
    } on DioException catch (e) {
      print('❌ Error creating VNPay payment: ${e.response?.data}');
      
      String errorMessage = 'Failed to create payment';
      if (e.response?.data != null && e.response!.data['message'] != null) {
        errorMessage = e.response!.data['message'];
      }
      
      return PaymentResponse(
        success: false,
        message: errorMessage,
      );
    } catch (e) {
      print('❌ Unexpected error creating VNPay payment: $e');
      return PaymentResponse(
        success: false,
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Get payment status for a booking
  Future<PaymentStatus?> getPaymentStatus(String bookingId) async {
    try {
      print('🔍 Getting payment status for booking: $bookingId');
      
      final response = await _dio.get('/payments/status/$bookingId');

      if (response.data['success'] == true) {
        print('✅ Payment status retrieved successfully');
        return PaymentStatus.fromJson(response.data['data']);
      }
      
      return null;
    } on DioException catch (e) {
      print('❌ Error getting payment status: ${e.response?.data}');
      rethrow;
    } catch (e) {
      print('❌ Unexpected error getting payment status: $e');
      rethrow;
    }
  }

  /// Get list of available banks for VNPay
  Future<List<Bank>> getAvailableBanks() async {
    try {
      print('🏦 Getting available banks for VNPay');
      
      final response = await _dio.get('/payments/vnpay/banks');

      if (response.data['success'] == true) {
        final List<dynamic> banksData = response.data['data'];
        final banks = banksData.map((bank) => Bank.fromJson(bank)).toList();
        
        print('✅ Retrieved ${banks.length} banks');
        return banks;
      }
      
      return [];
    } on DioException catch (e) {
      print('❌ Error getting available banks: ${e.response?.data}');
      return [];
    } catch (e) {
      print('❌ Unexpected error getting available banks: $e');
      return [];
    }
  }

  /// Parse payment result from URL parameters
  PaymentResult parsePaymentResult(Map<String, String> params) {
    final status = params['status'] ?? 'unknown';
    final txnRef = params['txnRef'];
    final responseCode = params['responseCode'];
    final error = params['error'];

    return PaymentResult(
      status: status,
      txnRef: txnRef,
      responseCode: responseCode,
      error: error,
    );
  }

  /// Get payment method display name
  String getPaymentMethodName(String method) {
    switch (method.toLowerCase()) {
      case 'vnpay':
        return 'VNPay';
      case 'stripe':
        return 'Stripe';
      case 'cash':
        return 'Cash';
      default:
        return method;
    }
  }

  /// Get payment status display name and color
  Map<String, dynamic> getPaymentStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return {
          'name': 'Chờ thanh toán',
          'color': Colors.orange,
          'icon': Icons.pending,
        };
      case 'paid':
        return {
          'name': 'Đã thanh toán',
          'color': Colors.green,
          'icon': Icons.check_circle,
        };
      case 'failed':
        return {
          'name': 'Thanh toán thất bại',
          'color': Colors.red,
          'icon': Icons.error,
        };
      case 'refunded':
        return {
          'name': 'Đã hoàn tiền',
          'color': Colors.blue,
          'icon': Icons.money_off,
        };
      case 'partial_refund':
        return {
          'name': 'Hoàn tiền một phần',
          'color': Colors.blue,
          'icon': Icons.money_off_outlined,
        };
      default:
        return {
          'name': status,
          'color': Colors.grey,
          'icon': Icons.help,
        };
    }
  }

  /// Verify VNPay payment result and update booking status
  Future<Map<String, dynamic>> verifyVNPayPayment({
    required String bookingId,
    required String vnpTxnRef,
    required String vnpResponseCode,
    required String vnpTransactionStatus,
  }) async {
    try {
      print('🔍 Verifying VNPay payment for booking: $bookingId');
      
      final response = await _dio.post(
        '/payments/vnpay/verify',
        data: {
          'bookingId': bookingId,
          'vnp_TxnRef': vnpTxnRef,
          'vnp_ResponseCode': vnpResponseCode,
          'vnp_TransactionStatus': vnpTransactionStatus,
        },
      );

      print('✅ Payment verification successful');
      return response.data;
    } on DioException catch (e) {
      print('❌ Error verifying payment: ${e.response?.data}');
      
      String errorMessage = 'Failed to verify payment';
      if (e.response?.data != null && e.response!.data['message'] != null) {
        errorMessage = e.response!.data['message'];
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('❌ Unexpected error verifying payment: $e');
      return {
        'success': false,
        'message': 'Unexpected error occurred',
      };
    }
  }

  /// Format currency amount
  String formatCurrency(double amount, {String currency = 'VND'}) {
    if (currency == 'VND') {
      return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} đ';
    }
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  /// Check if payment is expired
  bool isPaymentExpired(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inMinutes > 30; // 30 minutes timeout
  }
}
