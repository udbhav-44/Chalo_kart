import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacementNamed('/home');
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacementNamed('/home');
              }
            },
          ),
          title: const Text('Notifications'),
        ),
        body: RawScrollbar(
          thumbVisibility: true,
          thickness: 6,
          radius: const Radius.circular(3),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            itemCount: 20, // Example count
            itemBuilder: (context, index) {
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications),
                  title: Text('Notification ${index + 1}'),
                  subtitle: const Text('Notification details here'),
                  onTap: () {
                    // Handle notification tap
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
