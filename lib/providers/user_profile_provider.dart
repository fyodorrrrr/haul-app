import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/user_profile_model.dart';

class UserProfileProvider extends ChangeNotifier {
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isProfileLoaded => _userProfile != null;

  // Fetch current user profile from Firestore
  Future<void> fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _userProfile = null;
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      // Get user document from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        // Convert document to UserProfile model
        _userProfile = UserProfile.fromMap(userDoc.data()!);
      } else {
        // Create basic profile if document doesn't exist
        _userProfile = UserProfile(
          uid: user.uid,
          email: user.email ?? '',
          fullName: user.displayName ?? '',
          gender: '',
          phone: '',
          photoUrl: user.photoURL,
          role: 'buyer',
          provider: 'email',
        );
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update profile in provider after edit
  void updateUserProfile(UserProfile updatedProfile) {
    _userProfile = updatedProfile;
    notifyListeners();
  }

  // Clear user profile on logout
  void clearUserProfile() {
    _userProfile = null;
    notifyListeners();
  }
}