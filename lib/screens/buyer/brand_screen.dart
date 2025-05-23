  import 'package:flutter/material.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:haul/models/product_model.dart';
  import 'package:haul/screens/buyer/product_details_screen.dart';
  import 'package:google_fonts/google_fonts.dart';

  class BrandProductsScreen extends StatefulWidget {
    final String brandName;

    const BrandProductsScreen({Key? key, required this.brandName}) : super(key: key);

    @override
    _BrandProductsScreenState createState() => _BrandProductsScreenState();
  }

  class _BrandProductsScreenState extends State<BrandProductsScreen> {
    List<Product> brandProducts = [];
    bool isLoading = true;

    @override
    void initState() {
      super.initState();
      fetchBrandProducts();
    }

    Future<void> fetchBrandProducts() async {
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('brand', isEqualTo: widget.brandName)
            .get();

        final results = querySnapshot.docs
            .map((doc) => Product.fromFirestore(doc))
            .toList();

        setState(() {
          brandProducts = results;
          isLoading = false;
        });
      } catch (e) {
        print('Error fetching brand products: $e');
        setState(() => isLoading = false);
      }
    }

    @override
      Widget build(BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color.fromARGB(255, 255, 255, 255),
            elevation: 4,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              widget.brandName,
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            ),
            centerTitle: true,
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : brandProducts.isEmpty
                  ? Center(child: Text('No products found for ${widget.brandName}'))
                  : ListView.builder(
                      itemCount: brandProducts.length,
                      itemBuilder: (context, index) {
                        final product = brandProducts[index];
                        final imageUrl = product.images.isNotEmpty ? product.images[0] : '';

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: imageUrl.isNotEmpty
                                ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                                : const Icon(Icons.image_not_supported),
                            title: Text(product.name),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailsScreen(product: product),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
        );
      }

  }
