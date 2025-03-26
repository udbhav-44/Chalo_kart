import 'package:chalokart/screens/main_screen.dart';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../utils/message_utils.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'sign_up_screen.dart';
import '../global/global.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final authService = AuthService();
      final result = await authService.signIn(
        _emailController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      if (result['success']) {
        final data = result['data'];
        final storageService = StorageService();

        await storageService.saveAuthData(
          token: data['tokens']['access'],
          userId: data['user_id']?.toString() ?? '0',
          userName: data['name'] ?? 'User',
        );
        currentUserEmail = _emailController.text;

        print('User signed in successfully:');
        final userDetails = await authService.fetchUserDetails(currentUserEmail);
        // print('User details: $userDetails');
        
        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      } else {
        setState(() {
          _emailController.clear();
          _passwordController.clear();
          _showPassword = false;
          _isLoading = false;
        });
        
        showMessage(
          context,
          result['message'] ?? 'Failed to sign in',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Text(
                              'Chalo',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                letterSpacing: 0,
                                fontFamily: 'Montserrat',
                                height: 0.8,
                              ),
                            ),
                            Positioned(
                              right: -30,
                              top: -20,
                              child: Icon(
                                  Icons.near_me,
                                  size: 44,
                                  color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      'KART',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        letterSpacing: 0,
                        fontFamily: 'Montserrat',
                        height: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: AppColors.containerColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(50),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 15),
                        const Center(
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w300,
                              color: Colors.black,
                              fontFamily: 'AlbertSans',
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                            fontFamily: 'AlbertSans',
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Email Id*',
                            labelStyle: const TextStyle(
                              fontFamily: 'AlbertSans',
                              color:  Color.fromARGB(255, 105, 101, 101),
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[400]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[400]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.primaryColor),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          style: const TextStyle(
                            fontFamily: 'AlbertSans',
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Password*',
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontFamily: 'AlbertSans',
                              color: Color.fromARGB(255, 105, 101, 101),
                              fontSize: 15,
                            ),
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[400]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[400]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.primaryColor),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(() {
                                  _showPassword = !_showPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => const ForgotPasswordScreen(),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    const begin = Offset(1.0, 0.0);
                                    const end = Offset.zero;
                                    const curve = Curves.easeInOutCubic;
                                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                    var offsetAnimation = animation.drive(tween);
                                    return SlideTransition(position: offsetAnimation, child: child);
                                  },
                                  transitionDuration: const Duration(milliseconds: 400),
                                  reverseTransitionDuration: const Duration(milliseconds: 400),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              'Forgot Password',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'AlbertSans',
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: Color.fromARGB(255, 51, 50, 50),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      fontFamily: 'AlbertSans',
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'First time here? ',
                      style: TextStyle(
                        color:  Color.fromARGB(255, 59, 59, 57),
                        fontSize: 15,
                        fontFamily: 'AlbertSans',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => const SignUpScreen(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              const begin = Offset(1.0, 0.0);
                              const end = Offset.zero;
                              const curve = Curves.easeInOutCubic;
                              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                              var offsetAnimation = animation.drive(tween);
                              return SlideTransition(position: offsetAnimation, child: child);
                            },
                            transitionDuration: const Duration(milliseconds: 400),
                            reverseTransitionDuration: const Duration(milliseconds: 400),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryColor,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 30),
                      ),
                      child: const Text(
                        'Create Account',
                        style: TextStyle(
                          color:  Color.fromARGB(255, 59, 59, 57),
                          fontSize: 15,
                          fontFamily: 'AlbertSans',
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 