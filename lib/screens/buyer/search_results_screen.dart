import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/product_model.dart';
import 'product_details_screen.dart';
import '../../widgets/product_card.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  
  const SearchResultsScreen({
    Key? key,
    required this.query,
  }) : super(key: key);
  
  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  List<Product> _searchResults = [];
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _performSearch();
  }
  
  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final query = widget.query.trim().toLowerCase();
      
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('products')
          .where('isActive', isEqualTo: true)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .limit(20)
          .get();
          
      final List<Product> products = result.docs
          .map((doc) => Product.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
          
      setState(() {
        _searchResults = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Results for "${widget.query}"',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : _error != null 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Error loading results',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _performSearch,
                    child: Text('Try Again'),
                  ),
                ],
              ),
            )
          : _searchResults.isEmpty 
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      'No products found',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Try a different search term',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            : GridView.builder(
                padding: EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  return ProductCard(product: _searchResults[index]);
                },
              ),
    );
  }
}
