import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class RouteService {
  // URL to JSONBin.io
  String get _jsonUrl {
    return 'https://api.jsonbin.io/v3/b/67eee4bd8561e97a50f83b09/latest';
  }

  Future<List<Map<String, dynamic>>> getRoutes({bool forceRefresh = false}) async {
    try {
      // Try to fetch from remote source first
      final response = await http.get(
        Uri.parse(_jsonUrl),
        headers: {
          'Cache-Control': 'no-cache',
          'X-Bin-Meta': 'false', // To get only the JSON data without metadata
        },
      );

      if (response.statusCode == 200) {
        print('Successfully loaded routes from remote source');
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('Failed to load routes from server: ${response.statusCode}');
        // Fallback to local data
        return await _getLocalRoutes();
      }
    } catch (e) {
      print('Error fetching routes: $e');
      // Fallback to local data if network fetch fails
      return await _getLocalRoutes();
    }
  }

  // Fallback method to load local data
  Future<List<Map<String, dynamic>>> _getLocalRoutes() async {
    print('Loading routes from local assets');
    // Load from local assets as a fallback
    final String response = await rootBundle.loadString('assets/database.json');
    final List<dynamic> data = json.decode(response);
    return List<Map<String, dynamic>>.from(data);
  }
}
