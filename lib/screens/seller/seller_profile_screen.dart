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

class _SellerProfileScreenState extends State<SellerProfileScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  
  // Text controllers
  final _businessNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  
  // Business hours controllers
  final Map<String, TextEditingController> _businessHoursControllers = {
    'monday': TextEditingController(),
    'tuesday': TextEditingController(),
    'wednesday': TextEditingController(),
    'thursday': TextEditingController(),
    'friday': TextEditingController(),
    'saturday': TextEditingController(),
    'sunday': TextEditingController(),
  };
  
  // Payment info controllers
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  String _selectedAccountType = 'Bank';
  
  // Profile data
  Map<String, dynamic> _profileData = {};
  bool _isLoading = true;
  bool _isUploading = false;
  File? _profileImage;
  String? _profileImageUrl;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      
      // Set controller values for basic profile
      _businessNameController.text = _profileData['businessName'] ?? '';
      _emailController.text = user.email ?? '';
      _phoneController.text = _profileData['phone'] ?? '';
      _addressController.text = _profileData['address'] ?? '';
      _descriptionController.text = _profileData['description'] ?? '';
      _websiteController.text = _profileData['website'] ?? '';
      _profileImageUrl = _profileData['profileImageUrl'];
      
      // Set business hours controllers
      final businessHours = _profileData['businessHours'] as Map<String, dynamic>? ?? {};
      businessHours.forEach((day, hours) {
        if (_businessHoursControllers.containsKey(day)) {
          _businessHoursControllers[day]?.text = hours ?? '';
        }
      });
      
      // Set payment info controllers
      final paymentInfo = _profileData['paymentInfo'] as Map<String, dynamic>? ?? {};
      _accountNameController.text = paymentInfo['accountName'] ?? '';
      _accountNumberController.text = paymentInfo['accountNumber'] ?? '';
      _bankNameController.text = paymentInfo['bankName'] ?? '';
      _selectedAccountType = paymentInfo['accountType'] ?? 'Bank';
      
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
      
      // Prepare business hours data
      final businessHours = <String, String>{};
      _businessHoursControllers.forEach((day, controller) {
        if (controller.text.isNotEmpty) {
          businessHours[day] = controller.text.trim();
        }
      });
      
      // Prepare payment info
      final paymentInfo = {
        'accountName': _accountNameController.text.trim(),
        'accountNumber': _accountNumberController.text.trim(),
        'bankName': _bankNameController.text.trim(),
        'accountType': _selectedAccountType,
      };
      
      // Update profile data
      final updatedData = {
        'businessName': _businessNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'description': _descriptionController.text.trim(),
        'website': _websiteController.text.trim(),
        'profileImageUrl': imageUrl,
        'businessHours': businessHours,
        'paymentInfo': paymentInfo,
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
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _bankNameController.dispose();
    _businessHoursControllers.values.forEach((controller) => controller.dispose());
    _tabController.dispose();
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
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Profile'),
            Tab(text: 'Business Hours'),
            Tab(text: 'Payment Info'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Profile Image Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundImage: _profileImage != null
                                    ? FileImage(_profileImage!) as ImageProvider
                                    : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                        ? NetworkImage(_profileImageUrl!)
                                        : const AssetImage('assets/default_profile.png') as ImageProvider),
                                backgroundColor: Colors.grey.shade200,
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to change profile picture',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Profile Tab
                      SingleChildScrollView(child: _buildProfileSection()),
                      
                      // Business Hours Tab
                      SingleChildScrollView(child: _buildBusinessHoursSection()),
                      
                      // Payment Info Tab
                      SingleChildScrollView(child: _buildPaymentInfoSection()),
                    ],
                  ),
                ),
              ],
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
    Widget _buildProfileSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              controller: _businessNameController,
              label: 'Business Name',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your business name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone',
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _addressController,
              label: 'Address',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _websiteController,
              label: 'Website',
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your website';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessHoursSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
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
          Text(
            'Set your store\'s business hours. Leave empty for closed days.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // Monday
          _buildBusinessHourField('Monday', _businessHoursControllers['monday']!),
          const SizedBox(height: 16),
          
          // Tuesday
          _buildBusinessHourField('Tuesday', _businessHoursControllers['tuesday']!),
          const SizedBox(height: 16),
          
          // Wednesday
          _buildBusinessHourField('Wednesday', _businessHoursControllers['wednesday']!),
          const SizedBox(height: 16),
          
          // Thursday
          _buildBusinessHourField('Thursday', _businessHoursControllers['thursday']!),
          const SizedBox(height: 16),
          
          // Friday
          _buildBusinessHourField('Friday', _businessHoursControllers['friday']!),
          const SizedBox(height: 16),
          
          // Saturday
          _buildBusinessHourField('Saturday', _businessHoursControllers['saturday']!),
          const SizedBox(height: 16),
          
          // Sunday
          _buildBusinessHourField('Sunday', _businessHoursControllers['sunday']!),
          
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  _setStandardBusinessHours();
                },
                icon: const Icon(Icons.access_time),
                label: const Text('Set Standard Hours'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  _clearAllBusinessHours();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear All'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildBusinessHourField(String day, TextEditingController controller) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            day,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'e.g. 9:00 AM - 5:00 PM',
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  void _setStandardBusinessHours() {
    setState(() {
      _businessHoursControllers['monday']!.text = '9:00 AM - 5:00 PM';
      _businessHoursControllers['tuesday']!.text = '9:00 AM - 5:00 PM';
      _businessHoursControllers['wednesday']!.text = '9:00 AM - 5:00 PM';
      _businessHoursControllers['thursday']!.text = '9:00 AM - 5:00 PM';
      _businessHoursControllers['friday']!.text = '9:00 AM - 5:00 PM';
      _businessHoursControllers['saturday']!.text = '10:00 AM - 4:00 PM';
      _businessHoursControllers['sunday']!.text = 'Closed';
    });
  }
  
  void _clearAllBusinessHours() {
    setState(() {
      _businessHoursControllers.forEach((day, controller) {
        controller.clear();
      });
    });
  }
  
  Widget _buildPaymentInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Information',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Provide your payment details for receiving payments from sales.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // Account Type Selection
          Text(
            'Account Type',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedAccountType,
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                borderRadius: BorderRadius.circular(8),
                items: [
                  DropdownMenuItem(
                    value: 'Bank',
                    child: Text('Bank Account', style: GoogleFonts.poppins()),
                  ),
                  DropdownMenuItem(
                    value: 'E-Wallet',
                    child: Text('E-Wallet', style: GoogleFonts.poppins()),
                  ),
                  DropdownMenuItem(
                    value: 'Other',
                    child: Text('Other', style: GoogleFonts.poppins()),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedAccountType = value;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Account Name
          _buildTextField(
            controller: _accountNameController,
            label: 'Account Name',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the account name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Account Number
          _buildTextField(
            controller: _accountNumberController,
            label: _selectedAccountType == 'E-Wallet' ? 'E-Wallet Number' : 'Account Number',
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the account number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Bank Name
          _buildTextField(
            controller: _bankNameController,
            label: _selectedAccountType == 'Bank' ? 'Bank Name' : 
                  _selectedAccountType == 'E-Wallet' ? 'E-Wallet Provider' : 'Provider Name',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the provider name';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your payment information is secure and will only be used for processing your sales revenue.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}