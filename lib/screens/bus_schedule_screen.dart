import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/route_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../widgets/sidebar.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';

class BusScheduleScreen extends StatefulWidget {
  @override
  _BusScheduleScreenState createState() => _BusScheduleScreenState();
}

class _BusScheduleScreenState extends State<BusScheduleScreen> {
  String currentTime = '';
  String userName = '';
  Timer? _timer;

  // Create an instance of the RouteService
  final RouteService _routeService = RouteService();

  // Add a key for caching
  final String _cacheKey = 'cached_bus_data';

  // Data from JSON
  List<dynamic> busData = [];
  Map<String, List<String>> scheduleRoutes = {
    'Regular': [],
    'Shuttle': [],
    'Friday': [],
  };
  List<String> availableRoutes = [];
  List<Map<String, dynamic>> startTimes = [];
  List<Map<String, dynamic>> departureTimes = [];
  bool isLoading = true;
  String selectedSchedule = 'Regular';
  String selectedRoute = ''; // Will be loaded from preferences if available
  final String _defaultRouteKey = 'default_route';

  @override
  void initState() {
    super.initState();
    _updateTime();
    // Update time every minute
    _timer = Timer.periodic(Duration(minutes: 1), (timer) => _updateTime());

    // Load user name
    _loadUserName();

    // Load data from JSON
    _loadBusData();
  }

  Future<void> _loadBusData() async {
    try {
      // Use the RouteService to fetch data
      final data = await _routeService.getRoutes();

      // Cache the data
      _cacheData(data);

      // Load saved default route preference
      String? savedDefaultRoute = await _loadDefaultRoute();

      setState(() {
        busData = data;

        // Group routes by schedule type
        for (var item in busData) {
          String routeCode = item['Route'];
          String routeName = "${routeCode} - ${item['Route Name']}";
          String schedule = item['Schedule'];

          // Map route codes to schedule types
          if (schedule == 'Regular' &&
              !scheduleRoutes['Regular']!.contains(routeName)) {
            scheduleRoutes['Regular']!.add(routeName);
          } else if (schedule == 'Shuttle' &&
              !scheduleRoutes['Shuttle']!.contains(routeName)) {
            scheduleRoutes['Shuttle']!.add(routeName);
          } else if (schedule == 'Friday' &&
              !scheduleRoutes['Friday']!.contains(routeName)) {
            scheduleRoutes['Friday']!.add(routeName);
          }
        }

        // Remove R1 - DSC <> Dhanmondi from the routes
        for (var key in scheduleRoutes.keys) {
          scheduleRoutes[key] =
              scheduleRoutes[key]!
                  .where((route) => !route.contains("R1 - DSC <> Dhanmondi"))
                  .toList();
        }

        // Set available routes based on default selected schedule
        availableRoutes = scheduleRoutes[selectedSchedule] ?? [];

        // If we have a saved default route and it's in the available routes, use it
        if (savedDefaultRoute != null && savedDefaultRoute.isNotEmpty) {
          // Extract the route code from the saved default route (e.g., "R4 - ECB Chattor <> Mirpur <> DSC" -> "R4")
          String savedRouteCode = savedDefaultRoute.split(' - ')[0];

          // Find the schedule type for this route
          String? routeSchedule;
          for (var item in busData) {
            if (item['Route'] == savedRouteCode) {
              routeSchedule = item['Schedule'];
              break;
            }
          }

          // If we found the schedule, update the selected schedule
          if (routeSchedule != null) {
            selectedSchedule = routeSchedule;
            availableRoutes = scheduleRoutes[selectedSchedule] ?? [];
          }

          // Check if the saved route is in the available routes for the selected schedule
          if (availableRoutes.contains(savedDefaultRoute)) {
            selectedRoute = savedDefaultRoute;
          } else {
            // Fallback to first available route if saved route is not available
            selectedRoute =
                availableRoutes.isNotEmpty ? availableRoutes[0] : '';
          }
        } else {
          // Set default route to first available route if no saved preference
          selectedRoute = availableRoutes.isNotEmpty ? availableRoutes[0] : '';
        }

        _updateScheduleData();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading bus data: $e');

      // Try to load from cache if network fetch fails
      _loadFromCache();

      setState(() {
        isLoading = false;
      });
    }
  }

  // Add method to cache data
  Future<void> _cacheData(List<dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(data);
      await prefs.setString(_cacheKey, jsonString);
      print('Bus data cached successfully');
    } catch (e) {
      print('Error caching bus data: $e');
    }
  }

  // Add method to load from cache
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);

