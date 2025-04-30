import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('Password reset email sent successfully to $email');
      return true;
    } catch (e) {
      print('Error sending password reset email: $e');
      return false;
    }
  }
}