import 'package:flutter/foundation.dart';
import 'package:ntakomisiyo1/models/product.dart';
import 'package:ntakomisiyo1/data/database_helper.dart';
import 'package:ntakomisiyo1/data/mock_products.dart';

class FavoritesProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Product> _favorites = [];
  bool _isLoading = false;

  List<Product> get favorites => _favorites;
  bool get isLoading => _isLoading;

  Future<void> loadFavorites() async {
    _isLoading = true;
    notifyListeners();

    _favorites = await _dbHelper.getFavorites();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleFavorite(Product product) async {
    await _dbHelper.toggleFavorite(product);
    await loadFavorites();
  }

  Future<bool> isFavorite(String productId) async {
    return await _dbHelper.isFavorite(productId);
  }
}
