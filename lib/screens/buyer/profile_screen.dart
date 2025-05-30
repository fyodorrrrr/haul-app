import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:haul/screens/buyer/help_center_screen.dart';
import 'package:haul/screens/buyer/notification_preferences_screen.dart';
import 'package:haul/screens/buyer/payment_methods_screen.dart';
import 'package:haul/screens/buyer/privacy_settings_screen.dart';
import 'package:haul/screens/buyer/return_status_screen.dart';
import 'package:haul/screens/buyer/start_return_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '/providers/user_profile_provider.dart';
import '/providers/seller_registration_provider.dart';
import 'welcome_screen.dart';
import '/widgets/loading_screen.dart';
import '/models/user_profile_model.dart';
import '/screens/buyer/edit_profile_screen.dart';
import '/screens/buyer/change_password_screen.dart';
import '/screens/seller/seller_registration_screen.dart';
import '/screens/seller/seller_verification_screen.dart';
import '/screens/buyer/saved_addresses_screen.dart';
import '/screens/seller/seller_dashboard_screen.dart';
import '/screens/buyer/order_history.dart';
import '/screens/buyer/package_tracking_screen.dart';
import '/screens/buyer/notification_preferences_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile userProfile;

  ProfileScreen({required this.userProfile});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isSellerApproved = false;
  
  @override
  void initState() {
    super.initState();
    _checkSellerStatus();
    // Fetch user profile when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProfileProvider>().fetchUserProfile();
    });
  }
  
  Future<void> _checkSellerStatus() async {
    try {
      final provider = Provider.of<SellerRegistrationProvider>(context, listen: false);
      final isApproved = await provider.isSellerApproved();
      
      if (mounted) {
        setState(() {
          isSellerApproved = isApproved;
        });
      }
    } catch (e) {
      print('Error checking seller status: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
              child: Text(
                'Profile',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Profile Header
            _buildProfileHeader(context, widget.userProfile),
            
            const SizedBox(height: 24),
            
            // Account Section
            _buildSectionHeader('Account'),
            _buildMenuItem(
              icon: Icons.person, 
              title: 'Personal Information',
              onTap: () => _showPersonalInfo(context, widget.userProfile),
            ),
            _buildMenuItem(
              icon: Icons.lock_outline, 
              title: 'Change Password',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              ),
            ),
            _buildMenuItem(
              icon: Icons.location_on_outlined, 
              title: 'Saved Addresses',
              onTap: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const SavedAddressesScreen())
              ),
            ),
            _buildMenuItem(
              icon: Icons.payment, 
              title: 'Payment Methods',
              subtitle: 'Manage your payment options',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PaymentMethodsScreen()),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Orders Section
            _buildSectionHeader('Orders'),
            _buildMenuItem(
              icon: Icons.shopping_bag_outlined, 
              title: 'Order History',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.local_shipping_outlined, 
              title: 'Track Package',
              subtitle: 'Monitor your order deliveries',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PackageTrackingScreen()),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.undo, 
              title: 'Returns',
              subtitle: 'Return policy and requests',
              onTap: () {
                _showReturnsBottomSheet(context);
              },
            ),
            
            const SizedBox(height: 16),
            
            // Settings Section
            _buildSectionHeader('Settings'),
            _buildMenuItem(
              icon: Icons.notifications_outlined, 
              title: 'Notification Preferences',
              subtitle: 'Manage how you receive updates',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => NotificationPreferencesScreen()),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.lock_outline, 
              title: 'Privacy Settings',
              subtitle: 'Control your data and privacy',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PrivacySettingsScreen()),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.help_outline, 
              title: 'Help Center',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => HelpCenterScreen()),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Seller Section
            _buildSectionHeader('Seller'),
            _buildMenuItem(
              icon: Icons.store,
              title: isSellerApproved ? 'Seller Dashboard' : 'Become a Seller',
              subtitle: isSellerApproved 
                ? 'Manage your products and orders'
                : 'Start selling on Haul today',
              onTap: () async {
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const Center(child: CircularProgressIndicator());
                  },
                );
                
                try {
                  // Get the provider and check seller status
                  final provider = Provider.of<SellerRegistrationProvider>(context, listen: false);
                  final isApproved = await provider.isSellerApproved();
                  final verificationDetails = await provider.getVerificationStatus();
                  
                  // Close loading dialog
                  Navigator.pop(context);
                  
                  if (isApproved) {
                    // Seller is approved - go to seller dashboard
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SellerDashboardScreen(),
                      ),
                    );
                  } else if (verificationDetails['hasActiveVerification'] == true) {
                    // Verification pending - go to verification status screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SellerVerificationScreen(
                          businessName: verificationDetails['businessName'] ?? "Your Business",
                        ),
                      ),
                    );
                  } else {
                    // No active verification - go to seller registration
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SellerRegistrationPage(),
                      ),
                    );
                  }
                } catch (e) {
                  // Close loading dialog
                  Navigator.pop(context);
                  
                  // Show error
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error checking seller status: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            
            const SizedBox(height: 24),
            
            // Logout Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 24),
              child: OutlinedButton(
                onPressed: () => _logout(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Logout',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Logout function  
  Future<void> _logout(BuildContext context) async {
    LoadingScreen.show(context);
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    } catch (e) {
      LoadingScreen.hide(context); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error logging out: ${e.toString()}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Widget _buildProfileHeader(BuildContext context, UserProfile profile) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          // Profile Image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              shape: BoxShape.circle,
              image: profile.photoUrl != null && profile.photoUrl!.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(profile.photoUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
            ),
            child: profile.photoUrl == null || profile.photoUrl!.isEmpty
                ? Center(
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.grey.shade600,
                    ),
                  )
                : null,
          ),
          
          const SizedBox(width: 16),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName.isNotEmpty ? profile.fullName : 'Guest User',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // Edit Button
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              // Handle edit profile
              _showEditProfile(context, profile);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  Widget _buildMenuItem({required IconData icon, required String title, String? subtitle, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.black, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              )
            : null,
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  // Show user's personal information
  void _showPersonalInfo(BuildContext context, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildInfoRow('Full Name', profile.fullName),
            _buildInfoRow('Email', profile.email),
            _buildInfoRow('Phone', profile.phone),
            _buildInfoRow('Gender', profile.gender),
            if (profile.birthDate != null)
              _buildInfoRow('Birth Date', DateFormat('MMMM d, yyyy').format(profile.birthDate!)),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Close',
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
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isNotEmpty ? value : 'Not provided',
            style: GoogleFonts.poppins(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  // Edit profile dialog
  void _showEditProfile(BuildContext context, UserProfile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(userProfile: profile),
      ),
    ).then((updated) {
      if (updated == true) {
        // Refresh user profile data after successful update
        context.read<UserProfileProvider>().fetchUserProfile();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  // Returns bottom sheet
  void _showReturnsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Returns & Refunds',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    'Start Return',
                    Icons.keyboard_return,
                    Colors.blue,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => StartReturnScreen()),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    'Return Status',
                    Icons.track_changes,
                    Colors.green,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ReturnStatusScreen()),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Return Policy
            Text(
              'Return Policy',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPolicyItem(
                      '30-Day Return Window',
                      'Items can be returned within 30 days of delivery',
                      Icons.schedule,
                    ),
                    _buildPolicyItem(
                      'Original Condition',
                      'Items must be in original, unused condition with tags',
                      Icons.check_circle_outline,
                    ),
                    _buildPolicyItem(
                      'Free Return Shipping',
                      'We provide prepaid return labels for most items',
                      Icons.local_shipping,
                    ),
                    _buildPolicyItem(
                      'Quick Refunds',
                      'Refunds processed within 3-5 business days',
                      Icons.monetization_on,
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => StartReturnScreen()),
                      );
                    },
                    child: Text('Start Return'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyItem(String title, String description, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue, size: 20),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
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

class ProfileScreenWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileProvider>(
      builder: (context, provider, child) {
        return provider.userProfile != null
            ? ProfileScreen(userProfile: provider.userProfile!)
            : const Center(child: CircularProgressIndicator());
      },
    );
  }
}