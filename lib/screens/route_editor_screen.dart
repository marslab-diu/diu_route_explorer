import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../providers/theme_provider.dart';

class RouteEditorScreen extends StatefulWidget {
  final bool isNewRoute;
  final Map<String, dynamic>? route;
  final int? routeIndex;

  RouteEditorScreen({required this.isNewRoute, this.route, this.routeIndex});

  @override
  _RouteEditorScreenState createState() => _RouteEditorScreenState();
}

class _RouteEditorScreenState extends State<RouteEditorScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  late TextEditingController _routeCodeController;
  late TextEditingController _routeNameController;
  late TextEditingController _timeController;
  late TextEditingController _stopsController;
  late TextEditingController _noteController;
  late TextEditingController _routeMapController;

  String _schedule = 'Regular';
  String _tripDirection = 'To DSC';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data if editing
    if (!widget.isNewRoute && widget.route != null) {
      final route = widget.route!;
      _routeCodeController = TextEditingController(text: route['Route']);
      _routeNameController = TextEditingController(text: route['Route Name']);
      _timeController = TextEditingController(text: route['Time']);
      _stopsController = TextEditingController(text: route['Stops']);
      _noteController = TextEditingController(text: route['Note'] ?? '');
      _routeMapController = TextEditingController(
        text: route['Route Map'] ?? '',
      );
      _schedule = route['Schedule'];
      _tripDirection = route['Trip Direction'];
    } else {
      // Initialize with empty values for new route
      _routeCodeController = TextEditingController();
      _routeNameController = TextEditingController();
      _timeController = TextEditingController();
      _stopsController = TextEditingController();
      _noteController = TextEditingController();
      _routeMapController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _routeCodeController.dispose();
    _routeNameController.dispose();
    _timeController.dispose();
    _stopsController.dispose();
    _noteController.dispose();
    _routeMapController.dispose();
    super.dispose();
  }

  Future<void> _saveRoute() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final routeData = {
      'Route': _routeCodeController.text,
      'Schedule': _schedule,
      'Route Name': _routeNameController.text,
      'Trip Direction': _tripDirection,
      'Time': _timeController.text,
      'Stops': _stopsController.text,
      'Note': _noteController.text,
      'Route Map': _routeMapController.text,
    };

    bool success;

    if (widget.isNewRoute) {
      success = await _databaseService.addRoute(routeData);
    } else {
      success = await _databaseService.updateRoute(
        widget.routeIndex!,
        routeData,
      );
    }

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isNewRoute
                ? 'Route added successfully'
                : 'Route updated successfully',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isNewRoute
                ? 'Failed to add route'
                : 'Failed to update route',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
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
    final textColor = isDarkMode ? Colors.white70 : Colors.black87;
    final hintTextColor = isDarkMode ? Colors.grey[500] : Colors.grey;
    final borderColor =
        isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;
    final inputBackgroundColor = isDarkMode ? Color(0xFF292929) : null;

    return Scaffold(
      backgroundColor: primaryColor,
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
                        widget.isNewRoute ? 'Add New Route' : 'Edit Route',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Enter route details below',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () {
                      Navigator.pop(context);
                    },
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
                          padding: EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Route Code
                                Text(
                                  'Route Code',
                                  style: GoogleFonts.inter(
                                    color: primaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextFormField(
                                  controller: _routeCodeController,
                                  style: TextStyle(color: textColor),
                                  decoration: InputDecoration(
                                    hintText: 'e.g., R1, F1',
                                    hintStyle: TextStyle(color: hintTextColor),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide(
                                        color: borderColor,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide(
                                        color: borderColor,
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
                                    fillColor: inputBackgroundColor,
                                    filled: isDarkMode,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a route code';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 16),

                                // Schedule Type
                                Text(
                                  'Schedule Type',
                                  style: GoogleFonts.inter(
                                    color: primaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: borderColor),
                                    borderRadius: BorderRadius.circular(4),
                                    color: inputBackgroundColor,
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _schedule,
                                      isExpanded: true,
                                      icon: Icon(
                                        Icons.arrow_drop_down,
                                        color:
                                            isDarkMode ? Colors.white70 : null,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      dropdownColor:
                                          isDarkMode ? Color(0xFF292929) : null,
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          _schedule = newValue!;
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

                                // Route Name
                                Text(
                                  'Route Name',
                                  style: GoogleFonts.inter(
                                    color: primaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextFormField(
                                  controller: _routeNameController,
                                  style: TextStyle(color: textColor),
                                  decoration: InputDecoration(
                                    hintText: 'e.g., DSC <> Dhanmondi',
                                    hintStyle: TextStyle(color: hintTextColor),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide(
                                        color: borderColor,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide(
                                        color: borderColor,
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
                                    fillColor: inputBackgroundColor,
                                    filled: isDarkMode,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a route name';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 16),

                                // Trip Direction
                                Text(
                                  'Trip Direction',
                                  style: GoogleFonts.inter(
                                    color: primaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: borderColor),
                                    borderRadius: BorderRadius.circular(4),
                                    color: inputBackgroundColor,
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _tripDirection,
                                      isExpanded: true,
                                      icon: Icon(
                                        Icons.arrow_drop_down,
                                        color:
                                            isDarkMode ? Colors.white70 : null,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      dropdownColor:
                                          isDarkMode ? Color(0xFF292929) : null,
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          _tripDirection = newValue!;
                                        });
                                      },
                                      items:
                                          [
                                            'To DSC',
                                            'From DSC',
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

                                // Time
                                Text(
                                  'Time',
                                  style: GoogleFonts.inter(
                                    color: primaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextFormField(
                                  controller: _timeController,
                                  style: TextStyle(color: textColor),
                                  decoration: InputDecoration(
                                    hintText: 'e.g., 7:00 AM',
                                    hintStyle: TextStyle(color: hintTextColor),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide(
                                        color: borderColor,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide(
                                        color: borderColor,
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
                                    fillColor: inputBackgroundColor,
                                    filled: isDarkMode,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a time';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 16),

                                // Stops
                                Text(
                                  'Stops',
                                  style: GoogleFonts.inter(
                                    color: primaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextFormField(
                                  controller: _stopsController,
                                  style: TextStyle(color: textColor),
                                  decoration: InputDecoration(
                                    hintText: 'Stop 1, Stop 2, Stop 3, ...',
                                    hintStyle: TextStyle(color: hintTextColor),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide(
                                        color: borderColor,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide(
                                        color: borderColor,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide(
                                        color: primaryColor,
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.all(12),
                                    fillColor: inputBackgroundColor,
                                    filled: isDarkMode,
                                  ),
                                  maxLines: 3,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter stops';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 16),

                                // Note
                                Text(
                                  'Note (optional)',
                                  style: GoogleFonts.inter(
                                    color: primaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextFormField(
                                  controller: _noteController,
                                  style: TextStyle(color: textColor),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Additional information about this route',
                                    hintStyle: TextStyle(color: hintTextColor),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide(
                                        color: borderColor,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide(
                                        color: borderColor,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide(
                                        color: primaryColor,
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.all(12),
                                    fillColor: inputBackgroundColor,
                                    filled: isDarkMode,
                                  ),
                                  maxLines: 2,
                                ),
                                SizedBox(height: 16),

                                // Route Map
                                Text(
                                  'Route Map URL (optional)',
                                  style: GoogleFonts.inter(
                                    color: primaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextFormField(
                                  controller: _routeMapController,
                                  style: TextStyle(color: textColor),
                                  decoration: InputDecoration(
                                    hintText: 'https://example.com/map',
                                    hintStyle: TextStyle(color: hintTextColor),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide(
                                        color: borderColor,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide(
                                        color: borderColor,
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
                                    fillColor: inputBackgroundColor,
                                    filled: isDarkMode,
                                  ),
                                ),
                                SizedBox(height: 30),

                                // Save Button
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: TextButton(
                                    onPressed: _saveRoute,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Text(
                                        widget.isNewRoute
                                            ? 'Add Route'
                                            : 'Update Route',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),
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
}
