import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:haul/providers/seller_registration_provider.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class SellerVerificationScreen extends StatefulWidget {
  final String businessName;
  
  const SellerVerificationScreen({
    Key? key, 
    required this.businessName
  }) : super(key: key);

  @override
  State<SellerVerificationScreen> createState() => _SellerVerificationScreenState();
}

class _SellerVerificationScreenState extends State<SellerVerificationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final String _applicationId = 'APP${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  final DateTime _estimatedApprovalDate = DateTime.now().add(const Duration(days: 2));
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _launchHelpCenter() async {
    final Uri url = Uri.parse('https://haul.app/help/seller-verification');
    if (!await launchUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open help center')),
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
          'Verification',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Success animation
                SizedBox(
                  height: 180,
                  child: Lottie.asset(
                    'assets/animations/success.json',
                    controller: _animationController,
                    repeat: false,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Application ID card
                _buildApplicationCard(theme),
                const SizedBox(height: 24),

                // Main content
                Text(
                  'Application Received',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Thank you for registering ${widget.businessName} as a seller on Haul.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Timeline steps
                _buildTimelineSteps(theme),
                const SizedBox(height: 32),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _launchHelpCenter,
                        icon: const Icon(Icons.help_outline),
                        label: const Text('Help Center'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Return to Home',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildApplicationCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Application ID',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                'Submitted on',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _applicationId,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                DateFormat('MMM dd, yyyy').format(DateTime.now()),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                'Est. Approval',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Under Review',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
              Text(
                DateFormat('MMM dd, yyyy').format(_estimatedApprovalDate),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimelineSteps(ThemeData theme) {
    return Column(
      children: [
        _buildTimelineStep(
          icon: Icons.assignment_turned_in,
          title: 'Application Submitted',
          description: 'We\'ve received your seller application',
          isCompleted: true,
          isLast: false,
          theme: theme,
        ),
        _buildTimelineStep(
          icon: Icons.verified_user,
          title: 'Verification in Progress',
          description: 'Our team is reviewing your information',
          isCompleted: false,
          isLast: false,
          theme: theme,
        ),
        _buildTimelineStep(
          icon: Icons.store,
          title: 'Start Selling',
          description: 'Once approved, you can list your products',
          isCompleted: false,
          isLast: true,
          theme: theme,
        ),
      ],
    );
  }
  
  Widget _buildTimelineStep({
    required IconData icon,
    required String title,
    required String description,
    required bool isCompleted,
    required bool isLast,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? theme.primaryColor : Colors.grey.shade300,
              ),
              child: Icon(
                icon,
                color: isCompleted ? Colors.white : Colors.grey.shade500,
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? theme.primaryColor : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: isLast ? 0 : 24),
            ],
          ),
        ),
      ],
    );
  }
}