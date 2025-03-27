import 'package:flutter/material.dart';
import 'dart:async';
import '../services/firebase_auth_service.dart';
import '../utils/logger.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _authService = FirebaseAuthService();
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    // Short delay to show splash screen
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    _checkAuth();
  }
  
  Future<void> _checkAuth() async {
    try {
      AppLogger.info('Checking authentication status');
      
      // Use our new auth service which handles SharedPreferences
      final isSignedIn = await _authService.isSignedInFromPrefs();
      
      if (!mounted) return;
      
      // Navigate based on auth status
      if (isSignedIn) {
        AppLogger.info('User is signed in, navigating to home');
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        AppLogger.info('User is not signed in, navigating to signin');
        Navigator.of(context).pushReplacementNamed('/signin');
      }
    } catch (e) {
      AppLogger.error('Error checking auth', e);
      
      if (mounted) {
        // On error, go to sign in screen
        Navigator.of(context).pushReplacementNamed('/signin');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 150,
              height: 150,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.local_taxi,
                  size: 100,
                  color: Colors.blue,
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'ChaloKART',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
} 