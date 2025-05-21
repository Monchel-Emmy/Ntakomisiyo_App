import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ntakomisiyo1/models/user.dart';
import 'package:flutter/material.dart';
import 'package:ntakomisiyo1/screens/admin/admin_dashboard.dart';
import 'package:ntakomisiyo1/screens/user/user_dashboard.dart';

class AuthService {
  static const String baseUrl = 'http://parkingtest.atwebpages.com/api.php';
  static const String _userKey = 'current_user';

  static Future<User?> login(
      String phone, String password, BuildContext context) async {
    try {
      print('Making login request to: $baseUrl?action=login');
      print('Request body: phone=$phone, password=****');

      final response = await http.post(
        Uri.parse('$baseUrl?action=login'),
        body: {
          'phone': phone,
          'password': password,
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Check if response is HTML
        if (response.body.trim().startsWith('<')) {
          if (response.body.contains('Duplicate entry') &&
              response.body.contains('phone')) {
            throw Exception(
                'This phone number is already registered. Please use a different number or try logging in.');
          }
          throw Exception(
              'Server error: Received HTML response instead of JSON. Response: ${response.body}');
        }

        try {
          final Map<String, dynamic> data = json.decode(response.body);
          if (data['success'] == true && data['user'] != null) {
            final user = User.fromJson(data['user']);
            await _saveUser(user);

            // Navigate to appropriate dashboard
            if (context.mounted) {
              if (user.isAdmin) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const AdminDashboard(),
                  ),
                );
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => UserDashboard(user: user),
                  ),
                );
              }
            }

            return user;
          } else {
            throw Exception(data['message'] ?? 'Login failed');
          }
        } catch (e) {
          throw Exception(
              'Invalid response format: ${e.toString()}\nResponse body: ${response.body}');
        }
      }
      throw Exception(
          'Login failed: ${response.statusCode}\nResponse body: ${response.body}');
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  static Future<User?> register(
      String name, String phone, String password, BuildContext context) async {
    try {
      print('Making register request to: $baseUrl?action=register');
      print('Request body: name=$name, phone=$phone, password=****');

      final response = await http.post(
        Uri.parse('$baseUrl?action=register'),
        body: {
          'name': name,
          'phone': phone,
          'password': password,
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Check if response is HTML
        if (response.body.trim().startsWith('<')) {
          if (response.body.contains('Duplicate entry') &&
              response.body.contains('phone')) {
            throw Exception(
                'This phone number is already registered. Please use a different number or try logging in.');
          }
          throw Exception(
              'Server error: Received HTML response instead of JSON. Response: ${response.body}');
        }

        try {
          final Map<String, dynamic> data = json.decode(response.body);
          if (data['success'] == true) {
            // After successful registration, log the user in
            return await login(phone, password, context);
          } else {
            throw Exception(data['message'] ?? 'Registration failed');
          }
        } catch (e) {
          throw Exception(
              'Invalid response format: ${e.toString()}\nResponse body: ${response.body}');
        }
      }
      throw Exception(
          'Registration failed: ${response.statusCode}\nResponse body: ${response.body}');
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  static Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        return User.fromJson(json.decode(userJson));
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  static Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
  }

  static Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }

  static Future<bool> isAdmin() async {
    final user = await getCurrentUser();
    return user?.isAdmin ?? false;
  }

  static Future<void> updateProfile(User user) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=update_profile'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'user_id': user.id,
          'name': user.name,
          'phone': user.phone,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Failed to update profile');
        }
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  static Future<void> updatePassword(
      String currentPassword, String newPassword) async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl?action=update_password'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'user_id': currentUser.id,
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Failed to update password');
        }
      } else {
        throw Exception('Failed to update password: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating password: $e');
      throw Exception('Failed to update password: $e');
    }
  }

  static Future<List<User>> getAllUsers() async {
    try {
      print('Starting getAllUsers...');

      // Get current user
      final currentUser = await getCurrentUser();
      print('Current user: ${currentUser?.toJson()}');

      if (currentUser == null) {
        print('No current user found');
        throw Exception('Not logged in');
      }

      if (!currentUser.isAdmin) {
        print('Current user is not admin');
        throw Exception('Unauthorized access');
      }

      final url = '$baseUrl?action=get_users&admin_id=${currentUser.id}';
      print('Making get_users request to: $url');

      final response = await http.get(Uri.parse(url));
      print('Response status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Check if response is empty
        if (response.body.trim().isEmpty) {
          print('Empty response received');
          throw Exception('Empty response from server');
        }

        // Check if response is HTML instead of JSON
        if (response.body.trim().startsWith('<')) {
          print(
              'Received HTML response instead of JSON. Response body: ${response.body}');
          throw Exception('Server returned HTML instead of JSON');
        }

        try {
          final Map<String, dynamic> data = json.decode(response.body);
          print('Decoded JSON data: $data');

          if (data['success'] == true && data['users'] != null) {
            final List<dynamic> users = data['users'];
            print('Found ${users.length} users');

            final List<User> userList = users.map((user) {
              print('Processing user: $user');
              return User(
                id: user['id'].toString(),
                name: user['name'],
                phone: user['phone'],
                isAdmin: user['is_admin'] == 1,
              );
            }).toList();

            print('Successfully processed ${userList.length} users');
            return userList;
          } else {
            print('API returned error: ${data['message']}');
            throw Exception(data['message'] ?? 'Failed to load users');
          }
        } catch (e) {
          print('JSON parsing error: $e');
          print('Response body: ${response.body}');
          throw Exception('Invalid JSON response from server: $e');
        }
      }
      print('Request failed with status: ${response.statusCode}');
      throw Exception('Failed to load users: ${response.statusCode}');
    } catch (e) {
      print('Error in getAllUsers: $e');
      rethrow;
    }
  }

  static Future<void> deleteUser(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=delete_user'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'user_id': userId,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Failed to delete user');
        }
      } else {
        throw Exception('Failed to delete user');
      }
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }
}
