import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../models/wishlist_model.dart';
import '../../providers/wishlist_providers.dart';
import '../../utils/snackbar_helper.dart';

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

  @override
  void initState() {
    super.initState();
    controller = CardSwiperController();
    _fetchUserId();
    _loadFeaturedProducts();
  }

  @override
  void dispose() {
    controller?.dispose();
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
    setState(() {
      _isLoading = true;
      _featuredProducts.clear();
    });

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
          .toList();

      setState(() {
        _featuredProducts = products;
        _isLoading = false;
      });

      if (products.isNotEmpty && controller == null) {
        controller = CardSwiperController();
      }
    } catch (e) {
      print('Error loading products: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoading || _featuredProducts.isEmpty) return;

    try {
      final lastProduct = _featuredProducts.last;
      
      QuerySnapshot result = await FirebaseFirestore.instance
          .collection('products')
          .where('isActive', isEqualTo: true)
          .where('createdAt', isLessThan: lastProduct.createdAt)
          .orderBy('createdAt', descending: true)
          .limit(20)
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
          .toList();

      if (newProducts.isNotEmpty) {
        setState(() {
          _featuredProducts.addAll(newProducts);
        });
      }
    } catch (e) {
      print('Error loading more products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
            // Enhanced Header with better styling
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discover',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Swipe to explore items',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Icon(
                          Icons.favorite_border,
                          color: Colors.grey[600],
                          size: 28,
                        ),
                        if (_wishlistProductIds.isNotEmpty)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${_wishlistProductIds.length}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Main Card Swiper Area
            Expanded(
              child: Stack(
                children: [
                  // Main Content - Card Swiper
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
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _featuredProducts.isEmpty
                        ? _buildEmptyState()
                        : Padding(
                            padding: EdgeInsets.only(
                              left: 20,
                              right: 20,
                              top: 20,
                              bottom: 120, // Space for bottom buttons
                            ),
                            child: CardSwiper(
                              key: _cardSwiperKey,
                              controller: controller,
                              cardsCount: _featuredProducts.length,
                              cardBuilder: (BuildContext context, int index) {
                                return _buildImprovedProductCard(context, _featuredProducts[index]);
                              },
                              onSwipe: (previousIndex, currentIndex, direction) {
                                _handleSwipe(previousIndex, currentIndex, direction);
                                return true;
                              },
                              threshold: 50,
                              maxAngle: 12,
                              isLoop: false,
                              scale: 0.9,
                            ),
                          ),
                  ),
                  
                  // Enhanced Bottom Action Buttons
                  Positioned(
                    bottom: 30,
                    left: 20,
                    right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Pass/Dislike button
                        _buildActionButton(
                          icon: Icons.close,
                          color: Colors.red,
                          onPressed: () {
                            if (!_isLoading && _featuredProducts.isNotEmpty && controller != null) {
                              try {
                                controller!.swipeLeft();
                              } catch (e) {
                                print('Error swiping left: $e');
                                if (_featuredProducts.isNotEmpty) {
                                  _handleSwipe(0, 1, CardSwiperDirection.left);
                                }
                              }
                            }
                          },
                        ),
                        
                        // Info button
                        _buildActionButton(
                          icon: Icons.info_outline,
                          color: Colors.blue,
                          size: 56,
                          onPressed: () {
                            _showProductInfo();
                          },
                        ),
                        
                        // Like/Add to wishlist button
                        _buildActionButton(
                          icon: Icons.favorite,
                          color: Colors.green,
                          onPressed: () {
                            if (!_isLoading && _featuredProducts.isNotEmpty && controller != null) {
                              try {
                                controller!.swipeRight();
                              } catch (e) {
                                print('Error swiping right: $e');
                                if (_featuredProducts.isNotEmpty) {
                                  _handleSwipe(0, 1, CardSwiperDirection.right);
                                }
                              }
                            }
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
    );
  }

  // Enhanced Action Button with better animations
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    double size = 64,
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
                  blurRadius: 20,
                  offset: Offset(0, 8),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: color.withOpacity(0.1),
                width: 2,
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
                      size: size * 0.4,
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
  Widget _buildImprovedProductCard(BuildContext context, Product product) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            offset: Offset(0, 12),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 4),
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
                              fontSize: 18,
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
              top: 24,
              left: 24,
              child: TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: Duration(milliseconds: 800),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(20),
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
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Only ${product.currentStock} left!',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
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
          
          // Enhanced price tag with better styling
          Positioned(
            top: 24,
            right: 24,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
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
                  Icon(
                    Icons.attach_money,
                    color: Colors.green[600],
                    size: 18,
                  ),
                  Text(
                    '${product.effectivePrice.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Enhanced bottom information panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(28),
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
                  // Brand badge with better styling
                  if (product.brand.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        product.brand.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  
                  // Enhanced product name
                  Text(
                    product.name,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Enhanced category and features row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
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
                      
                      // Rating chip (if you have ratings)
                      _buildInfoChip(
                        icon: Icons.star_outline,
                        label: '4.5', // Replace with actual rating
                        color: Colors.amber,
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Swipe hint with animation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: Duration(milliseconds: 1500),
                        builder: (context, double value, child) {
                          return Opacity(
                            opacity: 0.7,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.swipe_left,
                                  color: Colors.red.withOpacity(value),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Swipe to explore',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.swipe_right,
                                  color: Colors.green.withOpacity(value),
                                  size: 20,
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
    );
  }

  // Helper method for info chips
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
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
            size: 14,
          ),
          SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Show product info modal
  void _showProductInfo() {
    if (_featuredProducts.isEmpty) return;
    
    final product = _featuredProducts.first;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            Text(
              product.name,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 8),
            
            Text(
              product.brand,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            
            SizedBox(height: 16),
            
            Text(
              'Description',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            SizedBox(height: 8),
            
            Text(
              product.description,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            
            Spacer(),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Trigger pass
                      if (controller != null) {
                        controller!.swipeLeft();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black87,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Pass'),
                  ),
                ),
                
                SizedBox(width: 16),
                
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Trigger like
                      if (controller != null) {
                        controller!.swipeRight();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Add to Wishlist'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Handle card swipe actions
  bool _handleSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    if (previousIndex >= _featuredProducts.length || previousIndex < 0) {
      return false;
    }
    
    final product = _featuredProducts[previousIndex];
    
    if (direction == CardSwiperDirection.right) {
      _addToWishlist(product);
    } else if (direction == CardSwiperDirection.left) {
      print('Passed on: ${product.name}');
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
          '❤️ Added to wishlist!',
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
  Widget _buildEmptyState() {
    return Center(
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
            'You\'ve seen all available items.\nCheck back later for new finds.',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 40),
          
          ElevatedButton.icon(
            onPressed: () {
              _loadFeaturedProducts();
            },
            icon: Icon(Icons.refresh),
            label: Text('Refresh'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to update wishlist IDs when changed
  void _updateWishlistIds(WishlistProvider provider) {
    final newIds = provider.wishlist.map((item) => item.productId).toSet();
    
    if (_wishlistProductIds.length != newIds.length || 
        !_wishlistProductIds.containsAll(newIds)) {
      setState(() {
        _wishlistProductIds = newIds;
      });
      
      if (_wishlistProductIds.length < newIds.length) {
        _loadFeaturedProducts();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This ensures we listen to wishlist changes
    if (userId != null) {
      final wishlistProvider = Provider.of<WishlistProvider>(context);
      _updateWishlistIds(wishlistProvider);
    }
  }
  
  // Helper method to update wishlist IDs when changed
  void _updateWishlistIds(WishlistProvider provider) {
    final newIds = provider.wishlist.map((item) => item.productId).toSet();
    
    // If wishlist has changed, update our set and refresh products
    if (!setEquals(newIds, _wishlistProductIds)) {
      setState(() {
        _wishlistProductIds = newIds;
      });
      
      // Check if we need to reload products (e.g., something was removed from wishlist)
      if (_wishlistProductIds.length < newIds.length) {
        _loadFeaturedProducts(); // Reload to show newly unwishlisted items
      }
    }
  }

  // Add this method to handle reloading products when a wishlist item is removed
  void _refreshAfterWishlistRemoval(String productId) {
    setState(() {
      _wishlistProductIds.remove(productId);
    });
    _loadFeaturedProducts();
  }
}