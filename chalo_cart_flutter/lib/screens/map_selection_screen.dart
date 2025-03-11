import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';

class MapSelectionScreen extends StatefulWidget {
  final LatLng? initialLocation;
  
  const MapSelectionScreen({super.key, this.initialLocation});
  
  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  LatLng? _selectedPosition;
  LatLng? _currentLocation;
  bool _isLoading = true;
  String? _errorMessage;
  MapController? mapController;
  bool _isSearching = false;
  List<Map<String, dynamic>>? _searchResults;
  final _apiService = ApiService();
  String? _selectedAddress;
  
  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _initializeLocation();
  }
  
  Future<void> _initializeLocation() async {
    if (widget.initialLocation != null) {
      setState(() {
        _selectedPosition = widget.initialLocation;
        _isLoading = false;
      });
      _updateAddress(_selectedPosition!);
      return;
    }
    
    if (!await LocationService.checkLocationPermission(context)) {
      setState(() {
        _errorMessage = 'Location permission required';
        _isLoading = false;
      });
      return;
    }
    
    try {
      final location = await LocationService.getCurrentLocation();
      if (mounted && location != null) {
        setState(() {
          _currentLocation = LatLng(location.latitude, location.longitude);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not get current location';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateAddress(LatLng location) async {
    final address = await _apiService.getAddressFromCoordinates(location);
    if (mounted && address != null) {
      setState(() => _selectedAddress = address);
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = null);
      return;
    }

    final results = await _apiService.searchLocations(query);
    if (mounted) {
      setState(() => _searchResults = results);
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final location = LatLng(
      result['lat'] as double,
      result['lon'] as double,
    );
    setState(() {
      _selectedPosition = location;
      _selectedAddress = result['display_name'];
      _isSearching = false;
      _searchResults = null;
    });
    mapController?.move(location, 16);
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedPosition = point;
      _isSearching = false;
      _searchResults = null;
    });
    _updateAddress(point);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching 
          ? TextField(
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search location...',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
              onChanged: _searchLocation,
            )
          : const Text('Select Location'),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _isSearching = true),
            ),
          if (!_isSearching)
            TextButton(
              onPressed: _selectedPosition == null
                  ? null
                  : () => Navigator.pop(context, _selectedPosition),
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.white),
              ),
            ),
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
                    onPressed: _initializeLocation,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: _selectedPosition ?? _currentLocation ?? const LatLng(37.42796133580664, -122.085749655962),
                    initialZoom: 14,
                    onTap: _onMapTap,
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
                              color: Colors.blue,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    if (_selectedPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedPosition!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (_searchResults != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _searchResults!.map((result) => ListTile(
                          title: Text(result['display_name']),
                          onTap: () => _selectSearchResult(result),
                        )).toList(),
                      ),
                    ),
                  ),
                if (_selectedAddress != null && !_isSearching)
                  Positioned(
                    bottom: 100,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.1 * 255).round()),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(_selectedAddress!),
                    ),
                  ),
              ],
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_currentLocation != null)
            FloatingActionButton(
              heroTag: 'locate',
              onPressed: () => mapController?.move(_currentLocation!, 14),
              child: const Icon(Icons.my_location),
            ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'zoom_in',
            onPressed: () {
              final currentZoom = mapController?.zoom ?? 14;
              mapController?.move(
                mapController?.center ?? 
                _selectedPosition ?? 
                _currentLocation ?? 
                const LatLng(37.42796133580664, -122.085749655962),
                currentZoom + 1,
              );
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'zoom_out',
            onPressed: () {
              final currentZoom = mapController?.zoom ?? 14;
              mapController?.move(
                mapController?.center ?? 
                _selectedPosition ?? 
                _currentLocation ?? 
                const LatLng(37.42796133580664, -122.085749655962),
                currentZoom - 1,
              );
            },
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}
