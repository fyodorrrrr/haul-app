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
          const SnackBar(
            content: Text('Please select your date of birth'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_frontIdImage == null && _backIdImage == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(
            content: Text('Please upload images of both sides of your ID'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      } else if (_frontIdImage == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(
            content: Text('Please upload the front side of your ID'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      } else if (_backIdImage == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(
            content: Text('Please upload the back side of your ID'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_frontIdImage!.lengthSync() < 50000 || _backIdImage!.lengthSync() < 50000) {
        if (!mounted) return;
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(
            content: Text('ID images appear to be low quality. Please retake with better lighting.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (!mounted) return;
      safeSetState(() {
        _isUploading = true;
      });

      try {
        final provider = Provider.of<SellerRegistrationProvider>(currentContext, listen: false);

        final success = await provider.saveSellerPersonalInfo(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          dateOfBirth: _selectedDate!,
          ssn: _ssnController.text.trim(),
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
      } finally {
        if (mounted) {
          safeSetState(() {
            _isUploading = false;
          });
        }
      }
    } else {
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields correctly'),
          backgroundColor: Colors.red,
        ),
      );
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
        child: _buildBodyContent(theme),
      ),
    );
  }

  Widget _buildBodyContent(ThemeData theme) {
    if (_isLoading) {
      return _buildLoadingView();
    } else if (_isUploading) {
      return _buildUploadingView();
    } else if (_hasActiveVerification) {
      return _buildActiveVerificationView(theme);
    } else {
      return _buildFormView(theme);
    }
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Checking verification status...',
            softWrap: true,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Uploading your information...\nPlease wait',
            softWrap: true,
            maxLines: 3,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: _buildVerificationForm(theme),
      ),
    );
  }

  Widget _buildVerificationForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Personal Information',
          description: 'To ensure a secure selling environment, please provide your personal details and ID verification.',
        ),
        const SizedBox(height: 20),
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
                _buildFormSection(
                  title: 'Personal Details',
                  children: [
                    _buildTextField(
                      label: 'First Name',
                      controller: _firstNameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'First name is required';
                        }
                        if (value.length < 2) {
                          return 'First name is too short';
                        }
                        if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value)) {
                          return 'First name should only contain letters';
                        }
                        return null;
                      },
                      icon: Icons.person_outline,
                    ),
                    _buildTextField(
                      label: 'Last Name',
                      controller: _lastNameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Last name is required';
                        }
                        if (value.length < 2) {
                          return 'Last name is too short';
                        }
                        if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value)) {
                          return 'Last name should only contain letters';
                        }
                        return null;
                      },
                      icon: Icons.person_outline,
                    ),
                    _buildTextField(
                      label: 'Phone Number',
                      controller: _phoneController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Phone number is required';
                        }
                        String cleanNumber = value.replaceAll(RegExp(r'[\s\(\)\-]'), '');
                        if (!RegExp(r'^(09|\+639)\d{9}$').hasMatch(cleanNumber) &&
                            !RegExp(r'^\d{10}$').hasMatch(cleanNumber)) {
                          return 'Enter a valid phone number';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.phone,
                      icon: Icons.phone,
                    ),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: _buildTextField(
                          label: 'Date of Birth',
                          controller: _dobController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Date of birth is required';
                            }
                            try {
                              final date = DateFormat('MM/dd/yyyy').parseStrict(value);
                              final now = DateTime.now();
                              final age = now.year -
                                  date.year -
                                  ((now.month > date.month ||
                                          (now.month == date.month && now.day >= date.day))
                                      ? 0
                                      : 1);
                              if (age < 18) {
                                return 'You must be at least 18 years old';
                              }
                              if (age > 100) {
                                return 'Please enter a valid date of birth';
                              }
                            } catch (e) {
                              return 'Please enter a valid date (MM/DD/YYYY)';
                            }
                            return null;
                          },
                          keyboardType: TextInputType.datetime,
                          icon: Icons.calendar_today,
                          hintText: 'MM/DD/YYYY',
                        ),
                      ),
                    ),
                    _buildTextField(
                      label: 'Last 4 digits of SSS',
                      controller: _ssnController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'SSS last 4 digits are required';
                        }
                        if (!RegExp(r'^\d{4}$').hasMatch(value)) {
                          return 'Enter exactly 4 digits';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.number,
                      icon: Icons.security,
                      obscureText: true,
                      maxLength: 4,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildFormSection(
                  title: 'ID Verification',
                  description: 'Please provide clear images of the front and back of your government-issued ID',
                  children: [
                    _buildImageUploader(
                      label: 'Front of ID',
                      image: _frontIdImage,
                      onTap: () => _pickImage(true),
                    ),
                    _buildImageUploader(
                      label: 'Back of ID',
                      image: _backIdImage,
                      onTap: () => _pickImage(false),
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
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({required String title, String? description}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        if (description != null) ...[
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.grey[600],
            ),
            softWrap: true,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildFormSection({
    required String title,
    String? description,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        if (description != null) ...[
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            softWrap: true,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 20),
        ...children.expand((child) => [child, const SizedBox(height: 16)]).toList()..removeLast(),
      ],
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
          const SizedBox(height: 24),
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
                _buildStatusRow(
                  icon: statusIcon,
                  iconColor: statusColor,
                  iconBackgroundColor: statusColor.withOpacity(0.2),
                  title: 'Status',
                  subtitle: _verificationStatus?.toUpperCase() ?? 'UNKNOWN',
                  subtitleColor: statusColor,
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                _buildStatusRow(
                  icon: Icons.calendar_today,
                  iconColor: Colors.grey,
                  title: 'Submitted on',
                  subtitle: formattedDate,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            statusMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You cannot submit a new verification request until this one is processed.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
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

  Widget _buildStatusRow({
    required IconData icon,
    required Color iconColor,
    Color? iconBackgroundColor,
    required String title,
    required String subtitle,
    Color? subtitleColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBackgroundColor ?? Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ),
      ],
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
        Row(
          children: [
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(required)',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            counterText: '',
          ),
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
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
    final bool isValid = image != null;
    final Color borderColor = isValid ? Colors.green : Colors.grey.shade300;
    final Color bgColor = isValid ? Colors.green.withOpacity(0.05) : Colors.grey.shade100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(required)',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.18,
            width: double.infinity,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: isValid ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                if (image == null)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 36,
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
                        const SizedBox(height: 4),
                        Text(
                          'Must be clear and complete',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.file(
                      image,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (image != null)
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
                if (isValid)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (!isValid)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Valid government ID required',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.red.shade400,
              ),
            ),
          ),
      ],
    );
  }
}