import 'package:flutter/material.dart';
import '../core/configs/theme/app_colors.dart';
import '../core/widgets/app_sidebar.dart';

typedef PopCallback = Future<bool> Function(bool didPop);
typedef PopInvokedCallback = Future<bool> Function(bool didPop);

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

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
        key: scaffoldKey,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              scaffoldKey.currentState?.openDrawer();
            },
          ),
          title: const Text('Admin Dashboard'),
        ),
        drawer: const AppSidebar(),
        body: GridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.all(16),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildDashboardCard(
              context,
              icon: Icons.directions_car,
              title: 'Active Rides',
              count: '5',
              color: AppColors.primary,
            ),
            _buildDashboardCard(
              context,
              icon: Icons.people,
              title: 'Total Drivers',
              count: '12',
              color: AppColors.success,
            ),
            _buildDashboardCard(
              context,
              icon: Icons.history,
              title: 'Completed Rides',
              count: '128',
              color: AppColors.warning,
            ),
            _buildDashboardCard(
              context,
              icon: Icons.report_problem,
              title: 'Issues',
              count: '2',
              color: AppColors.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String count,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                count,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
