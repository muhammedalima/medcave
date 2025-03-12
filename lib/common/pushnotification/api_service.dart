import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Default value - will be updated with the actual server URL
  static String baseUrl = 'http://192.168.0.1:3000';

  // Initialize the API service by retrieving the server URL
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('server_url');

      if (savedUrl != null && savedUrl.isNotEmpty) {
        baseUrl = savedUrl;
        if (kDebugMode) {
          print('Using saved server URL: $baseUrl');
        }

        // Test connection to server URL
        try {
          final response = await http
              .get(
                Uri.parse('$baseUrl/api/server-info'),
              )
              .timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            if (kDebugMode) {
              print('Connection to server successful');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Warning: Cannot connect to saved server URL: $e');
          }
          // Don't throw - just log the warning
        }
      } else {
        if (kDebugMode) {
          print('No saved server URL found, using default: $baseUrl');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in ApiService initialization: $e');
      }
      // Use default URL as fallback
      baseUrl = 'http://192.168.0.1:3000';
    }
  }

  // Set and save a new server URL
  static Future<void> setServerUrl(String url) async {
    if (url.isEmpty) return;

    baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', url);

    if (kDebugMode) {
      print('Server URL updated and saved: $baseUrl');
    }
  }

  // Update the server URL from FCM notification payload
  static void updateServerUrlFromNotification(Map<String, dynamic> data) {
    if (data.containsKey('serverUrl')) {
      final serverUrl = data['serverUrl'];
      if (serverUrl != null && serverUrl.toString().isNotEmpty) {
        setServerUrl(serverUrl.toString());
      }
    }
  }

  // Get server info to verify connection and update configuration
  Future<Map<String, dynamic>> getServerInfo() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/server-info'),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Update the base URL if it's different
        if (data.containsKey('url')) {
          await ApiService.setServerUrl(data['url']);
        }

        return data;
      } else {
        throw Exception('Failed to get server info: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting server info: $e');
      }
      rethrow;
    }
  }

  Future<void> notifyDrivers(String requestId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final token = await user.getIdToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/notify-drivers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'requestId': requestId}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to notify drivers: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error notifying drivers: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getNotificationStatus(String requestId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final token = await user.getIdToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/notification-status/$requestId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get notification status: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting notification status: $e');
      }
      rethrow;
    }
  }

  Future<void> expandRadius(String requestId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final token = await user.getIdToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/expand-radius/$requestId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to expand radius: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error expanding radius: $e');
      }
      rethrow;
    }
  }
}
