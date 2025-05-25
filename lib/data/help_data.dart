import 'package:flutter/material.dart';
import '../models/help_models.dart';

final List<HelpCategory> helpCategories = [
  HelpCategory(
    title: 'Getting Started with Haul',
    icon: Icons.rocket_launch,
    items: [
      HelpItem(
        title: 'How to create your account',
        content: 'Welcome to Haul! Creating an account is quick and easy. You can sign up using your email address or continue as a guest to browse items.',
        steps: [
          'Open the Haul app',
          'Tap "Register" on the welcome screen',
          'Enter your email and create a password',
          'Fill in your basic information',
          'Verify your email address',
          'Complete your profile setup',
          'Start shopping for unique thrift finds!',
        ],
      ),
      HelpItem(
        title: 'Setting up your profile',
        content: 'A complete profile helps sellers and other users know more about you. Add your photo, contact information, and shopping preferences.',
        steps: [
          'Go to your Profile tab',
          'Tap the edit icon next to your name',
          'Add your profile photo',
          'Fill in your personal information',
          'Set your delivery addresses',
          'Add payment methods',
          'Save your changes',
        ],
      ),
      HelpItem(
        title: 'Understanding Haul marketplace',
        content: 'Haul is a marketplace where you can buy and sell unique thrift items, vintage finds, and pre-loved treasures. Discover how to navigate and make the most of our platform.',
      ),
      HelpItem(
        title: 'Exploring the app features',
        content: 'Learn about our key features including the swipe-to-discover Explore section, wishlist management, search filters, and notification preferences.',
      ),
    ],
  ),
  
  HelpCategory(
    title: 'Shopping & Orders',
    icon: Icons.shopping_bag_outlined,
    items: [
      HelpItem(
        title: 'How to place an order',
        content: 'Placing an order on Haul is simple and secure. Browse unique items, add them to your cart, and checkout with confidence.',
        steps: [
          'Browse products or use the Explore feature',
          'Tap on an item to view details',
          'Check size, condition, and seller info',
          'Add to cart or wishlist',
          'Review your cart items',
          'Proceed to checkout',
          'Select shipping address',
          'Choose payment method',
          'Confirm your order',
        ],
      ),
      HelpItem(
        title: 'Payment methods we accept',
        content: 'We accept various secure payment methods including credit/debit cards, PayPal, GCash, Maya, and cash on delivery for eligible locations.',
      ),
      HelpItem(
        title: 'Order tracking and updates',
        content: 'Track your orders in real-time from purchase to delivery. Get updates via push notifications, email, and in-app tracking.',
        steps: [
          'Go to "Order History" in your profile',
          'Select the order you want to track',
          'View detailed tracking information',
          'Get real-time updates on delivery status',
          'Contact seller if needed',
        ],
      ),
      HelpItem(
        title: 'Returns and refund policy',
        content: 'If you\'re not satisfied with your thrift purchase, you can return items within 7 days. Items must be in the same condition as received.',
        steps: [
          'Go to your Order History',
          'Select the item you want to return',
          'Tap "Request Return"',
          'Fill out the return reason form',
          'Package the item securely',
          'Ship using the provided return label',
          'Receive your refund within 5-7 business days',
        ],
      ),
    ],
  ),
  
  HelpCategory(
    title: 'Selling on Haul',
    icon: Icons.store_outlined,
    items: [
      HelpItem(
        title: 'Becoming a seller',
        content: 'Start your thrift selling journey on Haul! The process is straightforward and you can begin listing items quickly.',
        steps: [
          'Go to your Profile',
          'Tap "Become a Seller"',
          'Complete the seller registration form',
          'Verify your business information',
          'Set up your payment methods',
          'Read our seller guidelines',
          'Create your first product listing',
        ],
      ),
      HelpItem(
        title: 'Creating great product listings',
        content: 'Create compelling listings with high-quality photos and detailed descriptions to attract buyers to your thrift items.',
        steps: [
          'Go to your Seller Dashboard',
          'Tap "Add Product"',
          'Upload clear, well-lit photos (multiple angles)',
          'Write a detailed title and description',
          'Specify condition, size, and brand',
          'Set competitive pricing',
          'Choose appropriate categories and tags',
          'Publish your listing',
        ],
      ),
      HelpItem(
        title: 'Managing your inventory',
        content: 'Keep track of your thrift inventory, process orders quickly, and maintain good seller ratings to build trust with buyers.',
      ),
      HelpItem(
        title: 'Seller verification process',
        content: 'Verified sellers get better visibility and buyer trust. Complete your verification to unlock premium selling features.',
      ),
    ],
  ),
  
  HelpCategory(
    title: 'Account & Security',
    icon: Icons.security_outlined,
    items: [
      HelpItem(
        title: 'Changing your password',
        content: 'Keep your account secure by using a strong password and updating it regularly.',
        steps: [
          'Go to your Profile',
          'Tap "Change Password"',
          'Enter your current password',
          'Create a new strong password (8+ characters)',
          'Confirm your new password',
          'Save changes',
        ],
      ),
      HelpItem(
        title: 'Managing delivery addresses',
        content: 'Save multiple addresses for faster checkout. Perfect for sending thrift finds to different locations.',
        steps: [
          'Go to "Saved Addresses" in your profile',
          'Tap "Add New Address"',
          'Fill in complete address details',
          'Add special delivery instructions if needed',
          'Set as default if preferred',
          'Save the address',
        ],
      ),
      HelpItem(
        title: 'Payment method management',
        content: 'Add and manage your payment methods securely. All payment information is encrypted and protected.',
      ),
      HelpItem(
        title: 'Privacy and data settings',
        content: 'Control what information is visible to other users and how we use your data to improve your thrift shopping experience.',
      ),
    ],
  ),
  
  HelpCategory(
    title: 'App Features Guide',
    icon: Icons.apps_outlined,
    items: [
      HelpItem(
        title: 'Using the Explore feature',
        content: 'Discover unique thrift finds by swiping through our curated selection. Swipe right to add to wishlist, left to pass.',
        steps: [
          'Go to the Explore tab',
          'Swipe right on items you love',
          'Swipe left on items to pass',
          'Tap on items for detailed view',
          'Pull down to refresh for new finds',
          'Use the heart button for quick wishlist adds',
        ],
      ),
      HelpItem(
        title: 'Notification preferences',
        content: 'Customize your notification settings to stay updated on what matters to you most.',
        steps: [
          'Go to "Notification Preferences" in your profile',
          'Toggle different notification types',
          'Set quiet hours for peaceful evenings',
          'Choose notification categories',
          'Save your preferences',
        ],
      ),
      HelpItem(
        title: 'Search and filtering',
        content: 'Find exactly what you\'re looking for using our advanced search and filter options. Filter by size, brand, price, and condition.',
      ),
      HelpItem(
        title: 'Wishlist management',
        content: 'Save items you\'re interested in to your wishlist for later purchase. Get notified when prices drop or items go on sale.',
      ),
      HelpItem(
        title: 'Writing reviews and ratings',
        content: 'Leave honest reviews for products and sellers to help other thrift shoppers make informed decisions.',
      ),
    ],
  ),
  
  HelpCategory(
    title: 'Troubleshooting',
    icon: Icons.build_outlined,
    items: [
      HelpItem(
        title: 'App loading issues',
        content: 'If the app is not loading properly or running slowly, try these troubleshooting steps.',
        steps: [
          'Check your internet connection',
          'Close and restart the app completely',
          'Clear the app cache from device settings',
          'Update to the latest app version',
          'Restart your device',
          'Contact support if issue persists',
        ],
      ),
      HelpItem(
        title: 'Payment problems',
        content: 'Having trouble with payments during checkout? Here are common solutions to payment issues.',
        steps: [
          'Verify your payment method details',
          'Ensure sufficient funds or credit limit',
          'Try a different payment method',
          'Check if your card supports online transactions',
          'Clear browser cache if using web version',
          'Contact your bank if payment is declined',
          'Reach out to our support team for assistance',
        ],
      ),
      HelpItem(
        title: 'Login and access issues',
        content: 'Can\'t log into your account? Follow these steps to regain access to your Haul account.',
        steps: [
          'Double-check your email and password',
          'Try the "Forgot Password" option',
          'Check your email for reset instructions',
          'Clear app data and try logging in again',
          'Ensure your account isn\'t temporarily suspended',
          'Contact support if you still can\'t access',
        ],
      ),
      HelpItem(
        title: 'Photo upload problems',
        content: 'Having trouble uploading photos for your listings or profile? Here\'s how to fix common image upload issues.',
      ),
    ],
  ),

  HelpCategory(
    title: 'Thrift Shopping Tips',
    icon: Icons.lightbulb_outline,
    items: [
      HelpItem(
        title: 'How to find the best deals',
        content: 'Learn insider tips for finding amazing thrift deals and unique vintage pieces on Haul.',
      ),
      HelpItem(
        title: 'Authenticating vintage items',
        content: 'Tips for identifying authentic vintage pieces and avoiding replicas when thrift shopping.',
      ),
      HelpItem(
        title: 'Caring for thrift finds',
        content: 'Learn how to properly clean, store, and maintain your thrift purchases to make them last longer.',
      ),
      HelpItem(
        title: 'Sustainable shopping practices',
        content: 'Discover how thrift shopping on Haul contributes to sustainable fashion and reduces environmental impact.',
      ),
    ],
  ),
];

// All help items flattened for search functionality
final List<HelpItem> helpItems = helpCategories
    .expand((category) => category.items)
    .toList();