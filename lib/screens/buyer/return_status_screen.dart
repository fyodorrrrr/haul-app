import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ReturnStatusScreen extends StatefulWidget {
  const ReturnStatusScreen({Key? key}) : super(key: key);

  @override
  _ReturnStatusScreenState createState() => _ReturnStatusScreenState();
}

class _ReturnStatusScreenState extends State<ReturnStatusScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _returnRequests = [];
  String _selectedStatusFilter = 'all';

  final List<Map<String, String>> _statusFilters = [
    {'value': 'all', 'label': 'All Returns', 'icon': '📦'},
    {'value': 'pending', 'label': 'Pending', 'icon': '⏳'},
    {'value': 'approved', 'label': 'Approved', 'icon': '✅'},
    {'value': 'in_transit', 'label': 'In Transit', 'icon': '🚚'},
    {'value': 'completed', 'label': 'Completed', 'icon': '💰'},
    {'value': 'rejected', 'label': 'Rejected', 'icon': '❌'},
  ];

  @override
  void initState() {
    super.initState();
    _loadReturnRequests();
  }

  Future<void> _loadReturnRequests() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('returns')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> returns = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        returns.add(data);
      }

      setState(() {
        _returnRequests = returns;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading return requests: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getFilteredReturns() {
    if (_selectedStatusFilter == 'all') {
      return _returnRequests;
    }
    return _returnRequests
        .where((request) => request['status'] == _selectedStatusFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Return Status',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadReturnRequests,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStatusFilterTabs(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadReturnRequests,
                    child: _buildReturnsList(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusFilterTabs() {
    return Container(
      color: Colors.white,
      child: Container(
        height: 60,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: _statusFilters.length,
          itemBuilder: (context, index) {
            final filter = _statusFilters[index];
            final isSelected = _selectedStatusFilter == filter['value'];
            final count = filter['value'] == 'all'
                ? _returnRequests.length
                : _returnRequests
                    .where((r) => r['status'] == filter['value'])
                    .length;

            return Container(
              margin: EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedStatusFilter = filter['value']!;
                  });
                },
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(filter['icon']!),
                    SizedBox(width: 4),
                    Text(
                      '${filter['label']} ($count)',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                selectedColor: Theme.of(context).primaryColor,
                backgroundColor: Colors.grey[100],
                checkmarkColor: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildReturnsList() {
    final filteredReturns = _getFilteredReturns();

    if (filteredReturns.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredReturns.length,
      itemBuilder: (context, index) {
        return _buildReturnCard(filteredReturns[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_return,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 24),
            Text(
              _selectedStatusFilter == 'all'
                  ? 'No Return Requests'
                  : 'No ${_statusFilters.firstWhere((f) => f['value'] == _selectedStatusFilter)['label']} Returns',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 12),
            Text(
              _selectedStatusFilter == 'all'
                  ? 'You haven\'t made any return requests yet.'
                  : 'Try selecting a different status filter.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (_selectedStatusFilter != 'all') ...[
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedStatusFilter = 'all';
                  });
                },
                child: Text('Show All Returns'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReturnCard(Map<String, dynamic> returnRequest) {
    final status = returnRequest['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final createdAt = returnRequest['createdAt'] is Timestamp
        ? (returnRequest['createdAt'] as Timestamp).toDate()
        : DateTime.now();
    final items = returnRequest['items'] as List? ?? [];

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: statusColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Status Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(status),
                    color: statusColor,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    _getStatusText(status).toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Spacer(),
                  Text(
                    'Return #${returnRequest['id'].substring(0, 8)}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Return Content
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Information
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              returnRequest['orderNumber'] ?? 'Order #${returnRequest['orderId']?.substring(0, 12)}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Requested: ${DateFormat('MMM d, yyyy').format(createdAt)}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${items.length} item${items.length != 1 ? 's' : ''}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  // Return Reason
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            returnRequest['reason'] ?? 'No reason provided',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  // Progress Tracker
                  _buildProgressTracker(status),

                  SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showReturnDetails(returnRequest),
                          icon: Icon(Icons.info_outline, size: 16),
                          label: Text(
                            'View Details',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: BorderSide(color: statusColor),
                            foregroundColor: statusColor,
                          ),
                        ),
                      ),
                      if (status == 'pending') ...[
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showCancelReturnDialog(returnRequest),
                            icon: Icon(Icons.cancel, size: 16),
                            label: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressTracker(String status) {
    final steps = [
      {'title': 'Submitted', 'status': 'pending'},
      {'title': 'Approved', 'status': 'approved'},
      {'title': 'In Transit', 'status': 'in_transit'},
      {'title': 'Completed', 'status': 'completed'},
    ];

    int currentStepIndex = steps.indexWhere((step) => step['status'] == status);
    if (currentStepIndex == -1) currentStepIndex = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Return Progress',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: steps.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, String> step = entry.value;
            bool isActive = index <= currentStepIndex;
            bool isCurrent = index == currentStepIndex;

            return Expanded(
              child: Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.blue : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCurrent ? Icons.radio_button_checked : Icons.check,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        step['title']!,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isActive ? Colors.blue : Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isActive ? Colors.blue : Colors.grey[300],
                        margin: EdgeInsets.only(bottom: 20),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'in_transit':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'approved':
        return Icons.check_circle;
      case 'in_transit':
        return Icons.local_shipping;
      case 'completed':
        return Icons.monetization_on;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending Review';
      case 'approved':
        return 'Approved';
      case 'in_transit':
        return 'In Transit';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  void _showReturnDetails(Map<String, dynamic> returnRequest) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Return Details',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem('Return ID', returnRequest['id'].substring(0, 12)),
                    _buildDetailItem('Order Number', returnRequest['orderNumber'] ?? 'N/A'),
                    _buildDetailItem('Status', _getStatusText(returnRequest['status'] ?? '')),
                    _buildDetailItem('Reason', returnRequest['reason'] ?? 'N/A'),
                    if (returnRequest['description']?.isNotEmpty == true)
                      _buildDetailItem('Description', returnRequest['description']),
                    SizedBox(height: 16),
                    Text(
                      'Items to Return',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    ...(returnRequest['items'] as List? ?? []).map((item) {
                      final itemData = item['item'] as Map<String, dynamic>? ?? {};
                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    itemData['name'] ?? 'Product Name',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '₱${(itemData['price'] ?? 0).toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.green[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Qty: ${item['quantity'] ?? 1}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelReturnDialog(Map<String, dynamic> returnRequest) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Return Request',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to cancel this return request? This action cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Keep Request'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelReturnRequest(returnRequest['id']);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Cancel Request'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelReturnRequest(String returnId) async {
    try {
      await FirebaseFirestore.instance
          .collection('returns')
          .doc(returnId)
          .update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Return request cancelled successfully'),
          backgroundColor: Colors.green,
        ),
      );

      _loadReturnRequests(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling return request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}