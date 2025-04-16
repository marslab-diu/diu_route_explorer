import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';
import 'route_editor_screen.dart';
import 'dart:async';

class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Removed unused AdminService field
  final DatabaseService _databaseService = DatabaseService();

  List<Map<String, dynamic>> _routes = [];
  bool _isLoading = true;
  String _filterSchedule = 'All';
  String _searchQuery = '';
  String currentTime = '';
  String adminName = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
    _updateTime();
    _timer = Timer.periodic(Duration(minutes: 1), (timer) => _updateTime());
    _loadAdminName();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadAdminName() async {
    try {
      final AuthService authService = AuthService();
      final name = await authService.getUserName();
      setState(() {
        adminName = name;
      });
    } catch (e) {
      print('Error loading admin name: $e');
    }
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

  Future<void> _loadRoutes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final routes = await _databaseService.getDatabase();
      setState(() {
        _routes = routes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading routes: $e');
      setState(() {
        _isLoading = false;
      });

      // Only show error message if the context is still valid
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load routes: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Add this method to handle SharedPreferences errors
  Future<void> _safeLogout() async {
    try {
      // Use AuthService for consistent logout experience
      final authService = AuthService();
      await authService.logout();
    } catch (e) {
      print('Error during logout: $e');
      // Continue with navigation even if logout fails
    }

    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  List<Map<String, dynamic>> _getFilteredRoutes() {
    return _routes.where((route) {
      // Apply schedule filter
      if (_filterSchedule != 'All' && route['Schedule'] != _filterSchedule) {
        return false;
      }

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final routeName = route['Route Name']?.toString().toLowerCase() ?? '';
        final routeCode = route['Route']?.toString().toLowerCase() ?? '';
        final searchLower = _searchQuery.toLowerCase();

        return routeName.contains(searchLower) ||
            routeCode.contains(searchLower);
      }

      return true;
    }).toList();
  }

  // Replace the existing _logout method with this one
  Future<void> _logout() async {
    // Use the safe logout method instead
    await _safeLogout();
  }

  Future<void> _deleteRoute(int index) async {
    final filteredRoutes = _getFilteredRoutes();
    final routeToDelete = filteredRoutes[index];
    final originalIndex = _routes.indexOf(routeToDelete);

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Confirm Delete'),
                content: Text('Are you sure you want to delete this route?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmed) {
      setState(() {
        _isLoading = true;
      });

      try {
        final success = await _databaseService.deleteRoute(originalIndex);

        if (success) {
          await _loadRoutes();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Route deleted successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          setState(() {
            _isLoading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to delete route'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        print('Error deleting route: $e');
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting route: $e'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get theme provider
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Define colors for both themes
    final primaryColor =
        isDarkMode
            ? Color.fromARGB(255, 88, 13, 218) 
            : Color.fromARGB(
              255,
              88,
              13,
              218,
            ); // Original purple for light mode

    final backgroundColor = isDarkMode ? Color(0xFF121212) : Colors.white;
    final cardBackgroundColor = isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white70 : Colors.black87;
    final secondaryTextColor =
        isDarkMode ? Colors.grey[400] : Colors.grey.shade700;
    final borderColor =
        isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;
    final searchBorderColor =
        isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;

    final filteredRoutes = _getFilteredRoutes();

    return Scaffold(
      backgroundColor: primaryColor,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Route',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 8,
        onPressed: () async {
          try {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RouteEditorScreen(isNewRoute: true),
              ),
            );

            if (result == true) {
              await _loadRoutes();
            }
          } catch (e) {
            print('Error adding route: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error adding route: $e'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        },
      ),
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
                        'Welcome Admin,',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'it\'s $currentTime now.',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
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
                        onPressed: _loadRoutes,
                      ),
                      // Replace menu icon with logout icon
                      IconButton(
                        icon: Icon(Icons.logout, color: Colors.white, size: 26),
                        tooltip: 'Logout',
                        onPressed: _logout,
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
                        : Column(
                          children: [
                            // Search and filter bar
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Search Routes',
                                    style: GoogleFonts.inter(
                                      color: primaryColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  TextField(
                                    style: TextStyle(color: textColor),
                                    decoration: InputDecoration(
                                      hintText: 'Search routes...',
                                      hintStyle: TextStyle(
                                        color:
                                            isDarkMode
                                                ? Colors.grey[400]
                                                : Colors.grey,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search,
                                        color:
                                            isDarkMode
                                                ? Colors.grey[400]
                                                : null,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide: BorderSide(
                                          color: searchBorderColor,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide: BorderSide(
                                          color: searchBorderColor,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide: BorderSide(
                                          color: primaryColor,
                                        ),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 16,
                                      ),
                                      fillColor:
                                          isDarkMode ? Color(0xFF292929) : null,
                                      filled: isDarkMode,
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _searchQuery = value;
                                      });
                                    },
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Filter by Schedule',
                                    style: GoogleFonts.inter(
                                      color: primaryColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: searchBorderColor,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      color:
                                          isDarkMode ? Color(0xFF292929) : null,
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _filterSchedule,
                                        isExpanded: true,
                                        icon: Icon(
                                          Icons.arrow_drop_down,
                                          color:
                                              isDarkMode
                                                  ? Colors.white70
                                                  : null,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        dropdownColor:
                                            isDarkMode
                                                ? Color(0xFF292929)
                                                : null,
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            _filterSchedule = newValue!;
                                          });
                                        },
                                        items:
                                            [
                                              'All',
                                              'Regular',
                                              'Shuttle',
                                              'Friday',
                                            ].map<DropdownMenuItem<String>>((
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
                                            }).toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Routes list
                            Expanded(
                              child:
                                  filteredRoutes.isEmpty
                                      ? Center(
                                        child: Text(
                                          'No routes found',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            color:
                                                isDarkMode
                                                    ? Colors.grey[400]
                                                    : Colors.grey,
                                          ),
                                        ),
                                      )
                                      : RefreshIndicator(
                                        onRefresh: _loadRoutes,
                                        color: primaryColor,
                                        child: ListView.builder(
                                          itemCount: filteredRoutes.length,
                                          itemBuilder: (context, index) {
                                            final route = filteredRoutes[index];
                                            return Card(
                                              margin: EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                              elevation: 4,
                                              shadowColor:
                                                  isDarkMode
                                                      ? Colors.black
                                                      : Colors.black26,
                                              color: cardBackgroundColor,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                side: BorderSide(
                                                  color: borderColor,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Padding(
                                                padding: EdgeInsets.all(16),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            '${route['Route']} - ${route['Route Name']}',
                                                            style: GoogleFonts.inter(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16,
                                                              color:
                                                                  primaryColor,
                                                            ),
                                                          ),
                                                        ),
                                                        Container(
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 4,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                isDarkMode
                                                                    ? (route['Schedule'] ==
                                                                            'Regular'
                                                                        ? Colors
                                                                            .blue
                                                                            .shade900
                                                                        : route['Schedule'] ==
                                                                            'Shuttle'
                                                                        ? Colors
                                                                            .green
                                                                            .shade900
                                                                        : Colors
                                                                            .orange
                                                                            .shade900)
                                                                    : (route['Schedule'] ==
                                                                            'Regular'
                                                                        ? Colors
                                                                            .blue
                                                                            .shade100
                                                                        : route['Schedule'] ==
                                                                            'Shuttle'
                                                                        ? Colors
                                                                            .green
                                                                            .shade100
                                                                        : Colors
                                                                            .orange
                                                                            .shade100),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            route['Schedule'],
                                                            style: GoogleFonts.inter(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color:
                                                                  isDarkMode
                                                                      ? (route['Schedule'] ==
                                                                              'Regular'
                                                                          ? Colors
                                                                              .blue
                                                                              .shade100
                                                                          : route['Schedule'] ==
                                                                              'Shuttle'
                                                                          ? Colors
                                                                              .green
                                                                              .shade100
                                                                          : Colors
                                                                              .orange
                                                                              .shade100)
                                                                      : (route['Schedule'] ==
                                                                              'Regular'
                                                                          ? Colors
                                                                              .blue
                                                                              .shade800
                                                                          : route['Schedule'] ==
                                                                              'Shuttle'
                                                                          ? Colors
                                                                              .green
                                                                              .shade800
                                                                          : Colors
                                                                              .orange
                                                                              .shade800),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(height: 12),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.directions_bus,
                                                          size: 16,
                                                          color:
                                                              secondaryTextColor,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          route['Trip Direction'],
                                                          style: GoogleFonts.inter(
                                                            fontSize: 14,
                                                            color:
                                                                secondaryTextColor,
                                                          ),
                                                        ),
                                                        SizedBox(width: 16),
                                                        Icon(
                                                          Icons.access_time,
                                                          size: 16,
                                                          color:
                                                              secondaryTextColor,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          route['Time'],
                                                          style: GoogleFonts.inter(
                                                            fontSize: 14,
                                                            color:
                                                                secondaryTextColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    if (route['Note'] != null &&
                                                        route['Note']
                                                            .toString()
                                                            .isNotEmpty)
                                                      Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                              top: 12,
                                                            ),
                                                        child: Container(
                                                          padding:
                                                              EdgeInsets.all(8),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                isDarkMode
                                                                    ? Color(
                                                                      0xFF282828,
                                                                    )
                                                                    : Colors
                                                                        .grey
                                                                        .shade100,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                          child: Row(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .info_outline,
                                                                size: 16,
                                                                color:
                                                                    secondaryTextColor,
                                                              ),
                                                              SizedBox(
                                                                width: 8,
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                  route['Note'],
                                                                  style: GoogleFonts.inter(
                                                                    fontSize:
                                                                        13,
                                                                    fontStyle:
                                                                        FontStyle
                                                                            .italic,
                                                                    color:
                                                                        secondaryTextColor,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    SizedBox(height: 12),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.end,
                                                      children: [
                                                        ElevatedButton.icon(
                                                          icon: Icon(
                                                            Icons.edit,
                                                            size: 18,
                                                          ),
                                                          label: Text('Edit'),
                                                          style: ElevatedButton.styleFrom(
                                                            foregroundColor:
                                                                primaryColor,
                                                            backgroundColor:
                                                                isDarkMode
                                                                    ? Color(
                                                                      0xFF252525,
                                                                    )
                                                                    : Colors
                                                                        .white,
                                                            elevation: 0,
                                                            side: BorderSide(
                                                              color:
                                                                  primaryColor,
                                                            ),
                                                            padding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 8,
                                                                ),
                                                          ),
                                                          onPressed: () async {
                                                            try {
                                                              final originalIndex =
                                                                  _routes
                                                                      .indexOf(
                                                                        route,
                                                                      );
                                                              final result = await Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder:
                                                                      (
                                                                        context,
                                                                      ) => RouteEditorScreen(
                                                                        isNewRoute:
                                                                            false,
                                                                        route:
                                                                            route,
                                                                        routeIndex:
                                                                            originalIndex,
                                                                      ),
                                                                ),
                                                              );

                                                              if (result ==
                                                                  true) {
                                                                await _loadRoutes();
                                                              }
                                                            } catch (e) {
                                                              print(
                                                                'Error editing route: $e',
                                                              );
                                                              if (mounted) {
                                                                ScaffoldMessenger.of(
                                                                  context,
                                                                ).showSnackBar(
                                                                  SnackBar(
                                                                    content: Text(
                                                                      'Error editing route: $e',
                                                                    ),
                                                                    backgroundColor:
                                                                        Colors
                                                                            .red,
                                                                    duration:
                                                                        Duration(
                                                                          seconds:
                                                                              2,
                                                                        ),
                                                                  ),
                                                                );
                                                              }
                                                            }
                                                          },
                                                        ),
                                                        SizedBox(width: 8),
                                                        ElevatedButton.icon(
                                                          icon: Icon(
                                                            Icons.delete,
                                                            size: 18,
                                                            color: Colors.white,
                                                          ),
                                                          label: Text(
                                                            'Delete',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                          style: ElevatedButton.styleFrom(
                                                            foregroundColor:
                                                                Colors.white,
                                                            backgroundColor:
                                                                Colors.red,
                                                            elevation: 0,
                                                            side: BorderSide(
                                                              color: Colors.red,
                                                            ),
                                                            padding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 8,
                                                                ),
                                                          ),
                                                          onPressed:
                                                              () =>
                                                                  _deleteRoute(
                                                                    index,
                                                                  ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                            ),
                          ],
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
