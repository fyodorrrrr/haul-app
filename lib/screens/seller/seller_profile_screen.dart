import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '/widgets/loading_screen.dart';
import '/theme/app_theme.dart';
import 'store_policies_preview_screen.dart';

class SellerProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final int initialTab; // Add this parameter
  
  const SellerProfileScreen({
    Key? key, 
    this.initialData,
    this.initialTab = 0, // Default to first tab
  }) : super(key: key);

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize tab controller
    _tabController = TabController(
      length: 4,  // Changed from 3 to 4 to add Store Policies tab
      vsync: this,
      initialIndex: widget.initialTab,
    );
    
    // Add this line to load the profile data
    _loadSellerProfile();
  }
  
  final _formKey = GlobalKey<FormState>();
  
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
  
  // Store policies controllers
  final _returnPolicyController = TextEditingController();
  final _shippingPolicyController = TextEditingController();
  final _termsAndConditionsController = TextEditingController();
    // Profile data
  Map<String, dynamic> _profileData = {};
  bool _isLoading = true;
  File? _profileImage;
  String? _profileImageUrl;
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
        // Set store policies controllers
      final storePolicies = _profileData['storePolicies'] as Map<String, dynamic>? ?? {};
      _returnPolicyController.text = storePolicies['returnPolicy'] ?? '';
      _shippingPolicyController.text = storePolicies['shippingPolicy'] ?? '';
      _termsAndConditionsController.text = storePolicies['termsAndConditions'] ?? '';
      
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
    
    final loadingContext = context;
    LoadingScreen.show(loadingContext);
    
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
      LoadingScreen.hide(loadingContext);
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
      
      // Prepare store policies
      final storePolicies = {
        'returnPolicy': _returnPolicyController.text.trim(),
        'shippingPolicy': _shippingPolicyController.text.trim(),
        'termsAndConditions': _termsAndConditionsController.text.trim(),
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
        'storePolicies': storePolicies,
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
    _returnPolicyController.dispose();
    _shippingPolicyController.dispose();
    _termsAndConditionsController.dispose();
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
          isScrollable: true, // Make tabs scrollable
          labelPadding: const EdgeInsets.symmetric(horizontal: 20.0), // Add padding between tabs
          indicatorSize: TabBarIndicatorSize.label, // Makes indicator match tab width
          tabs: [
            Tab(
              child: Text('Profile', style: GoogleFonts.poppins(fontSize: 13)),
            ),
            Tab(
              child: Text('Business Hours', style: GoogleFonts.poppins(fontSize: 13)),
            ),
            Tab(
              child: Text('Payment Info', style: GoogleFonts.poppins(fontSize: 13)),
            ),
            Tab(
              child: Text('Store Policies', style: GoogleFonts.poppins(fontSize: 13)),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
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
                        
                        // Store Policies Tab
                        SingleChildScrollView(child: _buildStorePoliciesSection()),
                      ],
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
      child: Column(  // Remove the Form widget from here
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
          
          const SizedBox(height: 20),
          Divider(color: Colors.grey.shade300),
          const SizedBox(height: 16),

          // More compact buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Standard Hours button (smaller)
              ElevatedButton(
                onPressed: () {
                  _setStandardBusinessHours();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Standard hours applied'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  minimumSize: Size(100, 40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 16),
                    SizedBox(width: 4),
                    Text('Standard Hours', style: GoogleFonts.poppins(fontSize: 12)),
                  ],
                ),
              ),
              
              // Clear All button (smaller)
              OutlinedButton(
                onPressed: () {
                  _clearAllBusinessHours();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hours cleared'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  minimumSize: Size(100, 40),
                  side: BorderSide(color: Colors.red.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.clear_all, size: 16, color: Colors.red),
                    SizedBox(width: 4),
                    Text('Clear All', 
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  Widget _buildBusinessHourField(String day, TextEditingController controller) {
    // Parse existing times if any
    TimeOfDay? openingTime;
    TimeOfDay? closingTime;
    bool isClosed = false;
    
    if (controller.text.toLowerCase() == 'closed') {
      isClosed = true;
    } else if (controller.text.contains('-')) {
      try {
        final parts = controller.text.split('-');
        if (parts.length == 2) {
          openingTime = _parseTimeString(parts[0].trim());
          closingTime = _parseTimeString(parts[1].trim());
        }
      } catch (e) {
        // Invalid format, use default values
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header with closed switch
        Row(
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
            Spacer(),
            Text(
              'Closed',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: isClosed ? Colors.red[700] : Colors.grey[600],
              ),
            ),
            Switch(
              value: isClosed,
              onChanged: (value) {
                setState(() {
                  if (value) {
                    controller.text = 'Closed';
                  } else {
                    // Default to 9-5 if no previous values
                    openingTime ??= TimeOfDay(hour: 9, minute: 0);
                    closingTime ??= TimeOfDay(hour: 17, minute: 0);
                    controller.text = '${_formatTimeOfDay(openingTime!)} - ${_formatTimeOfDay(closingTime!)}';
                  }
                });
              },
              activeColor: Colors.red[700],
            ),
          ],
        ),
        
        // Time selection controls (hidden when closed)
        if (!isClosed)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Row(
              children: [
                const SizedBox(width: 16),
                // Opening time button
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: openingTime ?? TimeOfDay(hour: 9, minute: 0),
                      );
                      
                      if (time != null) {
                        setState(() {
                          openingTime = time;
                          if (closingTime != null) {
                            controller.text = '${_formatTimeOfDay(openingTime!)} - ${_formatTimeOfDay(closingTime!)}';
                          } else {
                            closingTime = TimeOfDay(hour: 17, minute: 0); // Default closing time
                            controller.text = '${_formatTimeOfDay(openingTime!)} - ${_formatTimeOfDay(closingTime!)}';
                          }
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            openingTime != null ? _formatTimeOfDay(openingTime!) : 'Opening time',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                          Icon(Icons.access_time, size: 16, color: Colors.grey[700]),
                        ],
                      ),
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('to', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                ),
                
                // Closing time button
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: closingTime ?? TimeOfDay(hour: 17, minute: 0),
                      );
                      
                      if (time != null) {
                        setState(() {
                          closingTime = time;
                          if (openingTime != null) {
                            controller.text = '${_formatTimeOfDay(openingTime!)} - ${_formatTimeOfDay(closingTime!)}';
                          } else {
                            openingTime = TimeOfDay(hour: 9, minute: 0); // Default opening time
                            controller.text = '${_formatTimeOfDay(openingTime!)} - ${_formatTimeOfDay(closingTime!)}';
                          }
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            closingTime != null ? _formatTimeOfDay(closingTime!) : 'Closing time',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                          Icon(Icons.access_time, size: 16, color: Colors.grey[700]),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        Divider(),
      ],
    );
  }

  // Helper method to parse a time string (e.g. "9:00 AM") to TimeOfDay
  TimeOfDay? _parseTimeString(String timeStr) {
    try {
      final isAM = timeStr.toUpperCase().contains('AM');
      final isPM = timeStr.toUpperCase().contains('PM');
      
      // Remove AM/PM indicators
      timeStr = timeStr
        .toUpperCase()
        .replaceAll('AM', '')
        .replaceAll('PM', '')
        .trim();
      
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        
        // Convert 12-hour format to 24-hour format
        if (isPM && hour < 12) hour += 12;
        if (isAM && hour == 12) hour = 0;
        
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      // Parsing failed
    }
    return null;
  }

  // Helper method to format TimeOfDay to string (e.g. "9:00 AM")
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
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
  
  Widget _buildStorePoliciesSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Store Policies',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  final policies = {
                    'returnPolicy': _returnPolicyController.text.trim(),
                    'shippingPolicy': _shippingPolicyController.text.trim(),
                    'termsAndConditions': _termsAndConditionsController.text.trim(),
                  };
                  
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => StorePoliciesPreviewScreen(storePolicies: policies),
                    ),
                  );
                },
                icon: Icon(Icons.visibility_outlined, size: 16),
                label: Text(
                  'Preview',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Define your store policies for customers. Clear, informative policies help build trust with your buyers.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // Return Policy
          _buildPolicyField(
            controller: _returnPolicyController,
            label: 'Return Policy',
            icon: Icons.assignment_return,
            hintText: 'Example: Items can be returned within 14 days of delivery if unused and in original packaging.',
            iconColor: Colors.orange,
          ),
          const SizedBox(height: 16),
          
          // Shipping Policy
          _buildPolicyField(
            controller: _shippingPolicyController,
            label: 'Shipping Policy',
            icon: Icons.local_shipping,
            hintText: 'Example: Orders are shipped within 2 business days. Standard shipping takes 3-5 business days.',
            iconColor: Colors.blue,
          ),
          const SizedBox(height: 16),
          
          // Terms and Conditions
          _buildPolicyField(
            controller: _termsAndConditionsController,
            label: 'Terms and Conditions',
            icon: Icons.gavel,
            hintText: 'Example: By placing an order, you agree to our terms of service. Payment must be received before shipping.',
            iconColor: Colors.purple,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPolicyField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hintText,
    required Color iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[400],
              fontStyle: FontStyle.italic,
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.all(16),
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
              borderSide: BorderSide(color: iconColor),
            ),
          ),
          validator: (value) {
            // Optional validation - not making policies required, but giving feedback
            if (value == null || value.isEmpty) {
              return 'Consider adding a $label for better customer experience';
            }
            return null;
          },
        ),
      ],
    );
  }
}