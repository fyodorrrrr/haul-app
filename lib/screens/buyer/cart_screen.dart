import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
            child: Text(
              'Your Cart',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Cart items Testing Jose
          Expanded(
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) {
                return _buildCartItem(context);
              },
            ),
          ),
          
          // Order summary
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Subtotal Row
                _buildSummaryRow('Subtotal', '\$159.97'),
                const SizedBox(height: 8),
                
                // Shipping Row
                _buildSummaryRow('Shipping', '\$5.99'),
                const SizedBox(height: 8),
                
                // Tax Row
                _buildSummaryRow('Tax', '\$16.00'),
                
                const Divider(height: 24),
                
                // Total Row
                _buildSummaryRow(
                  'Total',
                  '\$181.96',
                  isTotal: true,
                ),
                
                const SizedBox(height: 16),
                
                // Checkout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Proceed to Checkout',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: Colors.black,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
  
  Widget _buildCartItem(BuildContext context) {
    final itemNumber = (100 + UniqueKey().hashCode % 900).abs();
    final price = (15 + UniqueKey().hashCode % 85).abs();
    
    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          
          // Product Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Thrift Item $itemNumber',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Size: M  |  Color: Vintage',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$$price.99',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      // Quantity selector
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () {},
                              child: Icon(
                                Icons.remove,
                                size: 16,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                '1',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {},
                              child: Icon(
                                Icons.add,
                                size: 16,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Remove button
          Container(
            width: 40,
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 12.0, right: 12.0),
            child: Icon(
              Icons.close,
              size: 18,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
} 