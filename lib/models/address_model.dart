// models/address_model.dart
class Address {
  final String? id;
  final String fullName;
  final String phoneNumber;
  final String addressLine1;
  final String addressLine2;
  final String barangay;
  final String city;
  final String province;
  final String region;
  final String postalCode;
  final String label; // "home", "work", etc.
  final bool isDefault;

  Address({
    this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.addressLine1,
    required this.addressLine2,
    required this.barangay,
    required this.city,
    required this.province,
    required this.region,
    required this.postalCode,
    required this.label,
    this.isDefault = false,
  });

  // Convert to/from Firestore
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'barangay': barangay,
      'city': city,
      'province': province,
      'region': region,
      'postalCode': postalCode,
      'label': label,
      'isDefault': isDefault,
    };
  }

  factory Address.fromMap(String id, Map<String, dynamic> map) {
    return Address(
      id: id,
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      addressLine1: map['addressLine1'] ?? '',
      addressLine2: map['addressLine2'] ?? '',
      barangay: map['barangay'] ?? '',
      city: map['city'] ?? '',
      province: map['province'] ?? '',
      region: map['region'] ?? '',
      postalCode: map['postalCode'] ?? '',
      label: map['label'] ?? '',
      isDefault: map['isDefault'] ?? false,
    );
  }
}