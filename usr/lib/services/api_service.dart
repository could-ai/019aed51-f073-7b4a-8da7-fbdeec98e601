import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class ApiService {
  // Default base URL, can be overwritten by user settings
  String baseUrl = 'https://pos.kheyalcafe.com/connector/api'; 
  
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('base_url') ?? baseUrl;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = await getBaseUrl();
    // Assuming standard OAuth or simple token endpoint. Adjust based on specific API docs.
    // UltimatePOS usually uses /oauth/token or a specific login endpoint.
    // Here we'll implement a generic structure that can be adapted.
    
    try {
      final response = await http.post(
        Uri.parse('$url/login'), // Adjust endpoint as needed
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'email': username, // or username
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', token);
          return {'success': true, 'data': data};
        }
      }
      return {'success': false, 'message': 'Invalid credentials'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<List<Product>> fetchProducts() async {
    final url = await getBaseUrl();
    final token = await getToken();
    
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$url/product'), // Standard UltimatePOS endpoint for products
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // UltimatePOS usually wraps data in a 'data' key
      final List<dynamic> productList = data['data'] ?? [];
      return productList.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products: ${response.statusCode}');
    }
  }

  Future<bool> syncOrder(Map<String, dynamic> orderData, List<Map<String, dynamic>> items) async {
    final url = await getBaseUrl();
    final token = await getToken();
    
    if (token == null) return false;

    // Construct the payload expected by the API
    final payload = {
      'sells': [
        {
          ...orderData,
          'payments': [], // Add payment logic if needed
          'products': items.map((item) => {
            'product_id': item['product_id'],
            'quantity': item['quantity'],
            'unit_price': item['unit_price'],
          }).toList(),
        }
      ]
    };

    try {
      final response = await http.post(
        Uri.parse('$url/sell'), // Endpoint for creating sales
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Sync error: $e');
      return false;
    }
  }
}
