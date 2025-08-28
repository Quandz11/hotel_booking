import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/main/main_screen.dart';
import '../screens/main/home_screen.dart';
import '../screens/main/search_screen.dart';
import '../screens/main/bookings_screen.dart';
import '../screens/main/profile_screen.dart';
import '../screens/hotel_owner/hotel_dashboard_screen.dart';
import '../screens/booking/payment_screen.dart';
import '../models/booking.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
        
      case '/register':
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
          settings: settings,
        );
        
      case '/forgot-password':
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordScreen(),
          settings: settings,
        );
        
      case '/verify-email':
        final email = settings.arguments as String?;
        if (email == null) {
          return _errorRoute('Email parameter is required');
        }
        return MaterialPageRoute(
          builder: (_) => VerifyEmailScreen(email: email),
          settings: settings,
        );
        
      case '/reset-password':
        final email = settings.arguments as String?;
        if (email == null) {
          return _errorRoute('Email parameter is required');
        }
        return MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(email: email),
          settings: settings,
        );
        
      case '/home':
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
        
      case '/main':
        return MaterialPageRoute(
          builder: (_) => const MainScreen(),
          settings: settings,
        );
        
      case '/search':
        return MaterialPageRoute(
          builder: (_) => const SearchScreen(),
          settings: settings,
        );
        
      case '/bookings':
        return MaterialPageRoute(
          builder: (_) => const BookingsScreen(),
          settings: settings,
        );
        
      case '/profile':
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
          settings: settings,
        );
        
      case '/hotel-dashboard':
        return MaterialPageRoute(
          builder: (_) => const HotelDashboardScreen(),
          settings: settings,
        );
        
      case '/payment':
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) {
          return _errorRoute('Payment parameters are required');
        }
        
        final booking = args['booking'] as Booking?;
        final paymentMethod = args['paymentMethod'] as String?;
        final isRetry = args['isRetry'] as bool? ?? false;
        
        if (booking == null || paymentMethod == null) {
          return _errorRoute('Invalid payment parameters');
        }
        
        return MaterialPageRoute(
          builder: (_) => PaymentScreen(
            booking: booking,
            paymentMethod: paymentMethod,
            isRetry: isRetry,
          ),
          settings: settings,
        );
        
      default:
        return _errorRoute('Route not found: ${settings.name}');
    }
  }
  
  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
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
                message,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Navigate back to login
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
