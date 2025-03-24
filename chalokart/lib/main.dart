import 'package:chalokart/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/verify_email_screen.dart';
import 'utils/app_colors.dart';
import 'infoHandler/app_info.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppInfo(),
      child: MaterialApp(
        title: 'ChalokartKART',
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.transparent,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryColor,
          ),
          fontFamily: 'AlbertSans',
          textTheme: const TextTheme(
            bodyLarge: TextStyle(fontFamily: 'AlbertSans'),
            bodyMedium: TextStyle(fontFamily: 'AlbertSans'),
            titleLarge: TextStyle(fontFamily: 'AlbertSans'),
            titleMedium: TextStyle(fontFamily: 'AlbertSans'),
            labelLarge: TextStyle(fontFamily: 'AlbertSans'),
          ),
          useMaterial3: true,
        ),
        builder: (context, child) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0,0.32,0.32,1],
                colors: [
                  AppColors.primaryColor,
                  AppColors.primaryColor,
                  Color(0xFFF8F8F8),
                  Color(0xFFF8F8F8)
                ],
              ),
            ),
            child: child!,
          );
        },
        initialRoute: '/',
        routes: {
          '/': (context) => const SignInScreen(),
          '/signin': (context) => const SignInScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/home': (context) => const HomeScreen(),
          '/verify-email': (context) => VerifyEmailScreen(
            email: ModalRoute.of(context)!.settings.arguments as String,
          ),
        },
      ),
    );
  }
}
