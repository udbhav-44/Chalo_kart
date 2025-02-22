import 'package:flutter/material.dart';

class RouteTransitions {
  static PageRoute createRoute(Widget page, {bool fullscreenDialog = false}) {
    return MaterialPageRoute(
      builder: (context) => page,
      fullscreenDialog: fullscreenDialog,
    );
  }
}
