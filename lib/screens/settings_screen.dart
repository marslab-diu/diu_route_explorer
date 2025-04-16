import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../services/route_service.dart';
import 'dart:convert';
import 'dart:async';
import '../widgets/sidebar.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final RouteService _routeService = RouteService();
  final String _cacheKey = 'cached_route_data';
  final String _defaultRouteKey = 'default_route';

  bool _pushNotifications = true;
  String _selectedDefaultRoute = '';

  List<String> _availableRoutes = [];
  bool _isLoading = true;
  String currentTime = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(Duration(minutes: 1), (timer) => _updateTime());
    _loadSettings();
    _loadRouteData();
  }

  void _updateTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : now.hour;
    final hourString = hour == 0 ? '12' : hour.toString();
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';

    setState(() {
      currentTime = '$hourString:$minute $period';
    });
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _pushNotifications = prefs.getBool('push_notifications') ?? true;
        _selectedDefaultRoute = prefs.getString(_defaultRouteKey) ?? '';
      });
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('push_notifications', _pushNotifications);
      await prefs.setString(_defaultRouteKey, _selectedDefaultRoute);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Settings updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error saving settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadRouteData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _routeService.getRoutes();
      _processRouteData(data);
    } catch (e) {
      print('Error loading route data: $e');
      _loadFromCache();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);

      if (jsonString != null) {
        final data = json.decode(jsonString);
        _processRouteData(List<dynamic>.from(data));
      }
    } catch (e) {
      print('Error loading from cache: $e');
    }
  }

  void _processRouteData(List<dynamic> data) {
    // Get all unique routes
    Set<String> uniqueRoutes = {};

    for (var route in data) {
      String routeCode = route['Route'];
      String routeName = route['Route Name'];
      uniqueRoutes.add('$routeCode - $routeName');
    }

    setState(() {
      _availableRoutes = uniqueRoutes.toList();

      // If no default route is selected yet, and we have routes available
      if (_selectedDefaultRoute.isEmpty && _availableRoutes.isNotEmpty) {
        _selectedDefaultRoute = _availableRoutes[0];
        _saveSettings();
      } else if (!_availableRoutes.contains(_selectedDefaultRoute) &&
          _availableRoutes.isNotEmpty) {
        // If the saved default route is no longer available
        _selectedDefaultRoute = _availableRoutes[0];
        _saveSettings();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final backgroundColor = isDarkMode ? Color(0xFF121212) : Colors.white;
    final primaryColor = Color.fromARGB(255, 88, 13, 218);

    return Scaffold(
      backgroundColor: primaryColor,
      endDrawer: _buildSidebar(context),
      body: Stack(
        children: [
          // Fixed purple header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              width: double.infinity,
              color: primaryColor,
              padding: EdgeInsets.only(
                top: 60,
                bottom: 15,
                left: 20,
                right: 20,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 26,
                        ),
                        onPressed: _loadRouteData,
                      ),
                      Builder(
                        builder:
                            (context) => IconButton(
                              icon: Icon(
                                Icons.menu,
                                color: Colors.white,
                                size: 30,
                              ),
                              onPressed: () {
                                Scaffold.of(context).openEndDrawer();
                              },
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Scrollable content area
          Positioned(
            top: 140,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(30),
                  ),
                ),
                child:
                    _isLoading
                        ? Center(
                          child: CircularProgressIndicator(color: primaryColor),
                        )
                        : SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Default Route Section
                              Text(
                                'Select Default Route',
                                style: GoogleFonts.inter(
                                  color:
                                      isDarkMode ? Colors.white : primaryColor,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:
                                        isDarkMode
                                            ? Colors.grey.shade700
                                            : Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value:
                                        _availableRoutes.contains(
                                              _selectedDefaultRoute,
                                            )
                                            ? _selectedDefaultRoute
                                            : (_availableRoutes.isNotEmpty
                                                ? _availableRoutes[0]
                                                : null),
                                    isExpanded: true,
                                    icon: Icon(
                                      Icons.arrow_drop_down,
                                      color:
                                          isDarkMode
                                              ? Colors.white
                                              : Colors.black54,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    dropdownColor: backgroundColor,
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          _selectedDefaultRoute = newValue;
                                        });
                                        _saveSettings();
                                      }
                                    },
                                    items:
                                        _availableRoutes
                                            .map<DropdownMenuItem<String>>((
                                              String value,
                                            ) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(
                                                  value,
                                                  style: TextStyle(
                                                    color: textColor,
                                                  ),
                                                ),
                                              );
                                            })
                                            .toList(),
                                  ),
                                ),
                              ),

                              SizedBox(height: 24),

                              // Push Notification Toggle
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Push Notification',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: textColor,
                                    ),
                                  ),
                                  Switch(
                                    value: false, // Force disabled state
                                    onChanged: (value) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Push notifications coming soon!',
                                          ),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    activeColor: primaryColor,
                                  ),
                                ],
                              ),

                              SizedBox(height: 16),

                              // Dark Mode Toggle
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Dark Mode',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: textColor,
                                    ),
                                  ),
                                  Switch(
                                    value: themeProvider.isDarkMode,
                                    onChanged: (value) {
                                      themeProvider.toggleTheme();
                                    },
                                    activeColor: primaryColor,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildSidebar(BuildContext context) {
    return Sidebar();
  }
}
