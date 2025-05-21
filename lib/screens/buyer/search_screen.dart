import 'package:flutter/material.dart';
import '/widgets/custom_appbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haul/models/product_model.dart';
import 'package:haul/screens/buyer/product_details_screen.dart';


class search_product extends StatefulWidget {
  final bool showSearchBar;
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final String query;

  const search_product ({
    Key? key,    
    required this.showSearchBar,
    required this.searchController,
    required this. onSearchChanged,
    required this.query
  }) :super(key: key);


  @override
  searchProductState createState() => searchProductState();

  

}


  class searchProductState extends State<search_product>{
    @override
    void initState() {
      super.initState();
      widget.searchController.clear();
      searchProducts(widget.query).then((results) {
        setState(() {
          searchResults = results;
        });
      });
    }

    List<Product> searchResults = [];
    Future<List<Product>> searchProducts(String query) async{
      if (query.isEmpty){
        return [];
      }
      

      final result = await FirebaseFirestore.instance
    .collection('products')
    .where('name', isGreaterThanOrEqualTo: query)
    .where('name', isLessThan: query + 'z')
    .get();
    return result.docs.map((doc) => Product.fromFirestore(doc)).toList();
    }

    void handleSearchChanged(String query){
    print("user is searching for: $query");
  }
    @override
    Widget build(BuildContext context){
      
      return Scaffold(
        appBar: CustomAppBar(
          showSearchBar: widget.showSearchBar,
          searchController: widget.searchController,
          onSearchChanged: handleSearchChanged
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Column(
              children: [
                Text("Showing results for ${widget.query}"),
                Expanded(
                  
                  child: ListView.builder(
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final product1 = searchResults[index];
                    final name = product1.name;
                    final imageUrl = product1.images.isNotEmpty ? product1.images[0] : '';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        leading: imageUrl.isNotEmpty
                          ? Image.network(
                          imageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : Icon(Icons.image_not_supported),

                          title: Text(name),
                          onTap: () {
                            Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailsScreen(
                                product: product1,
                              ),
                            ),
                          );
                        },
                      )
                    );
                   }
                )
                )
              ]
            )
          )
        )
      )
    );
    }
}
