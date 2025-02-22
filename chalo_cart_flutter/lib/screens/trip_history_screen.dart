import 'package:flutter/material.dart';
import '../core/configs/theme/app_colors.dart';

class TripHistoryScreen extends StatelessWidget {
  const TripHistoryScreen({super.key});

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
      child: DefaultTabController(
        length: 2,
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
            title: const Text('Trip History'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Completed'),
                Tab(text: 'Cancelled'),
              ],
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
            ),
          ),
          body: TabBarView(
            children: [
              _buildTripList(completed: true),
              _buildTripList(completed: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripList({required bool completed}) {
    return RawScrollbar(
      thumbVisibility: true,
      thickness: 6,
      radius: const Radius.circular(3),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Trip #${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: completed
                              ? AppColors.success.withAlpha(26)
                              : AppColors.error.withAlpha(26),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          completed ? 'Completed' : 'Cancelled',
                          style: TextStyle(
                            color: completed ? AppColors.success : AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildTripDetail(
                    icon: Icons.location_on,
                    title: 'From',
                    value: 'Campus Center',
                  ),
                  const SizedBox(height: 8),
                  _buildTripDetail(
                    icon: Icons.location_on_outlined,
                    title: 'To',
                    value: 'Library',
                  ),
                  const SizedBox(height: 8),
                  _buildTripDetail(
                    icon: Icons.access_time,
                    title: 'Time',
                    value: '10:30 AM, Feb 10',
                  ),
                  const SizedBox(height: 8),
                  _buildTripDetail(
                    icon: Icons.attach_money,
                    title: 'Amount',
                    value: '\$5.00',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTripDetail({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$title: ',
          style: TextStyle(
            color: Colors.grey.withAlpha(120),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}