import 'package:shared_preferences/shared_preferences.dart';
import 'admin_service.dart';

class AuthService {
  // Keys for SharedPreferences
  static const String _userLoginKey = 'user_login_state';
  static const String _userIdKey = 'user_id';
  static const String _userTypeKey = 'user_type';
  static const String _userNameKey = 'user_name';
  static const String _defaultRouteKey = 'default_route';
  static const String _onboardingCompletedKey = 'onboarding_completed';

  // User types
  static const String USER_TYPE_STUDENT = 'student';
  static const String USER_TYPE_ADMIN = 'admin';

  final AdminService _adminService = AdminService();

  // Save user login state
  Future<bool> saveUserLogin(String userId, String userType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_userLoginKey, true);
      await prefs.setString(_userIdKey, userId);
      await prefs.setString(_userTypeKey, userType);
      return true;
    } catch (e) {
      print('Error saving user login state: $e');
      return false;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_userLoginKey) ?? false;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Get logged in user type
  Future<String?> getUserType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userTypeKey);
    } catch (e) {
      print('Error getting user type: $e');
      return null;
    }
  }

  // Get logged in user ID
  Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userIdKey);
    } catch (e) {
      print('Error getting user ID: $e');
      return null;
    }
  }

  // Check if admin is logged in (uses AdminService)
  Future<bool> isAdminLoggedIn() async {
    return await _adminService.isLoggedIn();
  }

  // Logout user
  Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userType = await getUserType();

      // Clear user login data
      await prefs.remove(_userLoginKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_userTypeKey);

      // If admin, also logout from admin service
      if (userType == USER_TYPE_ADMIN) {
        await _adminService.logout();
      }

      return true;
    } catch (e) {
      print('Error logging out: $e');
      return false;
    }
  }

  // Check if onboarding is completed
  Future<bool> isOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingCompletedKey) ?? false;
    } catch (e) {
      print('Error checking onboarding status: $e');
      return false;
    }
  }

  // Mark onboarding as completed
  Future<bool> markOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompletedKey, true);
      return true;
    } catch (e) {
      print('Error marking onboarding as completed: $e');
      return false;
    }
  }

  // Save user name
  Future<bool> saveUserName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userNameKey, name);
      return true;
    } catch (e) {
      print('Error saving user name: $e');
      return false;
    }
  }

  // Get user name
  Future<String> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userNameKey) ?? '';
    } catch (e) {
      print('Error getting user name: $e');
      return '';
    }
  }

  // Save default route
  Future<bool> saveDefaultRoute(String route) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_defaultRouteKey, route);
      return true;
    } catch (e) {
      print('Error saving default route: $e');
      return false;
    }
  }

  // Get default route
  Future<String> getDefaultRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_defaultRouteKey) ?? '';
    } catch (e) {
      print('Error getting default route: $e');
      return '';
    }
  }
}
