import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class PaymentProvider with ChangeNotifier {
  double walletBalance = 0.0;
  List<Map<String, dynamic>> transactions = [];
  bool isLoading = false;
  bool isProcessing = false;
  String? error;
  
  final ApiService _apiService = ApiService();

  Future<void> fetchWalletBalance() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _apiService.getWalletInfo();
      if (response != null) {
        walletBalance = (response['balance'] as num).toDouble();
        transactions = List<Map<String, dynamic>>.from(response['transactions'] ?? []);
      } else {
        error = 'Failed to fetch wallet information';
      }
    } catch (e) {
      error = e.toString();
      debugPrint('Fetch wallet error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addFunds(double amount) async {
    if (amount <= 0) {
      error = 'Amount must be greater than 0';
      notifyListeners();
      return false;
    }

    isProcessing = true;
    error = null;
    notifyListeners();

    try {
      final response = await _apiService.addFunds(amount);
      if (response != null) {
        walletBalance = (response['new_balance'] as num).toDouble();
        transactions = List<Map<String, dynamic>>.from(response['transactions'] ?? []);
        return true;
      }
      error = 'Failed to add funds';
      return false;
    } catch (e) {
      error = e.toString();
      debugPrint('Add funds error: $e');
      return false;
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }

  void clearError() {
    error = null;
    notifyListeners();
  }
}
