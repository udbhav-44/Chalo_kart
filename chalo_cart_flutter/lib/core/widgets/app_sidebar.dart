import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_provider.dart';
import '../../state/navigation_provider.dart';
import '../configs/theme/app_colors.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  List<MenuSection> _getMenuSections(String role) {
    return [
      MenuSection(
        title: 'Main',
        items: [
          MenuItem(
            title: role == 'driver' ? 'Driver Home' : 'Home',
            icon: Icons.home,
            route: role == 'driver' ? '/driverHome' : '/home',
          ),
          if (role == 'admin')
            MenuItem(
              title: 'Admin Dashboard',
              icon: Icons.dashboard,
              route: '/adminDashboard',
            ),
        ],
      ),
      MenuSection(
        title: 'Activities',
        items: [
          MenuItem(
            title: 'Trip History',
            icon: Icons.history,
            route: '/tripHistory',
          ),
          MenuItem(
            title: 'Wallet',
            icon: Icons.account_balance_wallet,
            route: '/payment',
          ),
        ],
      ),
      MenuSection(
        title: 'Account',
        items: [
          MenuItem(
            title: 'Profile',
            icon: Icons.person,
            route: '/profile',
          ),
          MenuItem(
            title: 'Notifications',
            icon: Icons.notifications,
            route: '/notifications',
          ),
          MenuItem(
            title: 'Settings',
            icon: Icons.settings,
            route: role == 'driver' ? '/driverSettings' : '/profile',
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final navigationProvider = Provider.of<NavigationProvider>(context);
    final String role = authProvider.user?['role'] as String? ?? 'customer';
    final menuSections = _getMenuSections(role);

    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, authProvider, role),
          Expanded(
            child: Scrollbar(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: menuSections.length,
                itemBuilder: (context, sectionIndex) {
                  final section = menuSections[sectionIndex];
                  return _buildSection(context, section, navigationProvider);
                },
              ),
            ),
          ),
          const Divider(height: 1),
          _buildLogoutTile(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider authProvider, String role) {
    return DrawerHeader(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, '/profile'),
              child: const Icon(Icons.person, size: 32, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, '/profile'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    authProvider.user?['user_name'] ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      role[0].toUpperCase() + role.substring(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, MenuSection section, NavigationProvider navigationProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            section.title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...section.items.map((item) => _buildMenuItem(context, item, navigationProvider)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, MenuItem item, NavigationProvider navigationProvider) {
    final isSelected = navigationProvider.currentRoute == item.route;
    return ListTile(
      leading: Icon(
        item.icon,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        item.title,
        style: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primaryBack,
      onTap: () {
        navigationProvider.setCurrentRoute(item.route);
        Navigator.pop(context); // Close the drawer
        if (ModalRoute.of(context)?.settings.name != item.route) {
          Navigator.pushNamed(context, item.route);
        }
      },
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListTile(
        leading: const Icon(Icons.logout, color: AppColors.error),
        title: const Text(
          'Logout',
          style: TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.error),
        ),
        onTap: () {
          Provider.of<AuthProvider>(context, listen: false).logout();
          Provider.of<NavigationProvider>(context, listen: false).setCurrentRoute('/login');
          Navigator.pushReplacementNamed(context, '/login');
        },
      ),
    );
  }
}

class MenuItem {
  final String title;
  final IconData icon;
  final String route;

  MenuItem({
    required this.title,
    required this.icon,
    required this.route,
  });
}

class MenuSection {
  final String title;
  final List<MenuItem> items;

  MenuSection({
    required this.title,
    required this.items,
  });
}
