import 'user.dart';

class AuthResponse {
  final bool success;
  final String message;
  final String? accessToken;
  final String? refreshToken;
  final User? user;
  final Map<String, dynamic>? errors;
  
  AuthResponse({
    required this.success,
    required this.message,
    this.accessToken,
    this.refreshToken,
    this.user,
    this.errors,
  });
  
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // If we have accessToken, it means login was successful
    bool isSuccess = json['accessToken'] != null || json['token'] != null;
    
    return AuthResponse(
      success: json['success'] ?? isSuccess,
      message: json['message'] ?? '',
      accessToken: json['accessToken'] ?? json['token'],
      refreshToken: json['refreshToken'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      errors: json['errors'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'user': user?.toJson(),
      'errors': errors,
    };
  }
}

class LoginRequest {
  final String email;
  final String password;
  
  LoginRequest({
    required this.email,
    required this.password,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class RegisterRequest {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String? phone;
  final String role;
  
  RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    this.phone,
    this.role = 'customer',
  });
  
  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      'phone': phone,
      'role': role,
    };
  }
}

class VerifyOtpRequest {
  final String email;
  final String otp;
  
  VerifyOtpRequest({
    required this.email,
    required this.otp,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otp': otp,
    };
  }
}

class ForgotPasswordRequest {
  final String email;
  
  ForgotPasswordRequest({
    required this.email,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
}

class ResetPasswordRequest {
  final String email;
  final String otp;
  final String newPassword;
  
  ResetPasswordRequest({
    required this.email,
    required this.otp,
    required this.newPassword,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    };
  }
}

class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;
  
  ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    };
  }
}
