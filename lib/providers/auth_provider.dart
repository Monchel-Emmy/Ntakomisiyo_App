import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ntakomisiyo1/models/user.dart';
import 'package:ntakomisiyo1/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;

  Future<void> checkAuthStatus() async {
    // _isLoading = true;
    // notifyListeners();

    try {
      _user = await AuthService.getCurrentUser();
      print('User after checkAuthStatus: ${_user?.toJson()}');
      print('Is Admin: ${_user?.isAdmin}');
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(
      String phone, String password, BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await AuthService.login(phone, password, context);
      print('User after login: ${_user?.toJson()}');
      print('Is Admin: ${_user?.isAdmin}');
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(
      String name, String phone, String password, BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await AuthService.register(name, phone, password, context);
      print('User after register: ${_user?.toJson()}');
      print('Is Admin: ${_user?.isAdmin}');
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await AuthService.logout();
      _user = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
