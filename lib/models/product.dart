class Product {
  final String id;
  final String name;
  final double price;
  final String description;
  final String imageUrl;
  final String category;
  final String sellerId;
  final String sellerPhone;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.sellerId,
    required this.sellerPhone,
    required this.createdAt,
  });

  // Factory constructor to create a Product from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      category: json['category'] as String,
      sellerId: json['sellerId'] as String,
      sellerPhone: json['sellerPhone'] as String? ??
          '+250780600494', // default phone if not provided
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  // Convert Product to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'sellerId': sellerId,
      'sellerPhone': sellerPhone,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
