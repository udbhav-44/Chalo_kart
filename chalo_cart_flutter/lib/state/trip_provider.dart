import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TripProvider extends ChangeNotifier {
  Map<String, dynamic>? currentTrip;
  final ApiService _apiService = ApiService();
  
  Future<bool> bookTrip(Map<String, dynamic> tripData) async {
    final response = await _apiService.bookTrip(tripData);
    if(response != null) {
      currentTrip = response;
      notifyListeners();
      return true;
    }
    return false;
  }
  
  Future<void> fetchTrip(String tripId) async {
    final response = await _apiService.getTrip(tripId);
    if(response != null){
      currentTrip = response;
      notifyListeners();
    }
  }
  
  void clearTrip() {
    currentTrip = null;
    notifyListeners();
  }
}
