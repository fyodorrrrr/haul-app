import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haul/models/country.dart';
import '/models/state.dart';
import 'package:haul/models/city.dart';
import 'package:haul/services/location_service.dart';
import 'package:provider/provider.dart';
import '/providers/user_profile_provider.dart';
import 'seller_verification_screen.dart';

class seller_registration_page extends StatefulWidget {
  const seller_registration_page({super.key});
  @override
  _SellerRegState createState() => _SellerRegState();
}

class _SellerRegState extends State<seller_registration_page> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _address1Controller = TextEditingController();
  final TextEditingController _address2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();

  Future<List<Country>> _countries = LocationService().getCountries();
  Future<List<StateModel>>? _states;
  Future<List<City>>? _cities;

  String? _selectedCountryIso;
  String? selectedRegion;
  String? selectedCountry;
  String? selectedCity;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _states = Future.value([]);
    _cities = Future.value([]);
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveSellerData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final sellerData = {
        'businessName': _businessNameController.text,
        'addressLine1': _address1Controller.text,
        'addressLine2': _address2Controller.text,
        'city': selectedCity,
        'region': selectedRegion,
        'zipCode': _zipCodeController.text,
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

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SellerVerificationScreen(
            businessName: _businessNameController.text,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $_errorMessage'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Stack(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: 10, left: 10),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    child: Icon(Icons.arrow_back, color: Colors.black),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Image.asset(
                  "assets/images/vendor.png",
                  height: 180,
                  width: 200,
                ),
              ),
              Center(
                child: Container(
                  margin: EdgeInsets.fromLTRB(0, screenHeight * .45, 0, 0),
                  width: 300,
                  height: 550,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey,
                        blurRadius: 5,
                        spreadRadius: 2,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: <Widget>[
                      Positioned(
                        top: 10,
                        left: 45,
                        child: Text(
                          style: GoogleFonts.poppins(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                          ),
                          "Start Selling",
                        ),
                      ),
                      Positioned(
                        top: 50,
                        left: 60,
                        child: Text(
                          "Be part of the seller community",
                          style: GoogleFonts.poppins(fontSize: 9.5),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: Center(
                          child: Column(
                            children: [
                              Text(
                                "Business Information",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, 140, 20, 0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              if (_errorMessage != null)
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  child: Container(
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _errorMessage!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.red.shade900,
                                      ),
                                    ),
                                  ),
                                ),
                              TextFormField(
                                controller: _businessNameController,
                                style: GoogleFonts.poppins(fontSize: 11),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor:
                                      const Color.fromARGB(255, 220, 219, 219),
                                  hintText: "Business Name",
                                  hintStyle: TextStyle(color: Colors.black),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your business name';
                                  }
                                  return null;
                                },
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 25),
                                child: TextFormField(
                                  controller: _address1Controller,
                                  style: GoogleFonts.poppins(fontSize: 11),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color.fromARGB(
                                        255, 220, 219, 219),
                                    hintText: "Address Line 1",
                                    hintStyle: TextStyle(color: Colors.black),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your address';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              TextFormField(
                                controller: _address2Controller,
                                style: GoogleFonts.poppins(fontSize: 11),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor:
                                      const Color.fromARGB(255, 220, 219, 219),
                                  hintText: "Address Line 2",
                                  hintStyle: TextStyle(color: Colors.black),
                                ),
                              ),
                              Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(top: 25, right: 10),
                                    child: SizedBox(
                                      width: 125,
                                      child: FutureBuilder<List<Country>>(
                                        future: _countries,
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return Center(child: CircularProgressIndicator());
                                          } else if (snapshot.hasError) {
                                            return Text('Error: ${snapshot.error}');
                                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                            return DropdownButtonFormField<String>(
                                              items: [],
                                              onChanged: null,
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: const Color.fromARGB(255, 220, 219, 219),
                                                hintText: "Select Country",
                                              ),
                                            );
                                          }
                                          List<Country> countries = snapshot.data!;
                                          return DropdownButtonFormField<String>(
                                            value: selectedCountry,
                                            isExpanded: true,
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: Colors.black,
                                            ),
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor: const Color.fromARGB(255, 220, 219, 219),
                                              hintText: "Country",
                                            ),
                                            icon: Icon(Icons.arrow_drop_down),
                                            onChanged: (String? newValue) {
                                              setState(() {
                                                selectedCountry = newValue;
                                                selectedRegion = null;
                                                selectedCity = null;
                                                if (newValue != null) {
                                                  final countryIso2 = countries.firstWhere((c) => c.name == newValue).iso2;
                                                  _selectedCountryIso = countryIso2;
                                                  _states = LocationService().getStates(countryIso2);
                                                  _cities = Future.value([]);
                                                } else {
                                                  _selectedCountryIso = null;
                                                  _states = Future.value([]);
                                                  _cities = Future.value([]);
                                                }
                                              });
                                            },
                                            items: countries.map((country) {
                                              return DropdownMenuItem<String>(
                                                value: country.name,
                                                child: Text(country.name),
                                              );
                                            }).toList(),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Please select a country';
                                              }
                                              return null;
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(top: 25),
                                    child: SizedBox(
                                      width: 125,
                                      child: FutureBuilder<List<StateModel>>(
                                        future: _states,
                                        builder: (context, snapshot) {
                                          if (_selectedCountryIso == null) {
                                            return TextFormField(
                                              enabled: false,
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: const Color.fromARGB(255, 220, 219, 219),
                                                hintText: "Region",
                                              ),
                                            );
                                          }
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return Center(child: CircularProgressIndicator());
                                          } else if (snapshot.hasError) {
                                            return Text('Error: ${snapshot.error}');
                                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                            return DropdownButtonFormField<String>(
                                              items: [],
                                              onChanged: null,
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: const Color.fromARGB(255, 220, 219, 219),
                                                hintText: "No regions found",
                                              ),
                                            );
                                          }
                                          List<StateModel> states = snapshot.data!;
                                          return DropdownButtonFormField<String>(
                                            isExpanded: true,
                                            value: selectedRegion,
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: Colors.black,
                                            ),
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor: const Color.fromARGB(255, 220, 219, 219),
                                              hintText: "Region",
                                            ),
                                            icon: Icon(Icons.arrow_drop_down),
                                            onChanged: (String? newRegion) {
                                              setState(() {
                                                selectedRegion = newRegion;
                                                selectedCity = null;
                                                if (newRegion != null) {
                                                  final stateIso2 = states.firstWhere((s) => s.name == newRegion).iso2;
                                                  print('Fetching cities for country: $_selectedCountryIso, state: $stateIso2');
                                                  _cities = LocationService().getCities(_selectedCountryIso!, stateIso2)
                                                    ..then((cities) {
                                                      print('Fetched cities: ${cities.map((c) => c.name).toList()}');
                                                    });
                                                } else {
                                                  _cities = Future.value([]);
                                                  print('No region selected, setting cities to empty.');
                                                }
                                              });
                                            },
                                            items: states.map((state) {
                                              return DropdownMenuItem<String>(
                                                value: state.name,
                                                child: Text(state.name),
                                              );
                                            }).toList(),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Please select a region';
                                              }
                                              return null;
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(top: 15, right: 10),
                                    child: SizedBox(
                                      width: 125,
                                      child: FutureBuilder<List<City>>(
                                        future: _cities,
                                        builder: (context, snapshot) {
                                          if (selectedRegion == null) {
                                            return TextFormField(
                                              enabled: false,
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: const Color.fromARGB(255, 220, 219, 219),
                                                hintText: "City",
                                              ),
                                            );
                                          }
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return Center(child: CircularProgressIndicator());
                                          } else if (snapshot.hasError) {
                                            return Text('Error: ${snapshot.error}');
                                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                            return TextFormField(
                                              controller: _cityController,
                                              style: GoogleFonts.poppins(fontSize: 11),
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: const Color.fromARGB(255, 220, 219, 219),
                                                hintText: "Enter City",
                                                hintStyle: TextStyle(color: Colors.black),
                                              ),
                                              onChanged: (value) {
                                                setState(() {
                                                  selectedCity = value;
                                                });
                                              },
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
                                                  return 'Please enter your city';
                                                }
                                                return null;
                                              },
                                            );
                                          }
                                          List<City> cities = snapshot.data!;
                                          return DropdownButtonFormField<String>(
                                            isExpanded: true,
                                            value: selectedCity,
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: Colors.black,
                                            ),
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor: const Color.fromARGB(255, 220, 219, 219),
                                              hintText: "City",
                                            ),
                                            icon: Icon(Icons.arrow_drop_down),
                                            onChanged: (String? newCity) {
                                              setState(() {
                                                selectedCity = newCity;
                                                _cityController.text = newCity ?? '';
                                              });
                                            },
                                            items: cities.map((city) {
                                              return DropdownMenuItem<String>(
                                                value: city.name,
                                                child: Text(city.name),
                                              );
                                            }).toList(),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Please select a city';
                                              }
                                              return null;
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(top: 15),
                                    child: SizedBox(
                                      width: 125,
                                      child: TextFormField(
                                        controller: _zipCodeController,
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.black,
                                        ),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: const Color.fromARGB(
                                              255, 220, 219, 219),
                                          hintText: "Zip Code",
                                          hintStyle: GoogleFonts.poppins(
                                            fontSize: 11,
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your zip code';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 15),
                                child: Align(
                                  alignment: Alignment.bottomRight,
                                  child: SizedBox(
                                    width: 100,
                                    height: 45,
                                    child: FloatingActionButton(
                                      onPressed: () {
                                        if (_formKey.currentState!.validate()) {
                                          _saveSellerData();
                                        }
                                      },
                                      child: Text(
                                        "NEXT",
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}