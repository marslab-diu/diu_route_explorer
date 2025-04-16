import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  // Public JSON URL for notifications
  final String _notificationsUrl = 'https://api.jsonbin.io/v3/b/67efe2438561e97a50f89e92/latest';
  
  // Cache key for notifications
  final String _cacheKey = 'cached_notifications';

  // Get notifications from API or cache
  Future<List<dynamic>> getNotifications({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      // Try to get from cache first
      final cachedData = await _getFromCache();
      if (cachedData != null) {
        return cachedData;
      }
    }

    try {
      // Make API request
      final response = await http.get(
        Uri.parse(_notificationsUrl),
        headers: {
          'X-Bin-Meta': 'false',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = response.body;
        print('Response body: $responseBody');
        
        // Try to parse the response body
        final dynamic data = json.decode(responseBody);
        List<dynamic> notifications = [];
        
        // Check if data is directly a list
        if (data is List) {
          notifications = data;
        } 
        // Check if data has a record field that is a list
        else if (data is Map && data.containsKey('record') && data['record'] is List) {
          notifications = data['record'];
        }
        // If record is a string, try to parse it as JSON
        else if (data is Map && data.containsKey('record') && data['record'] is String) {
          try {
            final recordData = json.decode(data['record']);
            if (recordData is List) {
              notifications = recordData;
            }
          } catch (e) {
            print('Error parsing record as JSON: $e');
            // If parsing fails, use an empty list
            notifications = [];
          }
        }
        
        // Ensure each item has a unique ID if not already present
        for (int i = 0; i < notifications.length; i++) {
          if (!notifications[i].containsKey('id')) {
            notifications[i]['id'] = i + 1;
          }
        }
        
        // Cache the data
        await _cacheData(notifications);
        
        return notifications;
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      // If network request fails, try to get from cache
      final cachedData = await _getFromCache();
      if (cachedData != null) {
        return cachedData;
      }
      throw Exception('Failed to load notifications: $e');
    }
  }

  // Cache notifications data
  Future<void> _cacheData(List<dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(data);
      await prefs.setString(_cacheKey, jsonString);
      print('Notifications cached successfully');
    } catch (e) {
      print('Error caching notifications: $e');
    }
  }

  // Get cached notifications
  Future<List<dynamic>?> _getFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      
      if (jsonString != null) {
        final data = json.decode(jsonString);
        print('Loaded notifications from cache');
        return List<dynamic>.from(data);
      }
      return null;
    } catch (e) {
      print('Error loading notifications from cache: $e');
      return null;
    }
  }
}