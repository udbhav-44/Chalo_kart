import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/real_time_service.dart';
import '../services/location_service.dart';
import 'dart:io';

class TripTrackingScreen extends StatefulWidget {
  final String tripId;
  
  const TripTrackingScreen({
    super.key,
    required this.tripId,
  });

  @override
  State<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends State<TripTrackingScreen> {
  final mapController = MapController();
  LatLng? _driverLocation;
  LatLng? _currentLocation;
  bool _isConnected = false;
  bool _isLoading = true;
  String? _errorMessage;
  RealTimeService? _realTimeService;
  
  String get _wsUrl {
    final baseUrl = Platform.isAndroid ? '10.0.2.2:8000' : 'localhost:8000';
    return 'ws://$baseUrl/ws/trips/${widget.tripId}/';
  }
  
  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }
  
  Future<void> _initializeTracking() async {
    try {
      if (!await LocationService.checkLocationPermission(context)) {
        setState(() {
          _errorMessage = 'Location permission required';
          _isLoading = false;
        });
        return;
      }
      
      final location = await LocationService.getCurrentLocation();
      if (mounted) {
        setState(() => _currentLocation = location);
      }
      
      _realTimeService = RealTimeService(
        socketUrl: _wsUrl,
        onData: _handleTripUpdate,
        onConnected: () {
          if (mounted) setState(() => _isConnected = true);
        },
        onDisconnected: () {
          if (mounted) setState(() => _isConnected = false);
        },
      );
      
      await _realTimeService?.connect();
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize tracking';
          _isLoading = false;
        });
      }
    }
  }
  
  void _handleTripUpdate(dynamic data) {
    if (!mounted) return;
    
    try {
      if (data['driver_location'] != null) {
        final location = data['driver_location'];
        setState(() {
          _driverLocation = LatLng(
            location['latitude'].toDouble(),
            location['longitude'].toDouble(),
          );
        });
        
        // Center map on driver if this is the first update
        if (_driverLocation != null && !_isConnected) {
          mapController.move(_driverLocation!, 14);
        }
      }
      
      if (data['status'] == 'completed') {
        _showTripCompletedDialog();
      }
    } catch (e) {
      debugPrint('Error handling trip update: $e');
    }
  }
  
  void _showTripCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Trip Completed'),
        content: const Text('Your trip has been completed.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _realTimeService?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Tracking'),
        actions: [
          if (!_isConnected)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.cloud_off, color: Colors.red),
            )
        ],
      ),
      body: Stack(
        children: [
          if (_errorMessage != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _initializeTracking,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: _currentLocation ?? const LatLng(37.42796133580664, -122.085749655962),
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.chalo_cart_flutter',
                ),
                MarkerLayer(
                  markers: [
                    if (_driverLocation != null)
                      Marker(
                        point: _driverLocation!,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.directions_car, color: Colors.blue),
                      ),
                    if (_currentLocation != null)
                      Marker(
                        point: _currentLocation!,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          if (!_isConnected && !_isLoading && _errorMessage == null)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Reconnecting...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
