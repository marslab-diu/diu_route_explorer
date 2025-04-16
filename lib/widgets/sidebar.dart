import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';

class Sidebar extends StatelessWidget {
  // Create a direct instance of AuthService instead of using Provider
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final backgroundColor = isDarkMode ? Color(0xFF121212) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final dividerColor = isDarkMode ? Colors.grey[800] : Colors.grey[300];

    return Drawer(
      backgroundColor: backgroundColor,
      child: Column(
        children: [
          // Purple header with app description
          Container(
            width: double.infinity,
            height: 240,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            color: const Color.fromARGB(255, 88, 13, 218),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DIU Route Explorers is a university bus schedule app that allows students to check bus routes, start and departure times, and important notes for a smooth commuting experience.',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.2,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Menu items with improved spacing
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading: Icon(
              Icons.schedule,
              color: isDarkMode ? Colors.white : null,
            ),
            title: Text(
              'Bus Schedule',
              style: GoogleFonts.inter(fontSize: 16, color: textColor),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/bus_schedule');
            },
          ),

          Divider(height: 1, thickness: 0.5, color: dividerColor),

          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading: Icon(
              Icons.route,
              color: isDarkMode ? Colors.white : null,
            ),
            title: Text(
              'Route Information',
              style: GoogleFonts.inter(fontSize: 16, color: textColor),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/route_information');
            },
          ),

          Divider(height: 1, thickness: 0.5, color: dividerColor),

          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading: Icon(
              Icons.notifications,
              color: isDarkMode ? Colors.white : null,
            ),
            title: Text(
              'Notifications',
              style: GoogleFonts.inter(fontSize: 16, color: textColor),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/notifications');
            },
          ),

          Divider(height: 1, thickness: 0.5, color: dividerColor),

          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading: Icon(
              Icons.settings,
              color: isDarkMode ? Colors.white : null,
            ),
            title: Text(
              'Settings',
              style: GoogleFonts.inter(fontSize: 16, color: textColor),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),

          Divider(height: 1, thickness: 0.5, color: dividerColor),

          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading: Icon(
              Icons.help,
              color: isDarkMode ? Colors.white : null,
            ),
            title: Text(
              'Help and Support',
              style: GoogleFonts.inter(fontSize: 16, color: textColor),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/help_support');
            },
          ),

          Divider(height: 1, thickness: 0.5, color: dividerColor),

          // Logout at the bottom with red text
          Spacer(),
          Divider(height: 1, thickness: 0.5, color: dividerColor),

          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text(
              'Logout',
              style: GoogleFonts.inter(color: Colors.red, fontSize: 16),
            ),
            onTap: () async {
              try {
                // Close the drawer
                Navigator.pop(context);

                // Use the direct instance of AuthService to properly logout
                await _authService.logout();

                // Navigate to login screen
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (Route<dynamic> route) => false,
                );
              } catch (e) {
                print('Error during logout: $e');
                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Logout failed. Please try again.'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );

                // Even if logout fails, attempt to navigate to login screen
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (Route<dynamic> route) => false,
                );
              }
            },
          ),

          // Version and footer
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              children: [
                Text(
                  'Version 1.0.1',
                  style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
                ),
                SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Made with ",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey : Colors.black54,
                      ),
                    ),
                    Icon(Icons.favorite, color: Colors.red, size: 12),
                    Text(
                      " by ",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey : Colors.black54,
                      ),
                    ),
                    Text(
                      "MarsLab",
                      style: GoogleFonts.inter(
                        color: Color.fromARGB(255, 88, 13, 218),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
