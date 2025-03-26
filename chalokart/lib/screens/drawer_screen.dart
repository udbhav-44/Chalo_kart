import 'package:flutter/material.dart';
import 'package:chalokart/global/global.dart';
import 'package:chalokart/screens/profile_screen.dart';
import 'package:chalokart/screens/sign_in_screen.dart';
import 'package:chalokart/services/auth_service.dart';
import 'package:chalokart/screens/razor_pay.dart';

class DrawerScreen extends StatefulWidget {
  const DrawerScreen({super.key});

  @override
  _DrawerScreenState createState() => _DrawerScreenState();
}

class _DrawerScreenState extends State<DrawerScreen> {
  late Future<Map<String, dynamic>> userDetailsFuture;

  @override
  void initState() {
    super.initState();
    userDetailsFuture = AuthService().fetchUserDetails(currentUserEmail);
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

                  /// Fetch and Display User Name
                  FutureBuilder<Map<String, dynamic>>(
                    future: userDetailsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text(
                          "Loading...",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        );
                      } else if (snapshot.hasError || !snapshot.data!['success']) {
                        return const Text(
                          "Unknown User",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        );
                      } else {
                        return Text(
                          snapshot.data!['data']['name'] ?? "Unknown User",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (c) => const ProfileScreen()),
                      );
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
                    child: Text(
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

              /// Logout Button
              GestureDetector(
                onTap: () {
                  // firebaseAuth.signOut();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const SignInScreen()),
                  );
                },
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
