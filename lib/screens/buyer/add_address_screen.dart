import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/providers/address_provider.dart';
import '/models/address_model.dart';

class AddAddressScreen extends StatefulWidget {
  final Address? address; // For editing existing address
  
  const AddAddressScreen({Key? key, this.address}) : super(key: key);

  @override
  _AddAddressScreenState createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _barangayController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _regionController = TextEditingController();
  final _postalCodeController = TextEditingController();
  
  String _selectedLabel = 'home';
  bool _isDefault = false;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    
    // If editing, populate form with existing data
    if (widget.address != null) {
      _fullNameController.text = widget.address!.fullName;
      _phoneController.text = widget.address!.phoneNumber;
      _addressLine1Controller.text = widget.address!.addressLine1;
      _addressLine2Controller.text = widget.address!.addressLine2;
      _barangayController.text = widget.address!.barangay;
      _cityController.text = widget.address!.city;
      _provinceController.text = widget.address!.province;
      _regionController.text = widget.address!.region;
      _postalCodeController.text = widget.address!.postalCode;
      _selectedLabel = widget.address!.label;
      _isDefault = widget.address!.isDefault;
    }
  }
  
  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _barangayController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _regionController.dispose();
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
      body: Form(
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
              
              _buildTextFormField(
                controller: _barangayController,
                label: 'Barangay',
                hint: 'Enter your barangay',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your barangay';
                  }
                  return null;
                },
              ),
              
              _buildTextFormField(
                controller: _cityController,
                label: 'City/Municipality',
                hint: 'Enter your city/municipality',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your city';
                  }
                  return null;
                },
              ),
              
              _buildTextFormField(
                controller: _provinceController,
                label: 'Province',
                hint: 'Enter your province',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your province';
                  }
                  return null;
                },
              ),
              
              _buildTextFormField(
                controller: _regionController,
                label: 'Region',
                hint: 'Enter your region',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your region';
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
          barangay: _barangayController.text.trim(),
          city: _cityController.text.trim(),
          province: _provinceController.text.trim(),
          region: _regionController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
          label: _selectedLabel,
          isDefault: _isDefault,
        );
        
        bool success;
        if (widget.address == null) {
          // Add new address
          success = await provider.addAddress(address);
        } else {
          // Update existing address
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