import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class PhilippineLocationHelper {
  static Map<String, dynamic>? _locationData;
  
  // Load and parse the JSON file
  static Future<Map<String, dynamic>> loadLocationData() async {
    if (_locationData != null) return _locationData!;
    
    final jsonString = await rootBundle.loadString(
      'assets/data/philippine_provinces_cities_municipalities_and_barangays_2019v2.json'
    );
    _locationData = json.decode(jsonString);
    return _locationData!;
  }
  
  // Get all regions
  static List<String> getRegions(Map<String, dynamic> data) {
    final regions = data.keys.toList();
    regions.sort();
    return regions;
  }
  
  // Get provinces for a region
  static List<String> getProvinces(Map<String, dynamic> data, String region) {
    if (!data.containsKey(region)) return [];
    
    final provinces = data[region]['province_list'].keys.toList();
    provinces.sort();
    return provinces;
  }
  
  // Get cities for a province
  static List<String> getCities(Map<String, dynamic> data, String region, String province) {
    if (!data.containsKey(region) || 
        !data[region]['province_list'].containsKey(province)) return [];
    
    final cities = data[region]['province_list'][province]['municipality_list'].keys.toList();
    cities.sort();
    return cities;
  }
  
  // Get barangays for a city
  static List<String> getBarangays(Map<String, dynamic> data, String region, String province, String city) {
    if (!data.containsKey(region) || 
        !data[region]['province_list'].containsKey(province) ||
        !data[region]['province_list'][province]['municipality_list'].containsKey(city)) return [];
    
    final barangays = List<String>.from(
      data[region]['province_list'][province]['municipality_list'][city]['barangay_list']
    );
    barangays.sort();
    return barangays;
  }
}