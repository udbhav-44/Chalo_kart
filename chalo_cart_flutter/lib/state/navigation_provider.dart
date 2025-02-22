import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  String _currentRoute = '/home';

  String get currentRoute => _currentRoute;

  void setCurrentRoute(String route) {
    if (_currentRoute != route) {
      _currentRoute = route;
      notifyListeners();
    }
  }
}
