# 🛍️ Haul - Thrift Marketplace App

**Discover unique thrift finds and turn your preloved items into cash!**

Haul is a modern Flutter-based marketplace app that connects thrift enthusiasts, making it easy to buy and sell unique secondhand treasures. With features like swipe-to-discover browsing, seller verification, and real-time order tracking, Haul transforms the thrift shopping experience.

---

## ✨ Features

### 🛒 For Buyers
- **Swipe-to-Discover**: Explore curated thrift finds with an intuitive swipe interface
- **Advanced Search & Filters**: Find exactly what you're looking for by size, brand, price, and condition
- **Wishlist Management**: Save items for later and get notified of price drops
- **Order Tracking**: Real-time updates from purchase to delivery
- **Secure Payments**: Multiple payment options including cards, digital wallets, and cash on delivery
- **Review System**: Make informed decisions with buyer reviews and ratings

### 🏪 For Sellers
- **Easy Listing**: Quick product uploads with multiple photos and detailed descriptions
- **Seller Dashboard**: Manage inventory, track sales, and view analytics
- **Order Management**: Process orders efficiently with status updates
- **Seller Verification**: Build trust with verified seller badges
- **Real-time Notifications**: Stay updated on orders and messages

### 🔧 Core Features
- **User Authentication**: Secure Firebase-based login and registration
- **Profile Management**: Customizable user profiles with saved addresses and payment methods
- **Help Center**: Comprehensive support with searchable articles and live chat
- **Push Notifications**: Stay informed about orders, messages, and app updates
- **Multi-platform Support**: Available on iOS, Android, and Web

---

## 🛠️ Tech Stack

### Frontend
- **Framework**: Flutter 3.x
- **Language**: Dart
- **State Management**: Provider
- **UI/UX**: Material Design with Google Fonts

### Backend & Services
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage
- **Push Notifications**: Firebase Cloud Messaging
- **Image Handling**: Image Picker

### Key Dependencies
```yaml
dependencies:
  flutter: sdk: flutter
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  firebase_storage: ^11.5.6
  provider: ^6.1.1
  google_fonts: ^6.1.0
  image_picker: ^1.0.4
  url_launcher: ^6.2.1
  intl: ^0.18.1
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- Android Studio / VS Code
- Firebase project setup

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/haul-app.git
   cd haul-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Add your Android/iOS app to the project
   - Download and place configuration files:
     - `google-services.json` in `android/app/`
     - `GoogleService-Info.plist` in `ios/Runner/`

4. **Configure Firebase Services**
   ```bash
   # Install Firebase CLI
   npm install -g firebase-tools
   
   # Login and configure
   firebase login
   flutterfire configure
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

### Firebase Security Rules

**Firestore Rules** (`firestore.rules`):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own profile
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Products are readable by all, writable by owners
    match /products/{productId} {
      allow read: if true;
      allow write: if request.auth != null && 
        (resource == null || request.auth.uid == resource.data.sellerId);
    }
    
    // Orders are readable/writable by buyer and seller
    match /orders/{orderId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == resource.data.buyerId || 
         request.auth.uid == resource.data.sellerId);
    }
  }
}
```

**Storage Rules** (`storage.rules`):
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /products/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    match /profiles/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## 📱 App Architecture

### Project Structure
```
lib/
├── data/                    # Data constants and configurations
│   └── help_data.dart
├── models/                  # Data models
│   ├── user_profile_model.dart
│   ├── product_model.dart
│   └── help_models.dart
├── providers/               # State management
│   ├── user_profile_provider.dart
│   ├── edit_profile_provider.dart
│   └── order_provider.dart
├── screens/                 # UI screens
│   ├── buyer/              # Buyer-specific screens
│   │   ├── explore_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── order_history.dart
│   │   └── help_center_screen.dart
│   └── seller/             # Seller-specific screens
│       ├── seller_dashboard_screen.dart
│       └── order_detail_screen.dart
├── widgets/                # Reusable widgets
│   └── loading_screen.dart
└── main.dart               # App entry point
```

### Key Components

#### State Management (Provider Pattern)
```dart
// User Profile Provider
class UserProfileProvider extends ChangeNotifier {
  UserProfile? _userProfile;
  
