import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Use different URLs for web and mobile
  String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api/auth';
    } else {
      return 'http://10.0.2.2:8000/api/auth';
    }
  }

  // Sign In with Email/Password (Django only)
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? data['error'] ?? 'Failed to sign in',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error signing in: $e',
      };
    }
  }

  // Sign Up with Email/Password (Django only)
  Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String mobile,
    required String password,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/register/'),
      );

      request.fields.addAll({
        'email': email,
        'password': password,
        'password2': password,
        'name': name,
        'mobile': mobile,
      });

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        String errorMessage = _extractErrorMessage(data);
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '• Error creating account: $e',
      };
    }
  }

  // Phone Authentication Methods (Firebase)
  Future<Map<String, dynamic>> verifyPhoneNumber(String phoneNumber) async {
    final completer = Completer<Map<String, dynamic>>();

    try {
      // Set Firebase Auth settings for testing
      await _auth.setSettings(
        appVerificationDisabledForTesting: true,
        forceRecaptchaFlow: false,
      );

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Do nothing here to prevent auto-verification
          return;
        },
        verificationFailed: (FirebaseAuthException e) {
          completer.complete({
            'success': false,
            'message': e.message ?? 'Verification failed',
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          completer.complete({
            'success': true,
            'verificationId': verificationId,
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (!completer.isCompleted) {
            completer.complete({
              'success': false,
              'message': 'Verification timeout',
            });
          }
        },
      );

      return await completer.future;
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> verifyOTP(String verificationId, String smsCode) async {
    try {
      // Set Firebase Auth settings for testing
      await _auth.setSettings(
        appVerificationDisabledForTesting: true,
        forceRecaptchaFlow: false,
      );

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      await _auth.signInWithCredential(credential);
      
      return {
        'success': true,
        'message': 'OTP verified successfully',
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': e.message ?? 'Invalid OTP',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Email Verification Methods
  Future<Map<String, dynamic>> verifyEmail(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-email/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'otp': otp,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? data['error'] ?? 'Failed to verify email',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error verifying email: $e',
      };
    }
  }

  Future<Map<String, dynamic>> sendEmailVerification(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send-email-verification/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Verification email sent successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? data['error'] ?? 'Failed to send verification email',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error sending verification email: $e',
      };
    }
  }

  Future<Map<String, dynamic>> resendVerification(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/resend-verification/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Verification email sent successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? data['error'] ?? 'Failed to resend verification',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error resending verification: $e',
      };
    }
  }

  // Password Reset Methods
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/request-password-reset/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Password reset OTP sent successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? data['error'] ?? 'Failed to request password reset',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error requesting password reset: $e',
      };
    }
  }

  Future<Map<String, dynamic>> resetPassword(String email, String otp, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'otp': otp,
          'new_password': newPassword,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Password reset successful',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? data['error'] ?? 'Failed to reset password',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error resetting password: $e',
      };
    }
  }

  String _extractErrorMessage(Map<String, dynamic> data) {
    // If there's a specific message, return it
    if (data['message'] != null) return data['message'];
    
    // Handle validation errors
    final errors = <String>[];
    
    // Handle field-specific errors
    if (data['email'] is List) {
      errors.add('• Email: ${(data['email'] as List).join('\n• ')}');
    } else if (data['email'] != null) {
      errors.add('• Email: ${data['email']}');
    }
    
    if (data['password'] is List) {
      errors.add('• Password: ${(data['password'] as List).join('\n• ')}');
    } else if (data['password'] != null) {
      errors.add('• Password: ${data['password']}');
    }
    
    if (data['mobile'] is List) {
      errors.add('• Mobile: ${(data['mobile'] as List).join('\n• ')}');
    } else if (data['mobile'] != null) {
      errors.add('• Mobile: ${data['mobile']}');
    }
    
    if (data['name'] is List) {
      errors.add('• Name: ${(data['name'] as List).join('\n• ')}');
    } else if (data['name'] != null) {
      errors.add('• Name: ${data['name']}');
    }

    // Handle non-field errors
    if (data['non_field_errors'] is List) {
      errors.add('• ${(data['non_field_errors'] as List).join('\n• ')}');
    } else if (data['non_field_errors'] != null) {
      errors.add('• ${data['non_field_errors']}');
    }
    
    // If we have specific errors, join them
    if (errors.isNotEmpty) {
      return errors.join('\n');
    }
    
    // If there's an error key with a string value
    if (data['error'] != null) {
      return '• ${data['error'].toString()}';
    }
    
    // Default message
    return 'Registration failed. Please check your information and try again.';
  }
} 