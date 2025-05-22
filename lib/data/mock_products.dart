import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ntakomisiyo1/services/storage_service.dart';
import 'package:ntakomisiyo1/models/product.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ntakomisiyo1/services/firebase_messaging_service.dart';

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
    sellerPhone: '+250780600494',
    createdAt: DateTime.now(),
  ),
  Product(
    id: '2',
    name: 'Nike Air Max',
    price: 129.99,
    description: 'Comfortable running shoes',
    imageUrl: 'assets/images/logo.png',
    category: 'Fashion',
    sellerId: 'seller2',
    sellerPhone: '+250780600494',
    createdAt: DateTime.now(),
  ),
  Product(
    id: '3',
    name: 'MacBook Pro',
    price: 1299.99,
    description: 'Powerful laptop for professionals',
    imageUrl: 'assets/images/logo.png',
    category: 'Electronics',
    sellerId: 'seller1',
    sellerPhone: '+250780600494',
    createdAt: DateTime.now(),
  ),
  Product(
    id: '4',
    name: 'Coffee Maker',
    price: 79.99,
    description: 'Automatic coffee maker for your home',
    imageUrl: 'assets/images/logo.png',
    category: 'Home',
    sellerId: 'seller3',
    sellerPhone: '+250780600494',
    createdAt: DateTime.now(),
  ),
];

// Helper functions to simulate API calls
class MockProductService {
  static const String baseUrl = 'http://parkingtest.atwebpages.com/api.php';
  static const int maxRetries = 2;
  static const Duration retryDelay = Duration(seconds: 2);

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<List<Product>> getAllProducts() async {
    int retryCount = 0;
    while (retryCount <= maxRetries) {
      try {
        print(
            'Attempting to fetch products from API (attempt ${retryCount + 1})...');
        final response = await http.get(Uri.parse('$baseUrl?action=products'));

        if (response.statusCode == 200) {
          // Check if response is HTML instead of JSON
          if (response.body.trim().startsWith('<')) {
            print(
                'Received HTML response instead of JSON. Response body: ${response.body}');
            throw Exception('Server returned HTML instead of JSON');
          }

          try {
            final Map<String, dynamic> data = json.decode(response.body);
            if (data['success'] == true && data['products'] != null) {
              print('Successfully fetched products from API');
              final List<dynamic> products = data['products'];
              final List<Product> apiProducts = products.map((product) {
                print(
                    'Processing product: ${product['name']} with seller_phone: ${product['seller_phone']}');
                return Product(
                  id: product['id'].toString(),
                  name: product['name'] ?? 'Untitled Product',
                  price: double.tryParse(product['price'].toString()) ?? 0.0,
                  description:
                      product['description'] ?? 'No description available',
                  imageUrl:
                      product['imageUrl'] ?? 'assets/images/placeholder.png',
                  category: product['category'] ?? 'Other',
                  sellerId: product['sellerId']?.toString() ?? 'unknown',
                  sellerPhone: product['seller_phone'] ?? '+250780600494',
                  createdAt: DateTime.tryParse(product['createdAt'] ?? '') ??
                      DateTime.now(),
                );
              }).toList();

              // Store API data for offline use
              await StorageService.cacheProducts(apiProducts);
              return apiProducts;
            } else {
              print('API returned error: ${data['message']}');
              throw Exception('API returned error: ${data['message']}');
            }
          } catch (e) {
            print('JSON parsing error: $e');
            print('Response body: ${response.body}');
            throw Exception('Invalid JSON response from server');
          }
        }
        print('API request failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception(
            'API request failed with status: ${response.statusCode}');
      } catch (e) {
        print('Network error: $e');
        retryCount++;

        if (retryCount <= maxRetries) {
          print('Retrying in ${retryDelay.inSeconds} seconds...');
          await Future.delayed(retryDelay);
          continue;
        }

        print(
            'All retry attempts failed. Attempting to use cached products...');
        // Try to get cached data
        final cachedProducts = await StorageService.getCachedProducts();
        if (cachedProducts.isNotEmpty) {
          print('Successfully loaded ${cachedProducts.length} cached products');
          return cachedProducts;
        }

        // If no cached data, use mock data
        print('No cached products found. Using mock products...');
        return mockProducts;
      }
    }
    return mockProducts;
  }

