class WishlistModel {
  final String productId;
  final String userId;
  final String productName;
  final String productImage;
  final double productPrice;
  final DateTime addedAt;

  WishlistModel({
    required this.productId,
    required this.userId,
    required this.productName,
    required this.productImage,
    required this.productPrice,
    required this.addedAt,
  });

  // Convert WishlistModel to Map (for saving in Firebase)
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'userId': userId,
      'productName': productName,
      'productImage': productImage,
      'productPrice': productPrice,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  // Convert Map to WishlistModel (for reading from Firebase)
  factory WishlistModel.fromMap(Map<String, dynamic> map) {
    return WishlistModel(
      productId: map['productId'],
      userId: map['userId'],
      productName: map['productName'],
      productImage: map['productImage'],
      productPrice: map['productPrice'],
      addedAt: DateTime.parse(map['addedAt']),
    );
  }

   bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(addedAt);
    return difference.inDays < 3;
  }
}
