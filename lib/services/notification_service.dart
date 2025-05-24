import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings);

    // Request permissions
    await _messaging.requestPermission();

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Handling background message: ${message.messageId}');
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Handling foreground message: ${message.messageId}');
    
    // Check user preferences before showing notification
    final shouldShow = await _shouldShowNotification(message.data['category']);
    
    if (shouldShow) {
      await _showLocalNotification(message);
    }
  }

  static Future<bool> _shouldShowNotification(String? category) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('preferences')
          .doc('notifications')
          .get();

      if (!doc.exists) return true; // Default to show if no preferences

      final prefs = doc.data()!;
      
      // Check if push notifications are enabled
      if (prefs['pushNotifications'] != true) return false;

      // Check quiet hours
      if (prefs['quietHoursEnabled'] == true) {
        final now = DateTime.now();
        final startTime = prefs['quietHoursStart'] ?? '22:00';
        final endTime = prefs['quietHoursEnd'] ?? '08:00';
        
        if (_isInQuietHours(now, startTime, endTime)) {
          return false;
        }
      }

      // Check category preferences
      switch (category) {
        case 'order':
          return prefs['orderUpdates'] ?? true;
        case 'promotion':
          return prefs['promotionalOffers'] ?? true;
        case 'new_product':
          return prefs['newProducts'] ?? true;
        case 'price_alert':
          return prefs['priceAlerts'] ?? true;
        case 'wishlist':
          return prefs['wishlistAlerts'] ?? true;
        case 'security':
          return prefs['securityAlerts'] ?? true;
        case 'seller':
          return prefs['sellerUpdates'] ?? false;
        case 'system':
          return prefs['systemAnnouncements'] ?? true;
        default:
          return true;
      }
    } catch (e) {
      print('Error checking notification preferences: $e');
      return true; // Default to show on error
    }
  }

  static bool _isInQuietHours(DateTime now, String startTime, String endTime) {
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);
    final current = TimeOfDay.fromDateTime(now);

    if (start.hour < end.hour) {
      // Same day quiet hours (e.g., 22:00 to 08:00 next day)
      return current.hour >= start.hour || current.hour < end.hour;
    } else {
      // Overnight quiet hours (e.g., 10:00 to 06:00)
      return current.hour >= start.hour && current.hour < end.hour;
    }
  }

  static TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'haul_notifications',
      'Haul Notifications',
      channelDescription: 'Notifications from Haul app',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      details,
    );
  }

  static Future<String?> getDeviceToken() async {
    return await _messaging.getToken();
  }
}