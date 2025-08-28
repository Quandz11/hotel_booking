const express = require('express');
const crypto = require('crypto');
const { body } = require('express-validator');
const Booking = require('../models/Booking');
const { authenticate, authorize } = require('../middleware/auth');
const { validate, asyncHandler } = require('../middleware/validation');
const { sendBookingConfirmation } = require('../utils/email');

const router = express.Router();

// VNPay configuration
const vnpayConfig = {
  vnp_TmnCode: process.env.VNPAY_TMN_CODE,
  vnp_HashSecret: process.env.VNPAY_SECRET_KEY,
  vnp_Url: process.env.VNPAY_URL,
  vnp_ReturnUrl: process.env.VNPAY_RETURN_URL,
  vnp_IpnUrl: process.env.VNPAY_IPN_URL
};

// Helper function to sort object by keys
function sortObject(obj) {
  const sorted = {};
  const str = [];
  let key;
  for (key in obj) {
    if (obj.hasOwnProperty(key)) {
      str.push(encodeURIComponent(key));
    }
  }
  str.sort();
  for (key = 0; key < str.length; key++) {
    sorted[str[key]] = encodeURIComponent(obj[str[key]]).replace(/%20/g, '+');
  }
  return sorted;
}

// Helper function to format date
function formatDate(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const hours = String(date.getHours()).padStart(2, '0');
  const minutes = String(date.getMinutes()).padStart(2, '0');
  const seconds = String(date.getSeconds()).padStart(2, '0');
  return `${year}${month}${day}${hours}${minutes}${seconds}`;
}

// @desc    Create VNPay payment URL
// @route   POST /api/payments/vnpay/create
// @access  Private (Customer)
router.post('/vnpay/create', 
  authenticate, 
  authorize('customer'),
  [
    body('bookingId').isMongoId().withMessage('Valid booking ID is required'),
    body('bankCode').optional().isString().withMessage('Bank code must be a string'),
    body('language').optional().isIn(['vn', 'en']).withMessage('Language must be vn or en')
  ],
  validate,
  asyncHandler(async (req, res) => {
    const { bookingId, bankCode, language = 'vn' } = req.body;
    
    // Get booking
    const booking = await Booking.findById(bookingId)
      .populate('customer', 'firstName lastName email')
      .populate('hotel', 'name')
      .populate('room', 'name type');
    
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }
    
    // Check if user owns this booking
    if (booking.customer._id.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to access this booking'
      });
    }
    
    // Check if booking is already paid
    if (booking.paymentStatus === 'paid') {
      return res.status(400).json({
        success: false,
        message: 'Booking is already paid'
      });
    }
    
    // Check if payment is expired (30 minutes)
    if (booking.isPaymentExpired()) {
      booking.status = 'cancelled';
      booking.cancellationReason = 'Payment expired';
      booking.cancellationDate = new Date();
      await booking.save();
      
      return res.status(400).json({
        success: false,
        message: 'Payment time has expired. Please create a new booking.'
      });
    }
    
    const createDate = new Date();
    const expireDate = new Date(createDate.getTime() + 30 * 60 * 1000); // 30 minutes
    const amount = booking.getVNPayAmount(); // Amount * 100
    const orderInfo = `Thanh toan booking ${booking.bookingNumber} - ${booking.hotel.name}`;
    
    // Get client IP
    const ipAddr = req.headers['x-forwarded-for'] || 
                   req.connection.remoteAddress || 
                   req.socket.remoteAddress ||
                   (req.connection.socket ? req.connection.socket.remoteAddress : null) ||
                   '127.0.0.1';
    
    // Create VNPay parameters
    let vnp_Params = {
      vnp_Version: '2.1.0',
      vnp_Command: 'pay',
      vnp_TmnCode: vnpayConfig.vnp_TmnCode,
      vnp_Locale: language,
      vnp_CurrCode: 'VND',
      vnp_TxnRef: booking.bookingNumber,
      vnp_OrderInfo: orderInfo,
      vnp_OrderType: 'hotel_booking',
      vnp_Amount: amount,
      vnp_ReturnUrl: vnpayConfig.vnp_ReturnUrl,
      vnp_IpAddr: ipAddr,
      vnp_CreateDate: formatDate(createDate),
      vnp_ExpireDate: formatDate(expireDate)
    };
    
    // Add bank code if provided
    if (bankCode && bankCode !== '') {
      vnp_Params.vnp_BankCode = bankCode;
    }
    
    // Sort parameters
    vnp_Params = sortObject(vnp_Params);
    
    // Create query string
    const signData = new URLSearchParams(vnp_Params).toString();
    
    // Create secure hash
    const hmac = crypto.createHmac('sha512', vnpayConfig.vnp_HashSecret);
    const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest('hex');
    vnp_Params['vnp_SecureHash'] = signed;
    
    // Create payment URL
    const paymentUrl = vnpayConfig.vnp_Url + '?' + new URLSearchParams(vnp_Params).toString();
    
    // Update booking with transaction reference
    booking.transactionId = booking.bookingNumber;
    await booking.save();
    
    res.json({
      success: true,
      data: {
        paymentUrl,
        vnp_TxnRef: booking.bookingNumber,
        amount: booking.totalAmount,
        orderInfo,
        expireTime: expireDate
      }
    });
  })
);

