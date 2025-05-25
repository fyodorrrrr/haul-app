import 'package:cloud_firestore/cloud_firestore.dart';

class ShippingAddress {
  final String? id;
  final String? fullName;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  final String? phoneNumber;
  final bool isDefault;

  ShippingAddress({
    this.id,
    this.fullName,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.phoneNumber,
    this.isDefault = false,
  });

  // ✅ Add toMap method
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'phoneNumber': phoneNumber,
      'isDefault': isDefault,
    };
  }

  // ✅ Add fromMap method
  factory ShippingAddress.fromMap(Map<String, dynamic> map) {
    return ShippingAddress(
      id: map['id'],
      fullName: map['fullName'],
      addressLine1: map['addressLine1'],
      addressLine2: map['addressLine2'],
      city: map['city'],
      state: map['state'],
      zipCode: map['zipCode'],
      country: map['country'],
      phoneNumber: map['phoneNumber'],
      isDefault: map['isDefault'] ?? false,
    );
  }

  // ✅ Keep existing fromJson for compatibility
  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress.fromMap(json);
  }

  // ✅ Keep existing toJson for compatibility
  Map<String, dynamic> toJson() {
    return toMap();
  }

  // ✅ Add copyWith method
  ShippingAddress copyWith({
    String? id,
    String? fullName,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    String? phoneNumber,
    bool? isDefault,
  }) {
    return ShippingAddress(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      country: country ?? this.country,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  // ✅ Helper method to get formatted address
  String get formattedAddress {
    List<String> parts = [];
    
    if (addressLine1?.isNotEmpty == true) parts.add(addressLine1!);
    if (addressLine2?.isNotEmpty == true) parts.add(addressLine2!);
    if (city?.isNotEmpty == true) parts.add(city!);
    if (state?.isNotEmpty == true) parts.add(state!);
    if (zipCode?.isNotEmpty == true) parts.add(zipCode!);
    if (country?.isNotEmpty == true) parts.add(country!);
    
    return parts.join(', ');
  }

  @override
  String toString() {
    return 'ShippingAddress(id: $id, fullName: $fullName, formattedAddress: $formattedAddress)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ShippingAddress &&
      other.id == id &&
      other.fullName == fullName &&
      other.addressLine1 == addressLine1 &&
      other.addressLine2 == addressLine2 &&
      other.city == city &&
      other.state == state &&
      other.zipCode == zipCode &&
      other.country == country &&
      other.phoneNumber == phoneNumber &&
      other.isDefault == isDefault;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      fullName.hashCode ^
      addressLine1.hashCode ^
      addressLine2.hashCode ^
      city.hashCode ^
      state.hashCode ^
      zipCode.hashCode ^
      country.hashCode ^
      phoneNumber.hashCode ^
      isDefault.hashCode;
  }
}