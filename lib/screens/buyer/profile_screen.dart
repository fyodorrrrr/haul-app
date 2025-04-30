import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'welcome_screen.dart';
import '/widgets/loading_screen.dart';
import '/models/user_profile_model.dart';
import '/screens/buyer/edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  
  const ProfileScreen({
    Key? key, 
    this.userData = const {},
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Convert Map to UserProfile model
    UserProfile userProfile = _getUserProfile();
    
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
            _buildProfileHeader(context, userProfile),
            
            const SizedBox(height: 24),
            
            // Account Section
            _buildSectionHeader('Account'),
            _buildMenuItem(
              Icons.person, 
              'Personal Information',
              onTap: () => _showPersonalInfo(context, userProfile),
            ),
            _buildMenuItem(Icons.location_on_outlined, 'Saved Addresses'),
            _buildMenuItem(Icons.payment, 'Payment Methods'),
            
            const SizedBox(height: 16),
            
            // Orders Section
            _buildSectionHeader('Orders'),
            _buildMenuItem(Icons.shopping_bag_outlined, 'Order History'),
            _buildMenuItem(Icons.local_shipping_outlined, 'Track Package'),
            _buildMenuItem(Icons.undo, 'Returns'),
            
            const SizedBox(height: 16),
            
            // Settings Section
            _buildSectionHeader('Settings'),
            _buildMenuItem(Icons.notifications_outlined, 'Notification Preferences'),
            _buildMenuItem(Icons.lock_outline, 'Privacy Settings'),
            _buildMenuItem(Icons.help_outline, 'Help Center'),
            
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
  
  // Convert Map data to UserProfile object
  UserProfile _getUserProfile() {
    try {
      return UserProfile.fromMap(userData);
    } catch (e) {
      // Fallback for if the map doesn't have all required fields
      return UserProfile(
        uid: userData['uid'] ?? '',
        email: userData['email'] ?? 'guest@example.com',
        fullName: userData['fullName'] ?? 'Guest User',
        gender: userData['gender'] ?? '',
        phone: userData['phone'] ?? '',
        role: userData['role'] ?? 'buyer',
        provider: userData['provider'] ?? 'email',
      );
    }
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
  
  Widget _buildMenuItem(IconData icon, String title, {VoidCallback? onTap}) {
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
    // Navigate to the edit profile screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(userProfile: profile),
      ),
    ).then((updated) {
      if (updated == true) {
        // Reload user profile data
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh profile data
        if (context.mounted) {
          // Refresh user data from Firestore
          // This depends on how you're managing your user data
          // Example: context.read<UserProvider>().refreshUserData();
        }
      }
    });
  }
}