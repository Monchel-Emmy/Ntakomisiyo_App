import 'package:flutter/material.dart';
import 'package:ntakomisiyo1/services/report_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final stats = await ReportService.getStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceStats() {
    final priceStats = _stats['price_stats'] ?? {};
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Price Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPriceStatRow('Minimum Price',
                'Frw ${priceStats['min_price']?.toStringAsFixed(2) ?? '0.00'}'),
            _buildPriceStatRow('Maximum Price',
                'Frw ${priceStats['max_price']?.toStringAsFixed(2) ?? '0.00'}'),
            _buildPriceStatRow('Average Price',
                'Frw ${priceStats['avg_price']?.toStringAsFixed(2) ?? '0.00'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDistribution() {
    final distribution = _stats['category_distribution'] ?? [];
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Distribution',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...distribution.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['category'] ?? '',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      '${item['count']} products',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_error',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadStats,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'System Overview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 2.5,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                          children: [
                            _buildStatCard(
                              'Total Users',
                              _stats['total_users']?.toString() ?? '0',
                              Icons.people,
                              Colors.blue,
                            ),
                            _buildStatCard(
                              'Total Products',
                              _stats['total_products']?.toString() ?? '0',
                              Icons.shopping_bag,
                              Colors.green,
                            ),
                            _buildStatCard(
                              'Total Categories',
                              _stats['total_categories']?.toString() ?? '0',
                              Icons.category,
                              Colors.orange,
                            ),
                            _buildStatCard(
                              'Active Sellers',
                              _stats['active_sellers']?.toString() ?? '0',
                              Icons.store,
                              Colors.purple,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildPriceStats(),
                        const SizedBox(height: 16),
                        _buildCategoryDistribution(),
                        const SizedBox(height: 16),
                        const Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_stats['recent_products'] != null)
                          ...(_stats['recent_products'] as List).map((product) {
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                leading:
                                    const Icon(Icons.shopping_bag, size: 24),
                                title: Text(
                                  product['name'] ?? '',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Price: \$${product['price']?.toString() ?? '0'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      'Seller: ${product['seller_name'] ?? ''}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                trailing: Text(
                                  'Added: ${product['created_at'] ?? ''}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            );
                          }).toList(),
                      ],
                    ),
                  ),
                ),
    );
  }
}
