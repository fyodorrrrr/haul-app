import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/models/product_model.dart';

class MainHomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const MainHomeScreen({
    Key? key,
    this.userData = const {},
  }) : super(key: key);

  @override
  _MainHomeScreenState createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    // addDummyProducts();
    fetchProducts(); // Fetch products when the screen is loaded
  }

  Future<void> fetchProducts() async {
    try {
      // Fetch products from Firestore
      final snapshot = await FirebaseFirestore.instance.collection('products').get();

      // Convert Firestore data to Product objects and update the state
      setState(() {
        products = snapshot.docs.map((doc) {
          return Product.fromMap(doc.data() as Map<String, dynamic>);
        }).toList();
      });
    } catch (e) {
      print('Error fetching products: $e');
    }
  }


// Future<void> addDummyProducts() async {
//   final firestore = FirebaseFirestore.instance;

//   final dummyProducts = [
//     {
//       'id': firestore.collection('products').doc().id,
//       'name': 'Vintage Denim Jacket',
//       'description': 'Classic denim jacket with retro vibes.',
//       'price': 49.99,
//       'category': 'Outerwear',
//       'condition': 'Used - Like New',
//       'size': 'M',
//       'imageUrl': 'https://via.placeholder.com/150', // Placeholder image URL
//       'brand': 'Levi\'s',
//     },
//     {
//       'id': firestore.collection('products').doc().id,
//       'name': 'Retro Leather Boots',
//       'description': 'Brown leather boots perfect for a rugged look.',
//       'price': 65.50,
//       'category': 'Footwear',
//       'condition': 'Used - Good',
//       'size': '9',
//       'imageUrl': 'https://via.placeholder.com/150', // Placeholder image URL
//       'brand': 'Dr. Martens',
//     },
//     {
//       'id': firestore.collection('products').doc().id,
//       'name': 'Graphic Band Tee',
//       'description': 'Vintage band tee from 90s rock tour.',
//       'price': 25.00,
//       'category': 'Tops',
//       'condition': 'Used - Fair',
//       'size': 'L',
//       'imageUrl': 'https://via.placeholder.com/150', // Placeholder image URL
//       'brand': 'Hanes',
//     },
//     {
//       'id': firestore.collection('products').doc().id,
//       'name': 'Plaid Mini Skirt',
//       'description': 'Preppy red plaid skirt, perfect for layering.',
//       'price': 22.00,
//       'category': 'Bottoms',
//       'condition': 'Used - Good',
//       'size': 'S',
//       'imageUrl': 'https://via.placeholder.com/150', // Placeholder image URL
//       'brand': 'Zara',
//     },
//     {
//       'id': firestore.collection('products').doc().id,
//       'name': 'Oversized Hoodie',
//       'description': 'Comfy and cozy oversized hoodie.',
//       'price': 30.00,
//       'category': 'Outerwear',
//       'condition': 'Used - Excellent',
//       'size': 'XL',
//       'imageUrl': 'https://via.placeholder.com/150', // Placeholder image URL
//       'brand': 'Champion',
//     },
//   ];

//   for (final product in dummyProducts) {
//     await firestore.collection('products').doc(product['id'] as String).set(product);
//   }

//   print("Dummy products added.");
// }




  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 350;

    return SingleChildScrollView(
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
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: 80,
            height: 80,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForYouGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length, // Use the fetched products
      itemBuilder: (context, index) {
        final product = products[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Display product image (if available)
              product.imageUrl.isNotEmpty
                  ? Image.network(product.imageUrl, height: 100, width: 100, fit: BoxFit.cover)
                  : Container(height: 100, width: 100, color: Colors.grey.shade400), // Placeholder

              // Display product name
              Text(
                product.name,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              // Display product price
              Text(
                '\$${product.price}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
