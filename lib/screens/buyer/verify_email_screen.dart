import 'package:flutter/material.dart';
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
        const SnackBar(content: Text('Verification email resent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.email_outlined, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            Text(
              'Check your email',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              'We sent a verification link to ${widget.email}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _checkEmailVerified,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('I\'ve verified my email'),
            ),
            TextButton(
              onPressed: _resendVerificationEmail,
              child: const Text('Resend verification email'),
            ),
          ],
        ),
      ),
    );
  }
}