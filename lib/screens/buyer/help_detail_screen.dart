import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
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
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
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
                          style: GoogleFonts.poppins(fontSize: 14),
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
            ? 'Thanks for your feedback!' 
            : 'Thanks for your feedback. We\'ll improve this article.'),
        backgroundColor: helpful ? Colors.green : Colors.orange,
      ),
    );
  }
}