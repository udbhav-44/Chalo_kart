import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../utils/logger.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign in with email and password
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Save user data to SharedPreferences
      await _saveUserData(userCredential.user);
      
      return userCredential;
    } catch (e) {
      AppLogger.error('Error signing in with email and password', e);
      rethrow; // Rethrow to let the UI handle specific error cases
    }
  }
  
  // Register with email and password
  Future<UserCredential> registerWithEmailPassword(String email, String password, String name) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await userCredential.user?.updateDisplayName(name);
      
      // Save user data to SharedPreferences
      await _saveUserData(userCredential.user);
      
      return userCredential;
    } catch (e) {
      AppLogger.error('Error registering with email and password', e);
      rethrow;
    }
  }
  
  // Save user data to SharedPreferences
  Future<void> _saveUserData(User? user) async {
    if (user == null) {
      AppLogger.error('Cannot save user data: User is null', null);
      return;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', await user.getIdToken() ?? 'logged_in');
      await prefs.setString('user_id', user.uid);
      await prefs.setString('user_email', user.email ?? '');
      await prefs.setString('user_name', user.displayName ?? user.email?.split('@')[0] ?? 'User');
      await prefs.setString('user_phone', user.phoneNumber ?? '');
      await prefs.setBool('is_logged_in', true);
      
      AppLogger.info('User data saved to SharedPreferences');
    } catch (e) {
      AppLogger.error('Error saving user data to SharedPreferences', e);
    }
  }
  
  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }
  
  // Check if user is signed in
  bool isSignedIn() {
    return _auth.currentUser != null;
  }
  
  // Check if user is signed in from SharedPreferences (faster for splash screens)
  Future<bool> isSignedInFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('is_logged_in') ?? false;
    } catch (e) {
      AppLogger.error('Error checking sign in status from prefs', e);
      return false;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      await prefs.remove('user_phone');
      await prefs.setBool('is_logged_in', false);
      
      AppLogger.info('User signed out successfully');
    } catch (e) {
      AppLogger.error('Error signing out', e);
      rethrow;
    }
  }
  
  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      AppLogger.info('Password reset email sent to $email');
    } catch (e) {
      AppLogger.error('Error sending password reset email', e);
      rethrow;
    }
  }
  
  // Send OTP to phone number
  Future<void> sendOtpToPhone(
    String phoneNumber, 
    Function(PhoneAuthCredential) verificationCompleted,
    Function(FirebaseAuthException) verificationFailed,
    Function(String, int?) codeSent,
    Function(String) codeAutoRetrievalTimeout,
  ) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      AppLogger.error('Error sending OTP to phone', e);
      rethrow;
    }
  }
  
  // Verify OTP
  Future<UserCredential> verifyOtp(String verificationId, String smsCode) async {
    try {
      // Create a PhoneAuthCredential with the code
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      
      // Sign in with credential
      final userCredential = await _auth.signInWithCredential(credential);
      
      // Save user data to SharedPreferences
      await _saveUserData(userCredential.user);
      
      return userCredential;
    } catch (e) {
      AppLogger.error('Error verifying OTP', e);
      rethrow;
    }
  }
  
  // Link phone number to existing account
  Future<UserCredential> linkPhoneNumber(String verificationId, String smsCode) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user is currently signed in',
        );
      }
      
      // Create a PhoneAuthCredential with the code
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      
      // Link credential to current user
      final userCredential = await user.linkWithCredential(credential);
      
      // Update user data in SharedPreferences
      await _saveUserData(userCredential.user);
      
      return userCredential;
    } catch (e) {
      AppLogger.error('Error linking phone number', e);
      rethrow;
    }
  }
} 