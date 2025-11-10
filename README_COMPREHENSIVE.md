# 🏨 Hotel Booking System - Complete Documentation

Hệ thống đặt phòng khách sạn toàn diện với Flutter Mobile App, React Admin Web, và Node.js REST API Backend.

**Table of Contents**
- [1. Tổng Quan Hệ Thống](#1-tổng-quan-hệ-thống)
- [2. Kiến Trúc Công Nghệ](#2-kiến-trúc-công-nghệ)
- [3. Setup & Installation](#3-setup--installation)
- [4. Cấu Hình Môi Trường](#4-cấu-hình-môi-trường)
- [5. Luồng Hoạt Động Chính](#5-luồng-hoạt-động-chính)
- [6. API Documentation](#6-api-documentation)
- [7. Database Schema](#7-database-schema)
- [8. Authentication Flow](#8-authentication-flow)
- [9. Feature Details](#9-feature-details)
- [10. Deployment Guide](#10-deployment-guide)

---

## 📚 Mục Lục Chi Tiết

### Phần 1: Khái Niệm & Setup
- [1. Tổng Quan Hệ Thống](#1-tổng-quan-hệ-thống)
- [2. Kiến Trúc Công Nghệ](#2-kiến-trúc-công-nghệ)
- [3. Setup & Installation](#3-setup--installation)
- [4. Cấu Hình Môi Trường](#4-cấu-hình-môi-trường)

### Phần 2: Workflows & Flows
- [5. Luồng Hoạt Động Chính](#5-luồng-hoạt-động-chính)
- [5.1. Authentication Flow - Chi Tiết](#51-authentication-flow---chi-tiết)
- [5.2. Booking Flow - Chi Tiết](#52-booking-flow---chi-tiết)

### Phần 3: Backend Implementation
- [6. API Documentation](#6-api-documentation)
- [7. Database Schema](#7-database-schema)
- [8. Authentication Flow](#8-authentication-flow)

### Phần 4: Frontend Implementation
- [9. Feature Details](#9-feature-details)
- [10. Code Examples](#10-code-examples)

### Phần 5: DevOps & Advanced
- [11. Deployment Guide](#11-deployment-guide)
- [12. Docker & CI/CD](#12-docker--cicd)
- [13. Performance & Security](#13-performance--security)
- [14. Testing Guide](#14-testing-guide)
- [15. Troubleshooting](#15-troubleshooting)

---

## 1. Tổng Quan Hệ Thống

### 1.1 Mô Tả Chung
Hệ thống Hotel Booking là một nền tảng hoàn chỉnh cho phép:
- **Khách du lịch**: Tìm kiếm, xem chi tiết, đặt phòng khách sạn
- **Chủ khách sạn**: Quản lý khách sạn, phòng, đặt phòng, doanh thu
- **Quản trị viên**: Quản lý toàn bộ hệ thống, duyệt khách sạn, thống kê

### 1.2 Các Nền Tảng
| Nền Tảng | Công Nghệ | Mục Đích |
|---------|-----------|---------|
| **Mobile App** | Flutter 3.8+ | Khách đặt phòng + Chủ hotel quản lý |
| **Admin Web** | React 18 + Redux | Quản trị hệ thống |
| **Backend API** | Node.js + Express | RESTful API |
| **Database** | MongoDB | Lưu trữ dữ liệu |

### 1.3 Tính Năng Chính
✅ Xác thực đa vai trò (Customer, Hotel Owner, Admin)  
✅ Đặt phòng với thanh toán (VNPAY + Stripe)  
✅ Hệ thống xếp hạng thành viên (Bronze → Diamond)  
✅ Review & Đánh giá khách sạn  
✅ Chatbot AI (Gemini)  
✅ Quản lý doanh thu  
✅ Đa ngôn ngữ (English + Tiếng Việt)  
✅ Real-time Chat (Socket.io)  

---

## 2. Kiến Trúc Công Nghệ

### 2.1 Backend Architecture
```
Backend (Node.js + Express)
├── Routes (RESTful API)
│   ├── auth.js          → Xác thực & OTP
│   ├── users.js         → Quản lý người dùng
│   ├── hotels.js        → Quản lý khách sạn
│   ├── rooms.js         → Quản lý phòng
│   ├── bookings.js      → Quản lý đặt phòng
│   ├── payments.js      → VNPAY + Stripe
│   ├── reviews.js       → Đánh giá & Review
│   ├── chatbot.js       → Chatbot AI
│   ├── upload.js        → Upload hình ảnh (Cloudinary)
│   └── admin.js         → Quản trị
├── Models (MongoDB)
│   ├── User.js          → Schema người dùng
│   ├── Hotel.js         → Schema khách sạn
│   ├── Room.js          → Schema phòng
│   ├── Booking.js       → Schema đặt phòng
│   ├── Review.js        → Schema đánh giá
├── Middleware
│   ├── auth.js          → JWT Authentication
│   └── validation.js    → Request validation
├── Utils
│   ├── auth.js          → Token generation
│   ├── email.js         → Email sending (Gmail SMTP)
│   └── cloudinary.js    → Image upload
└── server.js            → Entry point
```

### 2.2 Mobile App (Flutter) Architecture
```
Flutter App
├── lib/
│   ├── main.dart                 → Entry point
│   ├── config/
│   │   ├── api_config.dart      → API endpoints
│   │   ├── app_constants.dart   → Constants
│   │   └── app_theme.dart       → Themes
│   ├── models/                   → Data models
│   │   ├── user.dart
│   │   ├── hotel.dart
│   │   ├── booking.dart
│   │   ├── payment.dart
│   │   └── ...
│   ├── providers/                → State management (Provider)
│   │   ├── auth_provider.dart
│   │   ├── hotel_provider.dart
│   │   ├── locale_provider.dart
│   │   └── ...
│   ├── services/
│   │   ├── api_service.dart     → HTTP calls
│   │   └── payment_service.dart
│   ├── screens/                  → UI Screens
│   │   ├── auth/                → Login, Register
│   │   ├── booking/             → Booking flow
│   │   ├── hotel/               → Hotel listing
│   │   ├── hotel_owner/         → Owner management
│   │   └── main/                → Main screens
│   ├── widgets/                  → Reusable components
│   ├── utils/                    → Helper functions
│   └── l10n/                     → Localization
```

### 2.3 Admin Web (React) Architecture
```
React Admin Web
├── src/
│   ├── index.js
│   ├── App.js
│   ├── pages/                    → Page components
│   │   ├── dashboard/
│   │   ├── hotels/
│   │   ├── rooms/
│   │   ├── users/
│   │   ├── bookings/
│   │   └── ...
│   ├── components/               → Reusable components
│   │   ├── Layout/
│   │   ├── ProtectedRoute/
│   │   └── ...
│   ├── services/                 → API calls
│   ├── store/                    → Redux store
│   │   └── slices/
│   ├── i18n/                     → Internationalization
│   └── utils/
```

---

## 3. Setup & Installation

### 3.1 Prerequisites
- Node.js v16+
- Flutter SDK 3.8+
- MongoDB (local or Atlas)
- npm hoặc yarn

### 3.2 Backend Setup

#### 3.2.1 Clone & Install
```bash
# Clone repository
git clone <repo-url>
cd hotel_booking

# Install dependencies
npm install
```

#### 3.2.2 Configure Environment
```bash
# Copy example file
cp .env.example .env

# Edit .env với thông tin của bạn
```

#### 3.2.3 Start Backend Server
```bash
# Development
npm start
# hoặc
npm run dev

# Server sẽ chạy trên http://localhost:5000
```

#### 3.2.4 Add Sample Data (Optional)
```bash
node add_sample_data.js
```

### 3.3 Flutter Mobile App Setup

#### 3.3.1 Install Dependencies
```bash
cd flutter_client/hotel_booking_app

# Get packages
flutter pub get
```

#### 3.3.2 Configure API Base URL
**File**: `lib/config/api_config.dart`

```dart
// Cho Android Emulator
static const String baseUrl = 'http://10.0.2.2:5000/api';

// Cho iOS Simulator
static const String baseUrl = 'http://localhost:5000/api';

// Cho Physical Device
static const String baseUrl = 'http://<YOUR_MACHINE_IP>:5000/api';
```

#### 3.3.3 Run App
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web (preview)
flutter run -d web
```

### 3.4 React Admin Web Setup

#### 3.4.1 Install Dependencies
```bash
cd frontend/admin-web
npm install
```

#### 3.4.2 Configure API
**File**: `package.json`

```json
"proxy": "http://localhost:5000"
```

**hoặc** `.env`:
```
REACT_APP_API_URL=http://localhost:5000/api
```

#### 3.4.3 Run Development Server
```bash
npm start

# Server sẽ chạy trên http://localhost:3000
```

---

## 4. Cấu Hình Môi Trường

### 4.1 Backend Environment Variables (.env)

```bash
# ============ SERVER ============
NODE_ENV=development
PORT=5000

# ============ DATABASE ============
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/hotel_booking?retryWrites=true&w=majority

# ============ JWT TOKENS ============
JWT_SECRET=your_super_secret_jwt_key_here_min_32_chars
JWT_REFRESH_SECRET=your_refresh_token_secret_key_min_32_chars
JWT_EXPIRE=15m
JWT_REFRESH_EXPIRE=7d

# ============ EMAIL (Gmail SMTP) ============
# 1. Enable 2FA on Gmail
# 2. Create App Password: https://myaccount.google.com/apppasswords
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your_email@gmail.com
EMAIL_PASS=your_16_char_app_password

# ============ VNPAY ============
# Đăng ký trên: https://www.vnpayment.vn/
VNPAY_TMN_CODE=TMNCODE
VNPAY_SECRET_KEY=your_secret_key
VNPAY_URL=https://sandbox.vnpayment.vn/paygate
VNPAY_RETURN_URL=http://localhost:5000/api/payments/vnpay/return
VNPAY_IPN_URL=http://localhost:5000/api/payments/vnpay/ipn

# ============ STRIPE ============
# Đăng ký trên: https://stripe.com/
STRIPE_SECRET_KEY=sk_test_xxxxx
STRIPE_PUBLISHABLE_KEY=pk_test_xxxxx

# ============ CLOUDINARY (Image Upload) ============
# Đăng ký trên: https://cloudinary.com/
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret

# ============ GEMINI AI ============
# Lấy từ: https://aistudio.google.com/
GEMINI_API_KEY=your_gemini_api_key

# ============ FRONTEND URLs ============
CLIENT_URL=http://localhost:3000
ADMIN_URL=http://localhost:3001
```

### 4.2 Flutter Configuration

**File**: `lib/config/api_config.dart`

```dart
class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:5000/api'; // Android
  // static const String baseUrl = 'http://localhost:5000/api'; // iOS
  // static const String baseUrl = 'http://192.168.x.x:5000/api'; // Physical device
  
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
```

---

## 5. Luồng Hoạt Động Chính

### 5.1 Authentication Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    AUTHENTICATION FLOW                      │
└─────────────────────────────────────────────────────────────┘

1. REGISTER (Đăng Ký)
   ┌─────────┐
   │ App     │
   └────┬────┘
        │ POST /api/auth/register
        │ { email, password, firstName, lastName, phone }
        ▼
   ┌──────────┐
   │ Backend  │ → Validate input
   │ (Node)   │ → Hash password (bcryptjs)
   │          │ → Check existing user
   │          │ → Generate OTP (6 digits)
   │          │ → Send OTP to email
   └────┬─────┘
        │ Response: { accessToken, refreshToken, user }
        ▼
   ┌─────────┐
   │ App     │ → Save tokens (localStorage/SharedPreferences)
   │ Storage │ → Show OTP verification screen
   └─────────┘

2. VERIFY OTP (Xác Minh Email)
   ┌─────────┐
   │ App     │
   └────┬────┘
        │ POST /api/auth/verify-otp
        │ { email, otp }
        ▼
   ┌──────────┐
   │ Backend  │ → Verify OTP
   │          │ → Set isEmailVerified = true
   └────┬─────┘
        │ Response: { success: true }
        ▼
   ┌─────────┐
   │ App     │ → Navigate to login
   └─────────┘

3. LOGIN (Đăng Nhập)
   ┌─────────┐
   │ App     │
   └────┬────┘
        │ POST /api/auth/login
        │ { email, password }
        ▼
   ┌──────────┐
   │ Backend  │ → Find user by email
   │          │ → Compare password (bcrypt)
   │          │ → Generate JWT tokens
   │          │ → Save refreshToken to DB
   └────┬─────┘
        │ Response: { accessToken, refreshToken, user }
        ▼
   ┌─────────┐
   │ App     │ → Save tokens
   │ Storage │ → Save user info
   │         │ → Update AuthProvider state = authenticated
   └─────────┘

4. REFRESH TOKEN (Làm Mới Token)
   ┌─────────┐
   │ App     │
   └────┬────┘
        │ POST /api/auth/refresh-token
        │ { refreshToken }
        ▼
   ┌──────────┐
   │ Backend  │ → Verify refresh token
   │          │ → Generate new accessToken
   └────┬─────┘
        │ Response: { accessToken }
        ▼
   ┌─────────┐
   │ App     │ → Update accessToken
   └─────────┘

5. LOGOUT (Đăng Xuất)
   ┌─────────┐
   │ App     │
   └────┬────┘
        │ DELETE /api/auth/logout
        │ Headers: { Authorization: "Bearer token" }
        ▼
   ┌──────────┐
   │ Backend  │ → Clear refreshToken from DB
   └────┬─────┘
        │ Response: { success: true }
        ▼
   ┌─────────┐
   │ App     │ → Clear localStorage/SharedPreferences
   │ Storage │ → Clear AuthProvider
   │         │ → Navigate to login
   └─────────┘
```

### 5.2 Hotel Booking Flow

```
┌──────────────────────────────────────────────────┐
│           BOOKING FLOW                           │
└──────────────────────────────────────────────────┘

1. SEARCH & FILTER HOTELS (Tìm Khách Sạn)
   ┌─────────────┐
   │ User        │
   └────┬────────┘
        │ Nhập: ngày check-in, check-out, số khách
        ▼
   GET /api/hotels?page=1&limit=10&city=HCM&minPrice=1000000&maxPrice=5000000
        │
        ▼ Backend → Query MongoDB, filter by criteria
        │
   Response: { hotels: [...], total, pages }
        │
        ▼
   ┌─────────────┐
   │ Flutter App │ → Display hotel list
   │ (HotelList) │
   └─────────────┘

2. VIEW HOTEL DETAILS (Xem Chi Tiết Khách Sạn)
   GET /api/hotels/:hotelId
        │
        ▼ Backend → Get hotel with rooms, reviews, amenities
        │
   Response: {
     _id: "...",
     name: "Hotel Name",
     images: [...],
     rooms: [{type, price, availability}],
     reviews: [{rating, comment, author}],
     amenities: ["wifi", "pool", "gym"],
     policies: {checkIn, checkOut, cancellation}
   }
        │
        ▼
   ┌─────────────────────┐
   │ Flutter App         │
   │ (HotelDetailScreen) │ → Show full details
   └─────────────────────┘

3. CHECK ROOM AVAILABILITY (Kiểm Tra Phòng Còn Trống)
   GET /api/rooms/:roomId/availability
   ?checkIn=2024-01-15&checkOut=2024-01-18
        │
        ▼ Backend → Room.checkAvailability()
          → Query Booking collection
          → Count bookings in date range
          → Calculate available rooms
        │
   Response: {
     available: true,
     availableRooms: 3,
     totalRooms: 5,
     price: 2500000
   }
        │
        ▼
   ┌─────────────────────┐
   │ Flutter App         │
   │ (BookingScreen)     │ → Show availability & pricing
   └─────────────────────┘

4. CREATE BOOKING (Tạo Đặt Phòng)
   POST /api/bookings
   Headers: { Authorization: "Bearer token" }
   Body: {
     room: "roomId",
     checkIn: "2024-01-15T14:00:00Z",
     checkOut: "2024-01-18T12:00:00Z",
     guests: { adults: 2, children: 1 },
     guestInfo: { firstName, lastName, email, phone },
     paymentMethod: "vnpay",
     specialRequests: "..."
   }
        │
        ▼ Backend → Validate inputs
          → Check room availability again (prevent double booking)
          → Calculate pricing:
            - subtotal = room.price * nights
            - discount = subtotal * user.discountPercentage
            - tax = (subtotal - discount) * 0.1
            - total = subtotal - discount + tax
          → Create Booking document
          → Save to MongoDB
        │
   Response: {
     _id: "bookingId",
     bookingNumber: "HB172345670001",
     status: "pending",
     paymentStatus: "pending",
     totalAmount: 7500000,
     ...
   }
        │
        ▼
   ┌─────────────────────┐
   │ Flutter App         │
   │ (Payment Screen)    │ → Proceed to payment
   └─────────────────────┘

5. PROCESS PAYMENT (VNPAY)
   POST /api/payments/vnpay/create
   Headers: { Authorization: "Bearer token" }
   Body: { bookingId: "...", bankCode: "", language: "vn" }
        │
        ▼ Backend → Get booking info
          → Build VNPAY parameters:
            - vnp_Amount: booking.totalAmount * 100
            - vnp_CreateDate: now
            - vnp_TxnRef: unique transaction ID
            - vnp_OrderInfo: booking details
          → Create HMAC signature (SHA256)
          → Return VNPAY payment URL
        │
   Response: {
     paymentUrl: "https://sandbox.vnpayment.vn/paygate?...",
     bookingId: "..."
   }
        │
        ▼
   ┌──────────────────────┐
   │ Flutter App          │
   │ (WebViewScreen)      │ → Open WebView
   └────┬─────────────────┘
        │ User enters payment details
        ▼
   ┌──────────────────────┐
   │ VNPAY Gateway        │ → Process payment
   │ (External)           │ → Return to app
   └────┬─────────────────┘
        │
        ▼

6. PAYMENT CALLBACK / VERIFICATION
   POST /api/payments/vnpay/return
   (VNPAY redirects browser with query params)
   Params: { vnp_ResponseCode, vnp_TransactionNo, vnp_SecureHash, ... }
        │
        ▼ Backend → Verify secure hash
          → If valid:
            - Update booking.status = "confirmed"
            - Update booking.paymentStatus = "paid"
            - Update booking.transactionId
            - Update customer.totalSpent
            - Auto-update customer membership tier
            - Send confirmation email
          → If invalid: mark as failed
        │
        ▼
   ┌──────────────────────┐
   │ Flutter App          │
   │ (Confirmation)       │ → Show success/failure
   │                      │ → Send to MyBookings screen
   └──────────────────────┘

7. BOOKING CONFIRMATION (Xác Nhận Đặt Phòng)
   GET /api/bookings/:bookingId
   Headers: { Authorization: "Bearer token" }
        │
        ▼ Backend → Get booking with populated data:
          - customer info
          - hotel info
          - room details
          - payment details
        │
   Response: {
     bookingNumber: "HB172345670001",
     hotel: { name, address, phone },
     room: { name, type, basePrice },
     checkIn: "2024-01-15T14:00:00Z",
     checkOut: "2024-01-18T12:00:00Z",
     guests: { adults: 2, children: 1 },
     totalAmount: 7500000,
     status: "confirmed",
     paymentStatus: "paid",
     paidAt: "2024-01-14T10:30:00Z",
     ...
   }
        │
        ▼
   ┌──────────────────────┐
   │ Flutter App          │
   │ (MyBookings Screen)  │ → Display booking details
   │                      │ → Option to cancel/modify
   └──────────────────────┘
```

### 5.3 Membership Tier System (Hệ Thống Xếp Hạng)

```
┌────────────────────────────────────────────┐
│      MEMBERSHIP TIER SYSTEM                │
└────────────────────────────────────────────┘

Tier Levels:
┌──────────┬─────────────────┬──────────────┐
│   Tier   │ Total Spent     │   Discount   │
├──────────┼─────────────────┼──────────────┤
│ Bronze   │ 0 VND           │ 0%           │
│ Silver   │ 10,000,000 VND  │ 1%           │
│ Gold     │ 20,000,000 VND  │ 3%           │
│ Diamond  │ 50,000,000 VND  │ 5%           │
└──────────┴─────────────────┴──────────────┘

Flow:
1. User tạo booking → Booking confirmed & paid
   ↓
2. Backend update customer.totalSpent += booking.totalAmount
   ↓
3. Backend call customer.updateMembershipTier()
   ↓
4. Check: if totalSpent >= 50M → Diamond
          if totalSpent >= 20M → Gold
          if totalSpent >= 10M → Silver
          else → Bronze
   ↓
5. Next booking → Apply discount
   - subtotal = price * nights
   - discount = subtotal * tier.discount%
   - total = subtotal - discount
```

---

## 5.1 Authentication Flow - Chi Tiết

### 5.1.1 Register Workflow - Mermaid Diagram

```
sequenceDiagram
    participant User
    participant App as Flutter App
    participant Backend as Node.js Backend
    participant Email as Gmail SMTP
    participant DB as MongoDB

    User->>App: Enter email, password, name, phone
    App->>Backend: POST /api/auth/register
    
    Backend->>DB: Check if user exists
    alt User exists
        Backend->>App: 400 - User already exists
    else New user
        Backend->>Backend: Hash password (bcrypt, 12 rounds)
        Backend->>Backend: Generate OTP (6 digits)
        Backend->>DB: Create user doc (isEmailVerified: false)
        Backend->>DB: Save emailVerificationOTP
        Backend->>Backend: Generate JWT tokens
        Backend->>DB: Save refreshToken
        Backend->>Email: Send OTP email
        Email->>User: OTP in inbox
        Backend->>App: 201 - accessToken, refreshToken, user
        
        App->>App: Save tokens to SharedPreferences
        App->>App: Save user to SharedPreferences
        App->>App: Navigate to OTP verification screen
        
        User->>App: Enter OTP from email
        App->>Backend: POST /api/auth/verify-otp
        
        Backend->>DB: Find user by email
        Backend->>Backend: Compare OTP
        alt OTP valid & not expired
            Backend->>DB: Update isEmailVerified: true
            Backend->>App: 200 - Email verified successfully
            App->>App: Navigate to login screen
        else OTP invalid/expired
            Backend->>App: 400 - Invalid or expired OTP
            App->>App: Show error & allow resend
        end
    end
```

### 5.1.2 Login Workflow - Code Level

```
Browser Request:
  POST /api/auth/login
  Content-Type: application/json
  
  {
    "email": "user@example.com",
    "password": "password123"
  }

Backend Processing (routes/auth.js):
  
  1. Validate input:
     - Email format (valid email)
     - Password not empty
  
  2. Find user in database:
     const user = await User.findOne({ email })
     if (!user) → 401 Unauthorized
  
  3. Compare password:
     const isPasswordValid = await user.comparePassword(password)
     if (!isPasswordValid) → 401 Unauthorized
  
  4. Check email verification:
     if (!user.isEmailVerified) → 403 Email not verified
  
  5. Generate tokens:
     JWT accessToken (expires in 15 minutes)
     JWT refreshToken (expires in 7 days)
  
  6. Save refreshToken to database:
     user.refreshToken = refreshToken
     await user.save()
  
  7. Update lastLogin:
     user.lastLogin = new Date()
     await user.save()
  
  8. Return response with:
     - accessToken
     - refreshToken
     - user data (id, email, name, role, avatar, membershipTier)

Response:
  200 OK
  {
    "success": true,
    "message": "Login successful",
    "user": {
      "id": "507f1f77bcf86cd799439011",
      "email": "user@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "role": "customer",
      "membershipTier": "gold",
      "avatar": "https://..."
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }

Flutter/Dart Implementation (lib/providers/auth_provider.dart):

  Future<bool> login(String email, String password) async {
    _setState(AuthState.loading);
    _clearMessages();
    
    try {
      // 1. Validate input
      if (email.isEmpty || password.isEmpty) {
        _setError('Email and password required');
        return false;
      }
      
      // 2. Call API
      final request = LoginRequest(email: email, password: password);
      final response = await _apiService.login(request);
      
      // 3. Check response
      if (!response.success) {
        _setError(response.message);
        return false;
      }
      
      // 4. Check email verification
      if (response.user?.isEmailVerified == false) {
        _pendingVerificationEmail = email;
        _setState(AuthState.emailNotVerified);
        _setSuccess('Please verify your email');
        return false;
      }
      
      // 5. Save to storage
      await _apiService.saveTokens(
        response.accessToken!,
        response.refreshToken!
      );
      await _apiService.saveUserToStorage(response.user!);
      
      // 6. Update provider state
      _currentUser = response.user;
      _setState(AuthState.authenticated);
      _setSuccess('Login successful');
      
      // 7. Optional: Subscribe to notifications
      // await NotificationService.subscribeToUserChannel(user.id);
      
      return true;
      
    } on TimeoutException {
      _setError('Connection timeout');
      return false;
    } on SocketException {
      _setError('No internet connection');
      return false;
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      return false;
    }
  }
```

### 5.1.3 Token Refresh Mechanism

```
When Access Token Expires:

1. API Interceptor detects 401 response
   ↓
2. Check if refreshToken exists in storage
   ├─ NO → Logout user, navigate to login
   └─ YES → Continue
   ↓
3. Call POST /api/auth/refresh-token
   with refreshToken in body
   ↓
4. Backend validates refreshToken
   └─ Check JWT signature
   └─ Check against DB (user.refreshToken)
   └─ Check if token expired
   
   ├─ Invalid → 401 (logout)
   ├─ Expired → 401 (logout, ask user to login again)
   └─ Valid → Continue
   ↓
5. Backend generates new accessToken
   └─ Same user.id
   └─ New expiration (15 minutes from now)
   
   Response:
   {
     "success": true,
     "accessToken": "eyJhbGc...",
     "message": "Token refreshed"
   }
   ↓
6. Client updates accessToken in storage
   await storage.write(key: 'access_token', value: newToken)
   ↓
7. Retry original API request with new token
   ↓
8. Success! User stays logged in
```

### 5.1.4 Error Handling - Authentication

```javascript
// Backend error responses (routes/auth.js)

// Case 1: Invalid credentials
401 Unauthorized
{
  "success": false,
  "message": "Invalid email or password"
}

// Case 2: Email not verified
403 Forbidden
{
  "success": false,
  "message": "Please verify your email before logging in",
  "requiresEmailVerification": true,
  "email": "user@example.com"
}

// Case 3: Account inactive/suspended
403 Forbidden
{
  "success": false,
  "message": "Your account has been suspended"
}

// Case 4: Rate limiting (too many login attempts)
429 Too Many Requests
{
  "success": false,
  "message": "Too many login attempts. Try again in 15 minutes"
}

// Case 5: Invalid token
401 Unauthorized
{
  "success": false,
  "message": "Invalid or expired token"
}

// Case 6: Token missing
401 Unauthorized
{
  "success": false,
  "message": "Access denied. No token provided"
}
```

---

## 5.2 Booking Flow - Chi Tiết

### 5.2.1 Complete Booking Sequence

```
STEP 1: SEARCH HOTELS
────────────────────

Flutter Code:
  Future<void> searchHotels(String city, DateTime checkIn, DateTime checkOut) async {
    try {
      final params = {
        'city': city,
        'checkIn': checkIn.toIso8601String(),
        'checkOut': checkOut.toIso8601String(),
        'page': 1,
        'limit': 20,
      };
      
      _hotels = await apiService.get('/hotels', queryParameters: params);
    } catch (e) {
      print('Error searching hotels: $e');
    }
  }

Backend Processing (routes/hotels.js):
  
  GET /api/hotels?city=HCM&checkIn=2024-01-15&checkOut=2024-01-18
  
  1. Extract query parameters
  2. Build MongoDB query:
     {
       isApproved: true,
       isActive: true,
       'address.city': { $regex: 'HCM', $options: 'i' }
     }
  
  3. For each hotel:
     - Get rooms
     - Check availability for date range
     - Calculate pricing
     - Get average rating
  
  4. Sort by criteria (rating, price, name)
  5. Paginate results
  6. Return array of hotels with availability info

Response:
  [
    {
      _id: "hotel_1",
      name: "Luxury Hotel",
      starRating: 5,
      address: { city: "HCM", street: "..." },
      images: [...],
      availableRooms: [
        {
          _id: "room_1",
          type: "deluxe",
          basePrice: 2500000,
          availability: true,
          availableCount: 3
        }
      ],
      averageRating: 4.8,
      amenities: ["wifi", "pool", "gym"]
    }
  ]

Flutter UI (screens/hotel/hotel_list_screen.dart):
  - Display hotel cards
  - Show availability status
  - Show price per night
  - Show rating
  - On tap: Navigate to hotel detail screen


STEP 2: VIEW HOTEL DETAILS
──────────────────────────

Flutter Code:
  Future<void> getHotelDetails(String hotelId) async {
    _selectedHotel = await apiService.get('/hotels/$hotelId');
    _selectedHotel.rooms = await apiService.get('/rooms/hotel/$hotelId');
    _selectedHotel.reviews = await apiService.get('/reviews/hotel/$hotelId');
  }

Response includes:
  {
    _id: "hotel_1",
    name: "Luxury Hotel",
    description: "...",
    images: [...10 images],
    rooms: [
      {
        _id: "room_1",
        name: "Deluxe Room",
        type: "deluxe",
        maxGuests: 2,
        amenities: ["wifi", "ac", "balcony"],
        basePrice: 2500000,
        weekendPrice: 3500000
      }
    ],
    reviews: [
      {
        rating: 5,
        comment: "Amazing!",
        author: { firstName: "John", avatar: "..." },
        createdAt: "2024-01-10"
      }
    ],
    policies: {
      checkIn: "14:00",
      checkOut: "12:00",
      cancellation: "flexible"
    },
    amenities: ["wifi", "pool", "gym", "restaurant"]
  }

Flutter UI (screens/hotel/hotel_detail_screen.dart):
  - Image carousel (swipeable)
  - Hotel name, rating, reviews count
  - Description
  - Amenities list
  - Rooms section (scrollable)
  - Policies section
  - "Book Now" button


STEP 3: CHECK ROOM AVAILABILITY & PRICING
───────────────────────────────────────────

Flutter Code:
  Future<RoomAvailability> checkAvailability(
    String roomId,
    DateTime checkIn,
    DateTime checkOut,
    int guestCount
  ) async {
    final params = {
      'roomId': roomId,
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut.toIso8601String(),
      'guestCount': guestCount,
    };
    
    return await apiService.get('/rooms/$roomId/availability', 
      queryParameters: params
    );
  }

Backend Processing (models/Room.js - checkAvailability method):

  checkAvailability = async function(checkIn, checkOut, guestCount) {
    // 1. Check guest capacity
    if (guestCount > this.maxGuests) {
      return {
        available: false,
        reason: 'Exceeds maximum guest capacity'
      };
    }
    
    // 2. Query overlapping bookings
    const Booking = mongoose.model('Booking');
    const checkInDate = new Date(checkIn);
    const checkOutDate = new Date(checkOut);
    
    // Count bookings that overlap AND hold inventory:
    // - status in ['confirmed', 'checked_in']
    // - OR status='pending' created within last 30 minutes
    const overlappingBookings = await Booking.countDocuments({
      room: this._id,
      $and: [
        { checkIn: { $lt: checkOutDate } },
        { checkOut: { $gt: checkInDate } }
      ],
      $or: [
        { status: { $in: ['confirmed', 'checked_in'] } },
        { 
          status: 'pending',
          createdAt: { $gte: new Date(Date.now() - 30 * 60 * 1000) }
        }
      ]
    });
    
    // 3. Calculate available rooms
    const availableRooms = this.totalRooms - overlappingBookings;
    
    // 4. Calculate price
    const nights = Math.ceil((checkOutDate - checkInDate) / (1000*60*60*24));
    let totalPrice = 0;
    let currentDate = new Date(checkInDate);
    
    for (let i = 0; i < nights; i++) {
      const isWeekend = currentDate.getDay() === 0 || currentDate.getDay() === 6;
      const nightPrice = isWeekend ? this.weekendPrice : this.basePrice;
      totalPrice += nightPrice;
      currentDate.setDate(currentDate.getDate() + 1);
    }
    
    // Apply discount
    if (this.discountPercentage > 0) {
      totalPrice = totalPrice * (1 - this.discountPercentage / 100);
    }
    
    return {
      available: availableRooms > 0,
      availableRooms,
      totalRooms: this.totalRooms,
      price: {
        perNight: Math.round(totalPrice / nights),
        total: Math.round(totalPrice),
        nights,
        basePrice: this.basePrice,
        weekendPrice: this.weekendPrice,
        discount: this.discountPercentage
      }
    };
  }

Response:
  {
    available: true,
    availableRooms: 3,
    totalRooms: 5,
    price: {
      perNight: 2750000,
      total: 8250000,
      nights: 3,
      basePrice: 2500000,
      weekendPrice: 3500000,
      discount: 10
    }
  }

Flutter UI (screens/booking/room_select_screen.dart):
  - Show available count
  - Show price breakdown:
    - 2 nights @ 2,500,000 = 5,000,000
    - 1 weekend night @ 3,500,000 = 3,500,000
    - Subtotal: 8,500,000
    - Discount (10%): -850,000
    - Total: 7,650,000


STEP 4: CREATE BOOKING
──────────────────────

Flutter Code:
  Future<Booking> createBooking({
    required String roomId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int adults,
    required int children,
    required GuestInfo guestInfo,
    required String paymentMethod,
  }) async {
    final bookingData = {
      'room': roomId,
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut.toIso8601String(),
      'guests': {
        'adults': adults,
        'children': children
      },
      'guestInfo': {
        'firstName': guestInfo.firstName,
        'lastName': guestInfo.lastName,
        'email': guestInfo.email,
        'phone': guestInfo.phone,
        'specialRequests': guestInfo.specialRequests
      },
      'paymentMethod': paymentMethod // 'vnpay' or 'stripe'
    };
    
    // Add auth header automatically via interceptor
    return await apiService.post('/bookings', data: bookingData);
  }

Backend Processing (routes/bookings.js):

  POST /api/bookings
  Headers: { Authorization: "Bearer <accessToken>" }
  
  1. Authenticate user (middleware)
  2. Validate input:
     - roomId valid MongoDB ID
     - checkIn is ISO date
     - checkOut is ISO date
     - checkOut > checkIn
     - adults >= 1
     - children >= 0
     - guestInfo valid
     - paymentMethod in ['vnpay', 'stripe']
  
  3. Get room & populate hotel:
     const room = await Room.findById(roomId).populate('hotel');
     const hotel = room.hotel;
     const user = req.user; // Current user from auth middleware
  
  4. Check availability again (prevent double-booking):
     const availability = await room.checkAvailability(checkIn, checkOut);
     if (!availability.available) → 400 Room not available
  
  5. Calculate pricing:
     const { price } = availability;
     const subtotal = price.total;
     
     // Apply user membership discount
     const discountPercentage = user.getDiscountPercentage();
     const discountAmount = subtotal * (discountPercentage / 100);
     
     // Calculate tax (10%)
     const taxableAmount = subtotal - discountAmount;
     const taxAmount = taxableAmount * 0.1;
     
     const totalAmount = taxableAmount + taxAmount;
  
  6. Create booking document:
     const booking = new Booking({
       customer: user._id,
       hotel: hotel._id,
       room: room._id,
       bookingNumber: auto-generated,
       checkIn: new Date(checkIn),
       checkOut: new Date(checkOut),
       guests: { adults, children },
       guestInfo: { firstName, lastName, email, phone, specialRequests },
       roomPrice: price.perNight,
       nights: price.nights,
       subtotal,
       discountAmount,
       discountPercentage,
       taxAmount,
       totalAmount,
       currency: 'VND',
       status: 'pending',
       paymentStatus: 'pending',
       paymentMethod
     });
     
     await booking.save();
     // → Triggers pre-save hook to generate bookingNumber
  
  7. Populate booking with references:
     await booking.populate(['customer', 'hotel', 'room']);
  
  8. Return created booking

Response (201 Created):
  {
    _id: "507f1f77bcf86cd799439011",
    bookingNumber: "HB172345670001",
    customer: {
      _id: "507f1f77bcf86cd799439012",
      firstName: "John",
      email: "john@example.com"
    },
    hotel: {
      _id: "507f1f77bcf86cd799439013",
      name: "Luxury Hotel"
    },
    room: {
      _id: "507f1f77bcf86cd799439014",
      name: "Deluxe Room",
      type: "deluxe"
    },
    checkIn: "2024-01-15T14:00:00.000Z",
    checkOut: "2024-01-18T12:00:00.000Z",
    guests: { adults: 2, children: 1 },
    guestInfo: {
      firstName: "John",
      lastName: "Doe",
      email: "john@example.com",
      phone: "+84901234567"
    },
    roomPrice: 2750000,
    nights: 3,
    subtotal: 8250000,
    discountAmount: 412500,
    discountPercentage: 5,
    taxAmount: 783750,
    totalAmount: 8621250,
    currency: "VND",
    status: "pending",
    paymentStatus: "pending",
    paymentMethod: "vnpay",
    createdAt: "2024-01-14T10:30:00.000Z"
  }

Flutter Implementation:
  - Show booking summary
  - Display booking number
  - Show total amount
  - Display "Proceed to Payment" button


STEP 5: VNPAY PAYMENT
─────────────────────

Flutter Code:
  Future<String?> createVNPayPaymentUrl(String bookingId) async {
    final response = await apiService.post(
      '/payments/vnpay/create',
      data: {
        'bookingId': bookingId,
        'bankCode': '', // Optional
        'language': 'vn'
      }
    );
    
    return response['paymentUrl'] as String?;
  }

  // In WebView
  Future<void> openPaymentWebView(String paymentUrl) async {
    final result = await Navigator.push<PaymentResult>(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentWebViewScreen(url: paymentUrl)
      )
    );
    
    if (result?.success == true) {
      // Payment successful
      _navigateToBookingConfirmation();
    } else {
      // Payment failed
      _showErrorDialog('Payment failed');
    }
  }

Backend Processing (routes/payments.js):

  POST /api/payments/vnpay/create
  Headers: { Authorization: "Bearer <token>" }
  
  1. Get booking:
     const booking = await Booking.findById(bookingId);
     if (!booking) → 404 Not Found
  
  2. Check ownership:
     if (booking.customer._id !== req.user._id) → 403 Forbidden
  
  3. Check payment status:
     if (booking.paymentStatus !== 'pending') → 400 Bad Request
  
  4. Build VNPAY parameters:
     const vnpayParams = {
       vnp_Version: '2.1.0',
       vnp_Command: 'pay',
       vnp_TmnCode: process.env.VNPAY_TMN_CODE,
       vnp_Locale: language, // 'vn' or 'en'
       vnp_CurrCode: 'VND',
       vnp_TxnRef: `${booking._id}_${Date.now()}`,
       vnp_OrderInfo: `Booking ${booking.bookingNumber} - ${hotel.name}`,
       vnp_OrderType: 'other',
       vnp_Amount: booking.totalAmount * 100, // VNPay uses smallest unit
       vnp_ReturnUrl: process.env.VNPAY_RETURN_URL,
       vnp_IpnUrl: process.env.VNPAY_IPN_URL,
       vnp_CreateDate: formatDate(new Date()),
       vnp_ExpireDate: formatDate(new Date(Date.now() + 15*60*1000)), // 15 min
       vnp_Bill_Mobile: booking.guestInfo.phone,
       vnp_Bill_Email: booking.guestInfo.email,
       vnp_Bill_FirstName: booking.guestInfo.firstName,
       vnp_Bill_LastName: booking.guestInfo.lastName
     };
  
  5. Sort parameters by key:
     const sortedParams = sortObjectByKeys(vnpayParams);
  
  6. Create signature:
     const signatureData = Object.entries(sortedParams)
       .map(([key, value]) => `${key}=${value}`)
       .join('&');
     
     const signature = crypto
       .createHmac('sha512', process.env.VNPAY_SECRET_KEY)
       .update(signatureData)
       .digest('hex')
       .toUpperCase();
  
  7. Build payment URL:
     const paymentUrl = process.env.VNPAY_URL + '?' + 
       Object.entries({ ...sortedParams, vnp_SecureHash: signature })
       .map(([k,v]) => `${k}=${encodeURIComponent(v)}`)
       .join('&');
  
  8. Save transaction info temporarily:
     booking.paymentDetails.vnp_TxnRef = vnpayParams.vnp_TxnRef;
     await booking.save();
  
  9. Return payment URL

Response:
  {
    success: true,
    paymentUrl: "https://sandbox.vnpayment.vn/paygate?...",
    bookingId: "507f1f77bcf86cd799439011"
  }

Flutter WebView:
  - Open payment URL in WebView
  - User enters card details
  - VNPAY processes payment
  - VNPAY redirects to returnUrl


STEP 6: PAYMENT CALLBACK (Return URL)
──────────────────────────────────────

User completes payment on VNPAY
→ VNPAY redirects to return URL with query params:
  
  GET /api/payments/vnpay/return?vnp_Amount=862125000&vnp_BankCode=NCB&...&vnp_SecureHash=ABC123...

Backend Processing (routes/payments.js):

  1. Extract all query parameters
  2. Verify signature:
     - Extract vnp_SecureHash from params
     - Remove vnp_SecureHash from params
     - Recalculate hash based on other params + secret key
     - Compare: recalculated hash === provided hash
     - If mismatch → Signature invalid (possible tampering)
  
  3. Check response code:
     vnp_ResponseCode === '00' → Success
     else → Payment failed
  
  4. Get booking:
     const booking = await Booking.findById(bookingId);
  
  5. Verify amount:
     if (parseInt(vnp_Amount) !== booking.totalAmount * 100) → Amount mismatch
  
  6. Update booking:
     booking.status = 'confirmed';
     booking.paymentStatus = 'paid';
     booking.paymentMethod = 'vnpay';
     booking.transactionId = vnp_TransactionNo;
     booking.confirmedAt = new Date();
     booking.paidAt = new Date();
     booking.paymentDetails = {
       vnp_Amount: vnp_Amount,
       vnp_BankCode: vnp_BankCode,
       vnp_BankTranNo: vnp_BankTranNo,
       vnp_CardType: vnp_CardType,
       vnp_OrderInfo: vnp_OrderInfo,
       vnp_PayDate: vnp_PayDate,
       vnp_ResponseCode: vnp_ResponseCode,
       vnp_TmnCode: vnp_TmnCode,
       vnp_TransactionNo: vnp_TransactionNo,
       vnp_TransactionStatus: vnp_TransactionStatus,
       vnp_TxnRef: vnp_TxnRef,
       vnp_SecureHash: vnp_SecureHash,
       rawResponse: req.query
     };
     
     await booking.save();
  
  7. Update customer membership tier:
     const user = await User.findById(booking.customer);
     user.totalSpent += booking.totalAmount;
     user.updateMembershipTier();
     await user.save();
  
  8. Send confirmation email:
     await sendBookingConfirmation(booking);
  
  9. Redirect to success page:
     if (returnApp) {
       // Redirect to app with deep link
       return res.redirect(`hotelapp://booking-success/${booking._id}`);
     } else {
       // Redirect to web success page
       return res.redirect(`/payment-success?bookingId=${booking._id}`);
     }

Flutter Deep Link Handler:
  - App receives deep link: hotelapp://booking-success/bookingId
  - Parse booking ID
  - Fetch booking details
  - Show success screen with confirmation

Email Sent:
  Subject: "Booking Confirmed - HB172345670001"
  Body includes:
    - Booking number
    - Hotel name & address
    - Check-in/Check-out dates
    - Guest names
    - Total paid amount
    - Confirmation code
    - Hotel contact info
    - Cancel policy
    - QR code (optional)


STEP 7: BOOKING CONFIRMATION
────────────────────────────

Flutter Code:
  Future<Booking> getBookingDetails(String bookingId) async {
    return await apiService.get('/bookings/$bookingId');
  }

Response:
  {
    _id: "...",
    bookingNumber: "HB172345670001",
    status: "confirmed",
    paymentStatus: "paid",
    customer: { firstName, lastName, email },
    hotel: { name, address, phone, email, website },
    room: { name, type, maxGuests },
    checkIn: "2024-01-15T14:00:00Z",
    checkOut: "2024-01-18T12:00:00Z",
    guests: { adults: 2, children: 1 },
    guestInfo: { firstName, lastName, email, phone },
    totalAmount: 8621250,
    paidAt: "2024-01-14T10:35:00Z",
    confirmedAt: "2024-01-14T10:35:00Z",
    paymentDetails: { ... },
    policies: { ... }
  }

Flutter UI (screens/booking/booking_confirmation_screen.dart):
  - Show ✓ Success icon
  - Display booking number (copyable)
  - Show confirmation details
  - Display hotel info
  - Show check-in instructions
  - Show cancellation policy
  - Add to calendar button
  - Share button
  - View booking details button
```

### 5.2.2 Booking Status Transitions

```
PENDING (Initial state)
  └─ Created right after booking is made
  └─ No payment received yet
  └─ User viewing payment screen
  └─ Auto-cancel if payment not completed in 30 minutes

        ↓ (Payment successful)

CONFIRMED
  └─ Payment received and verified
  └─ Email confirmation sent
  └─ Hotel notified
  └─ Can be cancelled (with refund policy applied)
  
        ├─ (User cancels before check-in)
        │  └─ CANCELLED (refund calculated)
        │
        └─ (Check-in date arrives)
           └─ Ready for CHECK_IN

        ↓ (Guest checks in)

CHECKED_IN
  └─ Guest arrived and verified
  └─ Room key/code provided
  └─ Check-out time set
  
        ↓ (Guest checks out)

CHECKED_OUT
  └─ Final status
  └─ Review window opens (15 minutes after checkout)
  └─ Booking completed


Alternative Paths:

PENDING → CANCELLED (if user cancels or payment fails)
PENDING → EXPIRED (auto-cancel after 30 minutes)
CONFIRMED → NO_SHOW (guest didn't check in by 2 hours after check-in time)
CHECKED_IN → CANCELLED (emergency cancellation, full refund)
```

---

## 6. API Documentation

### 6.1 Authentication Endpoints

#### Register
```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepass123",
  "firstName": "John",
  "lastName": "Doe",
  "phone": "+84901234567",
  "role": "customer" // hoặc "hotel_owner"
}

Response 201:
{
  "message": "User registered successfully",
  "user": {
    "id": "...",
    "email": "user@example.com",
    "firstName": "John",
    "role": "customer",
    "isEmailVerified": false
  },
  "accessToken": "eyJhbGc...",
  "refreshToken": "eyJhbGc..."
}
```

#### Verify OTP
```http
POST /api/auth/verify-otp
Content-Type: application/json

{
  "email": "user@example.com",
  "otp": "123456"
}

Response 200:
{
  "success": true,
  "message": "Email verified successfully"
}
```

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepass123"
}

Response 200:
{
  "success": true,
  "message": "Login successful",
  "user": {
    "id": "...",
    "email": "user@example.com",
    "firstName": "John",
    "membershipTier": "gold"
  },
  "accessToken": "eyJhbGc...",
  "refreshToken": "eyJhbGc..."
}
```

### 6.2 Hotel Endpoints

#### Get All Hotels (Public)
```http
GET /api/hotels?page=1&limit=10&city=HCM&sortBy=rating
```

#### Get Hotel Details
```http
GET /api/hotels/:hotelId
```

#### Create Hotel (Hotel Owner)
```http
POST /api/hotels
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Luxury Hotel",
  "description": "...",
  "starRating": 5,
  "address": {
    "street": "123 Main St",
    "city": "Ho Chi Minh City",
    "country": "Vietnam"
  },
  "phone": "+84901234567",
  "email": "hotel@example.com",
  "amenities": ["wifi", "pool", "gym"]
}
```

### 6.3 Room Endpoints

#### Get Rooms by Hotel
```http
GET /api/rooms/hotel/:hotelId
```

#### Create Room (Hotel Owner)
```http
POST /api/rooms
Authorization: Bearer <token>
Content-Type: application/json

{
  "hotel": "hotelId",
  "name": "Deluxe Room",
  "type": "deluxe",
  "maxGuests": 2,
  "bedType": "king",
  "basePrice": 2500000,
  "weekendPrice": 3500000,
  "totalRooms": 5,
  "amenities": ["wifi", "air_conditioning", "tv"]
}
```

### 6.4 Booking Endpoints

#### Create Booking
```http
POST /api/bookings
Authorization: Bearer <token>
Content-Type: application/json

{
  "room": "roomId",
  "checkIn": "2024-01-15T14:00:00Z",
  "checkOut": "2024-01-18T12:00:00Z",
  "guests": {
    "adults": 2,
    "children": 1
  },
  "guestInfo": {
    "firstName": "John",
    "lastName": "Doe",
    "email": "john@example.com",
    "phone": "+84901234567"
  },
  "paymentMethod": "vnpay"
}

Response 201:
{
  "bookingNumber": "HB172345670001",
  "status": "pending",
  "totalAmount": 7500000,
  "_id": "..."
}
```

#### Get My Bookings
```http
GET /api/bookings/user
Authorization: Bearer <token>

Response 200:
{
  "bookings": [
    {
      "bookingNumber": "HB172345670001",
      "hotel": {...},
      "room": {...},
      "checkIn": "2024-01-15T14:00:00Z",
      "checkOut": "2024-01-18T12:00:00Z",
      "status": "confirmed",
      "paymentStatus": "paid"
    }
  ]
}
```

#### Cancel Booking
```http
DELETE /api/bookings/:bookingId
Authorization: Bearer <token>

Response 200:
{
  "success": true,
  "message": "Booking cancelled successfully",
  "refundAmount": 7000000
}
```

### 6.5 Payment Endpoints

#### Create VNPay Payment URL
```http
POST /api/payments/vnpay/create
Authorization: Bearer <token>
Content-Type: application/json

{
  "bookingId": "...",
  "bankCode": "",
  "language": "vn"
}

Response 200:
{
  "paymentUrl": "https://sandbox.vnpayment.vn/paygate?...",
  "bookingId": "..."
}
```

#### VNPay Return (Callback)
```http
GET /api/payments/vnpay/return?vnp_ResponseCode=00&vnp_TransactionNo=...

(VNPAY redirects here after payment)
- Backend verifies secure hash
- Updates booking status
- Sends confirmation email
```

### 6.6 Review Endpoints

#### Create Review
```http
POST /api/reviews
Authorization: Bearer <token>
Content-Type: application/json

{
  "hotel": "hotelId",
  "booking": "bookingId",
  "rating": 5,
  "comment": "Great hotel!",
  "title": "Excellent experience"
}
```

#### Get Hotel Reviews
```http
GET /api/reviews/hotel/:hotelId

Response 200:
{
  "reviews": [
    {
      "rating": 5,
      "comment": "Great hotel!",
      "author": {
        "firstName": "John",
        "avatar": "..."
      },
      "createdAt": "2024-01-15T10:30:00Z"
    }
  ],
  "averageRating": 4.5,
  "totalReviews": 45
}
```

---

## 7. Database Schema

### 7.1 User Model

```javascript
{
  _id: ObjectId,
  
  // Basic Info
  email: String (unique),
  password: String (hashed),
  firstName: String,
  lastName: String,
  phone: String,
  role: String enum['customer', 'hotel_owner', 'admin'],
  avatar: String (URL),
  
  // Address
  address: {
    street: String,
    city: String,
    state: String,
    country: String,
    zipCode: String
  },
  
  // Email Verification
  isEmailVerified: Boolean (default: false),
  emailVerificationOTP: String,
  emailVerificationOTPExpires: Date,
  
  // Password Reset
  passwordResetOTP: String,
  passwordResetOTPExpires: Date,
  
  // Customer Fields
  membershipTier: String enum['bronze', 'silver', 'gold', 'diamond'],
  totalSpent: Number (VND),
  favoriteHotels: [ObjectId ref: 'Hotel'],
  
  // Hotel Owner Fields
  businessLicense: String,
  identityDocument: String,
  isApproved: Boolean (default: false),
  
  // Auth
  refreshToken: String,
  lastLogin: Date,
  isActive: Boolean (default: true),
  
  // Timestamps
  createdAt: Date,
  updatedAt: Date
}
```

### 7.2 Hotel Model

```javascript
{
  _id: ObjectId,
  
  // Info
  name: String,
  description: String,
  owner: ObjectId ref: 'User',
  slug: String (unique),
  
  // Address
  address: {
    street: String,
    city: String,
    state: String,
    country: String,
    zipCode: String,
    coordinates: { latitude, longitude }
  },
  
  // Details
  starRating: Number (3-5),
  images: [{
    url: String,
    caption: String,
    isPrimary: Boolean
  }],
  
  // Amenities
  amenities: [String] enum[...],
  
  // Policies
  checkInTime: String (default: '14:00'),
  checkOutTime: String (default: '12:00'),
  cancellationPolicy: String enum['flexible', 'moderate', 'strict'],
  
  // Contact
  phone: String,
  email: String,
  website: String,
  
  // Status
  isApproved: Boolean (default: false),
  isActive: Boolean (default: true),
  
  // Stats
  totalRooms: Number,
  averageRating: Number (0-5),
  totalReviews: Number,
  
  // Timestamps
  createdAt: Date,
  updatedAt: Date
}
```

### 7.3 Room Model

```javascript
{
  _id: ObjectId,
  
  hotel: ObjectId ref: 'Hotel',
  name: String,
  type: String enum['standard', 'deluxe', 'suite', 'executive', 'presidential'],
  description: String,
  
  // Capacity
  maxGuests: Number,
  bedType: String enum['single', 'double', 'queen', 'king', 'twin'],
  bedCount: Number,
  
  // Pricing
  basePrice: Number,
  weekendPrice: Number,
  currency: String (default: 'VND'),
  
  // Features
  size: Number (sqm),
  amenities: [String] enum[...],
  images: [{
    url: String,
    caption: String,
    isPrimary: Boolean
  }],
  
  // Inventory
  totalRooms: Number,
  
  // Offers
  discountPercentage: Number (0-100),
  specialOfferDescription: String,
  
  // Status
  isActive: Boolean (default: true),
  
  // Timestamps
  createdAt: Date,
  updatedAt: Date
}
```

### 7.4 Booking Model

```javascript
{
  _id: ObjectId,
  
  // References
  customer: ObjectId ref: 'User',
  hotel: ObjectId ref: 'Hotel',
  room: ObjectId ref: 'Room',
  
  // Booking Info
  bookingNumber: String (unique),
  checkIn: Date,
  checkOut: Date,
  guests: {
    adults: Number,
    children: Number
  },
  
  // Guest Info
  guestInfo: {
    firstName: String,
    lastName: String,
    email: String,
    phone: String,
    specialRequests: String
  },
  
  // Pricing
  roomPrice: Number,
  nights: Number,
  subtotal: Number,
  discountAmount: Number,
  discountPercentage: Number,
  taxAmount: Number,
  totalAmount: Number,
  currency: String,
  
  // Status
  status: String enum['pending', 'confirmed', 'cancelled', 'checked_in', 'checked_out'],
  paymentStatus: String enum['pending', 'paid', 'failed', 'refunded'],
  paymentMethod: String enum['vnpay', 'stripe', 'cash'],
  
  // Payment Details
  transactionId: String,
  paidAt: Date,
  paymentDetails: {
    vnp_Amount: String,
    vnp_BankCode: String,
    vnp_TransactionNo: String,
    ...
  },
  
  // Cancellation
  cancellationReason: String,
  cancellationDate: Date,
  refundAmount: Number,
  
  // Timestamps
  confirmedAt: Date,
  checkedInAt: Date,
  checkedOutAt: Date,
  createdAt: Date,
  updatedAt: Date
}
```

### 7.5 Review Model

```javascript
{
  _id: ObjectId,
  
  hotel: ObjectId ref: 'Hotel',
  booking: ObjectId ref: 'Booking',
  author: ObjectId ref: 'User',
  
  // Review Content
  rating: Number (1-5),
  title: String,
  comment: String,
  images: [String] (URLs),
  
  // Moderation
  isApproved: Boolean (default: true),
  isHelpful: Number (default: 0),
  
  // Timestamps
  createdAt: Date,
  updatedAt: Date
}
```

---

## 8. Authentication Flow

### 8.1 JWT Token Strategy

```
Access Token (Short-lived: 15 minutes)
├─ Payload: { id: userId }
├─ Secret: JWT_SECRET
└─ Expires: 15m

Refresh Token (Long-lived: 7 days)
├─ Payload: { id: userId }
├─ Secret: JWT_REFRESH_SECRET
├─ Expires: 7d
└─ Stored in: Database (User.refreshToken)
```

### 8.2 Token Refresh Mechanism

```
1. User makes API request
   ↓
2. Backend checks Authorization header
   ↓
3. Token expired?
   ├─ YES → Return 401 Unauthorized
   │   ↓
   │   Client calls: POST /api/auth/refresh-token
   │   with refreshToken
   │   ↓
   │   Backend verifies refreshToken
   │   ├─ Valid → Generate new accessToken
   │   ├─ Invalid → Return 401 (login again)
   │   ↓
   │   Client saves new accessToken
   │   ↓
   │   Retry original request with new token
   │
   └─ NO → Continue to next middleware
```

### 8.3 Flutter AuthProvider Implementation

```dart
// File: lib/providers/auth_provider.dart

class AuthProvider with ChangeNotifier {
  AuthState _state = AuthState.initial;
  User? _currentUser;
  
  // Getters
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;
  
  // Initialize on app start
  Future<void> initialize() async {
    _setState(AuthState.loading);
    try {
      if (ApiService().isLoggedIn) {
        _currentUser = await _apiService.getUserFromStorage();
        if (_currentUser != null) {
          // Verify token is still valid
          final user = await _apiService.getCurrentUser();
          if (user != null) {
            _currentUser = user;
            _setState(AuthState.authenticated);
          } else {
            await logout();
          }
        }
      }
    } catch (e) {
      _setState(AuthState.unauthenticated);
    }
  }
  
  // Login
  Future<bool> login(String email, String password) async {
    _setState(AuthState.loading);
    try {
      final response = await _apiService.login(
        LoginRequest(email: email, password: password)
      );
      
      if (response.success && response.user?.isEmailVerified == true) {
        _currentUser = response.user;
        _setState(AuthState.authenticated);
        return true;
      }
      return false;
    } catch (e) {
      _setError('Login failed');
      _setState(AuthState.unauthenticated);
      return false;
    }
  }
  
  // Logout
  Future<void> logout() async {
    try {
      await _apiService.logout();
    } finally {
      _currentUser = null;
      _setState(AuthState.unauthenticated);
      notifyListeners();
    }
  }
}
```

---

## 9. Feature Details

### 9.1 Hotel Search & Filter

```dart
// lib/providers/hotel_provider.dart

Future<void> searchHotels({
  String? city,
  String? searchQuery,
  double? minPrice,
  double? maxPrice,
  int? starRating,
  List<String>? amenities,
  String sortBy = 'rating',
  int page = 1,
  int limit = 10,
}) async {
  try {
    final params = {
      if (city != null) 'city': city,
      if (searchQuery != null) 'search': searchQuery,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (starRating != null) 'starRating': starRating,
      if (amenities != null) 'amenities': amenities.join(','),
      'sortBy': sortBy,
      'page': page,
      'limit': limit,
    };
    
    _hotels = await _apiService.getHotels(params);
    notifyListeners();
  } catch (e) {
    print('Error searching hotels: $e');
  }
}
```

### 9.2 Payment Integration (VNPAY)

```dart
// lib/services/payment_service.dart

Future<String?> createVNPaymentUrl(
  String bookingId, {
  String? bankCode,
  String language = 'vn',
}) async {
  try {
    final response = await _apiService.post(
      '/payments/vnpay/create',
      data: {
        'bookingId': bookingId,
        'bankCode': bankCode,
        'language': language,
      },
    );
    
    return response['paymentUrl'] as String?;
  } catch (e) {
    print('Error creating VNPAY URL: $e');
    return null;
  }
}

// Open VNPAY in WebView
Future<bool> openVNPayPayment(String paymentUrl) async {
  // Navigate to WebView screen
  // User completes payment
  // VNPAY redirects back to app with payment result
  // Backend processes callback
}
```

### 9.3 Chatbot Integration (Gemini AI)

```javascript
// Backend: routes/chatbot.js

const { GoogleGenerativeAI } = require('@google/generative-ai');

router.post('/ask', authenticate, asyncHandler(async (req, res) => {
  const { question } = req.body;
  
  // Get hotel data from database
  const hotels = await Hotel.find().limit(50);
  const hotelsContext = JSON.stringify(hotels);
  
  const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
  const model = genAI.getGenerativeModel({ model: 'gemini-pro' });
  
  const systemPrompt = `You are a helpful hotel booking assistant. 
    Use this hotel data to answer questions: ${hotelsContext}
    Recommend hotels based on user preferences.
    Provide information about prices, amenities, and locations.`;
  
  const result = await model.generateContent(systemPrompt + question);
  
  res.json({
    response: result.response.text(),
    timestamp: new Date()
  });
}));
```

### 9.4 Localization (Multi-language)

```dart
// lib/providers/locale_provider.dart

class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('en');
  
  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString('app_language');
    
    if (savedLocale != null) {
      _locale = Locale(savedLocale);
    } else {
      // Get device locale
      _locale = Locale(window.locale.languageCode);
    }
    notifyListeners();
  }
  
  Future<void> changeLocale(String languageCode) async {
    _locale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', languageCode);
    notifyListeners();
  }
}

// Usage in App
MaterialApp(
  locale: localeProvider.locale,
  localizationsDelegates: [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
  ],
  supportedLocales: [
    Locale('en'),
    Locale('vi'),
  ],
)
```

### 9.5 Real-time Chat (Socket.io)

```javascript
// Backend: server.js

const io = require('socket.io')(server, {
  cors: { origin: [process.env.CLIENT_URL, process.env.ADMIN_URL] }
});

io.on('connection', (socket) => {
  console.log('User connected:', socket.id);
  
  // Join hotel chat room
  socket.on('join_hotel_chat', (hotelId) => {
    socket.join(`hotel_${hotelId}`);
  });
  
  // Send message to hotel room
  socket.on('send_message', (data) => {
    socket.to(`hotel_${data.hotelId}`).emit('receive_message', {
      sender: data.sender,
      message: data.message,
      timestamp: new Date(),
      hotelId: data.hotelId
    });
  });
  
  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});
```

```dart
// Flutter: lib/services/api_service.dart

class ChatService {
  late IO.Socket socket;
  
  void initSocket(String userId) {
    socket = IO.io(
      'http://10.0.2.2:5000',
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build(),
    );
    
    socket.onConnect((_) {
      print('Connected to chat server');
    });
    
    socket.on('receive_message', (data) {
      // Handle incoming message
      print('New message: ${data['message']}');
    });
    
    socket.connect();
  }
  
  void joinHotelChat(String hotelId) {
    socket.emit('join_hotel_chat', hotelId);
  }
  
  void sendMessage(String hotelId, String message) {
    socket.emit('send_message', {
      'hotelId': hotelId,
      'sender': userId,
      'message': message
    });
  }
}
```

---

## 10. Deployment Guide

### 10.1 Backend Deployment (Heroku / AWS / DigitalOcean)

#### Using Heroku

```bash
# 1. Install Heroku CLI
# https://devcenter.heroku.com/articles/heroku-cli

# 2. Login
heroku login

# 3. Create app
heroku create hotel-booking-api

# 4. Set environment variables
heroku config:set MONGODB_URI=mongodb+srv://...
heroku config:set JWT_SECRET=your_secret
heroku config:set EMAIL_USER=your_email@gmail.com
heroku config:set EMAIL_PASS=your_app_password
# ... set all other env vars

# 5. Deploy
git push heroku main

# 6. View logs
heroku logs --tail
```

#### Using Docker

```dockerfile
# Dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .

EXPOSE 5000

CMD ["npm", "start"]
```

```bash
# Build and push to Docker Hub
docker build -t your-username/hotel-booking-api .
docker push your-username/hotel-booking-api

# Deploy on DigitalOcean / AWS ECR / etc
```

### 10.2 Flutter App Deployment

#### Android Release Build

```bash
cd flutter_client/hotel_booking_app

# Build APK
flutter build apk --release

# Build App Bundle (for Google Play)
flutter build appbundle --release

# Output: build/app/outputs/flutter-app/release/
```

**Upload to Google Play Store:**
1. Create Google Play Developer account
2. Create new app
3. Upload App Bundle (AAB)
4. Fill in store listing details
5. Review and publish

#### iOS Release Build

```bash
flutter build ios --release

# Or use Xcode
# 1. Open ios/Runner.xcworkspace
# 2. Set signing certificate
# 3. Set bundle identifier
# 4. Set version/build number
# 5. Archive and upload to App Store
```

### 10.3 React Admin Web Deployment

#### Build for Production

```bash
cd frontend/admin-web

# Build
npm run build

# Output: build/
```

#### Deploy to Vercel

```bash
npm install -g vercel
vercel
# Follow prompts to deploy
```

#### Deploy to Netlify

```bash
# Via Netlify CLI
npm install -g netlify-cli
netlify deploy --prod --dir=build

# Or drag & drop build folder to Netlify
```

#### Deploy to AWS S3 + CloudFront

```bash
# Upload build to S3
aws s3 sync build/ s3://your-bucket-name --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"
```

### 10.4 Production Checklist

- [ ] All environment variables set correctly
- [ ] Database backups configured
- [ ] API rate limiting enabled
- [ ] SSL/HTTPS certificates installed
- [ ] CORS configured properly
- [ ] Logging and monitoring setup
- [ ] Error handling and alerting
- [ ] Database indexes optimized
- [ ] Images optimized and cached
- [ ] Security headers enabled
- [ ] API documentation updated
- [ ] User data privacy verified
- [ ] Payment gateway tested in production
- [ ] Email delivery tested
- [ ] Automated tests passing

---

## 11. Troubleshooting

### 11.1 Common Issues

#### Issue: "Cannot connect to API"

```
Solution:
1. Check if backend server is running: http://localhost:5000
2. Verify API_BASE_URL in app config
3. Check CORS settings in server.js
4. For mobile: Use correct IP (10.0.2.2 for Android emulator)
5. Check firewall/antivirus blocking
```

#### Issue: "Token expired but doesn't refresh"

```
Solution:
1. Check JWT_SECRET matches in backend
2. Verify refresh token is saved in localStorage/SharedPreferences
3. Check refresh token route returns new accessToken
4. Ensure interceptor handles 401 response
```

#### Issue: "Payment not working"

```
Solution:
1. Verify VNPAY credentials in .env
2. Check VNPAY_RETURN_URL matches backend setting
3. Test in VNPAY sandbox first
4. Check browser console for payment gateway errors
5. Verify booking is created before payment
```

#### Issue: "OTP not received"

```
Solution:
1. Check Gmail app password (not regular password)
2. Enable Less Secure Apps (if using old Gmail account)
3. Check EMAIL_USER and EMAIL_PASS in .env
4. Verify email regex validation
5. Check spam folder
```

### 11.2 Debug Tips

```bash
# Backend - Check logs
npm run dev # Shows detailed logs

# Check MongoDB connection
# Add console.log in mongoose connection

# Flutter - Enable debug logs
flutter run -v

# React - Chrome DevTools
F12 in browser

# Check API calls
# Network tab in DevTools

# Check local storage
# Application tab > Local Storage
```

---

## 12. Contributing Guidelines

### Code Style

- **JavaScript**: ESLint configured
- **Dart/Flutter**: dartfmt, effective_dart
- **React**: ESLint + Prettier

### Git Workflow

```bash
# Create feature branch
git checkout -b feature/feature-name

# Make changes
# Commit regularly
git add .
git commit -m "feat: description"

# Push
git push origin feature/feature-name

# Create Pull Request on GitHub
```

### Testing

```bash
# Backend
npm test

# Flutter
flutter test

# React
npm test
```

---

## 10. Code Examples & Implementation Details

### 10.1 Backend API Complete Examples with Error Handling

#### Register Endpoint Implementation

```javascript
router.post('/register', registerValidation, validate, asyncHandler(async (req, res) => {
  const { email, password, firstName, lastName, phone, role = 'customer' } = req.body;
  
  // Check if user exists
  const existingUser = await User.findOne({ email });
  if (existingUser) {
    return res.status(400).json({
      success: false,
      message: 'User already exists with this email',
      error: 'DUPLICATE_EMAIL'
    });
  }
  
  // Create user
  const user = new User({
    email: email.toLowerCase(),
    password, // Will be hashed by pre-save middleware
    firstName: firstName.trim(),
    lastName: lastName.trim(),
    phone,
    role: role === 'hotel_owner' ? 'hotel_owner' : 'customer'
  });
  
  // Generate OTP
  const otp = generateOTP();
  user.emailVerificationOTP = otp;
  user.emailVerificationOTPExpires = Date.now() + 10 * 60 * 1000;
  
  await user.save();
  
  // Generate tokens
  const { accessToken, refreshToken } = generateTokens(user._id);
  user.refreshToken = refreshToken;
  await user.save();
  
  // Send OTP email
  try {
    await sendOTP(email, otp, firstName);
  } catch (error) {
    console.error('Email sending failed:', error);
  }
  
  return res.status(201).json({
    success: true,
    message: 'User registered. Please verify your email.',
    user: { id: user._id, email, firstName, role },
    accessToken,
    refreshToken
  });
}));
```

#### Error Codes & Response Format

```javascript
// SUCCESS RESPONSES

// 200 OK
{ "success": true, "message": "...", "data": {...} }

// 201 CREATED
{ "success": true, "message": "Resource created", "data": {...} }


// ERROR RESPONSES

// 400 BAD REQUEST
{
  "success": false,
  "message": "Invalid request",
  "error": "INVALID_INPUT",
  "details": {
    "field": "email",
    "message": "Invalid email format"
  }
}

// 401 UNAUTHORIZED
{
  "success": false,
  "message": "Authentication required",
  "error": "INVALID_TOKEN"
}

// 403 FORBIDDEN
{
  "success": false,
  "message": "You don't have permission",
  "error": "INSUFFICIENT_PERMISSIONS"
}

// 404 NOT FOUND
{
  "success": false,
  "message": "Resource not found",
  "error": "RESOURCE_NOT_FOUND"
}

// 429 TOO MANY REQUESTS
{
  "success": false,
  "message": "Rate limit exceeded",
  "error": "RATE_LIMIT_EXCEEDED",
  "retryAfter": 60
}

// 500 INTERNAL SERVER ERROR
{
  "success": false,
  "message": "Internal server error",
  "error": "SERVER_ERROR"
}
```

### 10.2 Flutter API Service Implementation

```dart
class ApiService {
  static final ApiService _instance = ApiService._internal();
  
  late Dio _dio;
  late SharedPreferences _prefs;
  
  factory ApiService() {
    return _instance;
  }
  
  ApiService._internal();
  
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        contentType: 'application/json',
      ),
    );
    
    // Add interceptors
    _dio.interceptors.add(AuthInterceptor(_dio, _prefs));
    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }
  
  bool get isLoggedIn {
    final token = _prefs.getString(AppConstants.keyAccessToken);
    return token != null && token.isNotEmpty;
  }
  
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _prefs.setString(AppConstants.keyAccessToken, accessToken);
    await _prefs.setString(AppConstants.keyRefreshToken, refreshToken);
  }
  
  Future<AuthResponse> login(LoginRequest request) async {
    final response = await _dio.post(
      '/auth/login',
      data: request.toJson(),
    );
    
    return AuthResponse.fromJson(response.data);
  }
  
  Future<AuthResponse> register(RegisterRequest request) async {
    final response = await _dio.post(
      '/auth/register',
      data: request.toJson(),
    );
    
    return AuthResponse.fromJson(response.data);
  }
  
  Future<User> getCurrentUser() async {
    final response = await _dio.get('/auth/me');
    return User.fromJson(response.data['user']);
  }
  
  Future<void> logout() async {
    await _dio.post('/auth/logout');
    await clearStorage();
  }
  
  Future<void> clearStorage() async {
    await _prefs.remove(AppConstants.keyAccessToken);
    await _prefs.remove(AppConstants.keyRefreshToken);
    await _prefs.remove(AppConstants.keyUserData);
  }
}

// Auth Interceptor - handles token refresh
class AuthInterceptor extends Interceptor {
  final Dio dio;
  final SharedPreferences prefs;
  bool _isRefreshing = false;
  List<RequestInterceptorHandler> _waitingRequests = [];
  
  AuthInterceptor(this.dio, this.prefs);
  
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = prefs.getString(AppConstants.keyAccessToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
  
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 Unauthorized
    if (err.response?.statusCode == 401) {
      if (_isRefreshing) {
        // Wait for token refresh to complete
        _waitingRequests.add(handler);
        return;
      }
      
      _isRefreshing = true;
      
      try {
        final refreshToken = prefs.getString(AppConstants.keyRefreshToken);
        
        if (refreshToken == null) {
          throw Exception('No refresh token');
        }
        
        final response = await dio.post(
          '/auth/refresh-token',
          data: { 'refreshToken': refreshToken },
        );
        
        final newAccessToken = response.data['accessToken'];
        await prefs.setString(AppConstants.keyAccessToken, newAccessToken);
        
        // Retry original request
        final retryResponse = await dio.request(
          err.requestOptions.path,
          options: Options(
            method: err.requestOptions.method,
            headers: { 'Authorization': 'Bearer $newAccessToken' },
          ),
        );
        
        handler.resolve(retryResponse);
        
        // Resume waiting requests
        for (var request in _waitingRequests) {
          request.next(err.requestOptions);
        }
        _waitingRequests.clear();
      } catch (e) {
        // Refresh failed, logout user
        await prefs.clear();
        handler.reject(err);
      } finally {
        _isRefreshing = false;
      }
    } else {
      handler.next(err);
    }
  }
}
```

### 10.3 React Redux Store Setup

```javascript
// frontend/admin-web/src/store/slices/authSlice.js

import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000/api';

// Thunks
export const login = createAsyncThunk(
  'auth/login',
  async ({ email, password }, { rejectWithValue }) => {
    try {
      const response = await axios.post(`${API_URL}/auth/login`, {
        email,
        password,
      });
      
      localStorage.setItem('token', response.data.accessToken);
      localStorage.setItem('refreshToken', response.data.refreshToken);
      
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response.data);
    }
  }
);

export const getCurrentUser = createAsyncThunk(
  'auth/getCurrentUser',
  async (_, { rejectWithValue }) => {
    try {
      const token = localStorage.getItem('token');
      const response = await axios.get(`${API_URL}/auth/me`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response.data);
    }
  }
);

export const logout = createAsyncThunk(
  'auth/logout',
  async (_, { rejectWithValue }) => {
    try {
      const token = localStorage.getItem('token');
      await axios.post(`${API_URL}/auth/logout`, {}, {
        headers: { Authorization: `Bearer ${token}` },
      });
      
      localStorage.clear();
      return null;
    } catch (error) {
      localStorage.clear();
      return null;
    }
  }
);

// Slice
const authSlice = createSlice({
  name: 'auth',
  initialState: {
    user: null,
    isAuthenticated: false,
    loading: false,
    error: null,
  },
  extraReducers: (builder) => {
    // Login
    builder
      .addCase(login.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(login.fulfilled, (state, action) => {
        state.loading = false;
        state.user = action.payload.user;
        state.isAuthenticated = true;
      })
      .addCase(login.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload.message;
        state.isAuthenticated = false;
      });
    
    // Get current user
    builder
      .addCase(getCurrentUser.fulfilled, (state, action) => {
        state.user = action.payload.user;
        state.isAuthenticated = true;
      })
      .addCase(getCurrentUser.rejected, (state) => {
        state.isAuthenticated = false;
        localStorage.clear();
      });
    
    // Logout
    builder
      .addCase(logout.fulfilled, (state) => {
        state.user = null;
        state.isAuthenticated = false;
      });
  },
});

export default authSlice.reducer;
```

---

## 11. Database Queries & Relationships

### 11.1 MongoDB Indexes (Performance Optimization)

```javascript
// models/User.js
userSchema.index({ email: 1 }, { unique: true });
userSchema.index({ role: 1 });
userSchema.index({ membershipTier: 1 });
userSchema.index({ createdAt: -1 });

// models/Hotel.js
hotelSchema.index({ owner: 1 });
hotelSchema.index({ slug: 1 }, { unique: true });
hotelSchema.index({ isApproved: 1, isActive: 1 });
hotelSchema.index({ 'address.city': 1 });
hotelSchema.index({ starRating: 1 });
hotelSchema.index({ averageRating: -1 });
hotelSchema.index({ createdAt: -1 });

// models/Room.js
roomSchema.index({ hotel: 1 });
roomSchema.index({ type: 1 });
roomSchema.index({ isActive: 1 });
roomSchema.index({ createdAt: -1 });

// models/Booking.js
bookingSchema.index({ customer: 1 });
bookingSchema.index({ hotel: 1 });
bookingSchema.index({ room: 1 });
bookingSchema.index({ status: 1 });
bookingSchema.index({ paymentStatus: 1 });
bookingSchema.index({ bookingNumber: 1 }, { unique: true });
bookingSchema.index({ transactionId: 1 });
bookingSchema.index({ checkIn: 1, checkOut: 1 }); // For availability queries
bookingSchema.index({ createdAt: -1 });
```

### 11.2 Complex MongoDB Queries

```javascript
// Query 1: Find available rooms for date range
const findAvailableRooms = async (hotelId, checkIn, checkOut) => {
  const overlappingBookings = await Booking.countDocuments({
    hotel: hotelId,
    $and: [
      { checkIn: { $lt: new Date(checkOut) } },
      { checkOut: { $gt: new Date(checkIn) } }
    ],
    $or: [
      { status: { $in: ['confirmed', 'checked_in'] } },
      { status: 'pending', createdAt: { $gte: new Date(Date.now() - 30*60*1000) } }
    ]
  });
  
  return await Room.find({ hotel: hotelId, isActive: true })
    .select('name type maxGuests basePrice weekendPrice totalRooms')
    .lean();
};

// Query 2: Get hotel with stats
const getHotelWithStats = async (hotelId) => {
  const hotel = await Hotel.findById(hotelId)
    .populate('owner', 'firstName lastName email')
    .lean();
  
  const stats = await Booking.aggregate([
    { $match: { hotel: hotelId } },
    {
      $group: {
        _id: '$hotel',
        totalBookings: { $sum: 1 },
        totalRevenue: { $sum: '$totalAmount' },
        completedBookings: {
          $sum: { $cond: [{ $eq: ['$status', 'confirmed'] }, 1, 0] }
        },
        paidBookings: {
          $sum: { $cond: [{ $eq: ['$paymentStatus', 'paid'] }, 1, 0] }
        }
      }
    }
  ]);
  
  return { ...hotel, stats: stats[0] || {} };
};

// Query 3: Get user membership tier progression
const getUserMembershipInfo = async (userId) => {
  const bookings = await Booking.aggregate([
    { $match: { customer: userId, paymentStatus: 'paid' } },
    {
      $group: {
        _id: '$customer',
        totalSpent: { $sum: '$totalAmount' },
        totalBookings: { $sum: 1 },
        averageSpending: { $avg: '$totalAmount' }
      }
    }
  ]);
  
  const user = await User.findById(userId)
    .select('membershipTier totalSpent');
  
  return { user, stats: bookings[0] || {} };
};

// Query 4: Get dashboard statistics for admin
const getDashboardStats = async () => {
  const totalUsers = await User.countDocuments({ role: 'customer' });
  const totalHotels = await Hotel.countDocuments({ isApproved: true });
  const totalRooms = await Room.countDocuments({ isActive: true });
  const totalBookings = await Booking.countDocuments();
  
  const revenueStats = await Booking.aggregate([
    { $match: { paymentStatus: 'paid' } },
    {
      $group: {
        _id: { $dateToString: { format: '%Y-%m', date: '$paidAt' } },
        revenue: { $sum: '$totalAmount' },
        bookings: { $sum: 1 }
      }
    },
    { $sort: { _id: -1 } },
    { $limit: 12 }
  ]);
  
  return {
    totalUsers,
    totalHotels,
    totalRooms,
    totalBookings,
    revenueStats
  };
};
```

---

## 12. Security Implementation

### 12.1 Password Security

```javascript
// models/User.js
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  
  // Check if already hashed
  if (this.password.match(/^\$2[abyxy]?\$/)) {
    return next();
  }
  
  try {
    const salt = await bcrypt.genSalt(12); // 12 rounds
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Verify password
userSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};
```

### 12.2 JWT Token Security

```javascript
// utils/auth.js
const generateTokens = (userId) => {
  // Access token (short-lived: 15 minutes)
  const accessToken = jwt.sign(
    { id: userId },
    process.env.JWT_SECRET,
    {
      expiresIn: '15m',
      algorithm: 'HS256'
    }
  );
  
  // Refresh token (long-lived: 7 days)
  const refreshToken = jwt.sign(
    { id: userId },
    process.env.JWT_REFRESH_SECRET,
    {
      expiresIn: '7d',
      algorithm: 'HS256'
    }
  );
  
  return { accessToken, refreshToken };
};

// Verify token with security checks
const verifyToken = (token, secret) => {
  try {
    return jwt.verify(token, secret, { algorithms: ['HS256'] });
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      throw new Error('Token expired');
    }
    throw new Error('Invalid token');
  }
};
```

### 12.3 Rate Limiting

```javascript
// server.js
const rateLimit = require('express-rate-limit');

// General rate limiter
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  message: 'Too many requests, please try again later',
  standardHeaders: true, // Return rate limit info
  legacyHeaders: false,
});

// Login limiter (stricter)
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 attempts per 15 minutes
  skipSuccessfulRequests: true,
  message: 'Too many login attempts, try again later'
});

// Payment limiter
const paymentLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 10,
  message: 'Too many payment requests'
});

app.use(generalLimiter);
app.post('/api/auth/login', loginLimiter, ...);
app.post('/api/payments/vnpay/create', paymentLimiter, ...);
```

### 12.4 Input Validation & Sanitization

```javascript
// middleware/validation.js
const { body, validationResult } = require('express-validator');

const registerValidation = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Invalid email address'),
  
  body('password')
    .isLength({ min: 6, max: 50 })
    .withMessage('Password must be 6-50 characters')
    .matches(/^(?=.*[A-Za-z])(?=.*\d)/)
    .withMessage('Password must contain letters and numbers'),
  
  body('firstName')
    .trim()
    .isLength({ min: 2, max: 50 })
    .matches(/^[a-zA-Z\s]+$/)
    .withMessage('First name must contain only letters'),
  
  body('lastName')
    .trim()
    .isLength({ min: 2, max: 50 })
    .matches(/^[a-zA-Z\s]+$/)
    .withMessage('Last name must contain only letters'),
  
  body('phone')
    .isMobilePhone('vi-VN')
    .withMessage('Invalid Vietnamese phone number')
];

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: 'Validation error',
      errors: errors.array().map(err => ({
        field: err.param,
        message: err.msg
      }))
    });
  }
  next();
};
```

### 12.5 CORS Configuration

```javascript
// server.js
const cors = require('cors');

const corsOptions = {
  origin: function(origin, callback) {
    const allowedOrigins = [
      process.env.CLIENT_URL || 'http://localhost:3000',
      process.env.ADMIN_URL || 'http://localhost:3001',
      process.env.MOBILE_APP_SCHEME || 'hotelapp://'
    ];
    
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  optionsSuccessStatus: 200
};

app.use(cors(corsOptions));
app.options('*', cors(corsOptions)); // Handle preflight
```

---

## 13. Testing Guide

### 13.1 Backend Testing (Jest)

```javascript
// tests/auth.test.js
const request = require('supertest');
const app = require('../server');
const User = require('../models/User');

describe('Auth Endpoints', () => {
  beforeAll(async () => {
    // Connect to test database
  });
  
  afterEach(async () => {
    // Clear test data
    await User.deleteMany({});
  });
  
  describe('POST /api/auth/register', () => {
    it('should register a new user', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'test@example.com',
          password: 'Test123',
          firstName: 'John',
          lastName: 'Doe',
          phone: '+84901234567'
        });
      
      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.user.email).toBe('test@example.com');
      expect(res.body.accessToken).toBeDefined();
    });
    
    it('should reject duplicate email', async () => {
      // Create first user
      await User.create({...});
      
      // Try to create with same email
      const res = await request(app)
        .post('/api/auth/register')
        .send({...});
      
      expect(res.status).toBe(400);
      expect(res.body.error).toBe('DUPLICATE_EMAIL');
    });
  });
  
  describe('POST /api/auth/login', () => {
    it('should login successfully', async () => {
      // Create user
      await User.create({...});
      
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'test@example.com',
          password: 'Test123'
        });
      
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });
  });
});
```

### 13.2 Flutter Widget Testing

```dart
// test/screens/login_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hotel_booking_app/screens/auth/login_screen.dart';
import 'package:hotel_booking_app/providers/auth_provider.dart';

void main() {
  group('LoginScreen', () => {
    testWidgets('should display email and password fields', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider())
          ],
          child: MaterialApp(
            home: LoginScreen()
          )
        )
      );
      
      expect(find.byType(TextField), findsWidgets);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
    
    testWidgets('should show error on invalid email', (tester) async {
      await tester.pumpWidget(...);
      
      // Enter invalid email
      await tester.enterText(find.byType(TextField).first, 'invalid-email');
      
      // Tap login button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      
      // Verify error message shown
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
```

### 13.3 React Component Testing (React Testing Library)

```javascript
// frontend/admin-web/src/__tests__/LoginPage.test.js
import { render, screen, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import Login from '../pages/Login/Login';

describe('Login Page', () => {
  it('should render login form', () => {
    render(<Login />);
    
    expect(screen.getByPlaceholderText(/email/i)).toBeInTheDocument();
    expect(screen.getByPlaceholderText(/password/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /login/i })).toBeInTheDocument();
  });
  
  it('should show error on invalid credentials', async () => {
    render(<Login />);
    
    const emailInput = screen.getByPlaceholderText(/email/i);
    const passwordInput = screen.getByPlaceholderText(/password/i);
    const loginButton = screen.getByRole('button', { name: /login/i });
    
    await userEvent.type(emailInput, 'test@example.com');
    await userEvent.type(passwordInput, 'wrongpassword');
    fireEvent.click(loginButton);
    
    expect(await screen.findByText(/invalid credentials/i)).toBeInTheDocument();
  });
});
```

---

## 14. Performance Optimization

### 14.1 Backend Optimization

```javascript
// Connection pooling
const mongoose = require('mongoose');

mongoose.connect(process.env.MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
  maxPoolSize: 10,
  minPoolSize: 5,
  socketTimeoutMS: 45000,
});

// Query optimization - Use lean() for read-only queries
const hotels = await Hotel.find()
  .select('name starRating images averageRating') // Select only needed fields
  .lean() // Return plain JS objects (faster)
  .limit(20)
  .exec();

// Use aggregation pipeline for complex queries
const stats = await Booking.aggregate([
  { $match: { hotel: hotelId } },
  {
    $group: {
      _id: '$hotel',
      totalRevenue: { $sum: '$totalAmount' },
      avgBookingValue: { $avg: '$totalAmount' }
    }
  }
]);

// Caching with Redis (optional)
const redis = require('redis');
const client = redis.createClient();

app.get('/api/hotels', async (req, res) => {
  const cacheKey = `hotels:${JSON.stringify(req.query)}`;
  
  // Check cache
  const cached = await client.get(cacheKey);
  if (cached) {
    return res.json(JSON.parse(cached));
  }
  
  // Query DB
  const hotels = await Hotel.find(...);
  
  // Cache for 1 hour
  await client.setex(cacheKey, 3600, JSON.stringify(hotels));
  
  res.json(hotels);
});
```

### 14.2 Flutter Performance

```dart
// Use const constructors
const Text('Hello')

// Lazy load images
CachedNetworkImage(
  imageUrl: 'https://...',
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
)

// Use ListView.builder instead of ListView
ListView.builder(
  itemCount: hotels.length,
  itemBuilder: (context, index) => HotelCard(hotel: hotels[index]),
)

// Paginate data
Future<void> loadMore() {
  _currentPage++;
  _hotels.addAll(await fetchHotels(_currentPage));
}

// Use Isolates for heavy computation
Future<List<Hotel>> filterHotels(List<Hotel> hotels) async {
  return await compute(_filterHotelsIsolate, hotels);
}

List<Hotel> _filterHotelsIsolate(List<Hotel> hotels) {
  return hotels.where((h) => h.averageRating >= 4.0).toList();
}
```

### 14.3 React Performance

```javascript
// Use React.memo for pure components
export const HotelCard = React.memo(({ hotel }) => (
  <div>{hotel.name}</div>
));

// Use useMemo for expensive calculations
const filteredHotels = useMemo(() => {
  return hotels.filter(h => h.price <= maxPrice);
}, [hotels, maxPrice]);

// Use useCallback for stable function references
const handleSearch = useCallback((query) => {
  searchHotels(query);
}, []);

// Lazy load components
const AdminDashboard = lazy(() => import('./pages/AdminDashboard'));

<Suspense fallback={<Loading />}>
  <AdminDashboard />
</Suspense>
```

---

## 15. Docker & CI/CD

### 15.1 Docker Compose Setup

```yaml
# docker-compose.yml
version: '3.8'

services:
  # MongoDB
  mongo:
    image: mongo:5.0
    container_name: hotel_booking_db
    ports:
      - "27017:27017"
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: admin123
    volumes:
      - mongo_data:/data/db

  # Backend
  backend:
    build: .
    container_name: hotel_booking_api
    ports:
      - "5000:5000"
    environment:
      NODE_ENV: development
      MONGODB_URI: mongodb://admin:admin123@mongo:27017/hotel_booking?authSource=admin
      JWT_SECRET: your_jwt_secret_here
    depends_on:
      - mongo
    volumes:
      - .:/app
      - /app/node_modules

  # Redis (for caching)
  redis:
    image: redis:7-alpine
    container_name: hotel_booking_cache
    ports:
      - "6379:6379"

volumes:
  mongo_data:
```

### 15.2 GitHub Actions CI/CD

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v2
      
      - name: Set up Node
        uses: actions/setup-node@v2
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run tests
        run: npm test
      
      - name: Build
        run: npm run build
      
      - name: Deploy to Heroku
        uses: akhileshns/heroku-deploy@v3.12.12
        with:
          heroku_api_key: ${{ secrets.HEROKU_API_KEY }}
          heroku_app_name: ${{ secrets.HEROKU_APP_NAME }}
          heroku_email: ${{ secrets.HEROKU_EMAIL }}
```

---

## 13. Support & Documentation

- **Backend API Docs**: http://localhost:5000/api-docs (Swagger)
- **MongoDB Connection**: mongodb://localhost:27017/hotel_booking
- **VNPAY Docs**: https://sandbox.vnpayment.vn/
- **Stripe Docs**: https://stripe.com/docs
- **Flutter Docs**: https://flutter.dev/docs
- **React Docs**: https://react.dev

---

**Last Updated**: November 2024  
**Version**: 1.0.0  
**Author**: Development Team
