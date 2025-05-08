import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '/providers/user_profile_provider.dart';
// Import the next page in registration flow
import 'seller_verification_screen.dart';

class seller_registration_page extends StatefulWidget {
  const seller_registration_page({super.key});
  @override
  _SellerRegState createState() => _SellerRegState();
}

class _SellerRegState extends State<seller_registration_page> {
  // Add form key for validation
  final _formKey = GlobalKey<FormState>();

  // Add controllers for text fields
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _address1Controller = TextEditingController();
  final TextEditingController _address2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();

  List<String> countries = ['Philippines', 'Japan', 'America'];
  List<String> regions = ['Calabarzon', 'Mimaropa'];
  String? selectedRegion;
  String? selectedCountry;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    // Clean up controllers
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
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create seller data map
      final sellerData = {
        'businessName': _businessNameController.text,
        'addressLine1': _address1Controller.text,
        'addressLine2': _address2Controller.text,
        'city': _cityController.text,
        'region': selectedRegion,
        'zipCode': _zipCodeController.text,
        'country': selectedCountry,
        'userId': user.uid,
        'status': 'pending', // pending verification
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('sellers')
          .doc(user.uid)
          .set(sellerData);

      // Update user record to indicate seller registration
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'isSeller': true,
        'sellerStatus': 'pending',
      });

      // Navigate to next screen
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
                              // Add this above your form to display errors
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
                                      child: TextFormField(
                                        controller: _cityController,
                                        style: GoogleFonts.poppins(fontSize: 11),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: const Color.fromARGB(
                                              255, 220, 219, 219),
                                          hintText: "City",
                                          hintStyle:
                                              TextStyle(color: Colors.black),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your city';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(top: 25),
                                    child: SizedBox(
                                      width: 125,
                                      child: DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        value: selectedRegion,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.black,
                                        ),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: const Color.fromARGB(
                                              255, 220, 219, 219),
                                          hintText: "Region",
                                        ),
                                        icon: Icon(Icons.arrow_drop_down),
                                        onChanged: (String? newRegion) {
                                          setState(() {
                                            selectedRegion = newRegion;
                                          });
                                        },
                                        items: regions.map((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please select a region';
                                          }
                                          return null;
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
                                  Padding(
                                    padding: EdgeInsets.only(top: 15),
                                    child: SizedBox(
                                      width: 125,
                                      child: DropdownButtonFormField<String?>(
                                        value: selectedCountry,
                                        isExpanded: true,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.black,
                                        ),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: const Color.fromARGB(
                                              255, 220, 219, 219),
                                          hintText: "Country",
                                        ),
                                        icon: Icon(Icons.arrow_drop_down),
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            selectedCountry = newValue;
                                          });
                                        },
                                        items: countries.map((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please select a country';
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