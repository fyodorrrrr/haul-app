import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/models/shipping_address.dart';

class ShippingAddressForm extends StatefulWidget {
  final Function(ShippingAddress) onContinue;

  const ShippingAddressForm({
    Key? key,
    required this.onContinue,
  }) : super(key: key);

  @override
  State<ShippingAddressForm> createState() => _ShippingAddressFormState();
}

class _ShippingAddressFormState extends State<ShippingAddressForm> {
  final _formKey = GlobalKey<FormState>();
  
  final _fullNameController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final address = ShippingAddress(
        fullName: _fullNameController.text,
        addressLine1: _addressLine1Controller.text,
        addressLine2: _addressLine2Controller.text,
        city: _cityController.text,
        state: _stateController.text,
        zipCode: _zipCodeController.text,
        country: _countryController.text,
        phoneNumber: _phoneController.text,
      );
      widget.onContinue(address);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shipping Address',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    _buildTextField(
                      controller: _fullNameController,
                      label: 'Full Name',
                      prefixIcon: Icons.person_outline,
                      validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                    ),
                    
                    _buildTextField(
                      controller: _addressLine1Controller,
                      label: 'Address Line 1',
                      prefixIcon: Icons.home_outlined,
                      validator: (value) => value!.isEmpty ? 'Please enter your address' : null,
                    ),
                    
                    _buildTextField(
                      controller: _addressLine2Controller,
                      label: 'Address Line 2 (Optional)',
                      prefixIcon: Icons.home_outlined,
                    ),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _cityController,
                            label: 'City',
                            prefixIcon: Icons.location_city_outlined,
                            validator: (value) => value!.isEmpty ? 'Please enter your city' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _stateController,
                            label: 'State/Province',
                            prefixIcon: Icons.map_outlined,
                            validator: (value) => value!.isEmpty ? 'Please enter your state' : null,
                          ),
                        ),
                      ],
                    ),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _zipCodeController,
                            label: 'ZIP/Postal Code',
                            prefixIcon: Icons.pin_outlined,
                            validator: (value) => value!.isEmpty ? 'Please enter your ZIP code' : null,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _countryController,
                            label: 'Country',
                            prefixIcon: Icons.flag_outlined,
                            validator: (value) => value!.isEmpty ? 'Please enter your country' : null,
                          ),
                        ),
                      ],
                    ),
                    
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      prefixIcon: Icons.phone_outlined,
                      validator: (value) => value!.isEmpty ? 'Please enter your phone number' : null,
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Continue to Payment',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? prefixIcon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.black, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        validator: validator,
        keyboardType: keyboardType,
      ),
    );
  }
}