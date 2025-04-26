import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<void> _checkEmailVerified() async {
    setState(() => _isLoading = true);
    
    // Reload user to get latest verification status
    await FirebaseAuth.instance.currentUser?.reload();
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null && user.emailVerified) {
      // Update Firestore if verified
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'emailVerified': true});
      
      setState(() => _isVerified = true);
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(userData: {
            'uid': user.uid,
            'email': user.email,
          }),
        ),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _resendVerificationEmail() async {
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verification email resent!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.black,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.toString()}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
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
                
                // Email icon
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
                
                SizedBox(height: size.height * 0.05),
                
                // Check your email text
                Text(
                  'Check your email',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 22 : 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                SizedBox(height: size.height * 0.02),
                
                // Email description
                Text(
                  'We sent a verification link to:',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                
                SizedBox(height: 8),
                
                // Email address
                Text(
                  widget.email,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                SizedBox(height: size.height * 0.06),
                
                // I've verified button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _checkEmailVerified,
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
                
                // Resend verification email
                TextButton(
                  onPressed: _resendVerificationEmail,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                  ),
                  child: Text(
                    'Resend verification email',
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