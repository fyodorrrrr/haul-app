// providers/address_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/address_model.dart';

class AddressProvider extends ChangeNotifier {
  List<Address> _addresses = [];
  bool _isLoading = false;
  String? _error;
  
  List<Address> get addresses => _addresses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Get default address
  Address? get defaultAddress {
    try {
      return _addresses.firstWhere((address) => address.isDefault);
    } catch (e) {
      return _addresses.isNotEmpty ? _addresses.first : null;
    }
  }
  
  // Load addresses
  Future<void> loadAddresses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .get();
          
      _addresses = snapshot.docs
          .map((doc) => Address.fromMap(doc.id, doc.data()))
          .toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Add new address
  Future<bool> addAddress(Address address) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      // If this is the default address, unset any existing default
      if (address.isDefault) {
        await _unsetExistingDefault(user.uid);
      }
      
      // If this is the first address, make it default
      if (_addresses.isEmpty) {
        address = Address(
          fullName: address.fullName,
          phoneNumber: address.phoneNumber,
          addressLine1: address.addressLine1,
          addressLine2: address.addressLine2,
          barangay: address.barangay,
          city: address.city,
          province: address.province,
          region: address.region,
          postalCode: address.postalCode,
          label: address.label,
          isDefault: true,
        );
      }
      
      // Add to Firestore
      final docData = {
        'fullName': address.fullName,
        'phoneNumber': address.phoneNumber,
        'addressLine1': address.addressLine1,
        'addressLine2': address.addressLine2,
        'region': address.region,
        'province': address.province,
        'city': address.city,
        'barangay': address.barangay,
        'postalCode': address.postalCode,
        'label': address.label,
        'isDefault': address.isDefault,
      };
      
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .add(docData);
          
      // Add to local list
      final newAddress = Address.fromMap(docRef.id, docData);
      _addresses.add(newAddress);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Update address
  Future<bool> updateAddress(Address address) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      if (address.id == null) throw Exception('Address ID is required');
      
      // If this is the default address, unset any existing default
      if (address.isDefault) {
        await _unsetExistingDefault(user.uid, exceptId: address.id);
      }
      
      // Update in Firestore
      final docData = {
        'fullName': address.fullName,
        'phoneNumber': address.phoneNumber,
        'addressLine1': address.addressLine1,
        'addressLine2': address.addressLine2,
        'region': address.region,
        'province': address.province,
        'city': address.city,
        'barangay': address.barangay,
        'postalCode': address.postalCode,
        'label': address.label,
        'isDefault': address.isDefault,
      };
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .doc(address.id)
          .update(docData);
          
      // Update local list
      final index = _addresses.indexWhere((a) => a.id == address.id);
      if (index != -1) {
        _addresses[index] = address;
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Delete address
  Future<bool> deleteAddress(String addressId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      // Delete from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .doc(addressId)
          .delete();
          
      // Remove from local list
      _addresses.removeWhere((a) => a.id == addressId);
      
      // If deleted the default and other addresses exist, make another one default
      if (_addresses.isNotEmpty && !_addresses.any((a) => a.isDefault)) {
        final newDefault = _addresses.first;
        await updateAddress(Address(
          id: newDefault.id,
          fullName: newDefault.fullName,
          phoneNumber: newDefault.phoneNumber,
          addressLine1: newDefault.addressLine1,
          addressLine2: newDefault.addressLine2,
          barangay: newDefault.barangay,
          city: newDefault.city,
          province: newDefault.province,
          region: newDefault.region,
          postalCode: newDefault.postalCode,
          label: newDefault.label,
          isDefault: true,
        ));
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Set address as default
  Future<bool> setDefaultAddress(String addressId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      await _unsetExistingDefault(user.uid);
      
      // Update the new default
      final addressRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .doc(addressId);
          
      await addressRef.update({'isDefault': true});
      
      // Update local list
      final index = _addresses.indexWhere((a) => a.id == addressId);
      if (index != -1) {
        _addresses[index] = Address(
          id: _addresses[index].id,
          fullName: _addresses[index].fullName,
          phoneNumber: _addresses[index].phoneNumber,
          addressLine1: _addresses[index].addressLine1,
          addressLine2: _addresses[index].addressLine2,
          barangay: _addresses[index].barangay,
          city: _addresses[index].city,
          province: _addresses[index].province,
          region: _addresses[index].region,
          postalCode: _addresses[index].postalCode,
          label: _addresses[index].label,
          isDefault: true,
        );
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Helper to unset any existing default address
  Future<void> _unsetExistingDefault(String userId, {String? exceptId}) async {
    final batch = FirebaseFirestore.instance.batch();
    
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .where('isDefault', isEqualTo: true)
        .get();
        
    for (var doc in querySnapshot.docs) {
      if (doc.id != exceptId) {
        batch.update(doc.reference, {'isDefault': false});
        
        // Update local list
        final index = _addresses.indexWhere((a) => a.id == doc.id);
        if (index != -1) {
          _addresses[index] = Address(
            id: _addresses[index].id,
            fullName: _addresses[index].fullName,
            phoneNumber: _addresses[index].phoneNumber,
            addressLine1: _addresses[index].addressLine1,
            addressLine2: _addresses[index].addressLine2,
            barangay: _addresses[index].barangay,
            city: _addresses[index].city,
            province: _addresses[index].province,
            region: _addresses[index].region,
            postalCode: _addresses[index].postalCode,
            label: _addresses[index].label,
            isDefault: false,
          );
        }
      }
    }
    
    await batch.commit();
  }
}