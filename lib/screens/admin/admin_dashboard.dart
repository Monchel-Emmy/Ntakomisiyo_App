import 'package:flutter/material.dart';
import 'package:ntakomisiyo1/screens/products/product_list_screen.dart';
import 'package:ntakomisiyo1/screens/admin/users_screen.dart';
import 'package:ntakomisiyo1/screens/admin/categories_screen.dart';
import 'package:ntakomisiyo1/screens/admin/reports_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildDashboardCard(
            'Products',
            Icons.shopping_bag,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ProductListScreen()),
              );
            },
          ),
          _buildDashboardCard(
            'Users',
            Icons.people,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UsersScreen()),
              );
            },
          ),
          _buildDashboardCard(
            'Categories',
            Icons.category,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CategoriesScreen()),
              );
            },
          ),
          _buildDashboardCard(
            'Reports',
            Icons.report,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
