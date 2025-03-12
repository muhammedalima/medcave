import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Updated default value to your server URL
  static String baseUrl = 'https://medcave-server.onrender.com';

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
              .timeout(const Duration(seconds: 10)); // Increased timeout for Render

          if (response.statusCode == 200) {
            if (kDebugMode) {
              print('Connection to server successful');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Warning: Cannot connect to saved server URL: $e');
            print('Reverting to default server URL: https://medcave-server.onrender.com');
          }
          // If connection fails, revert to default server URL
          baseUrl = 'https://medcave-server.onrender.com';
          await prefs.setString('server_url', baseUrl);
        }
      } else {
        // Save the default URL if none was saved before
        await prefs.setString('server_url', baseUrl);
        if (kDebugMode) {
          print('No saved server URL found, using default: $baseUrl');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in ApiService initialization: $e');
      }
      // Use default URL as fallback
      baseUrl = 'https://medcave-server.onrender.com';
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
      if (kDebugMode) {
        print('Fetching server info from: $baseUrl/api/server-info');
      }
      
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/server-info'),
          )
          .timeout(const Duration(seconds: 15)); // Increased timeout for Render

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (kDebugMode) {
          print('Server info received: $data');
        }

        // Update the base URL if it's different
        if (data.containsKey('url')) {
          await ApiService.setServerUrl(data['url']);
        }

        return data;
      } else {
        if (kDebugMode) {
          print('Server returned status code: ${response.statusCode}');
          print('Response body: ${response.body}');
        }
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
      if (kDebugMode) {
        print('Notifying drivers for request: $requestId');
        print('Using server URL: $baseUrl');
      }
      
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
      ).timeout(const Duration(seconds: 30)); // Increased timeout for Render

      if (response.statusCode != 200) {
        throw Exception('Failed to notify drivers: ${response.body}');
      }
      
      if (kDebugMode) {
        print('Drivers notified successfully');
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
      ).timeout(const Duration(seconds: 15)); // Increased timeout for Render

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
      if (kDebugMode) {
        print('Expanding radius for request: $requestId');
      }
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final token = await user.getIdToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/expand-radius/$requestId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15)); // Increased timeout for Render

      if (response.statusCode != 200) {
        throw Exception('Failed to expand radius: ${response.body}');
      }
      
      if (kDebugMode) {
        print('Radius expanded successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error expanding radius: $e');
      }
      rethrow;
    }
  }
}