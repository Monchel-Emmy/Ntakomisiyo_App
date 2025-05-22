import 'package:flutter/foundation.dart';
import 'package:ntakomisiyo1/models/product.dart';
import 'package:ntakomisiyo1/data/mock_products.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Product> _userProducts = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  List<Product> get userProducts => _userProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final products = await MockProductService.getAllProducts();
      _products = products;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserProducts(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final products = await MockProductService.getUserProducts(userId);
      _userProducts = products;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProduct(Product product) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newProduct = await MockProductService.addProduct(
        name: product.name,
        price: product.price,
        description: product.description,
        imageUrl: product.imageUrl,
        category: product.category,
        sellerId: product.sellerId,
        sellerPhone: product.sellerPhone,
      );

      if (newProduct != null) {
        _products.add(newProduct);
        if (newProduct.sellerId == product.sellerId) {
          _userProducts.add(newProduct);
        }
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
    }
  }

  Future<void> updateProduct(Product product) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await MockProductService.updateProduct(
        productId: product.id,
        name: product.name,
        price: product.price,
        description: product.description,
        imageUrl: product.imageUrl,
        category: product.category,
      );

      if (success) {
        final index = _products.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          _products[index] = product;
          final userIndex = _userProducts.indexWhere((p) => p.id == product.id);
          if (userIndex != -1) {
            _userProducts[userIndex] = product;
          }
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow; // Rethrow to handle in the UI
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await MockProductService.deleteProduct(id);
      if (success) {
        _products.removeWhere((product) => product.id == id);
        _userProducts.removeWhere((product) => product.id == id);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow; // Rethrow to handle in the UI
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
