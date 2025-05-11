import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haul/models/country.dart';
import '/models/state.dart';
import 'package:haul/models/city.dart';
import 'package:haul/services/location_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class SellerRegistrationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  bool _isLoading = false;
  String? _errorMessage;
  
  // Location data
  Future<List<Country>> _countries;
  Future<List<StateModel>>? _states;
  Future<List<City>>? _cities;
  
  String? _selectedCountryIso;
  String? selectedRegion;
  String? selectedCountry;
  String? selectedCity;
  
  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Future<List<Country>> get countries => _countries;
  Future<List<StateModel>>? get states => _states;
  Future<List<City>>? get cities => _cities;
  String? get selectedCountryIso => _selectedCountryIso;
  
  SellerRegistrationProvider() : _countries = LocationService().getCountries() {
    _states = Future.value([]);
    _cities = Future.value([]);
  }
  
  void setCountry(String? countryName, String? countryIso2) {
    selectedCountry = countryName;
    _selectedCountryIso = countryIso2;
    selectedRegion = null;
    selectedCity = null;
    
    if (countryIso2 != null) {
      _states = _locationService.getStates(countryIso2);
    } else {
      _states = Future.value([]);
    }
    _cities = Future.value([]);
    notifyListeners();
  }
  
  void setRegion(String? regionName, String? stateIso2) {
    selectedRegion = regionName;
    selectedCity = null;
    
    if (regionName != null && _selectedCountryIso != null && stateIso2 != null) {
      _cities = _locationService.getCities(_selectedCountryIso!, stateIso2);
    } else {
      _cities = Future.value([]);
    }
    notifyListeners();
  }
  
  void setCity(String? cityName) {
    selectedCity = cityName;
    notifyListeners();
  }
  
  Future<bool> saveSellerData({
    required String businessName,
    required String addressLine1,
    required String zipCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      final sellerData = {
        'businessName': businessName,
        'addressLine1': addressLine1,
        'city': selectedCity,
        'region': selectedRegion,
        'zipCode': zipCode,
        'country': selectedCountry,
        'userId': user.uid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      await FirebaseFirestore.instance
          .collection('sellers')
          .doc(user.uid)
          .set(sellerData);
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'isSeller': true,
        'sellerStatus': 'pending',
      });
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveSellerPersonalInfo({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required DateTime dateOfBirth,
    required String ssn,
    required File frontIdImage,
    required File backIdImage,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      // Upload ID images to Firebase Storage
      final frontIdRef = FirebaseStorage.instance
          .ref()
          .child('seller_verification')
          .child(user.uid)
          .child('id_front.jpg');
          
      final backIdRef = FirebaseStorage.instance
          .ref()
          .child('seller_verification')
          .child(user.uid)
          .child('id_back.jpg');
      
      // Upload front ID
      await frontIdRef.putFile(frontIdImage);
      final frontIdUrl = await frontIdRef.getDownloadURL();
      
      // Upload back ID
      await backIdRef.putFile(backIdImage);
      final backIdUrl = await backIdRef.getDownloadURL();
      
      // Save personal info to Firestore
      await FirebaseFirestore.instance
          .collection('sellers')
          .doc(user.uid)
          .update({
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'dateOfBirth': Timestamp.fromDate(dateOfBirth),
        'ssnLast4': ssn,
        'idFrontUrl': frontIdUrl,
        'idBackUrl': backIdUrl,
        'verificationStatus': 'pending',
        'verificationSubmittedAt': FieldValue.serverTimestamp(),
      });
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}