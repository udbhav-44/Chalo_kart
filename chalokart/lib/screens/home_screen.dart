// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../services/storage_service.dart';
import 'sign_in_screen.dart';

class CartItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final double rating;
  final bool isAvailable;
  final int seatingCapacity;
  final String type;
  final List<String> features;

  CartItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.rating,
    required this.isAvailable,
    required this.seatingCapacity,
    required this.type,
    required this.features,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _isLoading = false;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Available', 'Top Rated', 'Price: Low to High', 'Price: High to Low', '4 Seater', '6 Seater'];
  
  // Dummy data for demonstration
  final List<CartItem> _carts = [
    CartItem(
      id: '1',
      name: 'Standard Golf Cart',
      description: 'Comfortable 4-seater golf cart, perfect for small groups and campus tours.',
      price: 499,
      imageUrl: 'assets/images/cart1.jpg',
      rating: 4.5,
      isAvailable: true,
      seatingCapacity: 4,
      type: 'Electric',
      features: ['Air-conditioned', 'USB Charging', 'Luggage Space'],
    ),
    CartItem(
      id: '2',
      name: 'Premium Transport Cart',
      description: 'Luxury 6-seater cart with enhanced comfort and amenities.',
      price: 799,
      imageUrl: 'assets/images/cart2.jpg',
      rating: 4.8,
      isAvailable: true,
      seatingCapacity: 6,
      type: 'Electric',
      features: ['Air-conditioned', 'USB Charging', 'Bluetooth Audio', 'Extra Luggage Space', 'Rain Protection'],
    ),
    CartItem(
      id: '3',
      name: 'Compact Cart',
      description: 'Economic 4-seater cart for quick trips and short distances.',
      price: 299,
      imageUrl: 'assets/images/cart3.jpg',
      rating: 4.2,
      isAvailable: false,
      seatingCapacity: 4,
      type: 'Electric',
      features: ['USB Charging', 'Basic Luggage Space'],
    ),
  ];

  List<CartItem> get _filteredCarts {
    switch (_selectedFilter) {
      case 'Available':
        return _carts.where((cart) => cart.isAvailable).toList();
      case 'Top Rated':
        return List.from(_carts)..sort((a, b) => b.rating.compareTo(a.rating));
      case 'Price: Low to High':
        return List.from(_carts)..sort((a, b) => a.price.compareTo(b.price));
      case 'Price: High to Low':
        return List.from(_carts)..sort((a, b) => b.price.compareTo(a.price));
      case '4 Seater':
        return _carts.where((cart) => cart.seatingCapacity == 4).toList();
      case '6 Seater':
        return _carts.where((cart) => cart.seatingCapacity == 6).toList();
      default:
        return _carts;
    }
  }

  void _handleLogout() async {
    final storageService = StorageService();
    await storageService.clearAuthData();
    
    if (!mounted) return;
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const SignInScreen()),
      (route) => false,
    );
  }

  void _showBookingDialog(CartItem cart) {
    String? pickupLocation;
    String? dropLocation;
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Book ${cart.name}',
          style: const TextStyle(
            fontFamily: 'AlbertSans',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Price: ₹${cart.price.toStringAsFixed(2)}/hour',
                style: const TextStyle(
                  fontFamily: 'AlbertSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Seating Capacity: ${cart.seatingCapacity} persons',
                style: const TextStyle(
                  fontFamily: 'AlbertSans',
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Type: ${cart.type}',
                style: const TextStyle(
                  fontFamily: 'AlbertSans',
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Features:',
                style: TextStyle(
                  fontFamily: 'AlbertSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: cart.features.map((feature) => Chip(
                  label: Text(
                    feature,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: AppColors.primaryColor.withAlpha(100),
                )).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Pickup Location',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) => pickupLocation = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Drop Location',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) => dropLocation = value,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Duration (hours)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'AlbertSans',
                color: Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle booking logic here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Booking request sent successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Book Now',
              style: TextStyle(
                fontFamily: 'AlbertSans',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        title: const Text(
          'ChaloKart',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontFamily: 'Montserrat',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primaryColor,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search carts...',
                    hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontFamily: 'AlbertSans',
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: Colors.black87,
                          checkmarkColor: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredCarts.length,
                    itemBuilder: (context, index) {
                      final cart = _filteredCarts[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                image: DecorationImage(
                                  image: AssetImage(cart.imageUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        cart.name,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'AlbertSans',
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: cart.isAvailable
                                              ? Colors.green
                                              : Colors.red,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          cart.isAvailable
                                              ? 'Available'
                                              : 'Not Available',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontFamily: 'AlbertSans',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    cart.description,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                      fontFamily: 'AlbertSans',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '₹${cart.price.toStringAsFixed(2)}/day',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryColor,
                                          fontFamily: 'AlbertSans',
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            cart.rating.toString(),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'AlbertSans',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: cart.isAvailable
                                          ? () => _showBookingDialog(cart)
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryColor,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        'Book Now',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'AlbertSans',
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 