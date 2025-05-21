import 'dart:convert';
import 'package:http/http.dart' as http;

class ReportService {
  static const String baseUrl = 'http://parkingtest.atwebpages.com/api.php';

  static Future<Map<String, dynamic>> getStats() async {
    try {
      print('Getting system stats...');
      final response = await http.get(Uri.parse('$baseUrl?action=get_stats'));
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return data['stats'] ?? {};
        } else {
          throw Exception(data['message'] ?? 'Failed to load stats');
        }
      }
      throw Exception('Failed to load stats: ${response.statusCode}');
    } catch (e) {
      print('Error getting stats: $e');
      rethrow;
    }
  }
}
