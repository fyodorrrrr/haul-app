import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/providers/address_provider.dart';
import '/models/address_model.dart';
import '/utils/philippine_location_helper.dart';

class AddAddressScreen extends StatefulWidget {
  final Address? address;
  
  const AddAddressScreen({Key? key, this.address}) : super(key: key);

  @override
  _AddAddressScreenState createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Text controllers
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _postalCodeController = TextEditingController();
  
  // Location data
  bool _isLoadingLocations = true;
  Map<String, dynamic>? _locationData;
  String? _selectedRegion;
  String? _selectedProvince;
  String? _selectedCity;
  String? _selectedBarangay;
  
  List<String> _regions = [];
  List<String> _provinces = [];
  List<String> _cities = [];
  List<String> _barangays = [];
  
  // Other settings
  String _selectedLabel = 'home';
  bool _isDefault = false;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    
    _loadLocationData();
    
    // If editing, populate form with existing data
    if (widget.address != null) {
      _fullNameController.text = widget.address!.fullName;
      _phoneController.text = widget.address!.phoneNumber;
      _addressLine1Controller.text = widget.address!.addressLine1;
      _addressLine2Controller.text = widget.address!.addressLine2;
      _postalCodeController.text = widget.address!.postalCode;
      _selectedLabel = widget.address!.label;
      _isDefault = widget.address!.isDefault;
      
      // We'll handle setting the dropdown values after the location data is loaded
    }
  }
  
  Future<void> _loadLocationData() async {
    setState(() {
      _isLoadingLocations = true;
    });
    
    try {
      _locationData = await PhilippineLocationHelper.loadLocationData();
      _regions = PhilippineLocationHelper.getRegions(_locationData!);
      
      // If editing, try to select the existing values
      if (widget.address != null) {
        // Set region
        if (widget.address!.region.isNotEmpty && 
            _regions.contains(widget.address!.region)) {
          _selectedRegion = widget.address!.region;
          _updateProvinces();
          
          // Set province
          if (widget.address!.province.isNotEmpty && 
              _provinces.contains(widget.address!.province)) {
            _selectedProvince = widget.address!.province;
            _updateCities();
            
            // Set city
            if (widget.address!.city.isNotEmpty && 
                _cities.contains(widget.address!.city)) {
              _selectedCity = widget.address!.city;
              _updateBarangays();
              
              // Set barangay
              if (widget.address!.barangay.isNotEmpty && 
                  _barangays.contains(widget.address!.barangay)) {
                _selectedBarangay = widget.address!.barangay;
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error loading location data: $e');
    } finally {
      setState(() {
        _isLoadingLocations = false;
      });
    }
  }
  
  void _updateProvinces() {
    if (_selectedRegion == null || _locationData == null) {
      setState(() {
        _provinces = [];
        _selectedProvince = null;
      });
      return;
    }
    
    setState(() {
      _provinces = PhilippineLocationHelper.getProvinces(_locationData!, _selectedRegion!);
      _selectedProvince = null;
    });
    _updateCities();
  }
  
  void _updateCities() {
    if (_selectedRegion == null || _selectedProvince == null || _locationData == null) {
      setState(() {
        _cities = [];
        _selectedCity = null;
      });
      return;
    }
    
    setState(() {
      _cities = PhilippineLocationHelper.getCities(_locationData!, _selectedRegion!, _selectedProvince!);
      _selectedCity = null;
    });
    _updateBarangays();
  }
  
  void _updateBarangays() {
    if (_selectedRegion == null || _selectedProvince == null || 
        _selectedCity == null || _locationData == null) {
      setState(() {
        _barangays = [];
        _selectedBarangay = null;
      });
      return;
    }
    
    setState(() {
      _barangays = PhilippineLocationHelper.getBarangays(
        _locationData!, _selectedRegion!, _selectedProvince!, _selectedCity!);
      _selectedBarangay = null;
    });
  }
  
  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.address == null ? "New Address" : "Edit Address",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1.0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoadingLocations 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: theme.primaryColor),
                SizedBox(height: 16),
                Text(
                  'Loading location data...',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
        : Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contact section
                  _buildSectionHeader('Contact Information'),
                  
                  _buildTextFormField(
                    controller: _fullNameController,
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  
                  _buildTextFormField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: 'Enter your phone number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a phone number';
                      }
                      
                      // Simple validation for Philippines phone number
                      if (!RegExp(r'(^(\+63|0)9\d{9}$)').hasMatch(value)) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  
                  // Address section
                  _buildSectionHeader('Address Details'),
                  
                  _buildTextFormField(
                    controller: _addressLine1Controller,
                    label: 'Address Line 1',
                    hint: 'House/Apt Number, Street Name',
                    icon: Icons.home_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your address';
                      }
                      return null;
                    },
                  ),
                  
                  _buildTextFormField(
                    controller: _addressLine2Controller,
                    label: 'Address Line 2',
                    hint: 'Building, Subdivision (optional)',
                    icon: Icons.location_city_outlined,
                  ),
                  
                  // Region dropdown
                  _buildDropdownField(
                    label: 'Region',
                    hint: 'Select your region',
                    value: _selectedRegion,
                    items: _regions,
                    onChanged: (value) {
                      setState(() {
                        _selectedRegion = value;
                      });
                      _updateProvinces();
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a region';
                      }
                      return null;
                    },
                  ),
                  
                  // Province dropdown
                  _buildDropdownField(
                    label: 'Province',
                    hint: 'Select your province',
                    value: _selectedProvince,
                    items: _provinces,
                    onChanged: (value) {
                      setState(() {
                        _selectedProvince = value;
                      });
                      _updateCities();
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a province';
                      }
                      return null;
                    },
                  ),
                  
                  // City dropdown
                  _buildDropdownField(
                    label: 'City/Municipality',
                    hint: 'Select your city/municipality',
                    value: _selectedCity,
                    items: _cities,
                    onChanged: (value) {
                      setState(() {
                        _selectedCity = value;
                      });
                      _updateBarangays();
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a city';
                      }
                      return null;
                    },
                  ),
                  
                  // Barangay dropdown
                  _buildDropdownField(
                    label: 'Barangay',
                    hint: 'Select your barangay',
                    value: _selectedBarangay,
                    items: _barangays,
                    onChanged: (value) {
                      setState(() {
                        _selectedBarangay = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a barangay';
                      }
                      return null;
                    },
                  ),
                  
                  _buildTextFormField(
                    controller: _postalCodeController,
                    label: 'Postal Code',
                    hint: 'Enter your postal code',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your postal code';
                      }
                      if (!RegExp(r'^[0-9]{4}$').hasMatch(value)) {
                        return 'Please enter a valid postal code';
                      }
                      return null;
                    },
                  ),
                  
                  // Settings section
                  _buildSectionHeader('Settings'),
                  
                  // Address label selector
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Label as',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            _buildLabelChip('home', 'Home'),
                            SizedBox(width: 12),
                            _buildLabelChip('work', 'Work'),
                            SizedBox(width: 12),
                            _buildLabelChip('other', 'Other'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Default address switch
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Set as Default Address',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Switch(
                          value: _isDefault,
                          onChanged: (value) {
                            setState(() {
                              _isDefault = value;
                            });
                          },
                          activeColor: theme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                  
                  // Save button
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                widget.address == null ? 'SAVE ADDRESS' : 'UPDATE ADDRESS',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey[700],
        ),
      ),
    );
  }
  
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.red),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }
  
  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        isExpanded: true,
        icon: Icon(Icons.arrow_drop_down),
        elevation: 2,
        style: TextStyle(color: Colors.black, fontSize: 16),
        validator: validator,
        onChanged: onChanged,
        items: items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildLabelChip(String value, String label) {
    final isSelected = _selectedLabel == value;
    final theme = Theme.of(context);
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedLabel = value;
          });
        }
      },
      labelStyle: GoogleFonts.poppins(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
      ),
      backgroundColor: Colors.grey[200],
      selectedColor: theme.primaryColor,
    );
  }
  
  Future<void> _saveAddress() async {
    if (_formKey.currentState?.validate() == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final provider = Provider.of<AddressProvider>(context, listen: false);
        final address = Address(
          id: widget.address?.id,
          fullName: _fullNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          addressLine1: _addressLine1Controller.text.trim(),
          addressLine2: _addressLine2Controller.text.trim(),
          barangay: _selectedBarangay ?? '',
          city: _selectedCity ?? '',
          province: _selectedProvince ?? '',
          region: _selectedRegion ?? '',
          postalCode: _postalCodeController.text.trim(),
          label: _selectedLabel,
          isDefault: _isDefault,
        );
        
        bool success;
        if (widget.address == null) {
          success = await provider.addAddress(address);
        } else {
          success = await provider.updateAddress(address);
        }
        
        if (!mounted) return;
        
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.address == null
                  ? 'Address added successfully'
                  : 'Address updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.error ?? 'An error occurred'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}