import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/country.dart';
import '../models/state.dart';
import '../models/city.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LocationService {
  final String _apiKey = dotenv.env['CSC_API_KEY']!;
  final String _baseUrl = 'https://api.countrystatecity.in/v1';

  Map<String, String> get _headers => {
        'X-CSCAPI-KEY': _apiKey,
      };

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
}
