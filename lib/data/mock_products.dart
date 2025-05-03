import 'dart:convert';
import 'package:http/http.dart' as http;

class Product {
  final String id;
  final String name;
  final double price;
  final String description;
  final String imageUrl;
  final String category;
  final String sellerId;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.sellerId,
  });
}

// Mock data that simulates API response
final List<Product> mockProducts = [
  Product(
    id: '1',
    name: 'iPhone 13',
    price: 10000,
    description: 'Latest iPhone model with amazing features',
    imageUrl: 'assets/images/logo.png',
    category: 'Electronics',
    sellerId: 'seller1',
  ),
  Product(
    id: '2',
    name: 'Nike Air Max',
    price: 129.99,
    description: 'Comfortable running shoes',
    imageUrl: 'assets/images/logo.png',
    category: 'Fashion',
    sellerId: 'seller2',
  ),
  Product(
    id: '3',
    name: 'MacBook Pro',
    price: 1299.99,
    description: 'Powerful laptop for professionals',
    imageUrl: 'assets/images/logo.png',
    category: 'Electronics',
    sellerId: 'seller1',
  ),
  Product(
    id: '4',
    name: 'Coffee Maker',
    price: 79.99,
    description: 'Automatic coffee maker for your home',
    imageUrl: 'assets/images/logo.png',
    category: 'Home',
    sellerId: 'seller3',
  ),
];

// Helper functions to simulate API calls
class MockProductService {
  static const String apiUrl = 'https://fakestoreapi.com/products';

  // Get all products
  static Future<List<Product>> getAllProducts() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> products = json.decode(response.body);

        return products
            .map((product) => Product(
                  id: product['id'].toString(),
                  name: product['title'],
                  price: product['price'].toDouble(),
                  description: product['description'],
                  imageUrl: product['image'],
                  category: product['category'],
                  sellerId:
                      'store1', // Fake Store API doesn't have brand/seller
                ))
            .toList();
      } else {
        return mockProducts;
      }
    } catch (e) {
      return mockProducts;
    }
  }

  // Get product by ID
  static Future<Product?> getProductById(String id) async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/$id'));
      if (response.statusCode == 200) {
        final product = json.decode(response.body);
        return Product(
          id: product['id'].toString(),
          name: product['title'],
          price: product['price'].toDouble(),
          description: product['description'],
          imageUrl: product['image'],
          category: product['category'],
          sellerId: 'store1',
        );
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Get products by category
  static Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final response = await http.get(
          Uri.parse('https://fakestoreapi.com/products/category/$category'));
      if (response.statusCode == 200) {
        final List<dynamic> products = json.decode(response.body);

        return products
            .map((product) => Product(
                  id: product['id'].toString(),
                  name: product['title'],
                  price: product['price'].toDouble(),
                  description: product['description'],
                  imageUrl: product['image'],
                  category: product['category'],
                  sellerId: 'store1',
                ))
            .toList();
      } else {
        return mockProducts;
      }
    } catch (e) {
      return mockProducts;
    }
  }
}
