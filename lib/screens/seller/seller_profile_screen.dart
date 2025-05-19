import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '/widgets/loading_screen.dart';
import '/theme/app_theme.dart';

class SellerProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const SellerProfileScreen({Key? key, this.initialData}) : super(key: key);

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Text controllers
  final _businessNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  
  // Profile data
  Map<String, dynamic> _profileData = {};
  bool _isLoading = true;
  bool _isUploading = false;
  File? _profileImage;
  String? _profileImageUrl;
  
  @override
  void initState() {
    super.initState();
    _loadSellerProfile();
  }
  
  Future<void> _loadSellerProfile() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Not logged in
        Navigator.of(context).pop();
        return;
      }
      
      // First try to use initialData if provided
      if (widget.initialData != null) {
        _profileData = widget.initialData!;
      } else {
        // Load from Firestore
        final sellerDoc = await FirebaseFirestore.instance
            .collection('sellers')
            .doc(user.uid)
            .get();
            
        if (sellerDoc.exists) {
          _profileData = sellerDoc.data() ?? {};
        }
      }
      
      // Set controller values
      _businessNameController.text = _profileData['businessName'] ?? '';
      _emailController.text = user.email ?? '';
      _phoneController.text = _profileData['phone'] ?? '';
      _addressController.text = _profileData['address'] ?? '';
      _descriptionController.text = _profileData['description'] ?? '';
      _websiteController.text = _profileData['website'] ?? '';
      _profileImageUrl = _profileData['profileImageUrl'];
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }
  
  Future<String?> _uploadProfileImage() async {
    if (_profileImage == null) return _profileImageUrl;
    
    setState(() {
      _isUploading = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('seller_profiles')
          .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
          
      final uploadTask = storageRef.putFile(_profileImage!);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return null;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }
  
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    LoadingScreen.show(context);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        LoadingScreen.hide(context);
        return;
      }
      
      // Upload image if changed
      String? imageUrl = _profileImageUrl;
      if (_profileImage != null) {
        imageUrl = await _uploadProfileImage();
      }
      
      // Update profile data
      final updatedData = {
        'businessName': _businessNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'description': _descriptionController.text.trim(),
        'website': _websiteController.text.trim(),
        'profileImageUrl': imageUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      
      await FirebaseFirestore.instance
          .collection('sellers')
          .doc(user.uid)
          .update(updatedData);
      
      // Update user email if changed and different
      if (_emailController.text.trim() != user.email) {
        await user.updateEmail(_emailController.text.trim());
      }
      
      LoadingScreen.hide(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      LoadingScreen.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Seller Profile',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _updateProfile,
            child: Text(
              'SAVE',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome section
                    Text(
                      'Welcome back!',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Here\'s your store performance',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // NEW: Profile Section
                    _buildProfileSection(),
                    const SizedBox(height: 24),
                    
                    // NEW: Payment Information Section
                    _buildPaymentInfo(),
                    const SizedBox(height: 24),
                    
                    // Metrics Cards
                    // Your existing metrics section
                    
                    // Other dashboard components
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    required FormFieldValidator<String> validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
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
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
  
  Widget _buildDrawer() {
    // Implement your drawer widget here
    return Drawer();
  }
  
  Future<void> _loadDashboardData() async {
    // Implement your dashboard data loading logic here
  }
  
  Widget _buildProfileSection() {
    // Implement your profile section widget here
    return Container();
  }

  Widget _buildVerificationStatus() {
    final verificationStatus = _profileData['verificationStatus'] ?? 'pending';
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (verificationStatus.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        statusText = 'Verified Seller';
        statusIcon = Icons.verified;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Verification Failed';
        statusIcon = Icons.cancel;
        break;
      case 'pending':
      default:
        statusColor = Colors.orange;
        statusText = 'Verification Pending';
        statusIcon = Icons.pending_actions;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessHours() {
    // Get business hours from Firestore or use defaults
    final businessHours = _profileData['businessHours'] as Map<String, dynamic>? ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business Hours',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _buildDayHourRow('Monday', businessHours['monday'] ?? '9:00 AM - 5:00 PM'),
        _buildDayHourRow('Tuesday', businessHours['tuesday'] ?? '9:00 AM - 5:00 PM'),
        _buildDayHourRow('Wednesday', businessHours['wednesday'] ?? '9:00 AM - 5:00 PM'),
        _buildDayHourRow('Thursday', businessHours['thursday'] ?? '9:00 AM - 5:00 PM'),
        _buildDayHourRow('Friday', businessHours['friday'] ?? '9:00 AM - 5:00 PM'),
        _buildDayHourRow('Saturday', businessHours['saturday'] ?? '10:00 AM - 4:00 PM'),
        _buildDayHourRow('Sunday', businessHours['sunday'] ?? 'Closed'),
      ],
    );
  }

  Widget _buildDayHourRow(String day, String hours) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            hours,
            style: GoogleFonts.poppins(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo() {
    final paymentInfo = _profileData['paymentInfo'] as Map<String, dynamic>? ?? {};
    final hasPaymentInfo = paymentInfo.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Payment Information',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to payment info update screen
              },
              child: Text(
                hasPaymentInfo ? 'EDIT' : 'ADD',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (hasPaymentInfo)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPaymentInfoRow('Account Type', paymentInfo['accountType'] ?? ''),
                _buildPaymentInfoRow('Account Name', paymentInfo['accountName'] ?? ''),
                _buildPaymentInfoRow('Account Number', '******${paymentInfo['accountNumber']?.toString().substring(paymentInfo['accountNumber'].toString().length - 4) ?? ''}'),
                // Add more payment details as needed
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'No payment information added yet',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(),
          ),
        ],
      ),
    );
  }
}