  Future<void> fetchUserProfile() async {
    // Fetch from Firestore
    notifyListeners();
  }
}
```

#### Firebase Integration
```dart
// Example: Fetching user orders
Future<List<Map<String, dynamic>>> fetchUserOrders() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];
  
  final snapshot = await FirebaseFirestore.instance
      .collection('orders')
      .where('buyerId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .get();
      
  return snapshot.docs.map((doc) => {
    'documentId': doc.id,
    ...doc.data(),
  }).toList();
}
```

---

## 🧪 Testing

### Run Tests
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Widget tests
flutter test test/widget_test.dart
```

### Test Coverage
```bash
# Generate coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## 🚀 Deployment

### Android
```bash
# Build release APK
flutter build apk --release

# Build App Bundle for Play Store
flutter build appbundle --release
```

### iOS
```bash
# Build for iOS
flutter build ios --release
```

### Web
```bash
# Build for web
flutter build web --release
```

---

## 📋 Roadmap

### Phase 1 (Current) ✅
- [x] User authentication and profiles
- [x] Product listing and browsing
- [x] Order management system
- [x] Help center with search

### Phase 2 (In Progress) 🚧
- [ ] In-app messaging between buyers and sellers
- [ ] Advanced recommendation engine
- [ ] Social features (follow sellers, share finds)
- [ ] Augmented reality try-on features

### Phase 3 (Planned) 📅
- [ ] Subscription model for premium sellers
- [ ] Integration with shipping providers
- [ ] Multi-language support
- [ ] AI-powered product categorization

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

### Code Style
- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Add comments for complex logic
- Write tests for new features

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🆘 Support

### Documentation
- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)

### Community
- [Issues](https://github.com/fyodorrrrr/haul-app/issues) - Report bugs or request features
- [Discussions](https://github.com/fyodorrrrr/haul-app/discussions) - Ask questions and share ideas

### Contact
- **Email**: support@haulapp.com
- **Website**: [www.haulapp.com](https://www.haulapp.com)
- **Twitter**: [@HaulApp](https://twitter.com/haulapp)

---

## 🙏 Acknowledgments

- **Firebase Team** for excellent backend services
- **Flutter Team** for the amazing framework
- **Material Design** for UI/UX guidelines
- **Contributors** who helped make this project better

---

## 📦 Project Deliverables

### 🎯 **Application**
- **📱 Android APK**: [Download APK](https://drive.google.com/file/d/1cQ-T6f2KTzzrUeprLFO1KI5dZDEEJiw2/view?usp=sharing)
- **📂 Source Code**: [GitHub Repository](https://github.com/fyodorrrrr/haul-app)

### 📋 **Documentation**
- **📖 Project Documentation**: [View Documentation](https://drive.google.com/file/d/1bbtbmQ0LZiTCN-54A2ZM9nUnNr4YRmoK/view?usp=sharing)

### 🎥 **Media & Presentation**
- **🎬 Promo Video**: [Watch Video](https://drive.google.com/file/d/1ktn-kfIdoi9m2IJzeSSG4qj4Cxym4va-/view?t=4)
- **📊 Project Presentation**: [View Slides](https://www.canva.com/design/DAGodBLxfFA/PePvZ-uOuCKAFjSSJBMC5Q/view?utm_content=DAGodBLxfFA&utm_campaign=designshare&utm_medium=link2&utm_source=uniquelinks&utlId=h8302d63868)

---

<div align="center">

**Built with ❤️ using Flutter**

[⭐ Star this repo](https://github.com/fyodorrrrr/haul-app) • [🐛 Report Bug](https://github.com/fyodorrrrr/haul-app/issues) • [✨ Request Feature](https://github.com/fyodorrrrr/haul-app/issues)

</div>
