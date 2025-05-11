import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haul/models/country.dart';
import '/models/state.dart';
import 'package:haul/models/city.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:haul/services/location_service.dart';

class SellerRegistrationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  bool _isLoading = false;
  String? _errorMessage;
  
  // Location data
  Future<List<Country>> _countries;
  Future<List<StateModel>>? _states;
  Future<List<City>>? _cities;
  
  // Add new fields for Philippines-specific hierarchy
  Future<List<dynamic>>? _regions;
  Future<List<dynamic>>? _provinces;
  String? _selectedRegion; // Keep this as the private field
  String? _selectedRegionCode; // Store the region code
  String? _selectedProvince;
  String? _selectedProvinceCode; // Store the province code
  
  String? _selectedCountryIso;
  String? selectedCountry;
  String? selectedCity;
  
  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Future<List<Country>> get countries => _countries;
  Future<List<StateModel>>? get states => _states;
  Future<List<City>>? get cities => _cities;
  Future<List<dynamic>>? get regions => _regions;
  Future<List<dynamic>>? get provinces => _provinces;
  String? get selectedCountryIso => _selectedCountryIso;
  String? get selectedRegion => _selectedRegion; // Use the private field here
  String? get selectedProvince => _selectedProvince;
  
  set selectedRegion(String? regionName) {
    _selectedRegion = regionName;
    notifyListeners();
  }
  
  SellerRegistrationProvider() : _countries = LocationService().getCountries() {
    _states = Future.value([]);
    _cities = Future.value([]);
    _regions = Future.value([]);
    _provinces = Future.value([]);
    
    // Pre-fetch Philippines regions
    setCountry("Philippines", "PH");
    _loadPhilippinesRegions();
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
    _selectedRegion = regionName;
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
  
  // New method to load Philippines regions
  Future<void> _loadPhilippinesRegions() async {
    _regions = _locationService.getPhilippinesRegions();
    notifyListeners();
  }

  // Set region and load provinces using the API
  void setPhilippinesRegion(String regionName, String regionCode) {
    _selectedRegion = regionName;
    _selectedRegionCode = regionCode; // Store the region code
    _provinces = _locationService.getPhilippinesProvinces(regionCode);
    _cities = Future.value([]);
    notifyListeners();
  }

  // Set province and load cities using the API
  void setPhilippinesProvince(String provinceName, String provinceCode) {
    _selectedProvince = provinceName;
    _selectedProvinceCode = provinceCode; // Store the province code
    _cities = _locationService.getPhilippinesCities(provinceCode);
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
        'province': _selectedProvince,
        'region': _selectedRegion,
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

  Future<Map<String, dynamic>> getVerificationStatus() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      final sellerDoc = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(user.uid)
          .get();
      
      final result = <String, dynamic>{
        'hasActiveVerification': false,
        'status': null,
        'submittedDate': null,
      };
      
      if (sellerDoc.exists) {
        final sellerData = sellerDoc.data();
        
        // Check if there's verification data
        if (sellerData != null && 
            sellerData.containsKey('verificationStatus') && 
            sellerData.containsKey('verificationSubmittedAt')) {
          
          final status = sellerData['verificationStatus'];
          
          // Consider any status except "declined" as an active verification
          final isActive = status != null && status != 'declined';
          
          result['hasActiveVerification'] = isActive;
          result['status'] = status;
          
          if (sellerData['verificationSubmittedAt'] != null) {
            result['submittedDate'] = (sellerData['verificationSubmittedAt'] as Timestamp).toDate();
          }
        }
      }
      
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }
}