import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ntakomisiyo1/models/category.dart';

class CategoryService {
  static const String baseUrl = 'http://parkingtest.atwebpages.com/api.php';

  static Future<List<Category>> getAllCategories() async {
    try {
      print('Getting all categories...');
      final response =
          await http.get(Uri.parse('$baseUrl?action=get_categories'));
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true && data['categories'] != null) {
          final List<dynamic> categories = data['categories'];
          return categories
              .map((category) => Category.fromJson(category))
              .toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load categories');
        }
      }
      throw Exception('Failed to load categories: ${response.statusCode}');
    } catch (e) {
      print('Error getting categories: $e');
      rethrow;
    }
  }

  static Future<void> addCategory(String name) async {
    try {
      print('Adding category: $name');
      final response = await http.post(
        Uri.parse('$baseUrl?action=add_category'),
        body: {
          'name': name,
        },
      );
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Failed to add category');
        }
      } else {
        throw Exception('Failed to add category: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding category: $e');
      rethrow;
    }
  }

  static Future<void> deleteCategory(String categoryId) async {
    try {
      print('Deleting category: $categoryId');
      final response = await http.post(
        Uri.parse('$baseUrl?action=delete_category'),
        body: {
          'category_id': categoryId,
        },
      );
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Failed to delete category');
        }
      } else {
        throw Exception('Failed to delete category: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting category: $e');
      rethrow;
    }
  }
}
