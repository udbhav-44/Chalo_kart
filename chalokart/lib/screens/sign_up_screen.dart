// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../services/auth_service.dart';
import '../utils/message_utils.dart';
import 'sign_in_screen.dart';
import 'dart:async';
import '../services/storage_service.dart';
import '../screens/home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _mobileOtpController = TextEditingController();
  final _emailOtpController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _showMobileOtpStep = false;
  bool _isMobileVerified = false;
  bool _isSendingOtp = false;
  bool _isVerifying = false;
  String? _verificationId;
  bool _isResendingOtp = false;
  String? _phoneNumber;
  Timer? _mobileResendTimer;
  int _mobileResendCountdown = 0;
  bool _otpSent = false;
  Timer? _emailResendTimer;
  int _emailResendCountdown = 0;
  bool _isResendingEmailOtp = false;
  bool _isVerifyingEmail = false;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _mobileOtpController.dispose();
    _emailOtpController.dispose();
    _mobileResendTimer?.cancel();
    _emailResendTimer?.cancel();
    super.dispose();
  }

  void _startMobileResendTimer() {
    _mobileResendCountdown = 30;
    _mobileResendTimer?.cancel();
    _mobileResendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_mobileResendCountdown > 0) {
          _mobileResendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  void _startEmailResendTimer() {
    _emailResendCountdown = 30;
    _emailResendTimer?.cancel();
    _emailResendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_emailResendCountdown > 0) {
          _emailResendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _sendMobileOtp() async {
    if (_mobileController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your mobile number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String mobileNumber = _mobileController.text.trim();
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(mobileNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit mobile number starting with 6-9'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_isSendingOtp) return;

    setState(() {
      _isSendingOtp = true;
      _phoneNumber = mobileNumber;
      _isMobileVerified = false;
      _mobileOtpController.clear();
    });

    final scaffoldContext = ScaffoldMessenger.of(context);

    try {
      final phoneNumber = '+91$mobileNumber';
      final result = await _authService.verifyPhoneNumber(phoneNumber);

      if (!mounted) return;

      if (result['success']) {
        setState(() {
          _verificationId = result['verificationId'];
          _otpSent = true;
          _showMobileOtpStep = true;
        });
        _startMobileResendTimer();
        
        Timer(const Duration(minutes: 5), () {
          if (mounted && !_isMobileVerified) {
            setState(() {
              _otpSent = false;
              _showMobileOtpStep = false;
            });
            scaffoldContext.showSnackBar(const SnackBar(
              content: Text('Mobile OTP has expired. Please request a new one.'),
              backgroundColor: Colors.red,
            ));
          }
        });
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
        setState(() => _isSendingOtp = false);
      }
    }
  }

  Future<void> _verifyMobileOtp() async {
    if (!_showMobileOtpStep || _isVerifying || _mobileOtpController.text.length != 6) {
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    final scaffoldContext = ScaffoldMessenger.of(context);

    try {
      final result = await _authService.verifyOTP(
        _verificationId!,
        _mobileOtpController.text,
      );

      if (!mounted) return;

      if (result['success']) {
        setState(() {
          _isMobileVerified = true;
          _mobileResendTimer?.cancel();
        });
        scaffoldContext.showSnackBar(const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Mobile number verified successfully'),
        ));
      } else {
        scaffoldContext.showSnackBar(SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _resendMobileOtp() async {
    if (_mobileResendCountdown > 0 || _isResendingOtp || _isSendingOtp) return;

    setState(() {
      _isResendingOtp = true;
      _mobileOtpController.clear();
    });

    final scaffoldContext = ScaffoldMessenger.of(context);

    try {
      final phoneNumber = '+91$_phoneNumber';
      final result = await _authService.verifyPhoneNumber(phoneNumber);

      if (!mounted) return;

      if (result['success']) {
        setState(() {
          _verificationId = result['verificationId'];
          _isResendingOtp = false;
        });
        _startMobileResendTimer();
        scaffoldContext.showSnackBar(const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Mobile OTP resent successfully'),
        ));
      } else {
        setState(() {
          _isResendingOtp = false;
        });
        scaffoldContext.showSnackBar(SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isResendingOtp = false;
      });
      scaffoldContext.showSnackBar(SnackBar(
        content: Text('Error resending OTP: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _resendEmailVerification() async {
    if (_emailResendCountdown > 0 || _isResendingEmailOtp) return;

    setState(() {
      _isResendingEmailOtp = true;
    });

    final scaffoldContext = ScaffoldMessenger.of(context);

    try {
      final result = await _authService.resendVerification(_emailController.text);

      if (!mounted) return;

      if (result['success']) {
        _startEmailResendTimer();
        scaffoldContext.showSnackBar(const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Email verification OTP resent successfully'),
        ));
      } else {
        scaffoldContext.showSnackBar(SnackBar(
          content: Text(result['message'] ?? 'Failed to resend verification'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldContext.showSnackBar(SnackBar(
        content: Text('Error resending verification: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) {
        setState(() {
          _isResendingEmailOtp = false;
        });
      }
    }
  }

  void _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      final scaffoldContext = ScaffoldMessenger.of(context);
      
      if (!_isMobileVerified) {
        scaffoldContext.showSnackBar(const SnackBar(
          content: Text('Please verify your mobile number first'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      if (_passwordController.text != _confirmPasswordController.text) {
        scaffoldContext.showSnackBar(const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ));
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final navigator = Navigator.of(context);

      // First, send email verification OTP
      final sendOtpResult = await _authService.sendEmailVerification(_emailController.text);

      if (!mounted) return;

      if (sendOtpResult['success']) {
        _startEmailResendTimer();
        final verificationResult = await showDialog<Map<String, dynamic>>(
          context: context,
          barrierDismissible: false,
          builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text(
                  'Verify Email',
                  style: TextStyle(
                    fontFamily: 'AlbertSans',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Please enter the OTP sent to your email\nThis OTP will expire in 5 minutes.',
                      style: TextStyle(
                        fontFamily: 'AlbertSans',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailOtpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: const TextStyle(
                        fontFamily: 'AlbertSans',
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Enter Email OTP',
                        counterText: '',
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
                      onChanged: (value) {
                        setDialogState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _isVerifyingEmail || _emailOtpController.text.length != 6 ? null : () async {
                          setDialogState(() => _isVerifyingEmail = true);
                          final navigator = Navigator.of(context);
                          final dialogContext = context;
                          
                          try {
                            final verifyResult = await _authService.verifyEmail(
                              _emailController.text,
                              _emailOtpController.text,
                            );
                            
                            if (!mounted) return;
                            
                            if (verifyResult['success']) {
                              navigator.pop(verifyResult);
                            } else {
                              if (verifyResult['expired'] == true) {
                                showMessage(
                                  dialogContext,
                                  'OTP has expired. Please request a new one.',
                                  isError: true,
                                );
                                navigator.pop(verifyResult);
                                _resendEmailVerification();
                              } else {
                                showMessage(
                                  dialogContext,
                                  verifyResult['message'] ?? 'Failed to verify email',
                                  isError: true,
                                );
                              }
                            }
                          } finally {
                            if (mounted) {
                              setDialogState(() => _isVerifyingEmail = false);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _isVerifyingEmail ? 'Verifying...' : 'Verify Email',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'AlbertSans',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_emailResendCountdown > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Resend OTP in $_emailResendCountdown seconds',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontFamily: 'AlbertSans',
                          ),
                        ),
                      ),
                    if (_emailResendCountdown == 0)
                      TextButton(
                        onPressed: _isResendingEmailOtp ? null : () async {
                          final dialogContext = context;
                          await _resendEmailVerification();
                          if (dialogContext.mounted) {
                            setDialogState(() {});
                          }
                        },
                        child: Text(
                          _isResendingEmailOtp ? 'Resending...' : 'Resend OTP',
                          style: const TextStyle(
                            fontFamily: 'AlbertSans',
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      final navigator = Navigator.of(context);
                      navigator.pop({'success': false, 'cancelled': true});
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'AlbertSans',
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );

        if (!mounted) return;

        if (verificationResult != null && verificationResult['success']) {
          // Only create user account after email is verified
          final result = await _authService.signUp(
            name: _nameController.text,
            email: _emailController.text,
            mobile: _mobileController.text,
            password: _passwordController.text,
          );

          if (!mounted) return;

          if (result['success']) {
            scaffoldContext.showSnackBar(
            const SnackBar(backgroundColor: Colors.green,content:
             Text('Account created successfully')));
            // Automatically sign in the user
            final signInResult = await _authService.signIn(
              _emailController.text,
              _passwordController.text,
            );

            if (!mounted) return;

            if (signInResult['success']) {
              final data = signInResult['data'];
              final storageService = StorageService();

              await storageService.saveAuthData(
                token: data['tokens']['access'],
                userId: data['user_id']?.toString() ?? '0',
                userName: data['name'] ?? 'User',
              );

              if (!mounted) return;

              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const SignInScreen()),
                (route) => false,
              );
            } else {
              // If auto sign-in fails, redirect to sign-in screen
              navigator.pushReplacement(
                MaterialPageRoute(builder: (context) => const SignInScreen()),
              );
            }
          } else {
            scaffoldContext.showSnackBar(SnackBar(
              content: Text(result['message'] ?? 'Failed to create account'),
              backgroundColor: Colors.red,
            ));
          }
        } else if (verificationResult != null && !verificationResult['cancelled']) {
          scaffoldContext.showSnackBar(SnackBar(
            content: Text(verificationResult['message'] ?? 'Failed to verify email'),
            backgroundColor: Colors.red,
          ));
        }
      } else {
        scaffoldContext.showSnackBar(SnackBar(
          content: Text(sendOtpResult['message'] ?? 'Failed to send verification email'),
          backgroundColor: Colors.red,
        ));
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
                Container(
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
                            'Sign Up',
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
                          controller: _nameController,
                          style: const TextStyle(
                            fontFamily: 'AlbertSans',
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Full Name*',
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _mobileController,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(
                                  fontFamily: 'AlbertSans',
                                  fontSize: 15,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Mobile Number*',
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
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your mobile number';
                                  }
                                  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
                                    return 'Enter valid number starting with 6-9';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              reverseDuration: const Duration(milliseconds: 200),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (Widget child, Animation<double> animation) {
                                return FadeTransition(
                                  opacity: CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeInOut,
                                  ),
                                  child: ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: !_otpSent
                                ? ElevatedButton(
                                    key: const ValueKey('send_otp'),
                                    onPressed: _isSendingOtp ? null : _sendMobileOtp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryColor,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    ),
                                    child: Text(_isSendingOtp ? 'Sending...' : 'Send OTP'),
                                  )
                                : Container(
                                    key: const ValueKey('otp_sent'),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withAlpha(25),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.green),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          'OTP Sent',
                                          style: TextStyle(color: Colors.green),
                                        ),
                                      ],
                                    ),
                                  ),
                            ),
                          ],
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 400),
                          reverseDuration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOutCubic,
                          alignment: Alignment.topCenter,
                          child: _showMobileOtpStep ? Column(
                            children: [
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _mobileOtpController,
                                      keyboardType: TextInputType.number,
                                      maxLength: 6,
                                      enabled: _otpSent && !_isMobileVerified && !_isVerifying,
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
                                        suffixIcon: _isMobileVerified
                                            ? const Icon(
                                                Icons.check_circle,
                                                color: Colors.green,
                                              )
                                            : null,
                                      ),
                                      validator: (value) {
                                        if (_showMobileOtpStep && !_isMobileVerified) {
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
                                  ),
                                  const SizedBox(width: 8),
                                  if (!_isMobileVerified)
                                    ElevatedButton(
                                      onPressed: (_otpSent && !_isVerifying && _mobileOtpController.text.length == 6) 
                                          ? _verifyMobileOtp 
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryColor,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      ),
                                      child: Text(_isVerifying ? 'Verifying...' : 'Verify OTP'),
                                    ),
                                ],
                              ),
                              if (!_isMobileVerified && _mobileResendCountdown > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Resend OTP in $_mobileResendCountdown seconds',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontFamily: 'AlbertSans',
                                    ),
                                  ),
                                ),
                              if (!_isMobileVerified && _mobileResendCountdown == 0)
                                TextButton(
                                  onPressed: _isResendingOtp ? null : _resendMobileOtp,
                                  child: Text(
                                    _isResendingOtp ? 'Resending...' : 'Resend OTP',
                                    style: const TextStyle(
                                      fontFamily: 'AlbertSans',
                                    ),
                                  ),
                                ),
                            ],
                          ) : Container(),
                        ),
                        const SizedBox(height: 16),
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
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_showConfirmPassword,
                          style: const TextStyle(
                            fontFamily: 'AlbertSans',
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Confirm Password*',
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
                                _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(() {
                                  _showConfirmPassword = !_showConfirmPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignUp,
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
                                    'Sign Up',
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
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: Color.fromARGB(255, 59, 59, 57),
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
                            pageBuilder: (context, animation, secondaryAnimation) => const SignInScreen(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              const begin = Offset(-1.0, 0.0);
                              const end = Offset.zero;
                              const curve = Curves.easeInOutCubic;
                              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                              var offsetAnimation = animation.drive(tween);
                              return SlideTransition(
                                position: offsetAnimation,
                                child: FadeTransition(
                                  opacity: animation.drive(
                                    CurveTween(curve: Curves.easeInOut),
                                  ),
                                  child: child,
                                ),
                              );
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
                        'Sign In',
                        style: TextStyle(
                          color: Color.fromARGB(255, 59, 59, 57),
                          fontSize: 15,
                          fontFamily: 'AlbertSans',
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.underline,
                        ),
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
} 