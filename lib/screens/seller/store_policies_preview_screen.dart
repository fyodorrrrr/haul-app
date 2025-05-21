import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorePoliciesPreviewScreen extends StatefulWidget {
  final Map<String, dynamic> storePolicies;
  
  const StorePoliciesPreviewScreen({
    Key? key,
    required this.storePolicies,
  }) : super(key: key);

  @override
  State<StorePoliciesPreviewScreen> createState() => _StorePoliciesPreviewScreenState();
}

class _StorePoliciesPreviewScreenState extends State<StorePoliciesPreviewScreen> {
  late Map<String, dynamic> _policies;
  
  @override
  void initState() {
    super.initState();
    _policies = widget.storePolicies;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Store Policies Preview',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                title: 'Return Policy',
                content: _policies['returnPolicy'] ?? 'No return policy defined.',
                icon: Icons.assignment_return,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              
              _buildSection(
                title: 'Shipping Policy',
                content: _policies['shippingPolicy'] ?? 'No shipping policy defined.',
                icon: Icons.local_shipping,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              
              _buildSection(
                title: 'Terms and Conditions',
                content: _policies['termsAndConditions'] ?? 'No terms and conditions defined.',
                icon: Icons.gavel,
                color: Colors.purple,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSection({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    final bool hasContent = content.isNotEmpty && content != 'No return policy defined.' && 
      content != 'No shipping policy defined.' && content != 'No terms and conditions defined.';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: hasContent ? Colors.grey.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasContent ? Colors.grey.shade300 : Colors.red.shade200,
            ),
          ),
          child: Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: hasContent ? Colors.grey[800] : Colors.red[700],
              fontStyle: hasContent ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}
