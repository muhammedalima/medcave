import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Default server URL - matches the server.js file
  static String baseUrl = 'https://medcave-server.onrender.com';
  static bool _isInitialized = false;

  // Initialize the API service by retrieving the server URL
  static Future<void> initialize() async {
    try {
      // If already initialized, return immediately
      if (_isInitialized) return;

      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('server_url');

      // Always use the saved URL first if available, without testing connection
      if (savedUrl != null && savedUrl.isNotEmpty) {
        baseUrl = savedUrl;
        if (kDebugMode) {
          print('Using saved server URL: $baseUrl');
        }
      } else {
        // Save the default URL if none was saved before
        await prefs.setString('server_url', baseUrl);
        if (kDebugMode) {
          print('No saved server URL found, using default: $baseUrl');
        }
      }

      // Mark as initialized even if the connection test fails
      _isInitialized = true;

      // Test connection in the background without blocking initialization
      _testConnection();
    } catch (e) {
      if (kDebugMode) {
        print('Error in ApiService initialization: $e');
      }
      // Use default URL as fallback and mark as initialized
      baseUrl = 'https://medcave-server.onrender.com';
      _isInitialized = true;
    }
  }

  // Test connection without blocking initialization
  static Future<void> _testConnection() async {
    try {
      if (kDebugMode) {
        print('Testing connection to server URL: $baseUrl');
      }

      // Attempt to connect with a longer timeout
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/server-info'),
          )
          .timeout(const Duration(seconds: 20)); // Longer timeout for Render

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Connection to server successful');
          print('Server info: ${response.body}');
        }
      } else {
        if (kDebugMode) {
          print('Server returned error status: ${response.statusCode}');
          print('Response body: ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Warning: Cannot connect to server URL: $e');
        // Don't revert to default URL automatically, just log the warning
      }
    }
  }

  // Set and save a new server URL
  static Future<void> setServerUrl(String url) async {
    if (url.isEmpty) return;

    // Ensure URL has proper format with http/https
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', url);

    if (kDebugMode) {
      print('Server URL updated and saved: $baseUrl');
    }

    // Test connection to the new URL
    _testConnection();
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

  // Get user authentication token
  static Future<String?> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      return await user.getIdToken();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting auth token: $e');
      }
      throw Exception('Failed to get authentication token');
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
          .timeout(const Duration(seconds: 30)); // Increased timeout for Render

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

      // Get auth token
      final token = await _getAuthToken();

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/notify-drivers'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'requestId': requestId}),
          )
          .timeout(const Duration(seconds: 30)); // Increased timeout for Render

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(
            'Failed to notify drivers: ${errorData['error'] ?? response.body}');
      }

      if (kDebugMode) {
        print('Drivers notified successfully');
        print('Response: ${response.body}');
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
      // Get auth token
      final token = await _getAuthToken();

      final response = await http.get(
        Uri.parse('$baseUrl/api/notification-status/$requestId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30)); // Increased timeout for Render

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
            'Failed to get notification status: ${errorData['error'] ?? response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting notification status: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> expandRadius(String requestId) async {
    try {
      if (kDebugMode) {
        print('Expanding radius for request: $requestId');
      }

      // Get auth token
      final token = await _getAuthToken();

      final response = await http.post(
        Uri.parse('$baseUrl/api/expand-radius/$requestId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30)); // Increased timeout for Render

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (kDebugMode) {
          print(
              'Radius expanded successfully to ${responseData['newRadius']}km');
        }
        return responseData;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
            'Failed to expand radius: ${errorData['error'] ?? response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error expanding radius: $e');
      }
      rethrow;
    }
  }

  // Register FCM token with the server
  Future<void> registerFCMToken(String fcmToken) async {
    try {
      if (kDebugMode) {
        print('Registering FCM token with server: $fcmToken');
      }

      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get auth token
      final token = await _getAuthToken();

      // Update the token in Firestore directly
      // (this assumes you have a 'drivers' collection with the user's UID as the document ID)
      // Note: This would typically be done through a server endpoint, but this is a direct approach
      await http
          .post(
            Uri.parse('$baseUrl/api/update-fcm-token'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'fcmToken': fcmToken,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (kDebugMode) {
        print('FCM token registered successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error registering FCM token: $e');
      }
      // Don't throw the error - just log it, as this shouldn't block the app
    }
  }
}
