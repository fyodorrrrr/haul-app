import '../models/address_model.dart';
import '../models/shipping_address.dart';

/// Utility class to convert between Address and ShippingAddress models
class AddressMapper {
  /// Convert from Address to ShippingAddress
  static ShippingAddress toShippingAddress(Address address) {
    return ShippingAddress(
      fullName: address.fullName,
      addressLine1: address.addressLine1,
      addressLine2: address.addressLine2,
      city: address.city,
      state: address.province, // Using province as state
      zipCode: address.postalCode,
      country: "Philippines", // Default to Philippines
      phoneNumber: address.phoneNumber,
    );
  }
  
  /// Convert from ShippingAddress to Address
  static Address toAddress(ShippingAddress shippingAddress) {
    return Address(
      fullName: shippingAddress.fullName,
      phoneNumber: shippingAddress.phoneNumber,
      addressLine1: shippingAddress.addressLine1,
      addressLine2: shippingAddress.addressLine2,
      barangay: "", // Not available in ShippingAddress
      city: shippingAddress.city,
      province: shippingAddress.state,
      region: "", // Not available in ShippingAddress
      postalCode: shippingAddress.zipCode,
      label: "other", // Default label
    );
  }
  
  /// Format address for display
  static String formatAddress(Address address) {
    List<String> components = [
      address.addressLine1,
      address.addressLine2,
      address.barangay,
      address.city,
      address.province,
      address.region,
      address.postalCode,
    ];
    
    // Filter out empty components
    components = components.where((c) => c.trim().isNotEmpty).toList();
    
    return components.join(', ');
  }
}
