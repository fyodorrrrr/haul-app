// Create lib/models/stock_movement.dart
class StockMovement {
  final String id;
  final String productId;
  final String productName;
  final String sku;
  final StockMovementType type;
  final int quantity;
  final int previousStock;
  final int newStock;
  final String reason;
  final String? reference; // Order ID, PO ID, etc.
  final String location;
  final String sellerId;
  final DateTime createdAt;
  final String createdBy;

  StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.type,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    required this.reason,
    this.reference,
    required this.location,
    required this.sellerId,
    required this.createdAt,
    required this.createdBy,
  });

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      sku: map['sku'] ?? '',
      type: StockMovementType.values.firstWhere((t) => t.name == map['type']),
      quantity: map['quantity'] ?? 0,
      previousStock: map['previousStock'] ?? 0,
      newStock: map['newStock'] ?? 0,
      reason: map['reason'] ?? '',
      reference: map['reference'],
      location: map['location'] ?? '',
      sellerId: map['sellerId'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      createdBy: map['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'sku': sku,
      'type': type.name,
      'quantity': quantity,
      'previousStock': previousStock,
      'newStock': newStock,
      'reason': reason,
      'reference': reference,
      'location': location,
      'sellerId': sellerId,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }
}

enum StockMovementType {
  stockIn,        // Adding stock
  stockOut,       // Removing stock
  sale,           // Stock sold
  returned,       // Stock returned
  adjustment,     // Manual adjustment
  damaged,        // Damaged goods
  expired,        // Expired products
  transfer,       // Transfer between locations
}