import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class UserRegistrationProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _emailVerified = false;
  Timer? _emailVerificationTimer;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get emailVerified => _emailVerified;
  
  // Check if email is verified
  Future<bool> checkEmailVerification() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Reload user to get latest verification status
      await _auth.currentUser?.reload();
      _user = _auth.currentUser;
      
      _emailVerified = _user?.emailVerified ?? false;
      _isLoading = false;
      notifyListeners();
      
      return _emailVerified;
    } catch (e) {
      _isLoading = false;
      _error = _getFirebaseErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // Start timer to check email verification periodically
  void startEmailVerificationCheck() {
    _emailVerificationTimer?.cancel();
    _emailVerificationTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final verified = await checkEmailVerification();
      if (verified) {
        timer.cancel();
      }
    });
  }
  
  // Stop checking email verification
  void stopEmailVerificationCheck() {
    _emailVerificationTimer?.cancel();
    _emailVerificationTimer = null;
  }
  
  // Update user profile information
  Future<bool> updateUserInformation(Map<String, dynamic> userData) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      _user = _auth.currentUser;
      
      if (_user == null) {
        throw Exception('User not authenticated');
      }
      
      // Update display name if available
      if (userData['fullName'] != null) {
        await _user?.updateDisplayName(userData['fullName']);
        await _user?.reload();
      }
      
      // Store user data in Firestore
      await _firestore.collection('users').doc(_user!.uid).set({
        'uid': _user!.uid,
        'email': _user!.email,
        'fullName': userData['fullName'],
        'gender': userData['gender'],
        'phone': userData['phone'],
        'birthDate': userData['birthDate'],
        'role': 'buyer',
        'created_at': FieldValue.serverTimestamp(),
        'provider': 'email',
      }, SetOptions(merge: true));
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = _getFirebaseErrorMessage(e);
      notifyListeners();
      return false;
    }
  }
  
  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      _user = _auth.currentUser;
      if (_user == null) return null;
      
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      return doc.data();
    } catch (e) {
      _error = _getFirebaseErrorMessage(e);
      notifyListeners();
      return null;
    }
  }
  
  // Helper to convert Firebase errors to user-friendly messages
  String _getFirebaseErrorMessage(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'This email is already in use.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'weak-password':
          return 'Password is too weak.';
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Incorrect password.';
        default:
          return e.message ?? 'An unknown error occurred.';
      }
    }
    return e.toString();
  }
  
  @override
  void dispose() {
    _emailVerificationTimer?.cancel();
    super.dispose();
  }
}