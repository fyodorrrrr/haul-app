import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/models/shipping_address.dart';
import '/models/address_model.dart';
import '/providers/address_provider.dart';
import '/utils/address_mapper.dart';
import '/screens/buyer/add_address_screen.dart';

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
  // Saved address selection
  Address? _selectedAddress;
  bool _isLoadingAddresses = false;

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
  }

  Future<void> _loadSavedAddresses() async {
    setState(() {
      _isLoadingAddresses = true;
    });

    try {
      await Provider.of<AddressProvider>(context, listen: false).loadAddresses();

      // Select the default address automatically if available
      final provider = Provider.of<AddressProvider>(context, listen: false);
      if (provider.addresses.isNotEmpty) {
        setState(() {
          _selectedAddress = provider.defaultAddress ?? provider.addresses.first;
        });
      }
    } catch (e) {
      print('Error loading addresses: $e');
    } finally {
      setState(() {
        _isLoadingAddresses = false;
      });
    }
  }

  void _submitForm() {
    if (_selectedAddress != null) {
      // Convert selected Address to ShippingAddress and submit
      final shippingAddress = AddressMapper.toShippingAddress(_selectedAddress!);
      widget.onContinue(shippingAddress);
    } else {
      // Show error message if no address is selected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a shipping address or add a new one')),
      );
    }
  }

  void _navigateToAddAddress(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddAddressScreen()),
    ).then((_) {
      // Reload addresses when returning
      _loadSavedAddresses();
    });
  }

  Color _getLabelColor(String label) {
    switch (label.toLowerCase()) {
      case 'home':
        return Colors.blue;
      case 'work':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingAddresses) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.primaryColor),
            SizedBox(height: 16),
            Text(
              'Loading saved addresses...',
              style: GoogleFonts.poppins(
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
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
          const SizedBox(height: 16),
          Expanded(
            child: Provider.of<AddressProvider>(context).addresses.isEmpty
                ? _buildNoAddressesView()
                : _buildSavedAddressList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _selectedAddress != null ? _submitForm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
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
    );
  }

  Widget _buildNoAddressesView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No Saved Addresses',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please add a shipping address',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.add),
            label: Text('Add New Address'),
            onPressed: () => _navigateToAddAddress(context),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedAddressList() {
    final addresses = Provider.of<AddressProvider>(context).addresses;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: addresses.length,
            itemBuilder: (context, index) => _buildAddressCard(addresses[index]),
          ),
        ),
        // Add new address button
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: OutlinedButton.icon(
            onPressed: () => _navigateToAddAddress(context),
            icon: Icon(Icons.add),
            label: Text('Add New Address'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12),
              minimumSize: Size(double.infinity, 0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressCard(Address address) {
    final isSelected = _selectedAddress?.id == address.id;
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: isSelected ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? theme.primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedAddress = address;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Radio<String>(
                value: address.id ?? '',
                groupValue: _selectedAddress?.id ?? '',
                onChanged: (value) {
                  setState(() {
                    _selectedAddress = address;
                  });
                },
                activeColor: theme.primaryColor,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            address.fullName,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (address.isDefault)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'DEFAULT',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: theme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      address.phoneNumber,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      AddressMapper.formatAddress(address),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                      ),
                    ),
                    if (address.label.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getLabelColor(address.label).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            address.label.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: _getLabelColor(address.label),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}