import '../models/address_model.dart';
import '../models/shipping_address.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Utility class to convert between Address and ShippingAddress models
class AddressMapper {
  /// Convert from Address to ShippingAddress
  static ShippingAddress toShippingAddress(Address address) {
    return ShippingAddress(
      id: address.id, // Add id if ShippingAddress has it
      fullName: address.fullName,
      addressLine1: address.addressLine1,
      addressLine2: address.addressLine2,
      city: address.city,
      state: address.province, // Using province as state
      zipCode: address.postalCode,
      country: "Philippines", // Default to Philippines
      phoneNumber: address.phoneNumber,
      isDefault: address.label == "default", // Map default status
    );
  }
  
  /// Convert from ShippingAddress to Address
  static Address toAddress(ShippingAddress shippingAddress, {String? userId}) {
    return Address(
      id: shippingAddress.id, // Preserve ID if available
      fullName: shippingAddress.fullName ?? '',
      phoneNumber: shippingAddress.phoneNumber ?? '',
      addressLine1: shippingAddress.addressLine1 ?? '',
      addressLine2: shippingAddress.addressLine2 ?? '',
      barangay: "", // Not available in ShippingAddress
      city: shippingAddress.city ?? '',
      province: shippingAddress.state ?? '',
      region: "", // Not available in ShippingAddress
      postalCode: shippingAddress.zipCode ?? '',
      label: shippingAddress.isDefault ? "default" : "other", // Map from isDefault
      userId: userId ?? FirebaseAuth.instance.currentUser?.uid ?? '',
    );
  }
  
  /// Format address for display
  static String formatAddress(Address address) {
    List<String> components = [
      address.addressLine1 ?? '',
      address.addressLine2 ?? '',
      address.barangay ?? '',
      address.city ?? '',
      address.province ?? '',
      address.region ?? '',
      address.postalCode ?? '',
    ];
    
    // Filter out empty components
    components = components.where((c) => c.trim().isNotEmpty).toList();
    
    return components.join(', ');
  }
  
  /// Format ShippingAddress for display
  static String formatShippingAddress(ShippingAddress address) {
    List<String> components = [
      address.addressLine1 ?? '',
      address.addressLine2 ?? '',
      address.city ?? '',
      address.state ?? '',
      address.zipCode ?? '',
      address.country ?? '',
    ];
    
    // Filter out empty components
    components = components.where((c) => c.trim().isNotEmpty).toList();
    
    return components.join(', ');
  }
  
  /// Check if address is complete
  static bool isAddressComplete(Address address) {
    return (address.fullName?.isNotEmpty ?? false) &&
           (address.addressLine1?.isNotEmpty ?? false) &&
           (address.city?.isNotEmpty ?? false) &&
           (address.province?.isNotEmpty ?? false) &&
           (address.postalCode?.isNotEmpty ?? false) &&
           (address.phoneNumber?.isNotEmpty ?? false);
  }
  
  /// Check if shipping address is complete
  static bool isShippingAddressComplete(ShippingAddress address) {
    return (address.fullName?.isNotEmpty ?? false) &&
           (address.addressLine1?.isNotEmpty ?? false) &&
           (address.city?.isNotEmpty ?? false) &&
           (address.state?.isNotEmpty ?? false) &&
           (address.zipCode?.isNotEmpty ?? false) &&
           (address.phoneNumber?.isNotEmpty ?? false);
  }
  
  /// Create a default address
  static Address createDefaultAddress({String? userId}) {
    return Address(
      id: null,
      fullName: '',
      phoneNumber: '',
      addressLine1: '',
      addressLine2: '',
      barangay: '',
      city: '',
      province: '',
      region: '',
      postalCode: '',
      label: 'default',
      userId: userId ?? FirebaseAuth.instance.currentUser?.uid ?? '',
    );
  }
  
  /// Create a default shipping address
  static ShippingAddress createDefaultShippingAddress() {
    return ShippingAddress(
      id: null,
      fullName: '',
      addressLine1: '',
      addressLine2: '',
      city: '',
      state: '',
      zipCode: '',
      country: 'Philippines',
      phoneNumber: '',
      isDefault: false,
    );
  }
}
