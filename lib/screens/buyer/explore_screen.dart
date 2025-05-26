import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../models/product.dart';
import '../../models/wishlist_model.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/wishlist_providers.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/currency_formatter.dart'; // ✅ Add this import
import '../../widgets/not_logged_in.dart';
import '../buyer/product_details_screen.dart'; // Import the ProductDetailScreen

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  CardSwiperController? controller;
  Key _cardSwiperKey = UniqueKey();
  List<Product> _featuredProducts = [];
  bool _isLoading = true;
  String? userId;
  Set<String> _wishlistProductIds = {};
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _fetchUserId();
    _loadFeaturedProducts();
  }

  // ✅ Improved controller initialization
  void _initializeController() {
    // Only dispose if controller exists and is not already disposed
    if (controller != null) {
      try {
        controller?.dispose();
      } catch (e) {
        print('Error disposing old controller: $e');
      }
    }
    controller = CardSwiperController();
  }

  @override
  void dispose() {
    _isDisposed = true;
    // ✅ Safe disposal
    try {
      controller?.dispose();
    } catch (e) {
      print('Error disposing controller in dispose: $e');
    } finally {
      controller = null;
    }
    super.dispose();
  }

  void _fetchUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
      _loadWishlistItems();
    }
  }

  Future<void> _loadWishlistItems() async {
    if (userId == null) return;

    try {
      final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
      await wishlistProvider.fetchWishlist(userId!);

      setState(() {
        _wishlistProductIds = wishlistProvider.wishlist
            .map((item) => item.productId)
            .toSet();
      });
    } catch (e) {
      print('Error loading wishlist: $e');
    }
  }

  Future<void> _loadFeaturedProducts() async {
    if (_isDisposed) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _featuredProducts.clear();
      });
    }

    try {
      QuerySnapshot result = await FirebaseFirestore.instance
          .collection('products')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      List<Product> products = result.docs
          .map((doc) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return Product.fromMap(data);
            } catch (e) {
              print('Error parsing product ${doc.id}: $e');
              return null;
            }
          })
          .where((product) => product != null)
          .cast<Product>()
          .where((product) => !_wishlistProductIds.contains(product.id))
          .where((product) => userId == null || product.sellerId != userId) // <-- Hide own products
          .toList();

      // ✅ Randomize the products
      products.shuffle();

      if (!_isDisposed && mounted) {
        setState(() {
          _featuredProducts = products;
          _isLoading = false;
        });

        // ✅ Only create controller if we don't have one and have products
        if (products.isNotEmpty && controller == null) {
          controller = CardSwiperController();
        }
      }
    } catch (e) {
      print('Error loading products: $e');
      if (!_isDisposed && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoading || _featuredProducts.isEmpty) return;

    try {
      // ✅ Get random products instead of chronological order
      QuerySnapshot result = await FirebaseFirestore.instance
          .collection('products')
          .where('isActive', isEqualTo: true)
          .limit(30) // Get 30 random products
          .get();

      List<Product> newProducts = result.docs
        .map((doc) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return Product.fromMap(data);
          } catch (e) {
            print('Error parsing product ${doc.id}: $e');
            return null;
          }
        })
        .where((product) => product != null)
        .cast<Product>()
        .where((product) => !_wishlistProductIds.contains(product.id))
        .where((product) => !_featuredProducts.any((existing) => existing.id == product.id))
        .where((product) => userId == null || product.sellerId != userId) // <-- Hide own products
        .toList();

      // ✅ Randomize the new products
      newProducts.shuffle();

      if (newProducts.isNotEmpty) {
        setState(() {
          _featuredProducts.addAll(newProducts.take(20)); // Add only 20 to avoid too many
        });
        
        print('Added ${newProducts.take(20).length} more randomized products');
      }
    } catch (e) {
      print('Error loading more products: $e');
    }
  }

  // ✅ Improved refresh method with better randomization
  Future<void> _refreshProducts() async {
    if (_isDisposed) return;
    
    print('Refreshing products...');
    
    // ✅ Create completely new controller and key
    setState(() {
      _cardSwiperKey = UniqueKey();
      _isLoading = true;
    });
    
    // ✅ Safely dispose old controller
    try {
      if (controller != null) {
        controller!.dispose();
        controller = null;
      }
    } catch (e) {
      print('Error disposing controller during refresh: $e');
    }
    
    // ✅ Wait a frame before creating new controller
    await Future.delayed(Duration(milliseconds: 100));
    
    if (!_isDisposed && mounted) {
      // Create new controller
      controller = CardSwiperController();
      
      // Reload wishlist first
      await _loadWishlistItems();
      
      // ✅ Get more products for better randomization
      await _loadRandomizedProducts();
      
      // Show success message
      if (mounted && !_isDisposed) {
        SnackBarHelper.showSnackBar(
          context,
          'Refreshed!',
          isSuccess: true,
        );
      }
    }
  }

  // ✅ New method specifically for randomized loading with larger pool
  Future<void> _loadRandomizedProducts() async {
    if (_isDisposed) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _featuredProducts.clear();
      });
    }

    try {
      // ✅ Get a larger pool of products for better randomization
      QuerySnapshot result = await FirebaseFirestore.instance
          .collection('products')
          .where('isActive', isEqualTo: true)
          .limit(100) // ✅ Increased from 50 to 100 for better variety
          .get();

      List<Product> allProducts = result.docs
        .map((doc) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return Product.fromMap(data);
          } catch (e) {
            print('Error parsing product ${doc.id}: $e');
            return null;
          }
        })
        .where((product) => product != null)
        .cast<Product>()
        .where((product) => !_wishlistProductIds.contains(product.id))
        .where((product) => userId == null || product.sellerId != userId) // <-- Hide own products
        .toList();

      // ✅ Shuffle all products first
      allProducts.shuffle();
      
      // ✅ Take only first 30-50 for the swipe session
      List<Product> products = allProducts.take(50).toList();
      
      // ✅ Shuffle again for extra randomness
      products.shuffle();

      if (!_isDisposed && mounted) {
        setState(() {
          _featuredProducts = products;
          _isLoading = false;
        });

        // ✅ Only create controller if we don't have one and have products
        if (products.isNotEmpty && controller == null) {
          controller = CardSwiperController();
        }
      }
    } catch (e) {
      print('Error loading randomized products: $e');
      if (!_isDisposed && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ Safe swipe methods with better error handling
  void _safeSwipeLeft() {
    if (_isDisposed || _isLoading || _featuredProducts.isEmpty) return;
    
    try {
      // ✅ Check if controller is still valid before using
      if (controller != null && !_isDisposed) {
        controller!.swipeLeft();
      }
    } catch (e) {
      print('Error swiping left: $e');
      // ✅ Recreate controller if it was disposed
      if (e.toString().contains('disposed')) {
        _recreateController();
      }
    }
  }

  void _safeSwipeRight() {
    if (_isDisposed || _isLoading || _featuredProducts.isEmpty) return;
    
    try {
      // ✅ Check if controller is still valid before using
      if (controller != null && !_isDisposed) {
        controller!.swipeRight();
      }
    } catch (e) {
      print('Error swiping right: $e');
      // ✅ Recreate controller if it was disposed
      if (e.toString().contains('disposed')) {
        _recreateController();
      }
    }
  }

  // ✅ Add method to recreate controller when needed
  void _recreateController() {
    if (_isDisposed) return;
    
    try {
      controller = CardSwiperController();
      if (mounted) {
        setState(() {
          _cardSwiperKey = UniqueKey();
        });
      }
    } catch (e) {
      print('Error recreating controller: $e');
    }
  }

  // Add this method to your _ExploreScreenState class
  Map<String, dynamic> _getResponsiveValues(BuildContext context) {
  final screenSize = MediaQuery.of(context).size;
  final screenWidth = screenSize.width;
  final screenHeight = screenSize.height;
  
  // Screen size categories
  final isSmallScreen = screenWidth < 360;
  final isMediumScreen = screenWidth >= 360 && screenWidth < 768;
  final isLargeScreen = screenWidth >= 768;
  final isTablet = screenWidth >= 768 && screenWidth < 1024;
  final isDesktop = screenWidth >= 1024;
  
  return {
    'isSmallScreen': isSmallScreen,
    'isMediumScreen': isMediumScreen,
    'isLargeScreen': isLargeScreen,
    'isTablet': isTablet,
    'isDesktop': isDesktop,
    'screenWidth': screenWidth,
    'screenHeight': screenHeight,
    
    // Responsive values
    'headerPadding': isSmallScreen ? 12.0 : isMediumScreen ? 16.0 : 20.0,
    'headerVerticalPadding': isSmallScreen ? 8.0 : 12.0,
    'titleFontSize': isSmallScreen ? 20.0 : isMediumScreen ? 24.0 : isTablet ? 28.0 : 32.0,
    'subtitleFontSize': isSmallScreen ? 10.0 : isMediumScreen ? 12.0 : 14.0,
    'buttonIconSize': isSmallScreen ? 16.0 : isMediumScreen ? 20.0 : 24.0,
    'buttonPadding': isSmallScreen ? 6.0 : 8.0,
    'cardPadding': isSmallScreen ? 2.0 : isMediumScreen ? 4.0 : 8.0,
    'bottomPadding': isSmallScreen ? 60.0 : isMediumScreen ? 70.0 : 80.0,
    'actionButtonSize': isSmallScreen ? 40.0 : isMediumScreen ? 44.0 : isTablet ? 50.0 : 56.0,
  };
}

  @override
  Widget build(BuildContext context) {
  final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: true);
  if (!userProfileProvider.isProfileLoaded) {
    return const NotLoggedInScreen(
      message: 'Please sign in to access Ukay.',
      icon: Icons.swap_horiz_outlined,
    );
  }

  // ✅ Get responsive values
  final responsive = _getResponsiveValues(context);
  
  // Listen for wishlist changes
  if (userId != null) {
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    _updateWishlistIds(wishlistProvider);
  }
  
  return Scaffold(
    backgroundColor: Colors.grey[50],
    body: SafeArea(
      child: Column(
        children: [
          // ✅ Responsive Header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: responsive['headerPadding'],
              vertical: responsive['headerVerticalPadding'],
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ukay',
                        style: GoogleFonts.poppins(
                          fontSize: responsive['titleFontSize'],
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Swipe to explore items',
                        style: GoogleFonts.poppins(
                          fontSize: responsive['subtitleFontSize'],
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // ✅ Responsive Refresh Button
                Container(
                  margin: EdgeInsets.only(right: responsive['isSmallScreen'] ? 8 : 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _refreshProducts,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.all(responsive['buttonPadding']),
                        decoration: BoxDecoration(
                          color: _isLoading 
                              ? Colors.grey[100] 
                              : Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isLoading 
                                ? Colors.grey[300]! 
                                : Theme.of(context).primaryColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: responsive['buttonIconSize'] - 4,
                                height: responsive['buttonIconSize'] - 4,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).primaryColor,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.refresh,
                                color: Theme.of(context).primaryColor,
                                size: responsive['buttonIconSize'],
                              ),
                      ),
                    ),
                  ),
                ),
                
                // ✅ Responsive Instructions Button
                Container(
                  padding: EdgeInsets.all(responsive['buttonPadding']),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue[200]!,
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showInstructions,
                      borderRadius: BorderRadius.circular(8),
                      child: Icon(
                        Icons.help_outline,
                        color: Colors.blue[600],
                        size: responsive['buttonIconSize'],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // ✅ Responsive Main Content Area
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: _isLoading 
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Finding amazing items...',
                              style: GoogleFonts.poppins(
                                fontSize: responsive['subtitleFontSize'] + 2,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _featuredProducts.isEmpty
                      ? _buildEmptyState(responsive)
                      : Padding(
                          padding: EdgeInsets.only(
                            left: responsive['cardPadding'],
                            right: responsive['cardPadding'],
                            top: responsive['cardPadding'],
                            bottom: responsive['bottomPadding'],
                          ),
                          child: CardSwiper(
                            key: _cardSwiperKey,
                            controller: controller,
                            cardsCount: _featuredProducts.length,
                            cardBuilder: (BuildContext context, int index) {
                              return _buildImprovedProductCard(
                                context, 
                                _featuredProducts[index],
                                responsive,
                              );
                            },
                            onSwipe: (previousIndex, currentIndex, direction) {
                              if (!_isDisposed && mounted) {
                                return _handleSwipe(previousIndex, currentIndex, direction);
                              }
                              return false;
                            },
                            threshold: responsive['isSmallScreen'] ? 40 : 50,
                            maxAngle: 12,
                            isLoop: false,
                            scale: 0.98,
                            numberOfCardsDisplayed: 1,
                          ),
                        ),
                ),
                
                // ✅ Responsive Bottom Action Buttons
                Positioned(
                  bottom: responsive['isSmallScreen'] ? 10 : 15,
                  left: responsive['isSmallScreen'] ? 10 : 15,
                  right: responsive['isSmallScreen'] ? 10 : 15,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.close,
                        color: Colors.red,
                        size: responsive['actionButtonSize'],
                        onPressed: () {
                          _safeSwipeLeft();
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.favorite,
                        color: Colors.green,
                        size: responsive['actionButtonSize'],
                        onPressed: () {
                          _safeSwipeRight();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    
    // ✅ Responsive Floating Action Button
    floatingActionButton: _featuredProducts.isEmpty && !_isLoading
        ? FloatingActionButton.extended(
            onPressed: _refreshProducts,
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            icon: Icon(
              Icons.refresh, 
              size: responsive['isSmallScreen'] ? 20 : 24,
            ),
            label: Text(
              'Refresh',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: responsive['isSmallScreen'] ? 12 : 14,
              ),
            ),
          )
        : null,
    floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
  );
}

  // Enhanced Action Button with even smaller default size
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    double size = 44, // ✅ Reduced default from 64 to 44
  }) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 12, // ✅ Reduced from 20
                  offset: Offset(0, 4), // ✅ Reduced from 8
                  spreadRadius: 1, // ✅ Reduced from 2
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4, // ✅ Reduced from 8
                  offset: Offset(0, 2), // ✅ Reduced from 4
                ),
              ],
              border: Border.all(
                color: color.withOpacity(0.1),
                width: 1.5, // ✅ Reduced from 2
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(size / 2),
                onTap: onPressed,
                splashColor: color.withOpacity(0.2),
                highlightColor: color.withOpacity(0.1),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: color,
                      size: size * 0.4, // Icon size remains proportional
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Enhanced Product Card Design with better animations and layout
  Widget _buildImprovedProductCard(BuildContext context, Product product, Map<String, dynamic> responsive) {
    return GestureDetector(
      onDoubleTap: () {
        // Add haptic feedback for better UX
        HapticFeedback.mediumImpact();
        _navigateToProductDetails(context, product);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 35,
              offset: Offset(0, 18),
              spreadRadius: 4,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Main Product Image with Hero animation
            Positioned.fill(
              child: Hero(
                tag: 'product_${product.id}',
                child: product.images.isNotEmpty
                  ? Image.network(
                      product.images.first,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.grey[200]!,
                                Colors.grey[100]!,
                                Colors.grey[50]!,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Loading...',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.grey[300]!, Colors.grey[200]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 48,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Image not available',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor.withOpacity(0.1),
                            Theme.of(context).primaryColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.shopping_bag_outlined,
                                size: 64,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              product.name,
                              style: GoogleFonts.poppins(
                                color: Colors.grey[700],
                                fontSize: 16, // ✅ Reduced from 18
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
              ),
            ),
            
            // Animated top gradient overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            
            // Enhanced stock indicator with animation
            if (product.currentStock <= 5 && product.currentStock > 0)
              Positioned(
                top: 20, // ✅ Reduced from 24
                left: 20, // ✅ Reduced from 24
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: Duration(milliseconds: 800),
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), // ✅ Reduced padding
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(16), // ✅ Reduced border radius
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              color: Colors.white,
                              size: 12, // ✅ Reduced from 16
                            ),
                            SizedBox(width: 3), // ✅ Reduced from 4
                            Text(
                              'Only ${product.currentStock} left!',
                              style: GoogleFonts.poppins(
                                fontSize: 10, // ✅ Reduced from 12
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        ),
                      );
                    },
                  ),
                ),
              
            // Enhanced price tag with smaller text
            Positioned(
              top: 20, // ✅ Reduced from 24
              right: 20, // ✅ Reduced from 24
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // ✅ Reduced padding
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20), // ✅ Reduced border radius
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      CurrencyFormatter.formatWhole(product.effectivePrice), // ✅ Changed from $ to ₱
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Enhanced bottom information panel with updated instructions
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.95),
                      Colors.black.withOpacity(0.8),
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand badge with smaller text
                    if (product.brand.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4), // ✅ Reduced padding
                        margin: EdgeInsets.only(bottom: 8), // ✅ Reduced margin
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12), // ✅ Reduced border radius
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          product.brand.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 9, // ✅ Reduced from 11
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    
                    // Enhanced product name with smaller text
                    Text(
                      product.name,
                      style: GoogleFonts.poppins(
                        fontSize: 20, // ✅ Reduced from 26
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: 8), // ✅ Reduced from 12
                    
                    // Enhanced category and features row with smaller chips (REMOVED RATING)
                    Wrap(
                      spacing: 6, // ✅ Reduced from 8
                      runSpacing: 6, // ✅ Reduced from 8
                      children: [
                        // Category chip
                        _buildInfoChip(
                          icon: Icons.category_outlined,
                          label: product.category,
                          color: Colors.blue,
                        ),
                        
                        // Stock status chip
                        _buildInfoChip(
                          icon: product.currentStock > 0 
                            ? Icons.check_circle_outline 
                            : Icons.cancel_outlined,
                          label: product.currentStock > 0 ? 'Available' : 'Sold Out',
                          color: product.currentStock > 0 ? Colors.green : Colors.red,
                        ),
                        
                        // ❌ REMOVED RATING CHIP
                        // _buildInfoChip(
                        //   icon: Icons.star_outline,
                        //   label: '4.5',
                        //   color: Colors.amber,
                        // ),
                      ],
                    ),
                    
                    SizedBox(height: 12), // ✅ Reduced from 16
                    
                    // Updated swipe hint with question mark reference
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: Duration(milliseconds: 1500),
                          builder: (context, double value, child) {
                            return Opacity(
                              opacity: 0.7,
                              child: Column(
                                children: [
                                  // Swipe instructions
                                  
                                  SizedBox(height: 4),
                                  // Updated instruction
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.help_outline,
                                        color: Colors.blue.withOpacity(value * 0.8),
                                        size: 12,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Tap ? for help',
                                        style: GoogleFonts.poppins(
                                          fontSize: 9,
                                          color: Colors.white60,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for info chips
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), // ✅ Reduced padding
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12), // ✅ Reduced border radius
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 10, // ✅ Reduced from 14
          ),
          SizedBox(width: 3), // ✅ Reduced from 4
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9, // ✅ Reduced from 12
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Handle card swipe actions
  bool _handleSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    if (_isDisposed || previousIndex >= _featuredProducts.length || previousIndex < 0) {
      return false;
    }
    
    final product = _featuredProducts[previousIndex];
    
    if (direction == CardSwiperDirection.right) {
      _addToWishlist(product);
    } else if (direction == CardSwiperDirection.left) {
      print('Passed on: ${product.name}');
    }
    
    // ✅ Check if this was the last card
    if (currentIndex != null && currentIndex >= _featuredProducts.length) {
      // Show end message and allow refresh
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted && !_isDisposed) { // ✅ Check both mounted and disposed
          SnackBarHelper.showSnackBar(
            context,
            '🎉 All done! Pull down to refresh for more items.',
            isSuccess: true,
          );
        }
      });
    }
    
    // Load more products when running low
    if (currentIndex != null && _featuredProducts.length - currentIndex < 5) {
      _loadMoreProducts();
    }
    
    return true;
  }

  // Add product to wishlist
  void _addToWishlist(Product product) async {
    if (userId == null) {
      SnackBarHelper.showSnackBar(
        context,
        'Please log in to add items to your wishlist.',
        isError: true,
      );
      return;
    }

    try {
      final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
      final isInWishlist = wishlistProvider.isInWishlist(product.id);
      
      if (!isInWishlist) {
        await wishlistProvider.addToWishlist(
          WishlistModel(
            productId: product.id,
            userId: userId!,
            productName: product.name,
            productImage: product.images.isNotEmpty ? product.images.first : '',
            productPrice: product.effectivePrice,
            addedAt: DateTime.now(),
          ),
        );
        
        setState(() {
          _wishlistProductIds.add(product.id);
        });
        
        SnackBarHelper.showSnackBar(
          context,
          'Added to wishlist!',
          isSuccess: true,
        );
      }
    } catch (e) {
      SnackBarHelper.showSnackBar(
        context,
        'An error occurred. Please try again.',
        isError: true,
      );
    }
  }

  // Enhanced empty state
  Widget _buildEmptyState(Map<String, dynamic> responsive) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.explore_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
            
            SizedBox(height: 32),
            
            Text(
              'No more discoveries!',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            
            SizedBox(height: 12),
            
            Text(
              'You\'ve seen all available items.\nTap the refresh button to find new items.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 32),
            
            // Big refresh button
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _refreshProducts,
                icon: _isLoading 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.refresh),
                label: Text(
                  _isLoading ? 'Loading...' : 'Refresh Now',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to update wishlist IDs when changed
  void _updateWishlistIds(WishlistProvider provider) {
    if (_isDisposed) return; // ✅ Check if disposed

    final newIds = provider.wishlist.map((item) => item.productId).toSet();
    
    if (_wishlistProductIds.length != newIds.length || 
        !_wishlistProductIds.containsAll(newIds)) {
      
      if (mounted) { // ✅ Check if mounted
        setState(() {
          _wishlistProductIds = newIds;
        });
        
        if (_wishlistProductIds.length < newIds.length) {
          _loadFeaturedProducts();
        }
      }
    }
  }

  // Add the instructions dialog method
  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.explore,
                  color: Colors.blue[600],
                  size: 32,
                ),
              ),
              
              SizedBox(height: 20),
              
              Text(
                'How to Ukay',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              SizedBox(height: 20),
              
              // Instructions list
              _buildInstructionItem(
                Icons.swipe_right,
                'Swipe Right',
                'Add item to your wishlist',
                Colors.green,
              ),
              
              SizedBox(height: 16),
              
              _buildInstructionItem(
                Icons.swipe_left,
                'Swipe Left',
                'Skip and see next item',
                Colors.red,
              ),
              
              SizedBox(height: 16),
              
              _buildInstructionItem(
                Icons.touch_app,
                'Double Tap',
                'View detailed product information',
                Colors.blue,
              ),
              
              SizedBox(height: 16),
              
              _buildInstructionItem(
                Icons.refresh,
                'Refresh Button',
                'Load new randomized items',
                Colors.orange,
              ),
              
        
              
              SizedBox(height: 24),
              
              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Got It!',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for instruction items
  Widget _buildInstructionItem(IconData icon, String title, String description, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        SizedBox(width: 16),
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
    );
  }

  // Add this method to handle navigation to product details
  void _navigateToProductDetails(BuildContext context, Product product) {
    // Get current user data
    final user = FirebaseAuth.instance.currentUser;
    final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
    
    Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ProductDetailsScreen(
        product: product,
        userId: user?.uid, // Pass the user ID
      ),
    ),
  );
  }
}