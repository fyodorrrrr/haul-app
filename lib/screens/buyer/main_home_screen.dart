import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haul/providers/cart_providers.dart';
import '/models/product_model.dart';
import '/providers/wishlist_providers.dart';
import 'package:provider/provider.dart';
import '/models/wishlist_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'product_details_screen.dart';
import '/utils/snackbar_helper.dart';
//import '/providers/product_provider.dart';
import '/main.dart';

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
      print('Fetching products from Firestore...');
      final snapshot = await FirebaseFirestore.instance.collection('products').get();

      final fetchedProducts = snapshot.docs.map((doc) {
        // Pass both the document ID and the data map
        return Product.fromMap(doc.id, doc.data());
      }).toList();

      setState(() {
        products = fetchedProducts;
        uniqueBrands = extractUniqueBrands(fetchedProducts);
      });

      print('Fetched ${products.length} products.');
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
      'id': firestore.collection('products').doc().id,
      'name': 'Vintage Denim Jacket',
      'description': 'Classic denim jacket with retro vibes.',
      'price': 49.99,
      'category': 'Outerwear',
      'condition': 'Used - Like New',
      'size': 'M',
      'imageUrl': imageUrl, // Placeholder image URL
      'brand': 'Levi\'s',
    },
    {
      'id': firestore.collection('products').doc().id,
      'name': 'Retro Leather Boots',
      'description': 'Brown leather boots perfect for a rugged look.',
      'price': 65.50,
      'category': 'Footwear',
      'condition': 'Used - Good',
      'size': '9',
      'imageUrl': imageUrl, // Placeholder image URL
      'brand': 'Dr. Martens',
    },
    {
      'id': firestore.collection('products').doc().id,
      'name': 'Graphic Band Tee',
      'description': 'Vintage band tee from 90s rock tour.',
      'price': 25.00,
      'category': 'Tops',
      'condition': 'Used - Fair',
      'size': 'L',
      'imageUrl': imageUrl, // Placeholder image URL
      'brand': 'Hanes',
    },
    {
      'id': firestore.collection('products').doc().id,
      'name': 'Plaid Mini Skirt',
      'description': 'Preppy red plaid skirt, perfect for layering.',
      'price': 22.00,
      'category': 'Bottoms',
      'condition': 'Used - Good',
      'size': 'S',
      'imageUrl': imageUrl, // Placeholder image URL
      'brand': 'Zara',
    },
    {
      'id': firestore.collection('products').doc().id,
      'name': 'Oversized Hoodie',
      'description': 'Comfy and cozy oversized hoodie.',
      'price': 30.00,
      'category': 'Outerwear',
      'condition': 'Used - Excellent',
      'size': 'XL',
      'imageUrl': imageUrl, // Placeholder image URL
      'brand': 'Champion',
    },
  ];

  for (final product in dummyProducts) {
    await firestore.collection('products').doc(product['id'] as String).set(product);
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

    return SingleChildScrollView(
      child: Expanded(
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
            _buildSectionHeader('Brands'),
            const SizedBox(height: 12),
            _buildBrandsRow(),
            
            const SizedBox(height: 24),
            
            // For You Section
            _buildSectionHeader('For You', showSubtitle: true),
            const SizedBox(height: 12),
            _buildForYouGrid(context),
            
            // Add space at the bottom
            const SizedBox(height: 20),
          ],
        ),
      ),
      )
    );
  }

  Widget _buildPromotionBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          '30% OFF',
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool showSubtitle = false}) {
    return Column(
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
    );
  }

  Widget _buildBrandsRow() {
    if (uniqueBrands.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(), // Show a loader if no brands are available
      );
    }

    final brandsList = uniqueBrands.toList(); // Convert Set to List

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: brandsList.length,
        itemBuilder: (context, index) {
          final brand = brandsList[index];
          return Container(
            width: 80,
            height: 80,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                brand,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForYouGrid(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    final itemWidth = (size.width - 48) / 2; // Account for padding and spacing
    final itemHeight = itemWidth * 1.35; // Maintain aspect ratio

    final wishlistProvider = Provider.of<WishlistProvider>(context);

    if (products.isEmpty) {
    return const Center(
      child: CircularProgressIndicator(), // Show a loader if no products are available
    );
  }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: itemWidth / itemHeight,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
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
                    // Product Image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      child: SizedBox(
                        height: itemHeight * 0.6, // Image takes 60% of card height
                        width: double.infinity,
                        child: product.imageUrl.isNotEmpty
                            ? Image.network(
                                product.imageUrl,
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
                            Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.bold,
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
                            'Please log in to add items to your wishlist.', isError: true,
                          );
                          return;
                        }

                        try {
                          if (isInWishlist) {
                            await wishlistProvider.removeFromWishlist(product.id);
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
                                productImage: product.imageUrl,
                                productPrice: product.price,
                                addedAt: DateTime.now(),
                              ),
                            );
                            SnackBarHelper.showSnackBar(
                              context,
                              'Added to wishlist', isSuccess: true,
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
