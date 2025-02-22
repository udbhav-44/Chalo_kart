import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'map_selection_screen.dart';
import '../state/trip_provider.dart';

class TripBookingScreen extends StatefulWidget {
  const TripBookingScreen({super.key});
  
  @override
  State<TripBookingScreen> createState() => _TripBookingScreenState();
}

class _TripBookingScreenState extends State<TripBookingScreen> {
  final TextEditingController pickupController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  
  LatLng? pickupLocation;
  LatLng? destinationLocation;
  
  bool isLoading = false;
  
  void _bookTrip() async {
    if ((pickupController.text.isEmpty && pickupLocation == null) ||
        (destinationController.text.isEmpty && destinationLocation == null)) {
      return;
    }
    setState(() => isLoading = true);
    
    final tripData = {
      'pickup': pickupLocation != null
          ? {
              'latitude': pickupLocation!.latitude,
              'longitude': pickupLocation!.longitude
            }
          : pickupController.text,
      'destination': destinationLocation != null
          ? {
              'latitude': destinationLocation!.latitude,
              'longitude': destinationLocation!.longitude
            }
          : destinationController.text,
    };
    
    final tripProvider = Provider.of<TripProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    
    bool success = await tripProvider.bookTrip(tripData);
    
    if (mounted) {
      setState(() => isLoading = false);
      
      if (success) {
        navigator.pushNamed('/tripTracking');
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Could not book trip'))
        );
      }
    }
  }
  
  Future<void> _selectPickupLocation() async {
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapSelectionScreen()),
    );
    if (selected != null && selected is LatLng) {
      setState(() {
        pickupLocation = selected;
        pickupController.text = 'Lat: ${selected.latitude.toStringAsFixed(4)}, Lng: ${selected.longitude.toStringAsFixed(4)}';
      });
    }
  }
  
  Future<void> _selectDestinationLocation() async {
    final selected = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapSelectionScreen()),
    );
    if (selected != null && selected is LatLng) {
      setState(() {
        destinationLocation = selected;
        destinationController.text = 'Lat: ${selected.latitude.toStringAsFixed(4)}, Lng: ${selected.longitude.toStringAsFixed(4)}';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book a Trip')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: pickupController,
              decoration: const InputDecoration(
                labelText: 'Pickup Location',
                suffixIcon: Icon(Icons.location_on),
              ),
              readOnly: true,
              onTap: _selectPickupLocation,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: destinationController,
              decoration: const InputDecoration(
                labelText: 'Destination',
                suffixIcon: Icon(Icons.location_on),
              ),
              readOnly: true,
              onTap: _selectDestinationLocation,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _bookTrip,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Book Trip'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    pickupController.dispose();
    destinationController.dispose();
    super.dispose();
  }
}
