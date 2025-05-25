import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../../models/help_models.dart';  // ✅ Add this
import '../../data/help_data.dart';     // ✅ Add this
import 'help_detail_screen.dart'; 

class HelpCenterScreen extends StatefulWidget {
  @override
  _HelpCenterScreenState createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  String _searchQuery = '';
  List<HelpItem> _filteredItems = [];
  
  @override
  void initState() {
    super.initState();
    _filteredItems = helpItems;
  }

  void _filterItems(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredItems = helpItems;
      } else {
        _filteredItems = helpItems
            .where((item) =>
                item.title.toLowerCase().contains(query.toLowerCase()) ||
                item.content.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Help Center',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16),
            child: TextField(
              onChanged: _filterItems,
              decoration: InputDecoration(
                hintText: 'Search for help...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
          ),
          
          // Quick Actions
          if (_searchQuery.isEmpty) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      _buildQuickAction(
                        icon: Icons.chat_bubble_outline,
                        title: 'Live Chat',
                        onTap: _openLiveChat,
                      ),
                      SizedBox(width: 12),
                      _buildQuickAction(
                        icon: Icons.email_outlined,
                        title: 'Email Us',
                        onTap: _sendEmail,
                      ),
                      SizedBox(width: 12),
                      _buildQuickAction(
                        icon: Icons.phone_outlined,
                        title: 'Call Us',
                        onTap: _makePhoneCall,
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Browse Help Topics',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12),
                ],
              ),
            ),
          ],
          
          // Help Categories/Items
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: _searchQuery.isEmpty ? helpCategories.length : _filteredItems.length,
              itemBuilder: (context, index) {
                if (_searchQuery.isEmpty) {
                  final category = helpCategories[index];
                  return _buildCategoryCard(category);
                } else {
                  final item = _filteredItems[index];
                  return _buildHelpItemCard(item);
                }
              },
            ),
          ),
          
          // Contact Support Footer
          Container(
            padding: EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Still need help?',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Our support team is available 24/7',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openLiveChat,
                            icon: Icon(Icons.chat),
                            label: Text('Live Chat'),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _sendEmail,
                            icon: Icon(Icons.email),
                            label: Text('Email Support'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, size: 24, color: Colors.black),
              SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(HelpCategory category) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(category.icon, color: Colors.black),
        title: Text(
          category.title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '${category.items.length} articles',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        children: category.items.map((item) => _buildHelpItemTile(item)).toList(),
      ),
    );
  }

  Widget _buildHelpItemCard(HelpItem item) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          item.title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          item.content.length > 100 
              ? '${item.content.substring(0, 100)}...'
              : item.content,
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showHelpDetail(item),
      ),
    );
  }

  Widget _buildHelpItemTile(HelpItem item) {
    return ListTile(
      title: Text(
        item.title,
        style: GoogleFonts.poppins(fontSize: 14),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 14),
      onTap: () => _showHelpDetail(item),
    );
  }

  void _showHelpDetail(HelpItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HelpDetailScreen(item: item),
      ),
    );
  }

  void _openLiveChat() {
    // Implement your live chat integration
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening live chat...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@haul.com',
      query: 'subject=Help Request&body=Please describe your issue:',
    );
    
    try {
      await launchUrl(emailUri);
    } catch (e) {
      // Fallback: Copy email to clipboard
      await Clipboard.setData(ClipboardData(text: 'support@haul.com'));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email copied to clipboard: support@haul.com'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _makePhoneCall() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+1-800-HAUL-HELP');
    
    try {
      await launchUrl(phoneUri);
    } catch (e) {
      // Fallback: Copy phone number to clipboard
      await Clipboard.setData(ClipboardData(text: '+1-800-HAUL-HELP'));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Phone number copied: +1-800-HAUL-HELP'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}