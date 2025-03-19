import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );
  
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  
  // Token management
  static Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (e) {
      debugPrint('Error saving token: $e');
      _memoryStorage[_tokenKey] = token;
    }
  }
  
  // Refresh token management
  static Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
    } catch (e) {
      debugPrint('Error saving refresh token: $e');
      _memoryStorage[_refreshTokenKey] = token;
    }
  }
  
  static Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('Error reading refresh token: $e');
      return _memoryStorage[_refreshTokenKey] as String?;
    }
  }
  
  static Future<void> deleteRefreshToken() async {
    try {
      await _storage.delete(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('Error deleting refresh token: $e');
      _memoryStorage.remove(_refreshTokenKey);
    }
  }
  
  static Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      debugPrint('Error reading token: $e');
      return _memoryStorage[_tokenKey] as String?;
    }
  }
  
  static Future<void> deleteToken() async {
    try {
      await _storage.delete(key: _tokenKey);
    } catch (e) {
      debugPrint('Error deleting token: $e');
      _memoryStorage.remove(_tokenKey);
    }
  }
  
  // User data management
  static Future<void> saveUserData(String userData) async {
    try {
      await _storage.write(key: _userKey, value: userData);
    } catch (e) {
      debugPrint('Error saving user data: $e');
      _memoryStorage[_userKey] = userData;
    }
  }
  
  static Future<String?> getUserData() async {
    try {
      return await _storage.read(key: _userKey);
    } catch (e) {
      debugPrint('Error reading user data: $e');
      return _memoryStorage[_userKey] as String?;
    }
  }
  
  static Future<void> deleteUserData() async {
    try {
      await _storage.delete(key: _userKey);
    } catch (e) {
      debugPrint('Error deleting user data: $e');
      _memoryStorage.remove(_userKey);
    }
  }
  
  // Clear all data
  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('Error clearing all data: $e');
      _memoryStorage.clear();
    }
  }
  
  // Fallback memory storage
  static final Map<String, dynamic> _memoryStorage = {};
}