  static Future<Product?> getProductById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=products'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true && data['products'] != null) {
          final List<dynamic> products = data['products'];
          final product = products.firstWhere(
            (p) => p['id'].toString() == id,
            orElse: () => throw Exception('Product not found'),
          );
          return Product(
            id: product['id'].toString(),
            name: product['title'],
            price: double.parse(product['price'].toString()),
            description: product['description'],
            imageUrl: product['image_url'] ?? 'assets/images/placeholder.png',
            category: product['category'] ?? 'Other',
            sellerId: product['user_id'].toString(),
            sellerPhone: product['seller_phone'] ?? '+250780600494',
            createdAt: DateTime.parse(
                product['created_at'] ?? DateTime.now().toIso8601String()),
          );
        }
      }
      throw Exception('Product not found');
    } catch (e) {
      print('Network error: $e');
      // Try to get from cached data
      final cachedProducts = await StorageService.getCachedProducts();
      return cachedProducts.firstWhere(
        (p) => p.id == id,
        orElse: () => mockProducts.firstWhere(
          (p) => p.id == id,
          orElse: () => throw Exception('Product not found'),
        ),
      );
    }
  }

  static Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=products'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true && data['products'] != null) {
          final List<dynamic> products = data['products'];
          return products
              .where((product) => (product['category'] ?? 'Other') == category)
              .map((product) => Product(
                    id: product['id'].toString(),
                    name: product['title'],
                    price: double.parse(product['price'].toString()),
                    description: product['description'],
                    imageUrl:
                        product['image_url'] ?? 'assets/images/placeholder.png',
                    category: product['category'] ?? 'Other',
                    sellerId: product['user_id'].toString(),
                    sellerPhone: product['seller_phone'] ?? '+250780600494',
                    createdAt: DateTime.parse(product['created_at'] ??
                        DateTime.now().toIso8601String()),
                  ))
              .toList();
        }
      }
      throw Exception('Category request failed');
    } catch (e) {
      print('Network error: $e');
      // Try to get from cached data
      final cachedProducts = await StorageService.getCachedProducts();
      final categoryProducts =
          cachedProducts.where((p) => p.category == category).toList();
      if (categoryProducts.isNotEmpty) {
        return categoryProducts;
      }
      // Fall back to mock data
      return mockProducts.where((p) => p.category == category).toList();
    }
  }

  static Future<Product?> addProduct({
    required String name,
    required double price,
    required String description,
    required String imageUrl,
    required String category,
    required String sellerId,
    required String sellerPhone,
  }) async {
    try {
      print('Making add product request with data:');
      print('name: $name');
      print('price: $price');
      print('description: $description');
      print('imageUrl: $imageUrl');
      print('category: $category');
      print('sellerId: $sellerId');
      print('sellerPhone: $sellerPhone');

      final response = await http.post(
        Uri.parse('$baseUrl?action=add_product'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'title': name,
          'description': description,
          'price': price.toString(),
          'image_url': imageUrl,
          'category': category,
          'seller_id': sellerId,
          'seller_phone': sellerPhone,
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          // Show local notification after successful product addition
          try {
            print('Showing local notification for new product...');
            await FirebaseMessagingService.notifications.show(
              DateTime.now().millisecond,
              'Hello, New Product Added! 🎉',
              '$name has been added with price $price\nContact seller: $sellerPhone',
              NotificationDetails(
                android: AndroidNotificationDetails(
                  'product_channel',
                  'Product Notifications',
                  channelDescription: 'Notifications for product updates',
                  importance: Importance.max,
                  priority: Priority.high,
                  icon: '@mipmap/ic_launcher',
                ),
                iOS: const DarwinNotificationDetails(),
              ),
              payload: json.encode({
                'product_id': data['product_id'],
                'category': category,
                'type': 'new_product',
                'seller_phone': sellerPhone,
              }),
            );
            print('Local notification shown successfully');
          } catch (e) {
            print('Error showing local notification: $e');
          }

          return Product(
            id: data['product_id'].toString(),
            name: name,
            price: price,
            description: description,
            imageUrl: imageUrl,
            category: category,
            sellerId: sellerId,
            sellerPhone: sellerPhone,
            createdAt: DateTime.now(),
          );
        } else {
          throw Exception(data['message'] ?? 'Failed to add product');
        }
      }
      throw Exception('Failed to add product: ${response.statusCode}');
    } catch (e) {
      print('Error adding product: $e');
      rethrow;
    }
  }

  static Future<List<Product>> getUserProducts(String userId) async {
    int retryCount = 0;
    while (retryCount <= maxRetries) {
      try {
        print(
            'Attempting to fetch user products from API (attempt ${retryCount + 1})...');
        final response = await http
            .get(Uri.parse('$baseUrl?action=user_products&user_id=$userId'));

        if (response.statusCode == 200) {
          if (response.body.trim().startsWith('<')) {
            print(
                'Received HTML response instead of JSON. Response body: ${response.body}');
            throw Exception('Server returned HTML instead of JSON');
          }

          try {
            final Map<String, dynamic> data = json.decode(response.body);
            if (data['success'] == true && data['products'] != null) {
              print('Successfully fetched user products from API');
              final List<dynamic> products = data['products'];
              final List<Product> apiProducts = products.map((product) {
                print(
                    'Processing user product: ${product['name']} with seller_phone: ${product['seller_phone']}');
                return Product(
                  id: product['id'].toString(),
                  name: product['name'] ?? 'Untitled Product',
                  price: double.tryParse(product['price'].toString()) ?? 0.0,
                  description:
                      product['description'] ?? 'No description available',
                  imageUrl:
                      product['imageUrl'] ?? 'assets/images/placeholder.png',
                  category: product['category'] ?? 'Other',
                  sellerId: product['sellerId']?.toString() ?? 'unknown',
                  sellerPhone: product['seller_phone'] ?? '+250780600494',
                  createdAt: DateTime.tryParse(product['createdAt'] ?? '') ??
                      DateTime.now(),
                );
              }).toList();

              return apiProducts;
            } else {
              print('API returned error: ${data['message']}');
              throw Exception('API returned error: ${data['message']}');
            }
          } catch (e) {
            print('JSON parsing error: $e');
            print('Response body: ${response.body}');
            throw Exception('Invalid JSON response from server');
          }
        }
        print('API request failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception(
            'API request failed with status: ${response.statusCode}');
      } catch (e) {
        print('Network error: $e');
        retryCount++;

        if (retryCount <= maxRetries) {
          print('Retrying in ${retryDelay.inSeconds} seconds...');
          await Future.delayed(retryDelay);
          continue;
        }

        // If all retries fail, return empty list
        print('All retry attempts failed. Returning empty list.');
        return [];
      }
    }
    return [];
  }

  static Future<bool> deleteProduct(String productId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=delete_product'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'product_id': productId,
        },
      );

      if (response.statusCode == 200) {
        // Check if response is HTML instead of JSON
        if (response.body.trim().startsWith('<')) {
          print(
              'Received HTML response instead of JSON. Response body: ${response.body}');
          throw Exception('Server returned HTML instead of JSON');
        }

        try {
          final Map<String, dynamic> data = json.decode(response.body);
          if (data['success'] == true) {
            print('Successfully deleted product from API');
            return true;
          } else {
            print('API returned error: ${data['message']}');
            throw Exception('API returned error: ${data['message']}');
          }
        } catch (e) {
          print('JSON parsing error: $e');
          print('Response body: ${response.body}');
          throw Exception('Invalid JSON response from server');
        }
      }
      print('API request failed with status: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to delete product: ${response.statusCode}');
    } catch (e) {
      print('Error deleting product: $e');
      throw Exception('Failed to delete product: $e');
    }
  }

  static Future<bool> updateProduct({
    required String productId,
    required String name,
    required double price,
    required String description,
    required String imageUrl,
    required String category,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=edit_product'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'product_id': productId,
          'title': name,
          'description': description,
          'price': price.toString(),
          'image_url':
              imageUrl.isEmpty ? 'assets/images/placeholder.png' : imageUrl,
          'category': category,
        },
      );

      if (response.statusCode == 200) {
        // Check if response is HTML instead of JSON
        if (response.body.trim().startsWith('<')) {
          print(
              'Received HTML response instead of JSON. Response body: ${response.body}');
          throw Exception('Server returned HTML instead of JSON');
        }

        try {
          final Map<String, dynamic> data = json.decode(response.body);
          if (data['success'] == true) {
            print('Successfully updated product in API');
            return true;
          } else {
            print('API returned error: ${data['message']}');
            throw Exception('API returned error: ${data['message']}');
          }
        } catch (e) {
          print('JSON parsing error: $e');
          print('Response body: ${response.body}');
          throw Exception('Invalid JSON response from server');
        }
      }
      print('API request failed with status: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to update product: ${response.statusCode}');
    } catch (e) {
      print('Error updating product: $e');
      throw Exception('Failed to update product: $e');
    }
  }
}
