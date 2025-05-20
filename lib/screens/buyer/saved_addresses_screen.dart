import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/providers/address_provider.dart';
import '/models/address_model.dart';
import 'add_address_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({Key? key}) : super(key: key);

  @override
  _SavedAddressesScreenState createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  @override
  void initState() {
    super.initState();
    // Load addresses when the screen opens
    Future.microtask(() => 
      Provider.of<AddressProvider>(context, listen: false).loadAddresses()
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Saved Addresses",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
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
      body: Consumer<AddressProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: theme.primaryColor),
            );
          }
          
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    provider.error!.contains('permission')
                      ? Icons.lock_outline
                      : Icons.error_outline,
                    size: 60, 
                    color: provider.error!.contains('permission') ? Colors.orange : Colors.red
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Error loading addresses',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Force reauthentication if permission error
                      if (provider.error!.contains('permission')) {
                        final auth = FirebaseAuth.instance;
                        // Sign out and redirect to login, or refresh token
                        // This depends on your auth implementation
                      } else {
                        provider.loadAddresses();
                      }
                    },
                    child: Text(
                      provider.error!.contains('permission')
                        ? 'Sign In Again'
                        : 'Try Again'
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }
          
          if (provider.addresses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 24),
                  Text(
                    'No Saved Addresses',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add a new address to continue',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 32),
                  ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('Add New Address'),
                    onPressed: () => _navigateToAddAddress(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }
          
          return Column(
            children: [
              // Section title
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Addresses',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton.icon(
                      icon: Icon(Icons.add, size: 18),
                      label: Text('Add'),
                      onPressed: () => _navigateToAddAddress(context),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Address list
              Expanded(
                child: ListView.builder(
                  itemCount: provider.addresses.length,
                  padding: EdgeInsets.only(bottom: 24),
                  itemBuilder: (context, index) {
                    final address = provider.addresses[index];
                    return _buildAddressCard(context, address, provider);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  // Navigate to add address screen
  void _navigateToAddAddress(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddAddressScreen()),
    ).then((_) {
      // Reload addresses when returning
      Provider.of<AddressProvider>(context, listen: false).loadAddresses();
    });
  }
  
  // Navigate to edit address screen
  void _navigateToEditAddress(BuildContext context, Address address) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAddressScreen(address: address),
      ),
    ).then((_) {
      // Reload addresses when returning
      Provider.of<AddressProvider>(context, listen: false).loadAddresses();
    });
  }
  
  // Show delete confirmation dialog
  Future<void> _confirmDelete(BuildContext context, Address address, AddressProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Address'),
        content: Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final success = await provider.deleteAddress(address.id!);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Address deleted successfully')),
        );
      }
    }
  }
  
  // Build address card
  Widget _buildAddressCard(BuildContext context, Address address, AddressProvider provider) {
    final theme = Theme.of(context);
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name and phone
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
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: address.label == 'home' 
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    address.label.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: address.label == 'home' ? Colors.blue : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 4),
            
            // Phone number
            Text(
              address.phoneNumber,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            
            SizedBox(height: 8),
            
            // Full address
            Text(
              _formatAddress(address),
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
            
            SizedBox(height: 16),
            
            // Actions
            Row(
              children: [
                // Default badge/button
                if (address.isDefault)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: theme.primaryColor,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'DEFAULT',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  TextButton(
                    onPressed: () async {
                      final success = await provider.setDefaultAddress(address.id!);
                      
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Default address updated')),
                        );
                      }
                    },
                    child: Text(
                      'Set as default',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.primaryColor,
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                
                Spacer(),
                
                // Edit button
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _navigateToEditAddress(context, address),
                  color: Colors.grey[700],
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
                
                SizedBox(width: 16),
                
                // Delete button
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _confirmDelete(context, address, provider),
                  color: Colors.red[400],
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper to format the full address
  String _formatAddress(Address address) {
    List<String> components = [
      address.addressLine1,
      address.addressLine2,
      address.barangay,
      address.city,
      address.province,
      address.region,
      address.postalCode,
    ];
    
    // Filter out empty components
    components = components.where((c) => c.trim().isNotEmpty).toList();
    
    return components.join(', ');
  }
}
