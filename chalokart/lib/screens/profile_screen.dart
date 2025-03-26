import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/auth_service.dart';
import '../global/global.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameTextEditingController = TextEditingController();
  final phoneTextEditingController = TextEditingController();
  final emailTextEditingController = TextEditingController();

  late Future<Map<String, dynamic>> userDetailsFuture;

  @override
  void initState() {
    super.initState();
    userDetailsFuture = AuthService().fetchUserDetails(currentUserEmail);
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

                // Call API to update the name
                final response = await AuthService().updateUserDetails(currentUserEmail, newName);

                if (response['success']) {
                  Fluttertoast.showToast(msg: "Name updated successfully.");

                  // Refresh the user details after updating the name
                  setState(() {
                    userDetailsFuture = AuthService().fetchUserDetails(currentUserEmail);
                  });

                  Navigator.pop(context);
                } else {
                  Fluttertoast.showToast(msg: response['message'] ?? "Failed to update name.");
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
        body: FutureBuilder<Map<String, dynamic>>(
          future: userDetailsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !(snapshot.data?['success'] ?? false)) {
              return Center(
                child: Text(
                  snapshot.data?['message'] ?? "Failed to fetch user details.",
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              );
            }

            final userData = snapshot.data!['data'];
            final String name = userData['name'] ?? "Unknown";
            final String phone = userData['phone_number'] ?? "N/A";
            final String email = userData['email'] ?? "N/A";

            return Padding(
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
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => showUserNameDialogAlert(context, name),
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
                        phone,
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
                        email,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
