import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haul/providers/cart_providers.dart';
import '../../models/product.dart';
import '/providers/wishlist_providers.dart';
import 'package:provider/provider.dart';
import '/models/wishlist_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'product_details_screen.dart';
import '/utils/snackbar_helper.dart';
import '/main.dart';
import 'brands_showcase_screen.dart';
import '../../widgets/brand_logo_widget.dart';
import 'search_screen.dart';
import 'brands_showcase_screen.dart';
import '../../utils/currency_formatter.dart'; // ✅ Add this import

class MainHomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  
  const MainHomeScreen({
    Key? key,
    this.userData = const {},
  }) : super(key: key);

  @override
  _MainHomeScreenState createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> with RouteAware {
  List<Product> products = [];
  int _productsToShow = 10; // <-- Add this line
  final String imageUrl = 'https://firebasestorage.googleapis.com/v0/b/haul-thrift-shop.firebasestorage.app/o/product.png?alt=media&token=8a229200-6b08-44c6-95ae-cf0efa4b1b5a'; 
  String? userId; // User ID to be used for wishlist
  Set<String> uniqueBrands = {};

  @override
  void initState() {
    super.initState();
    fetchUserId(); // Fetch user ID when the screen is loaded
    fetchProducts(); // Fetch products
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      if (userId != null) {
        wishlistProvider.fetchWishlist(userId!); // Fetch wishlist using the provider
        cartProvider.fetchCart(userId!);
      } else {
        wishlistProvider.clearWishlist();
        cartProvider.clearCart(); // Clear wishlist for guest users
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when returning to this screen
    fetchProducts(); 
    print("Refreshing products on home screen");
  }

  Future<void> fetchProducts() async {
  try {
    print('Fetching active products from Firestore...');
    
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('isActive', isEqualTo: true)
        .get();

    final currentUser = FirebaseAuth.instance.currentUser;
    final myUid = currentUser?.uid;

    final fetchedProducts = snapshot.docs.map((doc) {
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
    // Hide own products
    .where((product) => myUid == null || product.sellerId != myUid)
    .toList();

    setState(() {
      products = fetchedProducts;
      uniqueBrands = extractUniqueBrands(fetchedProducts);
    });

    print('Fetched ${products.length} active products.');
    print('Extracted brands: $uniqueBrands');
  } catch (e) {
    print('Error fetching products: $e');
    SnackBarHelper.showSnackBar(
      context,
      'Failed to fetch products. Please try again later.',
      isError: true,
    );
  }
}

  void fetchUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid; // Fetch the userID
      });
    } else {
      print('No user is currently logged in.');
    }
  }

  Future<void> addDummyProducts() async {
    final firestore = FirebaseFirestore.instance;

    final dummyProducts = [
      {
        'name': 'Vintage Denim Jacket',
        'description': 'Classic denim jacket with retro vibes.',
        'sellingPrice': 49.99,
        'costPrice': 35.00,
        'category': 'outerwear',
        'subcategory': 'jackets',
        'brand': 'Levi\'s',
        'sku': 'LEV-DJ-001',
        'images': [imageUrl],
        'variants': [],
        'currentStock': 10,
        'minimumStock': 2,
        'maximumStock': 50,
        'reorderPoint': 5,
        'reorderQuantity': 20,
        'location': 'Main Warehouse',
        'reservedStock': 0,
        'weight': 0.8,
        'dimensions': {
          'length': 65.0,
          'width': 50.0,
          'height': 2.0,
          'unit': 'cm'
        },
        'status': 'active',
        'isActive': true,
        'totalSold': 0,
        'viewCount': 0,
        'turnoverRate': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'sellerId': 'dummy_seller_1',
      },
      {
        'name': 'Retro Leather Boots',
        'description': 'Brown leather boots perfect for a rugged look.',
        'sellingPrice': 65.50,
        'costPrice': 45.00,
        'category': 'footwear',
        'subcategory': 'boots',
        'brand': 'Dr. Martens',
        'sku': 'DM-LB-002',
        'images': [imageUrl],
        'variants': [],
        'currentStock': 5,
        'minimumStock': 1,
        'maximumStock': 30,
        'reorderPoint': 3,
        'reorderQuantity': 15,
        'location': 'Main Warehouse',
        'reservedStock': 0,
        'weight': 1.2,
        'dimensions': {
          'length': 30.0,
          'width': 15.0,
          'height': 12.0,
          'unit': 'cm'
        },
        'status': 'active',
        'isActive': true,
        'totalSold': 0,
        'viewCount': 0,
        'turnoverRate': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'sellerId': 'dummy_seller_2',
      },
      {
        'name': 'Graphic Band Tee',
        'description': 'Vintage band tee from 90s rock tour.',
        'sellingPrice': 25.00,
        'costPrice': 15.00,
        'category': 'tops',
        'subcategory': 'tshirts',
        'brand': 'Hanes',
        'sku': 'HAN-BT-003',
        'images': [imageUrl],
        'variants': [],
        'currentStock': 15,
        'minimumStock': 3,
        'maximumStock': 100,
        'reorderPoint': 8,
        'reorderQuantity': 50,
        'location': 'Main Warehouse',
        'reservedStock': 0,
        'weight': 0.2,
        'dimensions': {
          'length': 70.0,
          'width': 50.0,
          'height': 1.0,
          'unit': 'cm'
        },
        'status': 'active',
        'isActive': true,
        'totalSold': 0,
        'viewCount': 0,
        'turnoverRate': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'sellerId': 'dummy_seller_3',
      },
      {
        'name': 'Plaid Mini Skirt',
        'description': 'Preppy red plaid skirt, perfect for layering.',
        'sellingPrice': 22.00,
        'costPrice': 12.00,
        'category': 'bottoms',
        'subcategory': 'skirts',
        'brand': 'Zara',
        'sku': 'ZAR-PS-004',
        'images': [imageUrl],
        'variants': [],
        'currentStock': 8,
        'minimumStock': 2,
        'maximumStock': 40,
        'reorderPoint': 5,
        'reorderQuantity': 20,
        'location': 'Main Warehouse',
        'reservedStock': 0,
        'weight': 0.3,
        'dimensions': {
          'length': 35.0,
          'width': 30.0,
          'height': 1.5,
          'unit': 'cm'
        },
        'status': 'active',
        'isActive': true,
        'totalSold': 0,
        'viewCount': 0,
        'turnoverRate': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'sellerId': 'dummy_seller_4',
      },
      {
        'name': 'Oversized Hoodie',
        'description': 'Comfy and cozy oversized hoodie.',
        'sellingPrice': 30.00,
        'costPrice': 20.00,
        'category': 'outerwear',
        'subcategory': 'hoodies',
        'brand': 'Champion',
        'sku': 'CHA-OH-005',
        'images': [imageUrl],
        'variants': [],
        'currentStock': 12,
        'minimumStock': 3,
        'maximumStock': 60,
        'reorderPoint': 7,
        'reorderQuantity': 30,
        'location': 'Main Warehouse',
        'reservedStock': 0,
        'weight': 0.6,
        'dimensions': {
          'length': 75.0,
          'width': 60.0,
          'height': 2.5,
          'unit': 'cm'
        },
        'status': 'active',
        'isActive': true,
        'totalSold': 0,
        'viewCount': 0,
        'turnoverRate': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'sellerId': 'dummy_seller_5',
      },
    ];

    for (final product in dummyProducts) {
      await firestore.collection('products').add(product);
    }

    print("Dummy products added.");
  }

  Set<String> extractUniqueBrands(List<Product> products) {
    if (products.isEmpty) {
      return {};
    }
    return products.map((product) => product.brand).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 350;

    return RefreshIndicator(
      onRefresh: () async {
        await fetchProducts();
        setState(() {
          _productsToShow = 10; // Reset on refresh
        });
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              // 30% OFF Banner
              _buildPromotionBanner(context),
              
              const SizedBox(height: 24),
              
              // Brands Section
              _buildSectionHeader(
                'Brands', 
                onViewAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BrandsShowcaseScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildBrandsRow(),
              
              const SizedBox(height: 24),
              
              // For You Section
              _buildSectionHeader('For You', showSubtitle: true),
              const SizedBox(height: 12),
              _buildForYouGrid(context),
              
              if (products.length > _productsToShow)
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _productsToShow += 10;
                      });
                    },
                    child: Text(
                      'See More',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              
              // Add space at the bottom
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromotionBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias, // This ensures the image respects the border radius
      child: AspectRatio(
        aspectRatio: 16/9, // Standard banner aspect ratio
        child: Image.asset(
          'assets/images/banner_1.jpg',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool showSubtitle = false, VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (showSubtitle)
              Text(
                'BASED ON YOUR RECENT ACTIVITIES',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
          ],
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: Text(
              'View All',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBrandsRow() {
    if (uniqueBrands.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final brandsList = uniqueBrands.toList();

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: brandsList.length,
        itemBuilder: (context, index) {
          final brand = brandsList[index];
          return Container(
            width: 80,
            margin: EdgeInsets.only(right: 12),
            child: BrandLogoWidget(
              brandName: brand,
              size: 60,
              showText: true,
              circular: true,
              showBorder: true,
              onTap: () {
                // ✅ THIS IS THE ONLY CHANGE - Replace the existing onTap with this:
                print('🔥 Navigating to search with brand: $brand');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchScreen(),
                    settings: RouteSettings(
                      arguments: {'brandFilter': brand},
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildForYouGrid(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    final itemWidth = (size.width - 48) / 2;
    final itemHeight = itemWidth * 1.35;

    final wishlistProvider = Provider.of<WishlistProvider>(context);

    if (products.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final productsToDisplay = products.take(_productsToShow).toList(); // <-- Only show limited products

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: itemWidth / itemHeight,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: productsToDisplay.length,
      itemBuilder: (context, index) {
        final product = productsToDisplay[index];
        final isInWishlist = wishlistProvider.isInWishlist(product.id);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailsScreen(
                  product: product,
                  userId: userId,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image - Updated to use images array
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      child: SizedBox(
                        height: itemHeight * 0.6, // Image takes 60% of card height
                        width: double.infinity,
                        child: product.images.isNotEmpty
                            ? Image.network(
                                product.images.first, // Use first image from array
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: Icon(
                                      Icons.error_outline,
                                      color: Colors.grey.shade400,
                                      size: isSmallScreen ? 24 : 32,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey.shade200,
                                child: Icon(
                                  Icons.image,
                                  color: Colors.grey.shade400,
                                  size: isSmallScreen ? 24 : 32,
                                ),
                              ),
                      ),
                    ),

                    // Product Details
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(isSmallScreen ? 6.0 : 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              product.name,
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 12 : 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Updated to use effectivePrice (shows sale price if available, otherwise selling price)
                            Text(
                              CurrencyFormatter.format(product.effectivePrice), // ✅ Changed from $ to ₱
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 12 : 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Wishlist Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: isSmallScreen ? 32 : 36,
                    height: isSmallScreen ? 32 : 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 1,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        isInWishlist ? Icons.favorite : Icons.favorite_border,
                        size: isSmallScreen ? 16 : 20,
                        color: isInWishlist ? Colors.red : Colors.grey,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () async {
                        if (userId == null) {
                          SnackBarHelper.showSnackBar(
                            context,
                            'Please log in to add items to your wishlist.', 
                            isError: true,
                          );
                          return;
                        }

                        try {
                          if (isInWishlist) {
                            await wishlistProvider.removeFromWishlist(product.id, userId!);
                            SnackBarHelper.showSnackBar(
                              context,
                              'Removed from wishlist',
                            );
                          } else {
                            await wishlistProvider.addToWishlist(
                              WishlistModel(
                                productId: product.id,
                                userId: userId!,
                                productName: product.name,
                                productImage: product.images.isNotEmpty ? product.images.first : '', // Updated
                                productPrice: product.effectivePrice, // Updated to use effective price
                                addedAt: DateTime.now(),
                              ),
                            );
                            SnackBarHelper.showSnackBar(
                              context,
                              'Added to wishlist', 
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
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}