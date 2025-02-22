import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  String? token;
  Map<String, dynamic>? user;
  bool isLoading = false;
  String? error;
  
  final ApiService _apiService = ApiService();
  
  AuthProvider() {
    _initializeAuth();
  }
  
  Future<void> _initializeAuth() async {
    isLoading = true;
    notifyListeners();
    
    try {
      final storedToken = await StorageService.getToken();
      final storedUserData = await StorageService.getUserData();
      
      if (storedToken != null && storedUserData != null) {
        token = storedToken;
        user = json.decode(storedUserData);
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> login(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.login(email, password);
      if (response != null && response['token'] != null) {
        token = response['token'];
        user = response['user'];
        
        // Save token and user data
        await StorageService.saveToken(token!);
        await StorageService.saveUserData(json.encode(user));
        
        error = null;
        notifyListeners();
        return true;
      }
      error = 'Invalid credentials';
      notifyListeners();
      return false;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      debugPrint('Login error: $e');
      notifyListeners();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signup(String userName, String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    
    if (password.length < 8) {
      error = 'Password must be at least 8 characters long';
      isLoading = false;
      notifyListeners();
      return false;
    }
    
    final hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    final hasLowerCase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecialCharacters = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    if (!hasUpperCase || !hasLowerCase || !hasDigits || !hasSpecialCharacters) {
      error = 'Password must contain uppercase, lowercase, number and special character';
      isLoading = false;
      notifyListeners();
      return false;
    }
    
    try {
      final response = await _apiService.register(userName, email, password);
      if (response != null && response['token'] != null) {
        token = response['token'];
        user = response['user'];
        notifyListeners();
        return true;
      }
      error = 'Failed to register';
      notifyListeners();
      return false;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> logout() async {
    isLoading = true;
    notifyListeners();
    
    try {
      await _apiService.logout();
      await StorageService.clearAll();
      token = null;
      user = null;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  
  bool get isAuthenticated => token != null;

  Future<bool> updateProfile(Map<String, dynamic> userData) async {
    isLoading = true;
    error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.updateProfile(userData);
      if (response != null) {
        user = response['user'];
        await StorageService.saveUserData(json.encode(user));
        notifyListeners();
        return true;
      }
      error = 'Failed to update profile';
      notifyListeners();
      return false;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
