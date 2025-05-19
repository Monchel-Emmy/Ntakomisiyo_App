import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ntakomisiyo1/models/product.dart';

class StorageService {
  static const String _productsKey = 'cached_products';

  static Future<void> cacheProducts(List<Product> products) async {
    final prefs = await SharedPreferences.getInstance();
    final productsJson = products.map((product) => product.toJson()).toList();
    await prefs.setString(_productsKey, json.encode(productsJson));
  }

  static Future<List<Product>> getCachedProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final productsJson = prefs.getString(_productsKey);
      if (productsJson == null) return [];

      final List<dynamic> decodedProducts = json.decode(productsJson);
      return decodedProducts.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error loading cached products: ${e.toString()}');
      return [];
    }
  }
}
