import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AdminService {
  // URL to JSONBin.io containing admin credentials
  final String _credentialsUrl =
      'https://api.jsonbin.io/v3/b/67eee4d28a456b7966820659/latest';

  // Token storage key
  final String _tokenKey = 'admin_auth_token';

  // Authenticate admin
  Future<bool> login(String username, String password) async {
    try {
      print('Attempting to login with username: $username');
      print('Fetching credentials from: $_credentialsUrl');

      // Fetch credentials from remote source
      final response = await http.get(
        Uri.parse(_credentialsUrl),
        headers: {
          'X-Bin-Meta': 'false', // To get only the JSON data without metadata
        },
      );

      print('Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('Response body: ${response.body}');

        final Map<String, dynamic> credentials = json.decode(response.body);
        print('Parsed credentials: $credentials');

        // Check if credentials match
        final bool usernameMatches = credentials['username'] == username;
        final bool passwordMatches = credentials['password'] == password;

        print('Username matches: $usernameMatches');
        print('Password matches: $passwordMatches');

        if (usernameMatches && passwordMatches) {
          try {
            // Store authentication token
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_tokenKey, _generateToken(username));
            print('Login successful');
            return true;
          } catch (e) {
            // If SharedPreferences fails, still return true since credentials matched
            print('SharedPreferences error: $e');
            return true;
          }
        }
      }
      print('Login failed');
      return false;
    } catch (e) {
      print('Error authenticating admin: $e');
      return false;
    }
  }

  // Check if admin is logged in
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      return token != null;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Logout admin
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (e) {
      print('Error logging out: $e');
    }
  }

  // Generate a simple token (in a real app, use a more secure method)
  String _generateToken(String username) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return base64Encode(utf8.encode('$username:$timestamp'));
  }
}
