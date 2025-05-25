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
      _searchQuery = query.trim();
      if (_searchQuery.isEmpty) {
        _filteredItems = helpItems;
      } else {
        _filteredItems = helpItems
            .where((item) =>
                item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                item.content.toLowerCase().contains(_searchQuery.toLowerCase()))
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
          
          // Main Content
          Expanded(
            child: _searchQuery.isEmpty 
                ? _buildMainContent()
                : _buildSearchResults(),
          ),
          
          // Contact Support Footer (always visible)
          _buildContactFooter(),
        ],
      ),
    );
  }

  // ✅ Main content when not searching
  Widget _buildMainContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Actions
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
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // Popular Topics Section
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Popular Topics',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildQuickTopicCard(
                        'Order Tracking',
                        Icons.local_shipping_outlined,
                        Colors.blue,
                        () => _showHelpDetail(_findHelpItem('tracking')),
                      ),
                      SizedBox(width: 12),
                      _buildQuickTopicCard(
                        'Payment Issues',
                        Icons.payment_outlined,
                        Colors.green,
                        () => _showHelpDetail(_findHelpItem('Payment')),
                      ),
                      SizedBox(width: 12),
                      _buildQuickTopicCard(
                        'Seller Guide',
                        Icons.store_outlined,
                        Colors.purple,
                        () => _showHelpDetail(_findHelpItem('seller')),
                      ),
                      SizedBox(width: 12),
                      _buildQuickTopicCard(
                        'App Features',
                        Icons.explore_outlined,
                        Colors.orange,
                        () => _showHelpDetail(_findHelpItem('Explore')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // Browse Help Topics
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Browse Help Topics',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),
                // Categories List
                ...helpCategories.map((category) => _buildCategoryCard(category)).toList(),
              ],
            ),
          ),
          
          SizedBox(height: 100), // Space for footer
        ],
      ),
    );
  }

  // ✅ Search results content
  Widget _buildSearchResults() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        return _buildHelpItemCard(item);
      },
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(category.icon, color: Colors.black, size: 20),
        ),
        title: Text(
          category.title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 15,
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
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          item.title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            item.content.length > 80 
                ? '${item.content.substring(0, 80)}...'
                : item.content,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios, 
          size: 16, 
          color: Colors.grey.shade400,
        ),
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

  Widget _buildQuickTopicCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Contact footer
  Widget _buildContactFooter() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
    );
  }

  // ✅ Helper method to safely find help items
  HelpItem _findHelpItem(String searchTerm) {
    try {
      return helpItems.firstWhere(
        (item) => item.title.toLowerCase().contains(searchTerm.toLowerCase()),
      );
    } catch (e) {
      // Return first item as fallback
      return helpItems.isNotEmpty ? helpItems.first : HelpItem(
        title: 'General Help',
        content: 'Welcome to Haul Help Center. How can we assist you today?',
      );
    }
  }
}