import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/country.dart';
import '../models/state.dart';
import '../models/city.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;

class LocationService {
  final String _apiKey = dotenv.env['CSC_API_KEY']!;
  final String _baseUrl = 'https://api.countrystatecity.in/v1';

  // Try both API endpoints
  final List<String> _phApiBaseUrls = [
    'https://ph-locations-api.buonzz.com/v1',
    'https://psgc.gitlab.io/api'
  ];

  Map<String, String> get _headers => {
        'X-CSCAPI-KEY': _apiKey,
      };

  Map<String, List<dynamic>> _cache = {};

  Future<String> _getWorkingApiUrl() async {
    for (var url in _phApiBaseUrls) {
      try {
        final response = await http.get(Uri.parse('$url/regions'))
            .timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          print('Using API URL: $url');
          return url;
        }
      } catch (e) {
        print('API $url failed: $e');
      }
    }
    print('All APIs failed, using default');
    return _phApiBaseUrls.first;
  }

  Future<List<Country>> getCountries() async {
    final res = await http.get(Uri.parse('$_baseUrl/countries'), headers: _headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Country.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load countries');
    }
  }

  Future<List<StateModel>> getStates(String countryIso2) async {
    final res = await http.get(Uri.parse('$_baseUrl/countries/$countryIso2/states'), headers: _headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => StateModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load states');
    }
  }

  Future<List<City>> getCities(String countryIso2, String stateIso2) async {
    print('Fetching cities for countryIso2: $countryIso2, stateIso2: $stateIso2'); // Debug print
    final res = await http.get(Uri.parse('$_baseUrl/countries/$countryIso2/states/$stateIso2/cities'), headers: _headers);
    print('API response status: ${res.statusCode}'); // Debug print
    print('URL: $_baseUrl/countries/$countryIso2/states/$stateIso2/cities');
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      print('Fetched cities: ${data.map((e) => e['name']).toList()}'); // Debug print
      return data.map((e) => City.fromJson(e)).toList();
    } else {
      print('Failed to load cities: ${res.body}'); // Debug print
      throw Exception('Failed to load cities');
    }
  }

  Future<Map<String, dynamic>> _loadPhilippinesData() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/philippine_provinces_cities_municipalities_and_barangays_2019v2.json');
      return jsonDecode(jsonString);
    } catch (e) {
      print('Error loading Philippines data: $e');
      return {};
    }
  }

  Future<List<dynamic>> getPhilippinesRegions() async {
    try {
      final data = await _loadPhilippinesData();
      
      // Map region codes and names from the data
      final regions = data.entries.map((entry) => {
        'name': entry.value['region_name'],
        'code': entry.key,
      }).toList();
      
      print('Loaded ${regions.length} regions from Philippine data');
      return regions;
    } catch (e) {
      print('Error parsing Philippines regions: $e');
      return [];
    }
  }

  Future<List<dynamic>> getPhilippinesProvinces(String regionCode) async {
    try {
      final data = await _loadPhilippinesData();
      
      if (!data.containsKey(regionCode)) {
        print('Region code not found: $regionCode');
        return [];
      }
      
      final region = data[regionCode];
      final provinceList = region['province_list'] as Map<String, dynamic>;
      
      // Map provinces to the expected format
      final provinces = provinceList.entries.map((entry) => {
        'name': entry.key,  // Province name
        'code': entry.key,  // Using name as code since there's no specific code
        'regionCode': regionCode,
      }).toList();
      
      print('Loaded ${provinces.length} provinces for region $regionCode');
      return provinces;
    } catch (e) {
      print('Error parsing Philippines provinces: $e');
      return [];
    }
  }

  Future<List<City>> getPhilippinesCities(String provinceCode) async {
    try {
      final data = await _loadPhilippinesData();
      
      // Find the region containing this province
      for (var regionEntry in data.entries) {
        final provinceList = regionEntry.value['province_list'] as Map<String, dynamic>;
        
        if (provinceList.containsKey(provinceCode)) {
          final municipalityList = provinceList[provinceCode]['municipality_list'] as Map<String, dynamic>;
          
          // Convert municipalities to City objects
          final cities = municipalityList.keys.map((municipalityName) => 
            City.fromJson({
              'name': municipalityName,
              'state_code': provinceCode,
              'country_code': 'PH'
            })
          ).toList();
          
          print('Loaded ${cities.length} cities/municipalities for province $provinceCode');
          return cities;
        }
      }
      
      print('Province not found: $provinceCode');
      return [];
    } catch (e) {
      print('Error loading or parsing cities: $e');
      return [];
    }
  }
}
