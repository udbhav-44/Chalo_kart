import 'package:flutter/material.dart';
import '../core/configs/theme/app_colors.dart';
import '../core/widgets/app_button.dart';

class DriverSettingsScreen extends StatefulWidget {
  const DriverSettingsScreen({super.key});

  @override
  State<DriverSettingsScreen> createState() => _DriverSettingsScreenState();
}

class _DriverSettingsScreenState extends State<DriverSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvoked: (didPop) {
        if (didPop) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            Navigator.of(context).pushReplacementNamed('/driverHome');
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacementNamed('/driverHome');
              }
            },
          ),
          title: const Text('Settings'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection(
              title: 'Account',
              children: [
                _buildSettingItem(
                  icon: Icons.person_outline,
                  title: 'Profile Information',
                  onTap: () {},
                ),
                _buildSettingItem(
                  icon: Icons.security,
                  title: 'Password & Security',
                  onTap: () {},
                ),
                _buildSettingItem(
                  icon: Icons.document_scanner_outlined,
                  title: 'Documents',
                  onTap: () {},
                ),
              ],
            ),
            _buildSection(
              title: 'Preferences',
              children: [
                _buildSwitchItem(
                  icon: Icons.notifications_outlined,
                  title: 'Push Notifications',
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                ),
                _buildSwitchItem(
                  icon: Icons.location_on_outlined,
                  title: 'Location Services',
                  value: _locationEnabled,
                  onChanged: (value) {
                    setState(() => _locationEnabled = value);
                  },
                ),
                _buildSettingItem(
                  icon: Icons.language,
                  title: 'Language',
                  onTap: () {},
                  trailing: DropdownButton<String>(
                    value: _selectedLanguage,
                    items: ['English', 'Hindi', 'Spanish']
                        .map((lang) => DropdownMenuItem(
                              value: lang,
                              child: Text(lang),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedLanguage = value);
                      }
                    },
                    underline: const SizedBox(),
                  ),
                ),
              ],
            ),
            _buildSection(
              title: 'Vehicle',
              children: [
                _buildSettingItem(
                  icon: Icons.directions_car_outlined,
                  title: 'Vehicle Information',
                  onTap: () {},
                ),
                _buildSettingItem(
                  icon: Icons.build_outlined,
                  title: 'Maintenance History',
                  onTap: () {},
                ),
              ],
            ),
            _buildSection(
              title: 'Support',
              children: [
                _buildSettingItem(
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  onTap: () {},
                ),
                _buildSettingItem(
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppButton(
                text: 'Logout',
                onPressed: () {},
                isOutlined: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }
}