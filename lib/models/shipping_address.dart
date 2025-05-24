class ShippingAddress {
  final String fullName;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final String phoneNumber;

  ShippingAddress({
    required this.fullName,
    required this.addressLine1,
    this.addressLine2 = '',
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    required this.phoneNumber,
  });

  // ✅ Safe factory constructor
  factory ShippingAddress.fromMap(Map<String, dynamic> map) {
    return ShippingAddress(
      fullName: map['fullName']?.toString() ?? '',
      addressLine1: map['addressLine1']?.toString() ?? '',
      addressLine2: map['addressLine2']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      state: map['state']?.toString() ?? '',
      zipCode: map['zipCode']?.toString() ?? '',
      country: map['country']?.toString() ?? '',
      phoneNumber: map['phoneNumber']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'phoneNumber': phoneNumber,
    };
  }
}