// @desc    Handle VNPay return
// @route   GET /api/payments/vnpay/return
// @access  Public
router.get('/vnpay/return', asyncHandler(async (req, res) => {
  const vnp_Params = req.query;
  
  const secureHash = vnp_Params['vnp_SecureHash'];
  delete vnp_Params['vnp_SecureHash'];
  delete vnp_Params['vnp_SecureHashType'];
  
  // Sort parameters
  const sortedParams = sortObject(vnp_Params);
  const signData = new URLSearchParams(sortedParams).toString();
  
  // Verify signature
  const hmac = crypto.createHmac('sha512', vnpayConfig.vnp_HashSecret);
  const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest('hex');
  
  if (secureHash === signed) {
    const vnp_TxnRef = vnp_Params['vnp_TxnRef'];
    const vnp_ResponseCode = vnp_Params['vnp_ResponseCode'];
    const vnp_TransactionStatus = vnp_Params['vnp_TransactionStatus'];
    
    // Success status codes
    const isSuccess = (vnp_ResponseCode === '00' && vnp_TransactionStatus === '00');
    
    // Redirect to frontend with status
    const frontendUrl = process.env.CLIENT_URL || 'http://localhost:3000';
    const redirectUrl = `${frontendUrl}/payment-result?txnRef=${vnp_TxnRef}&status=${isSuccess ? 'success' : 'failed'}&responseCode=${vnp_ResponseCode}`;
    
    res.redirect(redirectUrl);
  } else {
    const frontendUrl = process.env.CLIENT_URL || 'http://localhost:3000';
    const redirectUrl = `${frontendUrl}/payment-result?status=invalid&error=invalid_signature`;
    res.redirect(redirectUrl);
  }
}));

