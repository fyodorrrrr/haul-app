import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({Key? key}) : super(key: key);

  @override
  _PrivacySettingsScreenState createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Privacy Settings
  bool _profileVisibility = true;
  bool _showPurchaseHistory = false;
  bool _allowReviewDisplay = true;
  bool _shareDataWithPartners = false;
  bool _personalizedAds = true;
  bool _activityTracking = true;
  bool _locationServices = false;
  bool _marketingEmails = true;
  bool _smsNotifications = false;
  bool _dataCollection = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('privacy_settings')
            .doc('preferences')
            .get();
        
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _profileVisibility = data['profileVisibility'] ?? true;
            _showPurchaseHistory = data['showPurchaseHistory'] ?? false;
            _allowReviewDisplay = data['allowReviewDisplay'] ?? true;
            _shareDataWithPartners = data['shareDataWithPartners'] ?? false;
            _personalizedAds = data['personalizedAds'] ?? true;
            _activityTracking = data['activityTracking'] ?? true;
            _locationServices = data['locationServices'] ?? false;
            _marketingEmails = data['marketingEmails'] ?? true;
            _smsNotifications = data['smsNotifications'] ?? false;
            _dataCollection = data['dataCollection'] ?? true;
          });
        }
      }
    } catch (e) {
      print('Error loading privacy settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePrivacySettings() async {
    setState(() => _isSaving = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('privacy_settings')
            .doc('preferences')
            .set({
          'profileVisibility': _profileVisibility,
          'showPurchaseHistory': _showPurchaseHistory,
          'allowReviewDisplay': _allowReviewDisplay,
          'shareDataWithPartners': _shareDataWithPartners,
          'personalizedAds': _personalizedAds,
          'activityTracking': _activityTracking,
          'locationServices': _locationServices,
          'marketingEmails': _marketingEmails,
          'smsNotifications': _smsNotifications,
          'dataCollection': _dataCollection,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Privacy settings saved successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Privacy Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _savePrivacySettings,
              child: _isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Save',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntroCard(),
                  SizedBox(height: 24),
                  _buildProfilePrivacySection(),
                  SizedBox(height: 24),
                  _buildDataPrivacySection(),
                  SizedBox(height: 24),
                  _buildCommunicationSection(),
                  SizedBox(height: 24),
                  _buildDataRightsSection(),
                  SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Colors.blue, size: 24),
              SizedBox(width: 8),
              Text(
                'Your Privacy Matters',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Control how your personal information is used and shared. These settings help protect your privacy while using Haul.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePrivacySection() {
    return _buildSection(
      'Profile Privacy',
      'Control who can see your profile information',
      [
        _buildToggleItem(
          'Public Profile',
          'Allow others to view your profile',
          _profileVisibility,
          (value) => setState(() => _profileVisibility = value),
          Icons.person,
        ),
        _buildToggleItem(
          'Purchase History',
          'Show your purchase history on profile',
          _showPurchaseHistory,
          (value) => setState(() => _showPurchaseHistory = value),
          Icons.shopping_bag,
        ),
        _buildToggleItem(
          'Display Reviews',
          'Allow your reviews to be shown publicly',
          _allowReviewDisplay,
          (value) => setState(() => _allowReviewDisplay = value),
          Icons.star,
        ),
      ],
    );
  }

  Widget _buildDataPrivacySection() {
    return _buildSection(
      'Data & Analytics',
      'Manage how your data is collected and used',
      [
        _buildToggleItem(
          'Personalized Ads',
          'Show ads based on your interests',
          _personalizedAds,
          (value) => setState(() => _personalizedAds = value),
          Icons.ads_click,
        ),
        _buildToggleItem(
          'Activity Tracking',
          'Track your app usage for improvements',
          _activityTracking,
          (value) => setState(() => _activityTracking = value),
          Icons.analytics,
        ),
        _buildToggleItem(
          'Location Services',
          'Use location for better recommendations',
          _locationServices,
          (value) => setState(() => _locationServices = value),
          Icons.location_on,
        ),
        _buildToggleItem(
          'Share with Partners',
          'Share anonymous data with trusted partners',
          _shareDataWithPartners,
          (value) => setState(() => _shareDataWithPartners = value),
          Icons.share,
        ),
      ],
    );
  }

  Widget _buildCommunicationSection() {
    return _buildSection(
      'Communication Preferences',
      'Choose how we can contact you',
      [
        _buildToggleItem(
          'Marketing Emails',
          'Receive promotional emails and offers',
          _marketingEmails,
          (value) => setState(() => _marketingEmails = value),
          Icons.email,
        ),
        _buildToggleItem(
          'SMS Notifications',
          'Receive text messages for important updates',
          _smsNotifications,
          (value) => setState(() => _smsNotifications = value),
          Icons.sms,
        ),
      ],
    );
  }

  Widget _buildDataRightsSection() {
    return _buildSection(
      'Your Data Rights',
      'Manage your personal data',
      [
        _buildActionItem(
          'Download Your Data',
          'Get a copy of all your personal data',
          Icons.download,
          () => _showDownloadDataDialog(),
        ),
        _buildActionItem(
          'Delete Account',
          'Permanently delete your account and data',
          Icons.delete_forever,
          () => _showDeleteAccountDialog(),
          isDestructive: true,
        ),
        _buildActionItem(
          'Privacy Policy',
          'Read our complete privacy policy',
          Icons.policy,
          () => _showPrivacyPolicy(),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String subtitle, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildToggleItem(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.grey[700]),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 0.5),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive ? Colors.red[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDestructive ? Colors.red[600] : Colors.grey[700],
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDestructive ? Colors.red[600] : null,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }

  void _showDownloadDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Download Your Data',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'We\'ll prepare a file containing all your personal data and send it to your email address. This may take up to 24 hours.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement data download functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Data download request submitted. Check your email in 24 hours.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Request Download'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Account',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.red[600],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action cannot be undone. Deleting your account will:',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            SizedBox(height: 12),
            Text('• Remove all your personal data', style: GoogleFonts.poppins(fontSize: 12)),
            Text('• Cancel all active orders', style: GoogleFonts.poppins(fontSize: 12)),
            Text('• Delete your purchase history', style: GoogleFonts.poppins(fontSize: 12)),
            Text('• Remove all reviews and ratings', style: GoogleFonts.poppins(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement account deletion
              _showDeleteConfirmationDialog();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    final TextEditingController confirmController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Final Confirmation',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Type "DELETE" to confirm account deletion:',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            SizedBox(height: 12),
            TextField(
              controller: confirmController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Type DELETE here',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (confirmController.text == 'DELETE') {
                Navigator.pop(context);
                // Implement actual account deletion
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Account deletion process initiated. You will be logged out.'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please type "DELETE" exactly as shown'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Confirm Delete'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  '''
Haul Privacy Policy

Last updated: ${DateFormat('MMMM d, yyyy').format(DateTime.now())}

1. INFORMATION WE COLLECT
We collect information you provide directly, such as when you create an account, make purchases, or contact us.

2. HOW WE USE YOUR INFORMATION
- To provide and improve our services
- To process transactions
- To send you updates and marketing communications
- To ensure platform security

3. INFORMATION SHARING
We do not sell your personal information. We may share information with:
- Service providers who help us operate
- When required by law
- With your consent

4. DATA SECURITY
We implement appropriate technical and organizational measures to protect your information.

5. YOUR RIGHTS
You have the right to:
- Access your personal data
- Correct inaccurate information
- Delete your account
- Opt out of marketing communications

6. CONTACT US
If you have questions about this privacy policy, contact us at privacy@haul.com
                  ''',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}