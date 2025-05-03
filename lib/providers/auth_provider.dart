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

  /// Changes the user's password
  /// Requires the user to be recently authenticated
  Future<void> changePassword({
    required String currentPassword, 
    required String newPassword
  }) async {
    try {
      // Get current user
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      // Get the user's email (needed for reauthentication)
      final email = user.email;
      if (email == null) {
        throw Exception('No email associated with current user');
      }
      
      // Create credentials with current password
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      
      // Re-authenticate user
      await user.reauthenticateWithCredential(credential);
      
      // Change password
      await user.updatePassword(newPassword);
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'wrong-password':
            throw Exception('The current password is incorrect.');
          case 'requires-recent-login':
            throw Exception('Please log in again before changing your password.');
          case 'weak-password':
            throw Exception('The new password is too weak. Please use a stronger password.');
          default:
            throw Exception('Failed to change password: ${e.message}');
        }
      } else {
        throw Exception('Failed to change password: ${e.toString()}');
      }
    }
  }

  /// Check if user signed in with a specific provider
  bool isSignedInWithProvider(String providerName) {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    // Check provider IDs in the user's providerData
    return user.providerData.any((userInfo) => 
      userInfo.providerId == providerName);
  }

  /// Check if user can change password (has email/password auth)
  bool canChangePassword() {
    return isSignedInWithProvider('password');
  }
}