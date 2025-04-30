import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isValidEmail = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: size.height * 0.05),
                  
                  // Email icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset_outlined,
                      size: 60,
                      color: Colors.black,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Title
                  Text(
                    'Reset Password',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Subtitle
                  Text(
                    'Enter your email address and we\'ll send you instructions to reset your password.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  
                  SizedBox(height: size.height * 0.05),
                  
                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    onChanged: (value) {
                      final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                      setState(() {
                        _isValidEmail = regex.hasMatch(value);
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Email',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: Colors.grey.shade700,
                      ),
                      suffixIcon: _emailController.text.isNotEmpty
                        ? Icon(
                            _isValidEmail ? Icons.check_circle : Icons.error,
                            color: _isValidEmail ? Colors.green : Colors.red.shade300,
                          )
                        : null,
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.shade400,
                          width: 1,
                        ),
                      ),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  
                  SizedBox(height: size.height * 0.03),
                  
                  // Reset Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() => _isLoading = true);
                                
                                try {
                                  final success = await context
                                      .read<AuthProvider>()
                                      .sendPasswordResetEmail(_emailController.text.trim());
                                  
                                  if (success) {
                                    setState(() => _isLoading = false);
                                    
                                    // Show success animation dialog
                                    showDialog(
                                      context: context,
                                      builder: (context) => Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16)
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(24.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.check_circle, 
                                                color: Colors.green, 
                                                size: 70
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'Email Sent!',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Check your inbox for password reset instructions',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              const SizedBox(height: 24),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context); // Close dialog
                                                  Navigator.pop(context); // Return to login
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.black,
                                                  minimumSize: const Size(double.infinity, 50),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                                child: Text(
                                                  'Back to Login',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        behavior: SnackBarBehavior.floating,
                                        margin: const EdgeInsets.all(16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8)
                                        ),
                                        content: Text(
                                          'Failed to send password reset email',
                                          style: GoogleFonts.poppins(),
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    setState(() => _isLoading = false);
                                  }
                                } catch (e) {
                                  String errorMessage = 'An error occurred';
                                  
                                  // More specific error messages
                                  if (e.toString().contains('user-not-found')) {
                                    errorMessage = 'No account found with this email';
                                  } else if (e.toString().contains('invalid-email')) {
                                    errorMessage = 'Invalid email format';
                                  }
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      margin: const EdgeInsets.all(16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)
                                      ),
                                      content: Text(
                                        errorMessage,
                                        style: GoogleFonts.poppins(),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  setState(() => _isLoading = false);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? FadeTransition(
                              opacity: const AlwaysStoppedAnimation(0.8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Sending...',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Text(
                              'Send Reset Link',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Back to login link
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Back to login',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}