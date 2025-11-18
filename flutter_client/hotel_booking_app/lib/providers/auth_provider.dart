import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/auth.dart';
import '../services/api_service.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  emailNotVerified,
}

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  AuthState _state = AuthState.initial;
  User? _currentUser;
  String? _errorMessage;
  String? _successMessage;
  String? _pendingVerificationEmail;
  Map<String, String> _fieldErrors = {};
  
  AuthProvider() {
    // Initialize immediately when provider is created
    initialize();
  }
  
  // Getters
  AuthState get state => _state;
  User? get currentUser => _currentUser;
  User? get user => _currentUser; // Alias for compatibility
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String? get pendingVerificationEmail => _pendingVerificationEmail;
  Map<String, String> get fieldErrors => Map.unmodifiable(_fieldErrors);
  
  bool get isLoading => _state == AuthState.loading;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isEmailVerificationPending => _state == AuthState.emailNotVerified;
  
  // Initialize auth state
  Future<void> initialize() async {
    _setState(AuthState.loading);
    
    try {
      // Ensure ApiService is initialized
      _apiService.initialize();
      
      if (_apiService.isLoggedIn) {
        _currentUser = await _apiService.getUserFromStorage();
        print('🔍 User from storage: ${_currentUser?.fullName}');
        if (_currentUser != null) {
          // Verify token is still valid
          final user = await _apiService.getCurrentUser();
          print('🔍 User from API: ${user?.fullName}');
          if (user != null) {
            _currentUser = user;
            print('🔍 Setting authenticated state');
            _setState(AuthState.authenticated);
          } else {
            print('🔍 getCurrentUser returned null, logging out');
            await logout();
          }
        } else {
          print('🔍 No user in storage');
          _setState(AuthState.unauthenticated);
        }
      } else {
        _setState(AuthState.unauthenticated);
      }
    } catch (e) {
      _setError('Failed to initialize authentication');
      _setState(AuthState.unauthenticated);
    }
  }
  
  // Login
  Future<bool> login(String email, String password) async {
    _setState(AuthState.loading);
    _clearMessages();
    
    try {
      final request = LoginRequest(email: email, password: password);
      final response = await _apiService.login(request);
      
      print('🔍 Login response: success=${response.success}');
      print('🔍 User data: ${response.user}');
      print('🔍 User isEmailVerified: ${response.user?.isEmailVerified}');
      
      if (response.success) {
        if (response.user?.isEmailVerified == false) {
          _pendingVerificationEmail = email;
          _setState(AuthState.emailNotVerified);
          _setSuccess('Please verify your email to continue');
          return false;
        } else {
          _currentUser = response.user;
          print('🔍 Setting state to authenticated with user: ${_currentUser?.fullName}');
          _setState(AuthState.authenticated);
          _setSuccess('Login successful');
          return true;
        }
      } else {
        final fieldErrors = _mapFieldErrors(response.errors);
        _setError(
          response.message.isNotEmpty ? response.message : 'Login failed',
          fieldErrors: fieldErrors.isNotEmpty ? fieldErrors : null,
        );
        _setState(AuthState.unauthenticated);
        return false;
      }
    } catch (e) {
      _setError('Login failed. Please try again.');
      _setState(AuthState.unauthenticated);
      return false;
    }
  }
  
  // Register
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
    String role = 'customer',
  }) async {
    _setState(AuthState.loading);
    _clearMessages();
    
    try {
      final request = RegisterRequest(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phone: phone,
        role: role,
      );
      
      final response = await _apiService.register(request);
      
      if (response.success) {
        _pendingVerificationEmail = email;
        _setState(AuthState.emailNotVerified);
        _setSuccess('Registration successful! Please check your email for verification code.');
        return true;
      } else {
        final fieldErrors = _mapFieldErrors(response.errors);
        _setError(
          response.message.isNotEmpty
              ? response.message
              : 'Registration failed. Please check your details.',
          fieldErrors: fieldErrors.isNotEmpty ? fieldErrors : null,
        );
        _setState(AuthState.unauthenticated);
        return false;
      }
    } catch (e) {
      _setError('Registration failed. Please try again.');
      _setState(AuthState.unauthenticated);
      return false;
    }
  }
  
  // Verify OTP
  Future<bool> verifyOtp(String email, String otp) async {
    _setState(AuthState.loading);
    _clearMessages();
    
    try {
      final request = VerifyOtpRequest(email: email, otp: otp);
      final response = await _apiService.verifyOtp(request);
      
      print('🔍 VerifyOTP response: success=${response.success}');
      print('🔍 VerifyOTP message: ${response.message}');
      print('🔍 VerifyOTP user: ${response.user}');
      
      if (response.success) {
        _currentUser = response.user;
        _pendingVerificationEmail = null;
        print('🔍 Setting state to authenticated after email verification');
        _setState(AuthState.authenticated);
        _setSuccess('Email verified successfully!');
        return true;
      } else {
        final fieldErrors = _mapFieldErrors(response.errors);
        _setError(
          response.message.isNotEmpty ? response.message : 'OTP verification failed.',
          fieldErrors: fieldErrors.isNotEmpty ? fieldErrors : null,
        );
        _setState(AuthState.emailNotVerified);
        return false;
      }
    } catch (e) {
      print('🔍 VerifyOTP error: $e');
      _setError('OTP verification failed. Please try again.');
      _setState(AuthState.emailNotVerified);
      return false;
    }
  }
  
  // Resend OTP
  Future<bool> resendOtp(String email) async {
    _clearMessages();
    
    try {
      final response = await _apiService.resendOtp(email);
      
      if (response.success) {
        _setSuccess('Verification code sent to your email');
        return true;
      } else {
        final fieldErrors = _mapFieldErrors(response.errors);
        _setError(
          response.message.isNotEmpty ? response.message : 'Failed to resend verification code.',
          fieldErrors: fieldErrors.isNotEmpty ? fieldErrors : null,
        );
        return false;
      }
    } catch (e) {
      _setError('Failed to resend verification code');
      return false;
    }
  }
  
  // Forgot Password
  Future<bool> forgotPassword(String email) async {
    _setState(AuthState.loading);
    _clearMessages();
    
    try {
      final request = ForgotPasswordRequest(email: email);
      final response = await _apiService.forgotPassword(request);
      
      if (response.success) {
        _setSuccess('Password reset code sent to your email');
        _setState(AuthState.unauthenticated);
        return true;
      } else {
        final fieldErrors = _mapFieldErrors(response.errors);
        _setError(
          response.message.isNotEmpty ? response.message : 'Failed to send password reset email.',
          fieldErrors: fieldErrors.isNotEmpty ? fieldErrors : null,
        );
        _setState(AuthState.unauthenticated);
        return false;
      }
    } catch (e) {
      _setError('Failed to send password reset email');
      _setState(AuthState.unauthenticated);
      return false;
    }
  }
  
  // Reset Password
  Future<bool> resetPassword(String email, String otp, String newPassword) async {
    _setState(AuthState.loading);
    _clearMessages();
    
    try {
      final request = ResetPasswordRequest(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      final response = await _apiService.resetPassword(request);
      
      if (response.success) {
        _setSuccess('Password reset successful. Please login with your new password.');
        _setState(AuthState.unauthenticated);
        return true;
      } else {
        final fieldErrors = _mapFieldErrors(response.errors);
        _setError(
          response.message.isNotEmpty ? response.message : 'Password reset failed.',
          fieldErrors: fieldErrors.isNotEmpty ? fieldErrors : null,
        );
        _setState(AuthState.unauthenticated);
        return false;
      }
    } catch (e) {
      _setError('Password reset failed. Please try again.');
      _setState(AuthState.unauthenticated);
      return false;
    }
  }

  // Verify reset password OTP
  Future<bool> verifyResetOtp(String email, String otp) async {
    _setState(AuthState.loading);
    _clearMessages();

    try {
      final request = VerifyOtpRequest(email: email, otp: otp);
      final response = await _apiService.verifyResetOtp(request);

      if (response.success) {
        _setSuccess('Reset code verified. Please enter your new password.');
        _setState(AuthState.unauthenticated);
        return true;
      } else {
        final fieldErrors = _mapFieldErrors(response.errors);
        _setError(
          response.message.isNotEmpty ? response.message : 'Failed to verify reset code.',
          fieldErrors: fieldErrors.isNotEmpty ? fieldErrors : null,
        );
        _setState(AuthState.unauthenticated);
        return false;
      }
    } catch (e) {
      _setError('Failed to verify reset code. Please try again.');
      _setState(AuthState.unauthenticated);
      return false;
    }
  }
  
  // Logout
  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      print('Logout error: $e');
    } finally {
      _currentUser = null;
      _pendingVerificationEmail = null;
      _setState(AuthState.unauthenticated);
      _clearMessages();
    }
  }
  
  // Refresh user data
  Future<void> refreshUser() async {
    if (_state != AuthState.authenticated) return;
    
    try {
      final user = await _apiService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    } catch (e) {
      print('Failed to refresh user data: $e');
    }
  }
  
  // Update profile
  Future<bool> updateProfile(Map<String, dynamic> profileData, {dynamic profileImage}) async {
    try {
      _setState(AuthState.loading);
      _clearMessages();
      
      // Update profile via API
      final updatedUser = await _apiService.updateUserProfile(profileData, profileImage: profileImage);
      
      if (updatedUser != null) {
        _currentUser = updatedUser;
        _setState(AuthState.authenticated);
        _setSuccess('Profile updated successfully');
        return true;
      } else {
        _setError('Failed to update profile');
        _setState(AuthState.authenticated); // Keep authenticated state
        return false;
      }
    } catch (e) {
      print('❌ Update profile error: $e');
      _setError('Error updating profile: $e');
      _setState(AuthState.authenticated); // Keep authenticated state
      return false;
    }
  }

  // Get error for external use
  String get error => _errorMessage ?? '';
  
  Map<String, String> _mapFieldErrors(List<FieldError>? errors) {
    final mapped = <String, String>{};
    if (errors == null) return mapped;

    for (final error in errors) {
      final field = error.field;
      if (field != null && field.isNotEmpty) {
        mapped[field] = error.message;
      }
    }

    return mapped;
  }

  // Helper methods
  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }
  
  void _setError(String message, {Map<String, String>? fieldErrors}) {
    _errorMessage = message;
    _successMessage = null;
    _fieldErrors.clear();
    if (fieldErrors != null && fieldErrors.isNotEmpty) {
      _fieldErrors.addAll(fieldErrors);
    }
    notifyListeners();
  }
  
  void _setSuccess(String message) {
    _successMessage = message;
    _errorMessage = null;
    _fieldErrors.clear();
    notifyListeners();
  }
  
  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    _fieldErrors.clear();
    notifyListeners();
  }
  
  void clearMessages() {
    _clearMessages();
  }
}
