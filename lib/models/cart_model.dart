class CartModel {
  final String productId;
  final String userId;
  final String productName;
  final String imageURL;
  final double productPrice;
  final DateTime addedAt;

  CartModel({
    required this.productId,
    required this.userId,
    required this.productName,
    required this.imageURL,
    required this.productPrice,
    required this.addedAt,
  });

  // Convert WishlistModel to Map (for saving in Firebase)
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'userId': userId,
      'productName': productName,
      'imageURL': imageURL,
      'productPrice': productPrice,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  // Convert Map to CartModel (for reading from Firebase)
  factory CartModel.fromMap(Map<String, dynamic> map) {
    return CartModel(
      productId: map['productId'],
      userId: map['userId'],
      productName: map['productName'],
      imageURL: map['imageURL'],
      productPrice: map['productPrice'],
      addedAt: DateTime.parse(map['addedAt']),
    );
  }
}
