import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  MapController? mapController;
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
    mapController = MapController();
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
      if (mounted && location != null) {
        setState(() => _currentLocation = LatLng(location.latitude, location.longitude));
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
        final newDriverLocation = LatLng(
          location['latitude'].toDouble(),
          location['longitude'].toDouble(),
        );
        
        setState(() {
          _driverLocation = newDriverLocation;
        });
        
        // Center map on driver if this is the first update
        if (_driverLocation != null && !_isConnected) {
          mapController?.move(_driverLocation!, 14);
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
                minZoom: 4,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token={accessToken}',
                  additionalOptions: {
                    'accessToken': dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '',
                  },
                ),
                if (_currentLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentLocation!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.red,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                if (_driverLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _driverLocation!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.directions_car,
                          color: Colors.blue,
                          size: 36,
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_currentLocation != null)
            FloatingActionButton(
              heroTag: 'locate_user',
              onPressed: () => mapController?.move(_currentLocation!, 14),
              child: const Icon(Icons.my_location),
            ),
          const SizedBox(height: 8),
          if (_driverLocation != null)
            FloatingActionButton(
              heroTag: 'locate_driver',
              onPressed: () => mapController?.move(_driverLocation!, 14),
              backgroundColor: Colors.blue,
              child: const Icon(Icons.directions_car),
            ),
        ],
      ),
    );
  }
}
