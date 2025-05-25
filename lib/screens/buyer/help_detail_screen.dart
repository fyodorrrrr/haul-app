import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/help_models.dart';

class HelpDetailScreen extends StatelessWidget {
  final HelpItem item;

  HelpDetailScreen({required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Help',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _shareArticle(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              item.content,
              style: GoogleFonts.poppins(
                fontSize: 16,
                height: 1.6,
              ),
            ),
            if (item.steps.isNotEmpty) ...[
              SizedBox(height: 24),
              Text(
                'Step-by-step guide:',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12),
              ...item.steps.asMap().entries.map((entry) {
                int index = entry.key;
                String step = entry.value;
                return Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          step,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
            SizedBox(height: 32),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Was this article helpful?',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _provideFeedback(context, false),
                            icon: Icon(Icons.thumb_down_outlined),
                            label: Text('No'),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _provideFeedback(context, true),
                            icon: Icon(Icons.thumb_up_outlined),
                            label: Text('Yes'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
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
            SizedBox(height: 16),
            Card(
              color: Colors.blue.shade50,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.support_agent,
                        size: 32,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Need more help?',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Our support team is here to help you with any questions about thrift shopping on Haul.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _contactSupport(context),
                        icon: Icon(Icons.headset_mic),
                        label: Text(
                          'Contact Support',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareArticle(BuildContext context) {
    Clipboard.setData(ClipboardData(text: '${item.title}\n\n${item.content}'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Article copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _provideFeedback(BuildContext context, bool helpful) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(helpful 
            ? 'Thanks for your feedback! 👍' 
            : 'Thanks for your feedback. We\'ll improve this article. 📝'),
        backgroundColor: helpful ? Colors.green : Colors.orange,
      ),
    );
  }

  void _contactSupport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildContactSupportModal(context),
    );
  }

  Widget _buildContactSupportModal(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            
            // Header
            Text(
              'Contact Support',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Choose how you\'d like to get help',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            
            // Contact Options
            _buildContactOption(
              context,
              icon: Icons.chat_bubble_outline,
              title: 'Live Chat',
              subtitle: 'Chat with our support team',
              color: Colors.blue,
              onTap: () => _openLiveChat(context),
            ),
            SizedBox(height: 12),
            _buildContactOption(
              context,
              icon: Icons.email_outlined,
              title: 'Email Support',
              subtitle: 'Send us an email',
              color: Colors.green,
              onTap: () => _sendSupportEmail(context),
            ),
            SizedBox(height: 12),
            _buildContactOption(
              context,
              icon: Icons.phone_outlined,
              title: 'Call Us',
              subtitle: '+1-800-HAUL-HELP',
              color: Colors.orange,
              onTap: () => _makePhoneCall(context),
            ),
            SizedBox(height: 12),
            _buildContactOption(
              context,
              icon: Icons.bug_report_outlined,
              title: 'Report Bug',
              subtitle: 'Report a technical issue',
              color: Colors.red,
              onTap: () => _reportBug(context),
            ),
            
            SizedBox(height: 24),
            
            // Response Time Info
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: Colors.grey.shade600, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Average response time: 2-4 hours',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required Color color,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    ),
  );
}

  void _openLiveChat(BuildContext context) {
  Navigator.pop(context); // Close modal
  
  // Show loading then simulate opening chat
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Connecting to support...'),
        ],
      ),
    ),
  );
  
  // Simulate connection delay
  Future.delayed(Duration(seconds: 2), () {
    Navigator.pop(context); // Close loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.chat, color: Colors.white),
            SizedBox(width: 8),
            Text('Live chat opened! A support agent will be with you shortly.'),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  });
}

void _sendSupportEmail(BuildContext context) async {
  Navigator.pop(context); // Close modal
  
  try {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@haul.com',
      query: 'subject=Help Request - ${item.title}&body=Hi Haul Support Team,\n\nI need help with: ${item.title}\n\nMy question/issue:\n\n\nThanks!',
    );
    
    await launchUrl(emailUri);
  } catch (e) {
    // Fallback: Copy email and show instructions
    await Clipboard.setData(ClipboardData(text: 'support@haul.com'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email app not found. Email address copied!'),
            SizedBox(height: 4),
            Text(
              'Send your question to: support@haul.com',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 4),
      ),
    );
  }
}

void _makePhoneCall(BuildContext context) async {
  Navigator.pop(context); // Close modal
  
  try {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+18004285435'); // HAUL-HELP
    await launchUrl(phoneUri);
  } catch (e) {
    await Clipboard.setData(ClipboardData(text: '+1-800-HAUL-HELP'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.phone, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text('Phone number copied: +1-800-HAUL-HELP'),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

void _reportBug(BuildContext context) {
  Navigator.pop(context); // Close modal
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Report Bug',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Help us improve Haul by reporting bugs or technical issues.',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          SizedBox(height: 16),
          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Describe the issue you encountered...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Bug report submitted. Thank you!'),
                backgroundColor: Colors.green,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text('Submit'),
        ),
      ],
    ),
  );
}
}