// @desc    Handle VNPay IPN (Instant Payment Notification)
// @route   GET /api/payments/vnpay/ipn
// @access  Public
router.get('/vnpay/ipn', asyncHandler(async (req, res) => {
  const vnp_Params = req.query;
  
  const secureHash = vnp_Params['vnp_SecureHash'];
  delete vnp_Params['vnp_SecureHash'];
  delete vnp_Params['vnp_SecureHashType'];
  
  // Sort parameters
  const sortedParams = sortObject(vnp_Params);
  const signData = new URLSearchParams(sortedParams).toString();
  
  // Verify signature
  const hmac = crypto.createHmac('sha512', vnpayConfig.vnp_HashSecret);
  const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest('hex');
  
  let returnData = {
    RspCode: '00',
    Message: 'Success'
  };
  
  try {
    if (secureHash === signed) {
      const vnp_TxnRef = vnp_Params['vnp_TxnRef']; // booking number
      const vnp_Amount = vnp_Params['vnp_Amount'];
      const vnp_ResponseCode = vnp_Params['vnp_ResponseCode'];
      const vnp_TransactionStatus = vnp_Params['vnp_TransactionStatus'];
      const vnp_TransactionNo = vnp_Params['vnp_TransactionNo'];
      const vnp_BankCode = vnp_Params['vnp_BankCode'];
      const vnp_PayDate = vnp_Params['vnp_PayDate'];
      const vnp_BankTranNo = vnp_Params['vnp_BankTranNo'];
      const vnp_CardType = vnp_Params['vnp_CardType'];
      
      console.log('VNPay IPN received:', vnp_Params);
      
      // Find booking by booking number
      const booking = await Booking.findOne({ bookingNumber: vnp_TxnRef });
      
      if (booking) {
        const expectedAmount = booking.getVNPayAmount();
        
        // Check amount
        if (parseInt(vnp_Amount) === expectedAmount) {
          // Check if booking is not already processed
          if (booking.paymentStatus === 'pending') {
            // Update booking based on payment status
            if (vnp_ResponseCode === '00' && vnp_TransactionStatus === '00') {
              // Payment successful
              booking.paymentStatus = 'paid';
              booking.status = 'confirmed';
              booking.paidAt = new Date();
              booking.confirmedAt = new Date();
              
              // Update payment details
              booking.paymentDetails = {
                vnp_Amount,
                vnp_BankCode,
                vnp_BankTranNo,
                vnp_CardType,
                vnp_OrderInfo: vnp_Params['vnp_OrderInfo'],
                vnp_PayDate,
                vnp_ResponseCode,
                vnp_TmnCode: vnp_Params['vnp_TmnCode'],
                vnp_TransactionNo,
                vnp_TransactionStatus,
                vnp_TxnRef,
                vnp_SecureHash: secureHash,
                rawResponse: vnp_Params
              };
              
              await booking.save();
              
              console.log(`Booking ${vnp_TxnRef} payment successful`);
              
              returnData.RspCode = '00';
              returnData.Message = 'Confirm Success';
            } else {
              // Payment failed
              booking.paymentStatus = 'failed';
              booking.paymentDetails = {
                vnp_ResponseCode,
                vnp_TransactionStatus,
                vnp_TxnRef,
                rawResponse: vnp_Params
              };
              
              await booking.save();
              
              console.log(`Booking ${vnp_TxnRef} payment failed`);
              
              returnData.RspCode = '00';
              returnData.Message = 'Confirm Success';
            }
          } else {
            // Booking already processed
            returnData.RspCode = '02';
            returnData.Message = 'Order already confirmed';
          }
        } else {
          // Invalid amount
          returnData.RspCode = '04';
          returnData.Message = 'Invalid amount';
        }
      } else {
        // Booking not found
        returnData.RspCode = '01';
        returnData.Message = 'Order not found';
      }
    } else {
      // Invalid signature
      returnData.RspCode = '97';
      returnData.Message = 'Invalid signature';
    }
  } catch (error) {
    console.error('VNPay IPN Error:', error);
    returnData.RspCode = '99';
    returnData.Message = 'Unknown error';
  }
  
  res.json(returnData);
}));

// @desc    Get payment status
// @route   GET /api/payments/status/:bookingId
// @access  Private (Customer)
router.get('/status/:bookingId', 
  authenticate, 
  authorize('customer'),
  asyncHandler(async (req, res) => {
    const { bookingId } = req.params;
    
    const booking = await Booking.findById(bookingId)
      .populate('customer', 'firstName lastName email');
    
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }
    
    // Check if user owns this booking
    if (booking.customer._id.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to access this booking'
      });
    }
    
    res.json({
      success: true,
      data: {
        bookingId: booking._id,
        bookingNumber: booking.bookingNumber,
        paymentStatus: booking.paymentStatus,
        status: booking.status,
        totalAmount: booking.totalAmount,
        paidAt: booking.paidAt,
        paymentMethod: booking.paymentMethod,
        isExpired: booking.isPaymentExpired()
      }
    });
  })
);

