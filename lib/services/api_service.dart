import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "https://rabinchaudhary.com/api";

  static Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // LOGIN method
  static Future<Map<String, dynamic>?> login(String email, String password, bool remember) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
        'remember': remember ? 'true' : 'false',
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // returns {"user":..., "token":...}
    } else {
      return null;
    }
  }

  // Generic GET method
  static Future<List<dynamic>?> getData(String endpoint) async {
    String? token = await getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/$endpoint"),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    }
    return null;
  }

  // Generic DELETE method
  static Future<bool> deleteData(String endpoint, int id) async {
    String? token = await getToken();
    final response = await http.delete(
      Uri.parse("$baseUrl/$endpoint/$id"),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
  }

  // Inside ApiService class
  static Future<bool> createData(String endpoint, Map<String, dynamic> data) async {
    String? token = await getToken();
    final response = await http.post(
      Uri.parse("$baseUrl/$endpoint"),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    return response.statusCode == 201;
  }

  static Future<bool> updateData(String endpoint, int id, Map<String, dynamic> data) async {
    String? token = await getToken();
    final response = await http.put(
      Uri.parse("$baseUrl/$endpoint/$id"),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

// Add more generic methods (POST, PUT) if needed
}