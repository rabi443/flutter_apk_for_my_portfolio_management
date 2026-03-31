import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "https://rabinchaudhary.com/api";

  // Get stored token
  static Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // LOGIN
  static Future<Map<String, dynamic>?> login(
      String email, String password, bool remember) async {
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
      return jsonDecode(response.body);
    }
    return null;
  }

  static Future forgotPassword(String email) async {
    var response = await http.post(
      Uri.parse('$baseUrl/forgot-password'),
      body: {
        'email': email,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  // GET DATA (IMPORTANT FIX)
  static Future<List<dynamic>> getData(String endpoint) async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/$endpoint"),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    // ✅ SUCCESS
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data'] ?? [];
    }

    // 🔥 HANDLE UNAUTHORIZED
    if (response.statusCode == 401) {
      throw Exception("unauthorized");
    }

    throw Exception("Failed to load data");
  }

  // GET UNREAD COUNT (NEW)
  static Future<int> getUnreadCount() async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/contact-messages"),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['unread_count'] ?? 0;
    }

    if (response.statusCode == 401) {
      throw Exception("unauthorized");
    }

    return 0;
  }

  // DELETE
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

  // CREATE
  static Future<bool> createData(
      String endpoint, Map<String, dynamic> data) async {
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

  // UPDATE
  static Future<bool> updateData(
      String endpoint, int id, Map<String, dynamic> data) async {
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
}