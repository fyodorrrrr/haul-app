import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  @override
  _NotificationPreferencesScreenState createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  // Notification preference states
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  
  // Category preferences
  bool _orderUpdates = true;
  bool _promotionalOffers = true;
  bool _newProducts = true;
  bool _priceAlerts = true;
  bool _wishlistAlerts = true;
  bool _securityAlerts = true;
  bool _sellerUpdates = false;
  bool _systemAnnouncements = true;
  
  // Timing preferences
  String _quietHoursStart = '22:00';
  String _quietHoursEnd = '08:00';
  bool _quietHoursEnabled = false;
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('preferences')
            .doc('notifications')
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            // General preferences
            _pushNotifications = data['pushNotifications'] ?? true;
            _emailNotifications = data['emailNotifications'] ?? true;
            _smsNotifications = data['smsNotifications'] ?? false;
            
            // Category preferences
            _orderUpdates = data['orderUpdates'] ?? true;
            _promotionalOffers = data['promotionalOffers'] ?? true;
            _newProducts = data['newProducts'] ?? true;
            _priceAlerts = data['priceAlerts'] ?? true;
            _wishlistAlerts = data['wishlistAlerts'] ?? true;
            _securityAlerts = data['securityAlerts'] ?? true;
            _sellerUpdates = data['sellerUpdates'] ?? false;
            _systemAnnouncements = data['systemAnnouncements'] ?? true;
            
            // Timing preferences
            _quietHoursStart = data['quietHoursStart'] ?? '22:00';
            _quietHoursEnd = data['quietHoursEnd'] ?? '08:00';
            _quietHoursEnabled = data['quietHoursEnabled'] ?? false;
            
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading notification preferences: $e');
    }
  }

  Future<void> _saveNotificationPreferences() async {
    // ✅ Check if widget is still mounted before starting
    if (!mounted) return;
    
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final preferences = {
        // General preferences
        'pushNotifications': _pushNotifications,
        'emailNotifications': _emailNotifications,
        'smsNotifications': _smsNotifications,
        
        // Category preferences
        'orderUpdates': _orderUpdates,
        'promotionalOffers': _promotionalOffers,
        'newProducts': _newProducts,
        'priceAlerts': _priceAlerts,
        'wishlistAlerts': _wishlistAlerts,
        'securityAlerts': _securityAlerts,
        'sellerUpdates': _sellerUpdates,
        'systemAnnouncements': _systemAnnouncements,
        
        // Timing preferences
        'quietHoursStart': _quietHoursStart,
        'quietHoursEnd': _quietHoursEnd,
        'quietHoursEnabled': _quietHoursEnabled,
        
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('preferences')
          .doc('notifications')
          .set(preferences, SetOptions(merge: true));

      // Handle push notification permissions
      if (_pushNotifications) {
        await _requestNotificationPermission();
      }

      // ✅ Check mounted before showing success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Notification has been saved!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
        
        // ✅ No automatic navigation - user can tap back button when ready
      }

    } catch (e) {
      print('❌ Error saving preferences: $e');
      
      // ✅ Check mounted before showing error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Error saving preferences: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      // ✅ Check mounted before updating state
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ User granted notification permission');
        
        // Get FCM token and save it
        final token = await messaging.getToken();
        if (token != null && mounted) {
          await _saveFCMToken(token);
        }
      } else {
        print('❌ User declined or has not accepted permission');
        
        // ✅ Show user-friendly message about permissions
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Push notifications disabled. You can enable them in device settings.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error requesting notification permission: $e');
    }
  }

  Future<void> _saveFCMToken(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || !mounted) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'fcmToken': token,
        'fcmTokenUpdated': FieldValue.serverTimestamp(),
      });

      print('✅ FCM token saved successfully');
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  @override
  void dispose() {
    // ✅ Clean up any ongoing operations
    print('🗑️ NotificationPreferencesScreen disposing');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notification Preferences',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () async {
              // ✅ Add haptic feedback
              HapticFeedback.lightImpact();
              await _saveNotificationPreferences();
            },
            child: _isSaving
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Saving...',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Save',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
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
                  _buildSectionHeader('General Settings'),
                  _buildSwitchTile(
                    title: 'Push Notifications',
                    subtitle: 'Receive notifications on your device',
                    value: _pushNotifications,
                    onChanged: (value) => setState(() => _pushNotifications = value),
                  ),
                  _buildSwitchTile(
                    title: 'Email Notifications',
                    subtitle: 'Receive notifications via email',
                    value: _emailNotifications,
                    onChanged: (value) => setState(() => _emailNotifications = value),
                  ),
                  _buildSwitchTile(
                    title: 'SMS Notifications',
                    subtitle: 'Receive important updates via SMS',
                    value: _smsNotifications,
                    onChanged: (value) => setState(() => _smsNotifications = value),
                  ),

                  SizedBox(height: 24),

                  _buildSectionHeader('Notification Categories'),
                  _buildSwitchTile(
                    title: 'Order Updates',
                    subtitle: 'Status changes, delivery updates, etc.',
                    value: _orderUpdates,
                    onChanged: (value) => setState(() => _orderUpdates = value),
                    icon: Icons.shopping_bag_outlined,
                  ),
                  _buildSwitchTile(
                    title: 'Promotional Offers',
                    subtitle: 'Discounts, sales, and special deals',
                    value: _promotionalOffers,
                    onChanged: (value) => setState(() => _promotionalOffers = value),
                    icon: Icons.local_offer_outlined,
                  ),
                  _buildSwitchTile(
                    title: 'New Products',
                    subtitle: 'Latest arrivals and product launches',
                    value: _newProducts,
                    onChanged: (value) => setState(() => _newProducts = value),
                    icon: Icons.new_releases_outlined,
                  ),
                  _buildSwitchTile(
                    title: 'Price Alerts',
                    subtitle: 'Price drops on your wishlist items',
                    value: _priceAlerts,
                    onChanged: (value) => setState(() => _priceAlerts = value),
                    icon: Icons.trending_down,
                  ),
                  _buildSwitchTile(
                    title: 'Wishlist Alerts',
                    subtitle: 'Stock updates for wishlist items',
                    value: _wishlistAlerts,
                    onChanged: (value) => setState(() => _wishlistAlerts = value),
                    icon: Icons.favorite_outline,
                  ),
                  _buildSwitchTile(
                    title: 'Security Alerts',
                    subtitle: 'Login attempts and security updates',
                    value: _securityAlerts,
                    onChanged: (value) => setState(() => _securityAlerts = value),
                    icon: Icons.security,
                  ),
                  _buildSwitchTile(
                    title: 'Seller Updates',
                    subtitle: 'Updates from your followed sellers',
                    value: _sellerUpdates,
                    onChanged: (value) => setState(() => _sellerUpdates = value),
                    icon: Icons.store_outlined,
                  ),
                  _buildSwitchTile(
                    title: 'System Announcements',
                    subtitle: 'App updates and maintenance notices',
                    value: _systemAnnouncements,
                    onChanged: (value) => setState(() => _systemAnnouncements = value),
                    icon: Icons.announcement_outlined,
                  ),

                  SizedBox(height: 24),

                  _buildSectionHeader('Quiet Hours'),
                  _buildSwitchTile(
                    title: 'Enable Quiet Hours',
                    subtitle: 'No notifications during specified hours',
                    value: _quietHoursEnabled,
                    onChanged: (value) => setState(() => _quietHoursEnabled = value),
                    icon: Icons.bedtime_outlined,
                  ),

                  if (_quietHoursEnabled) ...[
                    SizedBox(height: 16),
                    _buildTimePicker(
                      title: 'Start Time',
                      time: _quietHoursStart,
                      onTimeChanged: (time) => setState(() => _quietHoursStart = time),
                    ),
                    SizedBox(height: 8),
                    _buildTimePicker(
                      title: 'End Time',
                      time: _quietHoursEnd,
                      onTimeChanged: (time) => setState(() => _quietHoursEnd = time),
                    ),
                  ],

                  // SizedBox(height: 32),

                  // _buildTestNotificationButton(),

                  // SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    IconData? icon,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: Colors.grey[600]),
              SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.black,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildTimePicker({
    required String title,
    required String time,
    required ValueChanged<String> onTimeChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: () async {
              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: int.parse(time.split(':')[0]),
                  minute: int.parse(time.split(':')[1]),
                ),
              );
              if (picked != null) {
                final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                onTimeChanged(formattedTime);
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                time,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildTestNotificationButton() {
  //   return Container(
  //     width: double.infinity,
  //     child: OutlinedButton.icon(
  //       onPressed: _sendTestNotification,
  //       icon: Icon(Icons.notifications_outlined),
  //       label: Text('Send Test Notification'),
  //       style: OutlinedButton.styleFrom(
  //         padding: EdgeInsets.symmetric(vertical: 16),
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(8),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Future<void> _sendTestNotification() async {
    if (_pushNotifications) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔔 Test notification sent!'),
          backgroundColor: Colors.blue,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enable push notifications to receive test notification'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}