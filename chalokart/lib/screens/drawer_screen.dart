import 'package:flutter/material.dart';
import 'package:chalokart/global/global.dart';
import 'package:chalokart/screens/profile_screen.dart';
import 'package:chalokart/screens/sign_in_screen.dart';
import 'package:chalokart/screens/razor_pay.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DrawerScreen extends StatefulWidget {
  const DrawerScreen({super.key});

  @override
  State<DrawerScreen> createState() => _DrawerScreenState();
}

class _DrawerScreenState extends State<DrawerScreen> {
  String _userName = "Loading...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }
  
  Future<void> _loadUserName() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Get current user from Firebase directly
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // Use display name or fallback to email
        setState(() {
          _userName = user.displayName ?? user.email?.split('@')[0] ?? 'User';
          _isLoading = false;
        });
      } else {
        setState(() {
          _userName = "Unknown User";
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user name: $e');
      setState(() {
        _userName = "Unknown User";
        _isLoading = false;
      });
    }
  }
  
  Future<void> _signOut() async {
    try {
      // Sign out from Firebase directly
      await FirebaseAuth.instance.signOut();
      
      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      await prefs.remove('user_name');
      
      if (!mounted) return;
      
      // Navigate to sign in screen and clear all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (c) => const SignInScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Drawer(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 50, 0, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.black,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Display User Name
                  _isLoading 
                      ? const Text(
                          "Loading...",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        )
                      : Text(
                          _userName,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),

                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (c) => const ProfileScreen()),
                      ).then((_) => _loadUserName()); // Refresh name when returning from profile
                    },
                    child: Text(
                      "Edit Profile",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent.shade700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (c) => const RazorPay()),
                      );
                    },
                    child: const Text(
                      "Wallet",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Your Trips",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "About Us",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),

              // Logout Button
              GestureDetector(
                onTap: _signOut,
                child: const Text(
                  "Logout",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
