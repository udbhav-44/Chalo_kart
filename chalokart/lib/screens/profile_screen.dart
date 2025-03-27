import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../global/global.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameTextEditingController = TextEditingController();
  final phoneTextEditingController = TextEditingController();
  final emailTextEditingController = TextEditingController();
  
  // User data map
  Map<String, dynamic> userData = {
    'name': 'Loading...',
    'phone_number': 'Loading...',
    'email': 'Loading...',
  };
  
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }
  
  Future<void> _loadUserDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      // Get current user directly from Firebase
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // Reload user to get latest data
        await user.reload();
        
        setState(() {
          userData = {
            'name': user.displayName ?? 'User',
            'phone_number': user.phoneNumber ?? 'Not set',
            'email': user.email ?? currentUserEmail,
          };
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'User not found or not logged in';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user details: $e');
      setState(() {
        _errorMessage = 'Failed to load user details: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> showUserNameDialogAlert(BuildContext context, String name) {
    nameTextEditingController.text = name;

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Update Name"),
          content: TextFormField(controller: nameTextEditingController),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () async {
                String newName = nameTextEditingController.text.trim();

                if (newName.isEmpty) {
                  Fluttertoast.showToast(msg: "Name cannot be empty.");
                  return;
                }

                try {
                  // Update user display name directly with Firebase
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await user.updateDisplayName(newName);
                    
                    Fluttertoast.showToast(msg: "Name updated successfully.");
                    
                    // Refresh the user details
                    setState(() {
                      userData['name'] = newName;
                    });
                    
                    Navigator.pop(context);
                  } else {
                    Fluttertoast.showToast(msg: "User not found or not logged in.");
                  }
                } catch (e) {
                  debugPrint('Error updating user name: $e');
                  Fluttertoast.showToast(msg: "Failed to update name: ${e.toString()}");
                }
              },
              child: const Text("OK", style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          ),
          elevation: 0,
          title: const Text(
            "Profile Screen",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : _errorMessage != null 
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)))
              : Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 50),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(50),
                        decoration: const BoxDecoration(
                          color: Colors.lightBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(height: 20),

                      // Name Edit
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            userData['name'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => showUserNameDialogAlert(context, userData['name']),
                            icon: const Icon(Icons.edit),
                          ),
                        ],
                      ),
                      const Divider(thickness: 1),

                      // Phone Edit
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            userData['phone_number'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(thickness: 1),

                      // Email
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            userData['email'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
