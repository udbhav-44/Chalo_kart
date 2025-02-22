import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'storage_service.dart';

class ApiService {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/';
    } else if (Platform.isIOS) {
      return 'http://127.0.0.1:8000/api/';
    } else {
      return 'http://localhost:8000/api/';
    }
  }
  
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final url = Uri.parse('${baseUrl}users/login/');
    try {
      debugPrint('Attempting login to: ${url.toString()}');
      debugPrint('Login payload: email: $email');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timed out. Please try again.');
        },
      );
      
      debugPrint('Login response status code: ${response.statusCode}');
      debugPrint('Login response body: ${response.body}');
      
      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        if (responseData['token'] == null) {
          throw Exception('Server response missing token');
        }
        return responseData;
      } else {
        final errorMessage = responseData['detail'] ?? 
                           responseData['error'] ?? 
                           responseData['message'] ??
                           'An error occurred during login';
        throw Exception(errorMessage);
      }
    } on TimeoutException {
      throw Exception('Connection timed out. Please check your internet connection and try again.');
    } on SocketException {
      throw Exception('Network error. Please check your internet connection.');
    } on FormatException {
      throw Exception('Invalid response from server. Please try again.');
    } catch (e) {
      debugPrint('Login error details: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> register(String userName, String email, String password) async {
    final url = Uri.parse('${baseUrl}users/register/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_name': userName,
          'email': email,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timed out. Please try again.');
        },
      );
      
      final responseData = json.decode(response.body);
      
      if (response.statusCode == 201) {
        if (responseData['token'] != null) {
          await StorageService.saveToken(responseData['token']);
        }
        if (responseData['user'] != null) {
          await StorageService.saveUserData(json.encode(responseData['user']));
        }
        return responseData;
      } else {
        final errorMessage = responseData['error'] ?? 'Registration failed';
        debugPrint('Registration failed with status: ${response.statusCode}');
        debugPrint('Error response: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Register error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await StorageService.clearAll();
    } catch (e) {
      debugPrint('Logout error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> bookTrip(Map<String, dynamic> tripData) async {
    final url = Uri.parse('${baseUrl}trips/');
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        url, 
        body: json.encode(tripData), 
        headers: await _authHeaders,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Connection timed out. Please try again.');
        },
      );
      
      final responseData = json.decode(response.body);
      
      if (response.statusCode == 201) {
        return responseData;
      } else if (response.statusCode == 401) {
        await StorageService.deleteToken();
        throw Exception('Authentication expired. Please login again.');
      } else {
        final errorMessage = responseData['error'] ?? 'Failed to book trip';
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Book trip error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getTrip(String tripId) async {
    final url = Uri.parse('${baseUrl}trips/$tripId/');
    try {
      final response = await http.get(
        url,
        headers: await _authHeaders,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timed out. Please try again.');
        },
      );
      
      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return responseData;
      } else if (response.statusCode == 401) {
        await StorageService.deleteToken();
        throw Exception('Authentication expired. Please login again.');
      } else {
        final errorMessage = responseData['error'] ?? 'Failed to get trip details';
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Get trip error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>?> searchLocations(String query) async {
    final url = Uri.parse('https://nominatim.openstreetmap.org/search');
    try {
      final response = await http.get(
        url.replace(queryParameters: {
          'q': query,
          'format': 'json',
          'limit': '5',
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Location search timed out. Please try again.');
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        return results.map((item) => {
          'display_name': item['display_name'] as String,
          'lat': double.parse(item['lat']),
          'lon': double.parse(item['lon']),
        }).toList();
      }
      throw Exception('Failed to search locations');
    } catch (e) {
      debugPrint('Location search error: $e');
      rethrow;
    }
  }

  Future<String?> getAddressFromCoordinates(LatLng coordinates) async {
    final url = Uri.parse('https://nominatim.openstreetmap.org/reverse');
    try {
      final response = await http.get(
        url.replace(queryParameters: {
          'lat': coordinates.latitude.toString(),
          'lon': coordinates.longitude.toString(),
          'format': 'json',
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Address lookup timed out. Please try again.');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'];
      }
      throw Exception('Failed to get address');
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getWalletInfo() async {
    final url = Uri.parse('${baseUrl}wallet/info/');
    try {
      final response = await http.get(
        url,
        headers: await _authHeaders,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timed out. Please try again.');
        },
      );
      
      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return responseData;
      } else if (response.statusCode == 401) {
        await StorageService.deleteToken();
        throw Exception('Authentication expired. Please login again.');
      } else {
        final errorMessage = responseData['error'] ?? 'Failed to get wallet info';
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Get wallet info error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> addFunds(double amount) async {
    final url = Uri.parse('${baseUrl}wallet/add-funds/');
    try {
      final response = await http.post(
        url,
        headers: await _authHeaders,
        body: json.encode({'amount': amount}),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Connection timed out. Please try again.');
        },
      );
      
      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return responseData;
      } else if (response.statusCode == 401) {
        await StorageService.deleteToken();
        throw Exception('Authentication expired. Please login again.');
      } else {
        final errorMessage = responseData['error'] ?? 'Failed to add funds';
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Add funds error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> updateProfile(Map<String, dynamic> userData) async {
    final url = Uri.parse('${baseUrl}users/update-profile/');
    try {
      final response = await http.put(
        url,
        headers: await _authHeaders,
        body: json.encode(userData),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timed out. Please try again.');
        },
      );
      
      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return responseData;
      } else if (response.statusCode == 401) {
        await StorageService.deleteToken();
        throw Exception('Authentication expired. Please login again.');
      } else {
        final errorMessage = responseData['error'] ?? 'Failed to update profile';
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Update profile error: $e');
      rethrow;
    }
  }

  Future<Map<String, String>> get _authHeaders async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
