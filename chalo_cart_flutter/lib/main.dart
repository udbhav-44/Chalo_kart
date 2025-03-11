import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/utils/route_transitions.dart';

import 'screens/onboarding_screen.dart';

import 'screens/login_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/trip_booking_screen.dart';
import 'screens/trip_tracking_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/trip_history_screen.dart';
import 'screens/driver_home_screen.dart';
import 'screens/driver_settings_screen.dart';
import 'state/auth_provider.dart';
import 'state/trip_provider.dart';
import 'state/payment_provider.dart';
import 'state/navigation_provider.dart';
import 'core/configs/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Request location permissions at app startup
  await Geolocator.requestPermission();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TripProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chalo Cart',
      theme: AppTheme.theme,
      initialRoute: '/onboarding',
      onGenerateRoute: (settings) {
        final routes = {
          '/onboarding': (context) => const OnboardingScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/resetPassword': (context) => const ResetPasswordScreen(),
          '/home': (context) => const HomeScreen(),
          '/tripBooking': (context) => const TripBookingScreen(),
          '/tripTracking': (context) {
            final tripId = settings.arguments as String;
            return TripTrackingScreen(tripId: tripId);
          },
          '/payment': (context) => const PaymentScreen(),
          '/adminDashboard': (context) => const AdminDashboardScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/tripHistory': (context) => const TripHistoryScreen(),
          '/driverHome': (context) => const DriverHomeScreen(),
          '/driverSettings': (context) => const DriverSettingsScreen(),
        };
        
        final builder = routes[settings.name];
        if (builder != null) {
          return RouteTransitions.createRoute(builder(context));
        }
        return null;
      },
    );
  }
}
