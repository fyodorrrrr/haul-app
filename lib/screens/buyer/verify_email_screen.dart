import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '/providers/user_registration_provider.dart';
import 'register_info_screen.dart';
import 'home_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isVerified = false;
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCooldown = 0;
  Timer? _verificationTimer;
  Timer? _cooldownTimer;
  Timer? _timer;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startAutoVerificationCheck();
    _startEmailVerificationTimer();
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    _cooldownTimer?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoVerificationCheck() {
    _verificationTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _checkEmailVerified();
    });
  }

  void _startEmailVerificationTimer() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkIfEmailIsVerified();
    });
  }

  void _startResendCooldown() {
    setState(() => _resendCooldown = 30);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        _cooldownTimer?.cancel();
      }
    });
  }

  Future<void> _checkEmailVerified() async {
    if (_isVerified) return;
    
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null && user.emailVerified) {
        await _updateFirestoreVerification(user.uid);
        setState(() => _isVerified = true);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomeScreen(userData: {
                'uid': user.uid,
                'email': user.email ?? widget.email,
              }),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildSnackBar('Error: ${e.toString()}', isError: true),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkIfEmailIsVerified() async {
    if (_isVerifying) return;
    
    setState(() {
      _isVerifying = true;
    });
    
    try {
      final verified = await context.read<UserRegistrationProvider>().checkEmailVerification();
      
      if (verified) {
        _timer?.cancel();
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => RegisterInfoScreen(
              userData: {'email': widget.email},
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  Future<void> _updateFirestoreVerification(String uid) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'emailVerified': true, 'verified_at': FieldValue.serverTimestamp()});
  }

  Future<void> _resendVerificationEmail() async {
    setState(() => _isResending = true);
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      _startResendCooldown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildSnackBar('Verification email resent!'),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildSnackBar('Error: ${e.toString()}', isError: true),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  SnackBar _buildSnackBar(String message, {bool isError = false}) {
    return SnackBar(
      content: Text(
        message,
        style: GoogleFonts.poppins(),
      ),
      backgroundColor: isError ? Colors.red : Colors.black,
    );
  }

  Future<void> _openEmailApp() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please check your email app'),
        backgroundColor: Colors.black,
      ),
    );
  }

  Future<void> _verifyEmailManually() async {
    setState(() {
      _isVerifying = true;
    });
    
    try {
      final verified = await context.read<UserRegistrationProvider>().checkEmailVerification();
      
      if (verified) {
        _timer?.cancel();
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => RegisterInfoScreen(
              userData: {'email': widget.email},
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email not verified yet. Please check your inbox.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 350;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: size.height * 0.08),
                
                // Email icon with status badge
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.email_outlined,
                        size: isSmallScreen ? 60 : 80,
                        color: Colors.black,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _isVerified ? Colors.green : Colors.orange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          _isVerified ? Icons.check : Icons.access_time,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: size.height * 0.05),
                
                // Title and description
                Text(
                  'Check your email',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 22 : 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                SizedBox(height: size.height * 0.02),
                
                Text(
                  'We sent a verification link to:',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                
                SizedBox(height: 8),
                
                // Email address with copy option
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: widget.email));
                    ScaffoldMessenger.of(context).showSnackBar(
                      _buildSnackBar('Email copied to clipboard'),
                    );
                  },
                  child: Text(
                    widget.email,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                SizedBox(height: size.height * 0.04),
                
                // Open email app button
                OutlinedButton.icon(
                  onPressed: _openEmailApp,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(
                    'Open Email App',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                ),
                
                SizedBox(height: size.height * 0.04),
                
                // Verification button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyEmailManually,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'I\'ve verified my email',
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Resend email button with cooldown
                TextButton(
                  onPressed: _resendCooldown > 0 || _isResending
                      ? null
                      : _resendVerificationEmail,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                  ),
                  child: _isResending
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          _resendCooldown > 0
                              ? 'Resend in $_resendCooldown seconds'
                              : 'Resend verification email',
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 13 : 14,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}