// @desc    Get available banks for VNPay
// @route   GET /api/payments/vnpay/banks
// @access  Public
router.get('/vnpay/banks', (req, res) => {
  const banks = [
    { code: 'VNPAYQR', name: 'Thanh toán quét mã VNPay QR' },
    { code: 'VNBANK', name: 'Thẻ ATM - Tài khoản ngân hàng nội địa' },
    { code: 'INTCARD', name: 'Thẻ thanh toán quốc tế' },
    { code: 'VIETCOMBANK', name: 'Ngân hàng TMCP Ngoại Thương Việt Nam' },
    { code: 'VIETINBANK', name: 'Ngân hàng Công thương Việt Nam' },
    { code: 'BIDV', name: 'Ngân hàng TMCP Đầu tư và Phát triển Việt Nam' },
    { code: 'AGRIBANK', name: 'Ngân hàng Nông nghiệp và Phát triển Nông thôn Việt Nam' },
    { code: 'TPB', name: 'Ngân hàng Tiên Phong' },
    { code: 'TECHCOMBANK', name: 'Ngân hàng TMCP Kỹ thương Việt Nam' },
    { code: 'MBBANK', name: 'Ngân hàng TMCP Quân đội' },
    { code: 'ACB', name: 'Ngân hàng TMCP Á Châu' },
    { code: 'OCB', name: 'Ngân hàng TMCP Phương Đông' },
    { code: 'IVB', name: 'Ngân hàng TNHH Indovina' },
    { code: 'VISA', name: 'Thẻ thanh toán VISA' }
  ];
  
  res.json({
    success: true,
    data: banks
  });
});

// @desc    Update booking payment status (for mobile app)
// @route   POST /api/payments/vnpay/verify
// @access  Private (Customer)
router.post('/vnpay/verify', authenticate, authorize('customer'), asyncHandler(async (req, res) => {
  const { bookingId, vnp_TxnRef, vnp_ResponseCode, vnp_TransactionStatus } = req.body;
  
  try {
    // Find booking
    const booking = await Booking.findOne({ 
      _id: bookingId,
      customer: req.user._id,
      bookingNumber: vnp_TxnRef 
    }).populate('hotel room');
    
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }
    
    // Check if already processed
    if (booking.paymentStatus !== 'pending') {
      return res.json({
        success: true,
        message: 'Booking already processed',
        booking: booking
      });
    }
    
    // Update booking based on payment result
    if (vnp_ResponseCode === '00' && vnp_TransactionStatus === '00') {
      // Payment successful
      booking.paymentStatus = 'paid';
      booking.status = 'confirmed';
      booking.paidAt = new Date();
      booking.confirmedAt = new Date();
      
      await booking.save();
      
      // Send confirmation email
      try {
        await sendBookingConfirmation(
          booking, 
          booking.guestInfo.email, 
          `${booking.guestInfo.firstName} ${booking.guestInfo.lastName}`
        );
      } catch (emailError) {
        console.error('Failed to send confirmation email:', emailError);
      }
      
      console.log(`Mobile app confirmed payment for booking ${vnp_TxnRef}`);
      
      res.json({
        success: true,
        message: 'Payment confirmed successfully',
        booking: booking
      });
    } else {
      // Payment failed
      booking.paymentStatus = 'failed';
      await booking.save();
      
      res.json({
        success: true,
        message: 'Payment failed',
        booking: booking
      });
    }
  } catch (error) {
    console.error('Error verifying payment:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
}));

module.exports = router;
