import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '/models/user_profile_model.dart';
import '/providers/user_profile_provider.dart';

class EditProfileProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Add a reference to the centralized profile provider
  UserProfileProvider? _userProfileProvider;
  
  // Getters
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Initialize with user profile and the centralized provider
  void initialize(UserProfile profile, UserProfileProvider userProfileProvider) {
    _userProfile = profile;
    _userProfileProvider = userProfileProvider;
    notifyListeners();
  }
  
  // Update profile information
  Future<bool> updateUserProfile({
    required String fullName,
    required String phone,
    required String? gender,
    DateTime? birthDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      // Update display name in Firebase Auth
      await user.updateDisplayName(fullName.trim());
      
      // Update data in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'fullName': fullName.trim(),
        'phone': phone.trim(),
        'gender': gender,
        'birthDate': birthDate?.toIso8601String(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      // After successful update, create updated profile
      final updatedProfile = _userProfile!.copyWith(
        fullName: fullName.trim(),
        phone: phone.trim(),
        gender: gender ?? _userProfile!.gender,
        birthDate: birthDate,
      );
      
      // Update local copy
      _userProfile = updatedProfile;
      
      // Also update the centralized user profile provider if available
      _userProfileProvider?.updateUserProfile(updatedProfile);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error updating profile: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Upload profile image
  Future<bool> uploadProfileImage(ImageSource source) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source, 
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      // Create storage reference
      final storageRef = _storage
        .ref()
        .child('profile_images')
        .child('${user.uid}.jpg');
      
      // Upload image
      final uploadTask = await storageRef.putFile(File(image.path));
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      // Update Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'photoUrl': downloadUrl,
      });
      
      // Update Auth profile
      await user.updatePhotoURL(downloadUrl);
      
      // Update local user profile
      final updatedProfile = _userProfile!.copyWith(photoUrl: downloadUrl);
      _userProfile = updatedProfile;
      
      // Update the centralized provider if available
      _userProfileProvider?.updateUserProfile(updatedProfile);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error uploading image: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Clear any errors
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}