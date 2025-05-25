import 'package:flutter/material.dart';

class HelpCategory {
  final String title;
  final IconData icon;
  final List<HelpItem> items;

  HelpCategory({
    required this.title,
    required this.icon,
    required this.items,
  });
}

class HelpItem {
  final String title;
  final String content;
  final List<String> steps;

  HelpItem({
    required this.title,
    required this.content,
    this.steps = const [],
  });
}

// Help Content Data
final List<HelpCategory> _helpCategories = [
  HelpCategory(
    title: 'Getting Started',
    icon: Icons.rocket_launch,
    items: [
      HelpItem(
        title: 'How to create an account',
        content: 'Welcome to Haul! Creating an account is quick and easy. You can sign up using your email address or social media accounts.',
        steps: [
          'Open the Haul app',
          'Tap "Sign Up" on the welcome screen',
          'Choose your preferred sign-up method (email or social)',
          'Fill in your basic information',
          'Verify your email address',
          'Complete your profile setup',
        ],
      ),
      HelpItem(
        title: 'Setting up your profile',
        content: 'A complete profile helps sellers and other users know more about you. Add your photo, contact information, and preferences.',
        steps: [
          'Go to your Profile tab',
          'Tap the edit icon next to your name',
          'Add your profile photo',
          'Fill in your personal information',
          'Set your location and preferences',
          'Save your changes',
        ],
      ),
      HelpItem(
        title: 'Understanding Haul basics',
        content: 'Haul is a marketplace where you can buy and sell items locally and globally. Learn about our key features and how to navigate the app.',
      ),
    ],
  ),
  
  HelpCategory(
    title: 'Buying & Orders',
    icon: Icons.shopping_cart,
    items: [
      HelpItem(
        title: 'How to place an order',
        content: 'Placing an order on Haul is simple. Browse products, add them to your cart, and checkout securely.',
        steps: [
          'Browse or search for products',
          'Tap on a product to view details',
          'Select quantity and options',
          'Add to cart',
          'Review your cart',
          'Proceed to checkout',
          'Enter shipping and payment information',
          'Confirm your order',
        ],
      ),
      HelpItem(
        title: 'Payment methods',
        content: 'We accept various payment methods including credit/debit cards, PayPal, digital wallets, and cash on delivery.',
      ),
      HelpItem(
        title: 'Order tracking',
        content: 'Track your orders in real-time from purchase to delivery. Get updates via notifications and email.',
        steps: [
          'Go to "Order History" in your profile',
          'Select the order you want to track',
          'View detailed tracking information',
          'Get real-time updates on delivery status',
        ],
      ),
      HelpItem(
        title: 'Returns and refunds',
        content: 'If you\'re not satisfied with your purchase, you can return items within 30 days for a full refund.',
        steps: [
          'Go to your Order History',
          'Select the item you want to return',
          'Tap "Request Return"',
          'Fill out the return form',
          'Package the item securely',
          'Ship using the provided return label',
          'Receive your refund within 5-7 business days',
        ],
      ),
    ],
  ),
  
  HelpCategory(
    title: 'Selling',
    icon: Icons.store,
    items: [
      HelpItem(
        title: 'How to become a seller',
        content: 'Start selling on Haul today! The process is straightforward and you can be up and running quickly.',
        steps: [
          'Go to your Profile',
          'Tap "Become a Seller"',
          'Complete the seller registration form',
          'Verify your business information',
          'Set up your payment methods',
          'Create your first product listing',
        ],
      ),
      HelpItem(
        title: 'Creating product listings',
        content: 'Create compelling product listings with high-quality photos and detailed descriptions to attract buyers.',
        steps: [
          'Go to your Seller Dashboard',
          'Tap "Add Product"',
          'Upload product photos',
          'Write a detailed title and description',
          'Set your price and inventory',
          'Choose categories and tags',
          'Publish your listing',
        ],
      ),
      HelpItem(
        title: 'Managing orders',
        content: 'Keep track of your sales, process orders quickly, and maintain good seller ratings.',
      ),
      HelpItem(
        title: 'Seller verification',
        content: 'Verified sellers get better visibility and buyer trust. Complete your verification process to unlock more features.',
      ),
    ],
  ),
  
  HelpCategory(
    title: 'Account & Security',
    icon: Icons.security,
    items: [
      HelpItem(
        title: 'Changing your password',
        content: 'Keep your account secure by using a strong password and changing it regularly.',
        steps: [
          'Go to your Profile',
          'Tap "Change Password"',
          'Enter your current password',
          'Create a new strong password',
          'Confirm your new password',
          'Save changes',
        ],
      ),
      HelpItem(
        title: 'Managing addresses',
        content: 'Save multiple addresses for faster checkout. Set a default address for convenience.',
        steps: [
          'Go to "Saved Addresses" in your profile',
          'Tap "Add New Address"',
          'Fill in the address details',
          'Set as default if needed',
          'Save the address',
        ],
      ),
      HelpItem(
        title: 'Payment methods',
        content: 'Add and manage your payment methods securely. All payment information is encrypted.',
      ),
      HelpItem(
        title: 'Privacy settings',
        content: 'Control what information is visible to other users and how we use your data.',
      ),
    ],
  ),
  
  HelpCategory(
    title: 'App Features',
    icon: Icons.apps,
    items: [
      HelpItem(
        title: 'Notifications',
        content: 'Customize your notification preferences to stay updated on what matters to you.',
        steps: [
          'Go to "Notification Preferences" in your profile',
          'Toggle different notification types',
          'Set quiet hours if needed',
          'Save your preferences',
        ],
      ),
      HelpItem(
        title: 'Search and filters',
        content: 'Find exactly what you\'re looking for using our advanced search and filter options.',
      ),
      HelpItem(
        title: 'Wishlist',
        content: 'Save items you\'re interested in to your wishlist for later purchase.',
      ),
      HelpItem(
        title: 'Reviews and ratings',
        content: 'Leave reviews for products and sellers to help other users make informed decisions.',
      ),
    ],
  ),
  
  HelpCategory(
    title: 'Troubleshooting',
    icon: Icons.build,
    items: [
      HelpItem(
        title: 'App not loading',
        content: 'If the app is not loading properly, try these troubleshooting steps.',
        steps: [
          'Check your internet connection',
          'Close and restart the app',
          'Clear the app cache',
          'Update to the latest version',
          'Restart your device',
          'Contact support if issue persists',
        ],
      ),
      HelpItem(
        title: 'Payment issues',
        content: 'Having trouble with payments? Here are common solutions.',
        steps: [
          'Check your payment method details',
          'Ensure sufficient funds/credit',
          'Try a different payment method',
          'Clear browser cache if using web',
          'Contact your bank if needed',
          'Reach out to our support team',
        ],
      ),
      HelpItem(
        title: 'Login problems',
        content: 'Can\'t log into your account? Follow these steps to regain access.',
        steps: [
          'Check your email and password',
          'Try "Forgot Password" option',
          'Check your email for reset link',
          'Clear app data and try again',
          'Ensure your account isn\'t suspended',
          'Contact support for help',
        ],
      ),
    ],
  ),
];

// All help items for search
final List<HelpItem> _helpItems = _helpCategories
    .expand((category) => category.items)
    .toList();