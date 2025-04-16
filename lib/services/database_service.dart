import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/route_service.dart';

class DatabaseService {
  final RouteService _routeService = RouteService();

  // JSONBin.io API endpoints and key
  final String _jsonBinUrl =
      'https://api.jsonbin.io/v3/b/67eee4bd8561e97a50f83b09';
  // Fixed API key format by escaping the dollar sign
  final String _jsonBinApiKey =
      r'$2a$10$R5e8yO0TEYXKSwWV4cRHXuA2J/iIpNp5fo.KzfV4ygmR8IT99TQdG';

  // Get current database
  Future<List<Map<String, dynamic>>> getDatabase() async {
    return await _routeService.getRoutes();
  }

  // Update database
  Future<bool> updateDatabase(List<Map<String, dynamic>> newData) async {
    try {
      // Convert data to JSON string
      final String jsonData = json.encode(newData);

      print('Updating database with data length: ${newData.length}');
      print('Request URL: $_jsonBinUrl');

      // Send PUT request to update JSONBin
      final response = await http
          .put(
            Uri.parse(_jsonBinUrl),
            headers: {
              'Content-Type': 'application/json',
              'X-Master-Key': _jsonBinApiKey,
              'X-Bin-Versioning': 'false', // Overwrite the current version
            },
            body: jsonData,
          )
          .timeout(Duration(seconds: 15));

      print('Response status code: ${response.statusCode}');
      
      // For debugging, print a shorter version of the response body
      if (response.body.length > 100) {
        print('Response body (truncated): ${response.body.substring(0, 100)}...');
      } else {
        print('Response body: ${response.body}');
      }

      // JSONBin.io returns 200 status code on success
      if (response.statusCode == 200) {
        // The response contains a "record" field with the updated data
        // We consider it a success if we get a 200 status code
        print('Update successful based on status code 200');
        return true;
      } else {
        print('Failed to update database. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error updating database: $e');
      return false;
    }
  }

  // Add a new route
  Future<bool> addRoute(Map<String, dynamic> newRoute) async {
    try {
      final database = await getDatabase();
      database.add(newRoute);
      return await updateDatabase(database);
    } catch (e) {
      print('Error adding route: $e');
      return false;
    }
  }

  // Update an existing route
  Future<bool> updateRoute(int index, Map<String, dynamic> updatedRoute) async {
    try {
      final database = await getDatabase();
      print('Database size: ${database.length}, Updating index: $index');

      if (index >= 0 && index < database.length) {
        database[index] = updatedRoute;
        return await updateDatabase(database);
      } else {
        print('Invalid index: $index for database of size ${database.length}');
        return false;
      }
    } catch (e) {
      print('Error updating route: $e');
      return false;
    }
  }

  // Delete a route
  Future<bool> deleteRoute(int index) async {
    try {
      final database = await getDatabase();
      if (index >= 0 && index < database.length) {
        database.removeAt(index);
        return await updateDatabase(database);
      }
      return false;
    } catch (e) {
      print('Error deleting route: $e');
      return false;
    }
  }
}
