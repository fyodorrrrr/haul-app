// Create lib/screens/seller/stock_movements_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/inventory_provider.dart';
import '../../models/stock_movement.dart';
import 'package:intl/intl.dart';

class StockMovementsScreen extends StatefulWidget {
  @override
  _StockMovementsScreenState createState() => _StockMovementsScreenState();
}

class _StockMovementsScreenState extends State<StockMovementsScreen> {
  String _selectedFilter = 'All';
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false).fetchStockMovements();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Stock Movements',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'All', child: Text('All Movements')),
              PopupMenuItem(value: 'stockIn', child: Text('Stock In')),
              PopupMenuItem(value: 'stockOut', child: Text('Stock Out')),
              PopupMenuItem(value: 'sale', child: Text('Sales')),
              PopupMenuItem(value: 'returned', child: Text('Returns')),
              PopupMenuItem(value: 'adjustment', child: Text('Adjustments')),
            ],
          ),
        ],
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          final filteredMovements = _getFilteredMovements(provider.stockMovements);

          return Column(
            children: [
              _buildSummaryCard(filteredMovements),
              Expanded(
                child: filteredMovements.isEmpty
                    ? _buildEmptyState()
                    : _buildMovementsList(filteredMovements),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(List<StockMovement> movements) {
    final stockInCount = movements.where((m) => 
      m.type == StockMovementType.stockIn || m.type == StockMovementType.returned).length;
    final stockOutCount = movements.where((m) => m.type == StockMovementType.stockOut || m.type == StockMovementType.sale).length;
    final adjustmentCount = movements.where((m) => m.type == StockMovementType.adjustment).length;

    return Container(
      margin: EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.timeline, color: Colors.green[600]),
                  SizedBox(width: 8),
                  Text(
                    'Movement Summary',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  if (_selectedDateRange != null)
                    Chip(
                      label: Text(
                        '${DateFormat('MMM dd').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd').format(_selectedDateRange!.end)}',
                        style: GoogleFonts.poppins(fontSize: 10),
                      ),
                      deleteIcon: Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _selectedDateRange = null;
                        });
                      },
                    ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Stock In',
                      stockInCount.toString(),
                      Icons.add_circle,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'Stock Out',
                      stockOutCount.toString(),
                      Icons.remove_circle,
                      Colors.red,
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'Adjustments',
                      adjustmentCount.toString(),
                      Icons.edit,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMovementsList(List<StockMovement> movements) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: movements.length,
      itemBuilder: (context, index) {
        final movement = movements[index];
        return _buildMovementCard(movement);
      },
    );
  }

  Widget _buildMovementCard(StockMovement movement) {
    final isIncoming = movement.type == StockMovementType.stockIn || 
                      movement.type == StockMovementType.returned;
    final color = isIncoming ? Colors.green : Colors.red;
    final icon = _getMovementIcon(movement.type);

    return Card(
      elevation: 1,
      margin: EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movement.productName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'SKU: ${movement.sku}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${isIncoming ? '+' : '-'}${movement.quantity}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, HH:mm').format(movement.createdAt),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'Type',
                          _getMovementTypeLabel(movement.type),
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          'Previous Stock',
                          movement.previousStock.toString(),
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          'New Stock',
                          movement.newStock.toString(),
                        ),
                      ),
                    ],
                  ),
                  if (movement.reason.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.note, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            movement.reason,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (movement.reference != null) ...[
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.link, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          'Ref: ${movement.reference}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No stock movements found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Stock movements will appear here as you manage your inventory',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<StockMovement> _getFilteredMovements(List<StockMovement> movements) {
    List<StockMovement> filtered = movements;

    // Filter by type
    if (_selectedFilter != 'All') {
      final filterType = StockMovementType.values.firstWhere(
        (type) => type.name == _selectedFilter,
        orElse: () => StockMovementType.adjustment,
      );
      filtered = movements.where((m) => m.type == filterType).toList();
    }

    // Filter by date range
    if (_selectedDateRange != null) {
      filtered = filtered.where((movement) {
        final date = movement.createdAt;
        return date.isAfter(_selectedDateRange!.start.subtract(Duration(days: 1))) &&
               date.isBefore(_selectedDateRange!.end.add(Duration(days: 1)));
      }).toList();
    }

    return filtered;
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  IconData _getMovementIcon(StockMovementType type) {
    switch (type) {
      case StockMovementType.stockIn:
        return Icons.add_circle;
      case StockMovementType.stockOut:
        return Icons.remove_circle;
      case StockMovementType.sale:
        return Icons.shopping_cart;
      case StockMovementType.returned:
        return Icons.undo;
      case StockMovementType.adjustment:
        return Icons.edit;
      case StockMovementType.damaged:
        return Icons.broken_image;
      case StockMovementType.expired:
        return Icons.access_time;
      case StockMovementType.transfer:
        return Icons.swap_horiz;
      default:
        return Icons.timeline;
    }
  }

  String _getMovementTypeLabel(StockMovementType type) {
    switch (type) {
      case StockMovementType.stockIn:
        return 'Stock In';
      case StockMovementType.stockOut:
        return 'Stock Out';
      case StockMovementType.sale:
        return 'Sale';
      case StockMovementType.returned:
        return 'Return';
      case StockMovementType.adjustment:
        return 'Adjustment';
      case StockMovementType.damaged:
        return 'Damaged';
      case StockMovementType.expired:
        return 'Expired';
      case StockMovementType.transfer:
        return 'Transfer';
      default:
        return 'Unknown';
    }
  }
}