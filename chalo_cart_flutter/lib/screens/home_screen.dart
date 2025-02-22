import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/trip_provider.dart';
import '../state/payment_provider.dart';
import '../core/widgets/app_sidebar.dart';
import '../core/configs/theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return WillPopScope(
      onWillPop: () async {
        // If possible pop the current route; otherwise, go to login
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return false;
      },
      child: Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              // Use the scaffold key to open the drawer
              scaffoldKey.currentState?.openDrawer();
            },
          ),
          title: const Text('Chalo Cart'),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => Navigator.pushNamed(context, '/notifications'),
            ),
          ],
        ),
        drawer: const AppSidebar(),
        body: isMobile
            ? RawScrollbar(
                thumbVisibility: true,
                thickness: 6,
                radius: const Radius.circular(3),
                child: _buildMobileLayout(context),
              )
            : _buildTabletLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh data
        await Future.wait([
          Provider.of<PaymentProvider>(context, listen: false).fetchWalletBalance(),
          Provider.of<TripProvider>(context, listen: false).fetchTrip('recent'), // placeholder for recent trips update
        ]);
      },
      child: RawScrollbar(
        thumbVisibility: true,
        thickness: 6,
        radius: const Radius.circular(3),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Where would you like to go today?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                _buildFeatureCard(
                  context,
                  title: 'Book a Trip',
                  description: 'Get a ride to your destination',
                  icon: Icons.directions_car,
                  onTap: () => Navigator.pushNamed(context, '/tripBooking'),
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  context,
                  title: 'View Trip History',
                  description: 'Check your past rides',
                  icon: Icons.history,
                  onTap: () => Navigator.pushNamed(context, '/tripHistory'),
                ),
                const SizedBox(height: 24),
                Consumer<PaymentProvider>(
                  builder: (context, paymentProvider, _) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Wallet Balance',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${paymentProvider.walletBalance.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/payment'),
                              child: const Text('Add Funds'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Consumer<TripProvider>(
                  builder: (context, tripProvider, _) {
                    if (tripProvider.currentTrip != null) {
                      return Card(
                        color: Color.fromRGBO(
                          AppColors.primary.r.toInt(),
                          AppColors.primary.g.toInt(),
                          AppColors.primary.b.toInt(),
                          0.1,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withAlpha(26), // Changed from withOpacity(0.1)
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Active Trip',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () => Navigator.pushNamed(
                                      context,
                                      '/tripTracking',
                                      arguments: tripProvider.currentTrip!['id'],
                                    ),
                                    child: const Text('View Details'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Driver: ${tripProvider.currentTrip!['driver_name'] ?? 'Assigned'}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Status: ${tripProvider.currentTrip!['status'] ?? 'Processing'}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Recent Trips',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Consumer<TripProvider>(
                  builder: (context, tripProvider, _) {
                    final recentTrips = [
                      {'from': 'Campus Center', 'to': 'Library', 'date': 'Today', 'amount': '\$5.00'},
                      {'from': 'Library', 'to': 'Dorm', 'date': 'Yesterday', 'amount': '\$3.50'},
                    ];
                    return Column(
                      children: recentTrips.map((trip) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Icon(Icons.directions_car, color: Colors.white),
                          ),
                          title: Text('${trip['from']} → ${trip['to']}'),
                          subtitle: Text(trip['date']!),
                          trailing: Text(
                            trip['amount']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      )).toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        context,
                        icon: Icons.person,
                        title: 'Profile',
                        onTap: () => Navigator.pushNamed(context, '/profile'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickActionCard(
                        context,
                        icon: Icons.notifications,
                        title: 'Notifications',
                        onTap: () => Navigator.pushNamed(context, '/notifications'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26), // Changed from withOpacity(0.1)
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildMobileLayout(context)),
        const Expanded(child: Center(child: Text('Map and other info will be displayed here'))),
      ],
    );
  }
}
