import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import 'reset_password_screen.dart';
import 'sign_in_screen.dart';
import 'dart:async';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  Timer? _resendTimer;
  int _resendCountdown = 0;
  bool _otpSent = false;
  final bool _isVerifyingOtp = false;
  bool _isResendingOtp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final scaffoldContext = ScaffoldMessenger.of(context);

    try {
      final result = await _authService.requestPasswordReset(_emailController.text);

      if (!mounted) return;

      if (result['success']) {
        setState(() {
          _otpSent = true;
          _startResendTimer();
        });
        scaffoldContext.showSnackBar(const SnackBar(
          backgroundColor: Colors.green,
          content: Text('OTP sent successfully. Please check your email.'),
        ));
      } else {
        scaffoldContext.showSnackBar(SnackBar(
          content: Text(result['message'] ?? 'Failed to send OTP'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldContext.showSnackBar(SnackBar(
        content: Text('Error sending OTP: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleVerifyOtp() async {
    if (!_formKey.currentState!.validate() || _otpController.text.length != 6) return;

    final navigator = Navigator.of(context);
    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (context) => ResetPasswordScreen(
          email: _emailController.text,
          otp: _otpController.text,
        ),
      ),
    );
  }

  Future<void> _handleResendOtp() async {
    if (_resendCountdown > 0 || _isResendingOtp) return;

    setState(() => _isResendingOtp = true);
    final scaffoldContext = ScaffoldMessenger.of(context);

    try {
      final result = await _authService.requestPasswordReset(_emailController.text);

      if (!mounted) return;

      if (result['success']) {
        _startResendTimer();
        scaffoldContext.showSnackBar(const SnackBar(
          content: Text('OTP resent successfully'),
          backgroundColor: Colors.green,
        ));
      } else {
        scaffoldContext.showSnackBar(SnackBar(
          content: Text(result['message'] ?? 'Failed to resend OTP'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldContext.showSnackBar(SnackBar(
        content: Text('Error resending OTP: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) {
        setState(() => _isResendingOtp = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.37, 0.37, 1],
                colors: [
                  AppColors.primaryColor,
                  AppColors.primaryColor,
                  Color(0xFFF8F8F8),
                  Color(0xFFF8F8F8)
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                      const Center(
                        child: Text(
                          'Forgot Password',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w300,
                            color: Colors.black,
                            fontFamily: 'AlbertSans',
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Enter your email address to receive a password reset OTP',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontFamily: 'AlbertSans',
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        enabled: !_otpSent,
                        style: const TextStyle(
                          fontFamily: 'AlbertSans',
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: const TextStyle(
                            fontFamily: 'AlbertSans',
                            color: Color.fromARGB(255, 105, 101, 101),
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
                        keyboardType: TextInputType.emailAddress,
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
                      if (!_otpSent)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSendOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
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
                                      'Send Reset OTP',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        fontFamily: 'AlbertSans',
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      if (_otpSent)
                        AnimatedSlide(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutCubic,
                          offset: _otpSent ? const Offset(0, 0) : const Offset(0, 0.5),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOutCubic,
                            opacity: _otpSent ? 1.0 : 0.0,
                            child: Column(
                              children: [
                                const SizedBox(height: 24),
                                TextFormField(
                                  controller: _otpController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  style: const TextStyle(
                                    fontFamily: 'AlbertSans',
                                    fontSize: 15,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Enter OTP',
                                    labelStyle: const TextStyle(
                                      fontFamily: 'AlbertSans',
                                      color: Color.fromARGB(255, 105, 101, 101),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                    counterText: '',
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
                                    if (_otpSent) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter the OTP';
                                      }
                                      if (value.length != 6) {
                                        return 'Please enter a valid 6-digit OTP';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: (_isVerifyingOtp || _otpController.text.length != 6)
                                        ? null
                                        : _handleVerifyOtp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      _isVerifyingOtp ? 'Verifying...' : 'Verify OTP',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        fontFamily: 'AlbertSans',
                                      ),
                                    ),
                                  ),
                                ),
                                if (_resendCountdown > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Text(
                                      'Resend OTP in $_resendCountdown seconds',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontFamily: 'AlbertSans',
                                      ),
                                    ),
                                  ),
                                if (_resendCountdown == 0)
                                  TextButton(
                                    onPressed: _isResendingOtp ? null : _handleResendOtp,
                                    child: Text(
                                      _isResendingOtp ? 'Resending...' : 'Resend OTP',
                                      style: const TextStyle(
                                        fontFamily: 'AlbertSans',
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => const SignInScreen(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                const begin = Offset(-1.0, 0.0);
                                const end = Offset.zero;
                                const curve = Curves.easeInOutCubic;
                                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                var offsetAnimation = animation.drive(tween);
                                return SlideTransition(position: offsetAnimation, child: child);
                              },
                              transitionDuration: const Duration(milliseconds: 400),
                              reverseTransitionDuration: const Duration(milliseconds: 400),
                            ),
                          ),
                          child: const Text(
                            'Back to Sign In',
                            style: TextStyle(
                              fontFamily: 'AlbertSans',
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 