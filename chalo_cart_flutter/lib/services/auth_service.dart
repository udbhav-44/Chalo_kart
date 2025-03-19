import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;
  String? _otp;
  
  // Backend API URL
  static String get baseUrl {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/';
    } else {
      return 'http://127.0.0.1:8000/api/';
    }
  }

  // Initialize user in backend
  Future<void> initializeUserInBackend(
    String uid,
    String name,
    String email, 
    String phoneNumber,
    String password,
    String? studentId,
  ) async {
    try {
      debugPrint('Initializing user in backend...');
      
      final response = await http.post(
        Uri.parse('${baseUrl}users/initialize/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'uid': uid,
          'name': name,
          'email': email,
          'phone_number': phoneNumber,
          'password': password,
          'student_id': studentId,
        }),
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint('Backend error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to initialize user in backend: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error initializing user in backend: $e');
      rethrow;
    }
  }

  // Sync user data with backend
  Future<void> syncUserData(User firebaseUser) async {
    try {
      // Force a token refresh to ensure we have the most recent token
      final idToken = await firebaseUser.getIdToken(true);
      
      final response = await http.post(
        Uri.parse('${baseUrl}users/sync/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({
          'firebase_uid': firebaseUser.uid,
          'email': firebaseUser.email,
          'phone_number': firebaseUser.phoneNumber ?? '',
          'email_verified': firebaseUser.emailVerified,
          'name': firebaseUser.displayName,
        }),
      );
      
      if (response.statusCode != 200) {
        debugPrint('Failed to sync user data: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to sync user data with backend');
      }
    } catch (e) {
      debugPrint('Warning: Failed to sync user data: $e');
      // Don't rethrow as this is a non-critical operation
    }
  }

  // Login with email and password
  Future<User?> loginWithEmailAndPassword(String email, String password) async {
    try {
      debugPrint('Attempting login with email: $email');
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      debugPrint('Login successful for user: ${userCredential.user?.email}');
      return userCredential.user;
    } catch (e) {
      debugPrint('Login error: $e');
      if (e is FirebaseAuthException) {
        throw Exception(_handleFirebaseAuthError(e));
      }
      throw Exception(_handleApiError(e));
    }
  }

  // Send OTP
  Future<void> sendOTP(String phoneNumber) async {
    try {
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '+91$phoneNumber'; // Add country code if not present
      }

      debugPrint('Initiating phone verification for: $phoneNumber');
      
      // Reset verification id and OTP when sending a new OTP
      _verificationId = null;
      _otp = null;
      
      // Create a completer to wait for verification ID
      final completer = Completer<String>();
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('Auto verification completed with credential: ${credential.toString()}');
          try {
            UserCredential userCredential = await _auth.signInWithCredential(credential);
            debugPrint('Auto signed in successfully with user: ${userCredential.user?.uid}');
            
            // If auto-verification succeeded, we should allow the OTP to be set
            if (!completer.isCompleted) {
              completer.complete(credential.verificationId ?? '');
            }
            
            // We need to sign out since we're just verifying the phone
            await _auth.signOut();
          } catch (e) {
            debugPrint('Error in auto verification: $e');
            
            // Don't fail here - this might just mean the phone is not registered yet
            // which is fine for registration flow
            if (!completer.isCompleted && e is FirebaseAuthException && e.code == 'user-not-found') {
              debugPrint('User not found with this phone number, which is expected for registration');
            } else if (!completer.isCompleted) {
              completer.completeError(e);
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Phone verification failed with code: ${e.code}');
          debugPrint('Phone verification failed with message: ${e.message}');
          completer.completeError(Exception(e.message ?? 'Failed to verify phone number'));
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('Verification code sent successfully. VerificationId: ${verificationId.substring(0, min(5, verificationId.length))}...');
          _verificationId = verificationId;
          completer.complete(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('Auto retrieval timeout. VerificationId: ${verificationId.substring(0, min(5, verificationId.length))}...');
          _verificationId = verificationId;
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        timeout: const Duration(seconds: 60),
      );
      
      // Wait for verification ID to be set
      await completer.future;
      
      // Double check that we received a verification ID
      if (_verificationId == null) {
        debugPrint('Warning: No verification ID was set after sending OTP');
      } else {
        debugPrint('Verification ID is set and ready for OTP verification');
      }
    } catch (e) {
      debugPrint('Error in sendOTP: $e');
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-phone-number':
            throw Exception('The phone number provided is invalid');
          case 'too-many-requests':
            throw Exception('Too many attempts. Please try again later');
          case 'operation-not-allowed':
            throw Exception('Phone authentication is not enabled');
          default:
            throw Exception(e.message ?? 'Failed to send verification code');
        }
      }
      rethrow;
    }
  }

  // Verify OTP without creating temporary users
  Future<void> verifyOTP(String otp) async {
    _otp = otp;
    try {
      if (_verificationId == null) {
        debugPrint('Error: No verification ID found when verifying OTP');
        throw Exception('Verification ID not found. Please request a new OTP.');
      }

      debugPrint('Storing OTP for later verification');
      
      // We'll just store the OTP and verify it during account creation
      // This avoids creating a temporary user in Firebase that would conflict with our new account
      
      // We'll perform a basic validation of the OTP format
      if (otp.length < 4 || otp.length > 8) {
        debugPrint('Invalid OTP format: ${otp.length} digits');
        throw Exception('Please enter a valid OTP code');
      }
      
      debugPrint('OTP stored for verification during account creation');
      // The actual verification will happen in createUserAccount
      
    } catch (e) {
      debugPrint('Error in verifyOTP: $e');
      rethrow;
    }
  }

  // Create user account with OTP verification
  Future<User?> createUserAccount(String name, String email, String password, String studentId) async {
    try {
      debugPrint('Starting user account creation process');
      
      // Verify the OTP before creating account
      if (_verificationId == null) {
        debugPrint('Error: No verification ID found. OTP was not sent or expired');
        throw Exception('Verification ID not found. Please request a new OTP.');
      }
      
      String? verifyingOtp = _otp;
      if (verifyingOtp == null || verifyingOtp.isEmpty) {
        debugPrint('Error: No OTP provided for verification');
        throw Exception('Please enter the OTP sent to your phone');
      }
      
      debugPrint('Creating phone credential for OTP verification');
      
      // First create the user, then link the phone credential
      debugPrint('Creating new user with email and password first');
      UserCredential? userCredential;
      
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        debugPrint('Error creating user with email/password: $e');
        if (e is FirebaseAuthException) {
          if (e.code == 'email-already-in-use') {
            throw Exception('This email is already registered. Please use a different email or log in.');
          } else {
            throw Exception(_handleFirebaseAuthError(e));
          }
        }
        throw Exception('Failed to create account: ${_handleApiError(e)}');
      }
      
      User? user = userCredential.user;
      if (user == null) {
        debugPrint('Error: No user returned after creating account');
        throw Exception('Failed to create user account');
      }
      
      debugPrint('User created successfully with UID: ${user.uid}');
      
      // Update display name
      await user.updateDisplayName(name);
      debugPrint('Display name updated successfully');
      
      // Now try to link the phone credential
      PhoneAuthCredential phoneCredential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: verifyingOtp,
      );
      
      try {
        // Attempt to link the phone credential to the new user
        debugPrint('Attempting to link phone credential to user');
        await user.linkWithCredential(phoneCredential);
        debugPrint('Phone credential linked successfully');
      } catch (e) {
        debugPrint('Error linking phone credential: $e');
        
        // Clean up by deleting the partial user
        await user.delete();
        
        if (e is FirebaseAuthException) {
          if (e.code == 'credential-already-in-use') {
            // Phone is already linked to another account
            debugPrint('Phone already linked to another account');
            throw Exception('This phone number is already linked to a different account. Please use a different phone number.');
          } else if (e.code == 'invalid-verification-code') {
            // Invalid OTP
            debugPrint('Invalid OTP provided');
            throw Exception('The OTP you entered is incorrect. Please try again.');
          } else if (e.code == 'invalid-verification-id') {
            debugPrint('Invalid verification ID');
            throw Exception('Your verification session has expired. Please request a new OTP.');
          } else {
            throw Exception(_handleFirebaseAuthError(e));
          }
        }
        
        throw Exception('Failed to link phone number to your account: ${_handleApiError(e)}');
      }
      
      // Save user to backend
      debugPrint('Initializing user in backend');
      
      // Trim studentId to avoid spaces
      String trimmedStudentId = studentId.trim();
      
      // Initialize user in backend with proper error handling
      try {
        await initializeUserInBackend(
          user.uid,
          name,
          user.email ?? '',
          user.phoneNumber ?? '',
          password,
          trimmedStudentId.isEmpty ? null : trimmedStudentId,
        );
        debugPrint('User initialized in backend successfully');
      } catch (e) {
        debugPrint('Error initializing user in backend: $e');
        // If backend initialization fails, delete the user in Firebase
        await user.delete();
        debugPrint('Deleted user due to failed backend initialization');
        throw Exception('Failed to initialize user in backend: ${_handleApiError(e)}');
      }
      
      return user;
    } catch (e) {
      debugPrint('Error in createUserAccount: $e');
      rethrow;
    }
  }

  // Send forgot password OTP
  Future<void> sendForgotPasswordOTP(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}users/forgot_password_request/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );
      
      if (response.statusCode != 200) {
        final error = json.decode(response.body)['error'] ?? 'Failed to send OTP';
        throw Exception(error);
      }
    } catch (e) {
      debugPrint('Error sending forgot password OTP: $e');
      rethrow;
    }
  }

  // Verify forgot password OTP and get forget link
  Future<void> verifyForgotPasswordOTP(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}users/verify_forget_otp/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'otp': otp,
        }),
      );
      
      if (response.statusCode != 200) {
        final error = json.decode(response.body)['error'] ?? 'Failed to verify OTP';
        throw Exception(error);
      }

      // The response will contain a message that the forget link has been sent
      // The user will need to check their email and click the link to forget their password
    } catch (e) {
      debugPrint('Error verifying forgot password OTP: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Notify backend about sign out
      try {
        final user = _auth.currentUser;
        if (user != null) {
          final idToken = await user.getIdToken();
          await http.post(
            Uri.parse('${baseUrl}users/signout/'),
            headers: {
              'Authorization': 'Bearer $idToken',
            },
          );
        }
      } catch (e) {
        debugPrint('Warning: Could not notify backend about sign out: $e');
      }

      // Sign out from Firebase
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Verify token with backend
  Future<bool> verifyTokenWithBackend(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}users/verify-token/'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error verifying token: $e');
      return false;
    }
  }

  // Helper method to handle Firebase authentication errors
  String _handleFirebaseAuthError(FirebaseAuthException e) {
    debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
    
    switch (e.code) {
      case 'invalid-verification-code':
        return 'The OTP you entered is incorrect';
      case 'invalid-verification-id':
        return 'Verification session expired. Please request a new OTP';
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'invalid-credential':
        return 'Invalid email or password';
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'operation-not-allowed':
        return 'Operation not allowed. Please contact support';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password';
      case 'invalid-phone-number':
        return 'The phone number provided is invalid';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in method';
      default:
        return e.message ?? 'Authentication failed';
    }
  }
  
  // Helper method to handle API and other errors
  String _handleApiError(dynamic error) {
    String errorMsg = error.toString();
    
    // Sanitize the error message (remove Exception: prefix)
    if (errorMsg.startsWith('Exception: ')) {
      errorMsg = errorMsg.substring('Exception: '.length);
    }
    
    // Check for common connection errors
    if (errorMsg.contains('SocketException') || 
        errorMsg.contains('Connection refused') ||
        errorMsg.contains('Network is unreachable')) {
      return 'Could not connect to the server. Please check your internet connection';
    }
    
    // Check for timeout errors
    if (errorMsg.contains('TimeoutException')) {
      return 'The connection to the server timed out. Please try again later';
    }
    
    // Return the sanitized error message
    return errorMsg;
  }
} 