import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:haul/providers/seller_registration_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:haul/screens/seller/seller_verification_screen.dart';
import 'package:haul/utils/safe_state.dart';

class SellerProcessingScreen extends StatefulWidget {
  final String businessName;

  const SellerProcessingScreen({
    Key? key,
    required this.businessName,
  }) : super(key: key);

  @override
  State<SellerProcessingScreen> createState() => _SellerProcessingScreenState();
}

class _SellerProcessingScreenState extends State<SellerProcessingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _ssnController = TextEditingController();

  File? _frontIdImage;
  File? _backIdImage;
  bool _isUploading = false;
  bool _isLoading = true;
  bool _hasActiveVerification = false;
  String? _verificationStatus;
  DateTime? _verificationDate;

  final ImagePicker _picker = ImagePicker();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkVerificationStatus();
    });
  }
  Future<void> _checkVerificationStatus() async {
    if (!mounted) return;
    safeSetState(() {
      _isLoading = true;
    });

    try {
      // Store context reference
      final currentContext = context;

      final provider = Provider.of<SellerRegistrationProvider>(currentContext, listen: false);
      final verificationDetails = await provider.getVerificationStatus();

      if (!mounted) return;
      safeSetState(() {
        _hasActiveVerification = verificationDetails['hasActiveVerification'] ?? false;
        _verificationStatus = verificationDetails['status'];
        _verificationDate = verificationDetails['submittedDate'];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      safeSetState(() {
        _isLoading = false;
      });

      // Store context reference
      final currentContext = context;
      if (mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text('Error checking verification status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _ssnController.dispose();
    super.dispose();
  }
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      if (!mounted) return;
      safeSetState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }
  Future<void> _pickImage(bool isFrontId) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        if (!mounted) return;
        safeSetState(() {
          if (isFrontId) {
            _frontIdImage = File(image.path);
          } else {
            _backIdImage = File(image.path);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _handleSubmit() async {
    final BuildContext currentContext = context;

    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Please select your date of birth')),
        );
        return;
      }

      if (_frontIdImage == null || _backIdImage == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Please upload images of both sides of your ID')),
        );
        return;
      }      if (!mounted) return;
      safeSetState(() {
        _isUploading = true;
      });

      try {
        final provider = Provider.of<SellerRegistrationProvider>(currentContext, listen: false);

        final success = await provider.saveSellerPersonalInfo(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          phoneNumber: _phoneController.text,
          dateOfBirth: _selectedDate!,
          ssn: _ssnController.text,
          frontIdImage: _frontIdImage!,
          backIdImage: _backIdImage!,
        );

        if (!mounted) return;

        if (success) {
          Navigator.pushAndRemoveUntil(
            currentContext,
            MaterialPageRoute(
              builder: (context) => SellerVerificationScreen(
                businessName: widget.businessName,
              ),
            ),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'An unknown error occurred'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {        if (mounted) {
          safeSetState(() {
            _isUploading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Seller Verification',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Checking verification status...'),
                  ],
                ),
              )
            : _isUploading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Uploading your information...\nPlease wait'),
                      ],
                    ),
                  )
                : _hasActiveVerification
                    ? _buildActiveVerificationView(theme)
                    : _buildVerificationForm(theme),
      ),
    );
  }

  Widget _buildActiveVerificationView(ThemeData theme) {
    String statusMessage;
    Color statusColor;
    IconData statusIcon;

    switch (_verificationStatus?.toLowerCase()) {
      case 'pending':
        statusMessage = 'Your verification is pending review.';
        statusColor = Colors.amber;
        statusIcon = Icons.pending_actions;
        break;
      case 'approved':
        statusMessage = 'Your verification has been approved!';
        statusColor = Colors.green;
        statusIcon = Icons.verified_user;
        break;
      case 'processing':
        statusMessage = 'Your verification is being processed.';
        statusColor = Colors.blue;
        statusIcon = Icons.hourglass_top;
        break;
      default:
        statusMessage = 'Verification status: $_verificationStatus';
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    String formattedDate = _verificationDate != null
        ? DateFormat('MMM dd, yyyy').format(_verificationDate!)
        : 'Unknown date';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            statusIcon,
            size: 80,
            color: statusColor,
          ),
          const SizedBox(height: 24),
          Text(
            'Verification In Progress',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        statusIcon,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            _verificationStatus?.toUpperCase() ?? 'UNKNOWN',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.grey),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Submitted on',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              statusMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'You cannot submit a new verification request until this one is processed.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: Text(
                'GO BACK',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationForm(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'To ensure a secure selling environment, please provide your personal details and ID verification.',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Details',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: 'First Name',
                          controller: _firstNameController,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter your first name'
                              : null,
                          icon: Icons.person_outline,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          label: 'Last Name',
                          controller: _lastNameController,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter your last name'
                              : null,
                          icon: Icons.person_outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Phone Number',
                    controller: _phoneController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      if (!RegExp(r'^\(\d{3}\) \d{3}-\d{4}$').hasMatch(value) &&
                          !RegExp(r'^\d{10}$').hasMatch(value)) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.phone,
                    icon: Icons.phone,
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: AbsorbPointer(
                      child: _buildTextField(
                        label: 'Date of Birth',
                        controller: _dobController,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter your date of birth'
                            : null,
                        keyboardType: TextInputType.datetime,
                        icon: Icons.calendar_today,
                        hintText: 'MM/DD/YYYY',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: 'Last 4 digits of SSS',
                    controller: _ssnController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter last 4 digits of SSS';
                      }
                      if (value.length != 4 || !RegExp(r'^\d{4}$').hasMatch(value)) {
                        return 'Enter valid last 4 digits of SSs';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.number,
                    icon: Icons.security,
                    obscureText: true,
                    maxLength: 4,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'ID Verification',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Please provide clear images of the front and back of your government-issued ID',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildImageUploader(
                          label: 'Front of ID',
                          image: _frontIdImage,
                          onTap: () => _pickImage(true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildImageUploader(
                          label: 'Back of ID',
                          image: _backIdImage,
                          onTap: () => _pickImage(false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'SUBMIT FOR VERIFICATION',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
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
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required FormFieldValidator<String> validator,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
    String? hintText,
    bool obscureText = false,
    int? maxLength,
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
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: icon != null ? Icon(icon) : null,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            counterText: '',
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploader({
    required String label,
    required File? image,
    required VoidCallback onTap,
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
        InkWell(
          onTap: onTap,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: image == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 40,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to take photo',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        Image.file(
                          image,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.black.withOpacity(0.6),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Tap to change',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}