class PaymentRequest {
  final String bookingId;
  final String? bankCode;
  final String language;

  PaymentRequest({
    required this.bookingId,
    this.bankCode,
    this.language = 'vn',
  });

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      if (bankCode != null) 'bankCode': bankCode,
      'language': language,
    };
  }
}

class PaymentResponse {
  final bool success;
  final String? paymentUrl;
  final String? vnpTxnRef;
  final double? amount;
  final String? orderInfo;
  final DateTime? expireTime;
  final String? message;

  PaymentResponse({
    required this.success,
    this.paymentUrl,
    this.vnpTxnRef,
    this.amount,
    this.orderInfo,
    this.expireTime,
    this.message,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      success: json['success'] ?? false,
      paymentUrl: json['data']?['paymentUrl'],
      vnpTxnRef: json['data']?['vnp_TxnRef'],
      amount: json['data']?['amount']?.toDouble(),
      orderInfo: json['data']?['orderInfo'],
      expireTime: json['data']?['expireTime'] != null 
          ? DateTime.parse(json['data']['expireTime']) 
          : null,
      message: json['message'],
    );
  }
}

class PaymentStatus {
  final String bookingId;
  final String bookingNumber;
  final String paymentStatus;
  final String status;
  final double totalAmount;
  final DateTime? paidAt;
  final String paymentMethod;
  final bool isExpired;

  PaymentStatus({
    required this.bookingId,
    required this.bookingNumber,
    required this.paymentStatus,
    required this.status,
    required this.totalAmount,
    this.paidAt,
    required this.paymentMethod,
    required this.isExpired,
  });

  factory PaymentStatus.fromJson(Map<String, dynamic> json) {
    return PaymentStatus(
      bookingId: json['bookingId'],
      bookingNumber: json['bookingNumber'],
      paymentStatus: json['paymentStatus'],
      status: json['status'],
      totalAmount: json['totalAmount'].toDouble(),
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      paymentMethod: json['paymentMethod'],
      isExpired: json['isExpired'] ?? false,
    );
  }
}

class Bank {
  final String code;
  final String name;

  Bank({
    required this.code,
    required this.name,
  });

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      code: json['code'],
      name: json['name'],
    );
  }
}

class PaymentResult {
  final String status; // 'success', 'failed', 'invalid'
  final String? txnRef;
  final String? responseCode;
  final String? error;

  PaymentResult({
    required this.status,
    this.txnRef,
    this.responseCode,
    this.error,
  });

  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed';
  bool get isInvalid => status == 'invalid';
}