      if (jsonString != null) {
        final data = json.decode(jsonString);

        // Load saved default route preference
        String? savedDefaultRoute = await _loadDefaultRoute();

        setState(() {
          busData = List<dynamic>.from(data);

          // Clear existing route mappings
          scheduleRoutes = {'Regular': [], 'Shuttle': [], 'Friday': []};

          // Group routes by schedule type
          for (var item in busData) {
            String routeCode = item['Route'];
            String routeName = "${routeCode} - ${item['Route Name']}";
            String schedule = item['Schedule'];

            // Map route codes to schedule types
            if (schedule == 'Regular' &&
                !scheduleRoutes['Regular']!.contains(routeName)) {
              scheduleRoutes['Regular']!.add(routeName);
            } else if (schedule == 'Shuttle' &&
                !scheduleRoutes['Shuttle']!.contains(routeName)) {
              scheduleRoutes['Shuttle']!.add(routeName);
            } else if (schedule == 'Friday' &&
                !scheduleRoutes['Friday']!.contains(routeName)) {
              scheduleRoutes['Friday']!.add(routeName);
            }
          }

          // Remove R1 - DSC <> Dhanmondi from the routes
          for (var key in scheduleRoutes.keys) {
            scheduleRoutes[key] =
                scheduleRoutes[key]!
                    .where((route) => !route.contains("R1 - DSC <> Dhanmondi"))
                    .toList();
          }

          // Set available routes based on selected schedule
          availableRoutes = scheduleRoutes[selectedSchedule] ?? [];

          // If we have a saved default route and it's in the available routes, use it
          if (savedDefaultRoute != null && savedDefaultRoute.isNotEmpty) {
            // Extract the route code from the saved default route
            String savedRouteCode = savedDefaultRoute.split(' - ')[0];

            // Find the schedule type for this route
            String? routeSchedule;
            for (var item in busData) {
              if (item['Route'] == savedRouteCode) {
                routeSchedule = item['Schedule'];
                break;
              }
            }

            // If we found the schedule, update the selected schedule
            if (routeSchedule != null) {
              selectedSchedule = routeSchedule;
              availableRoutes = scheduleRoutes[selectedSchedule] ?? [];
            }

            // Check if the saved route is in the available routes for the selected schedule
            if (availableRoutes.contains(savedDefaultRoute)) {
              selectedRoute = savedDefaultRoute;
            } else {
              // Fallback to first available route if saved route is not available
              selectedRoute =
                  availableRoutes.isNotEmpty ? availableRoutes[0] : '';
            }
          } else {
            // Set default route to first available route if no saved preference
            selectedRoute =
                availableRoutes.isNotEmpty ? availableRoutes[0] : '';
          }

          _updateScheduleData();
        });

        print('Loaded bus data from cache');
      }
    } catch (e) {
      print('Error loading from cache: $e');
    }
  }

  // Load default route from SharedPreferences
  Future<String?> _loadDefaultRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_defaultRouteKey);
    } catch (e) {
      print('Error loading default route: $e');
      return null;
    }
  }

  void _updateScheduleData() {
    if (selectedRoute.isEmpty) return;

    // Extract route code (R1, R2, etc.) from the selected route
    String routeCode = selectedRoute.split(' - ')[0];

    // Filter data based on selected route and schedule
    List<dynamic> filteredData =
        busData
            .where(
              (item) =>
                  item['Route'] == routeCode &&
                  item['Schedule'] == selectedSchedule,
            )
            .toList();

    // Separate into start times (To DSC) and departure times (From DSC)
    List<Map<String, dynamic>> newStartTimes = [];
    List<Map<String, dynamic>> newDepartureTimes = [];

    for (var item in filteredData) {
      if (item['Trip Direction'] == 'To DSC') {
        newStartTimes.add({
          'time': item['Time'],
          'note':
              item['Note'] ??
              '', // Changed from 'No additional information' to empty string
          'stops': item['Stops'],
        });
      } else if (item['Trip Direction'] == 'From DSC') {
        newDepartureTimes.add({
          'time': item['Time'],
          'note':
              item['Note'] ??
              '', // Changed from 'No additional information' to empty string
          'stops': item['Stops'],
        });
      }
    }

    setState(() {
      startTimes = newStartTimes;
      departureTimes = newDepartureTimes;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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

  Future<void> _loadUserName() async {
    try {
      final AuthService authService = AuthService();
      final name = await authService.getUserName();
      setState(() {
        userName = name;
      });
    } catch (e) {
      print('Error loading user name: $e');
    }
  }

  // Update this method to refresh data
  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Force fetch from network
      final data = await _routeService.getRoutes(forceRefresh: true);

      // Cache the new data
      _cacheData(data);

      setState(() {
        busData = data;

        // Clear existing route mappings
        scheduleRoutes = {'Regular': [], 'Shuttle': [], 'Friday': []};

        // Group routes by schedule type
        for (var item in busData) {
          String routeCode = item['Route'];
          String routeName = "${routeCode} - ${item['Route Name']}";
          String schedule = item['Schedule'];

          // Map route codes to schedule types
          if (schedule == 'Regular' &&
              !scheduleRoutes['Regular']!.contains(routeName)) {
            scheduleRoutes['Regular']!.add(routeName);
          } else if (schedule == 'Shuttle' &&
              !scheduleRoutes['Shuttle']!.contains(routeName)) {
            scheduleRoutes['Shuttle']!.add(routeName);
          } else if (schedule == 'Friday' &&
              !scheduleRoutes['Friday']!.contains(routeName)) {
            scheduleRoutes['Friday']!.add(routeName);
          }
        }

        // Remove R1 - DSC <> Dhanmondi from the routes
        for (var key in scheduleRoutes.keys) {
          scheduleRoutes[key] =
              scheduleRoutes[key]!
                  .where((route) => !route.contains("R1 - DSC <> Dhanmondi"))
                  .toList();
        }

        // Set available routes based on selected schedule
        availableRoutes = scheduleRoutes[selectedSchedule] ?? [];

        // Set default route to first available route
        selectedRoute = availableRoutes.isNotEmpty ? availableRoutes[0] : '';
        _updateScheduleData();

        isLoading = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Schedule data updated successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error refreshing data: $e');
      setState(() {
        isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update schedule data'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Add theme provider
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final primaryColor = Color.fromARGB(255, 88, 13, 218);
    final backgroundColor = isDarkMode ? Color(0xFF121212) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final borderColor =
        isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;

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
                top: 60, // Increased from 40 to 60 for more space from the top
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
                        'Welcome, $userName',
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
                      // Add refresh button
                      IconButton(
                        icon: Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 26,
                        ),
                        onPressed: _refreshData,
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
                    isLoading
                        ? Center(
                          child: CircularProgressIndicator(color: primaryColor),
                        )
                        : SingleChildScrollView(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Schedule Selection (First)
                                Text(
                                  'Select Schedule',
                                  style: GoogleFonts.inter(
                                    color:
                                        isDarkMode
                                            ? Colors.white
                                            : primaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: borderColor),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedSchedule,
                                      isExpanded: true,
                                      icon: Icon(
                                        Icons.arrow_drop_down,
                                        color: isDarkMode ? Colors.white : null,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      dropdownColor: backgroundColor,
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          selectedSchedule = newValue!;
                                          // Update available routes based on selected schedule
                                          availableRoutes =
                                              scheduleRoutes[selectedSchedule] ??
                                              [];
                                          // Reset selected route
                                          selectedRoute =
                                              availableRoutes.isNotEmpty
                                                  ? availableRoutes[0]
                                                  : '';
                                          _updateScheduleData();
                                        });
                                      },
                                      items:
                                          [
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

                                SizedBox(height: 16),

                                // Route Selection (Second)
                                Text(
                                  'Select Route',
                                  style: GoogleFonts.inter(
                                    color:
                                        isDarkMode
                                            ? Colors.white
                                            : primaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: borderColor),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedRoute,
                                      isExpanded: true,
                                      icon: Icon(
                                        Icons.arrow_drop_down,
                                        color: isDarkMode ? Colors.white : null,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      dropdownColor: backgroundColor,
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          selectedRoute = newValue!;
                                          _updateScheduleData();
                                        });
                                      },
                                      items:
                                          availableRoutes
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

                                SizedBox(height: 20),

                                // Start Time Section
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                    child: Text(
                                      'Start Time',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),

                                // Start Time Table
                                startTimes.isEmpty
                                    ? Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                        child: Text(
                                          'No start times available for this selection',
                                          style: GoogleFonts.inter(
                                            color:
                                                isDarkMode
                                                    ? Colors.grey[400]
                                                    : Colors.grey,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    )
                                    : Table(
                                      border: TableBorder.all(
                                        color: borderColor,
                                        width: 1,
                                      ),
                                      children:
                                          startTimes.map<TableRow>((time) {
                                            return TableRow(
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.all(12),
                                                  child: Text(
                                                    time['time'] ?? '',
                                                    style: GoogleFonts.inter(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: textColor,
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(12),
                                                  child: Text(
                                                    time['note'] == null ||
                                                            time['note'].isEmpty
                                                        ? 'No additional information'
                                                        : time['note'],
                                                    style: GoogleFonts.inter(
                                                      fontSize: 14,
                                                      color: textColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }).toList(),
                                    ),

                                SizedBox(height: 20),

                                // Departure Time Section
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                    child: Text(
                                      'Departure Time',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),

                                // Departure Time Table
                                departureTimes.isEmpty
                                    ? Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                        child: Text(
                                          'No departure times available for this selection',
                                          style: GoogleFonts.inter(
                                            color:
                                                isDarkMode
                                                    ? Colors.grey[400]
                                                    : Colors.grey,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    )
                                    : Table(
                                      border: TableBorder.all(
                                        color: borderColor,
                                        width: 1,
                                      ),
                                      children:
                                          departureTimes.map<TableRow>((time) {
                                            return TableRow(
                                              children: [
                                                Padding(
                                                  padding: EdgeInsets.all(12),
                                                  child: Text(
                                                    time['time'] ?? '',
                                                    style: GoogleFonts.inter(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: textColor,
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.all(12),
                                                  child: Text(
                                                    time['note'] == null ||
                                                            time['note'].isEmpty
                                                        ? 'No additional information'
                                                        : time['note'],
                                                    style: GoogleFonts.inter(
                                                      fontSize: 14,
                                                      color: textColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }).toList(),
                                    ),

                                // Stops Information Section
                                if (startTimes.isNotEmpty ||
                                    departureTimes.isNotEmpty)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 20),
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: primaryColor,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Route Stops',
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children:
                                              (startTimes.isNotEmpty
                                                      ? startTimes[0]['stops']
                                                      : (departureTimes
                                                              .isNotEmpty
                                                          ? departureTimes[0]['stops']
                                                          : 'No stops information available'))
                                                  .split(',')
                                                  .map<Widget>(
                                                    (stop) => Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 6,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                          color: borderColor,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        '$stop',
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontSize: 12,
                                                              color: textColor,
                                                            ),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Sidebar();
  }
}
