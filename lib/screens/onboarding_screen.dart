import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/route_service.dart';
import '../providers/theme_provider.dart';
import 'bus_schedule_screen.dart';
import 'admin_dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final String userId;
  final String userType;

  const OnboardingScreen({
    Key? key,
    required this.userId,
    required this.userType,
  }) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();
  final RouteService _routeService = RouteService();
  final AuthService _authService = AuthService();

  List<String> _availableRoutes = [];
  String _selectedRoute = '';
  bool _isLoading = true;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _loadRouteData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadRouteData() async {
    try {
      final data = await _routeService.getRoutes();

      // Process route data
      Set<String> uniqueRoutes = {};

      for (var item in data) {
        String routeCode = item['Route'];
        String routeName = "${routeCode} - ${item['Route Name']}";

        // Skip the R1 - DSC <> Dhanmondi route
        if (!routeName.contains("R1 - DSC <> Dhanmondi")) {
          uniqueRoutes.add(routeName);
        }
      }

      setState(() {
        _availableRoutes = uniqueRoutes.toList();
        _isLoading = false;

        // Set default selected route if available
        if (_availableRoutes.isNotEmpty) {
          _selectedRoute = _availableRoutes[0];
        }
      });
    } catch (e) {
      print('Error loading route data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _completeOnboarding() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Save user name
      await _authService.saveUserName(_nameController.text);

      // Save default route preference
      await _authService.saveDefaultRoute(_selectedRoute);

      // Mark onboarding as completed
      await _authService.markOnboardingCompleted();

      // Navigate to appropriate screen based on user type
      if (widget.userType == AuthService.USER_TYPE_ADMIN) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminDashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BusScheduleScreen()),
        );
      }
    } catch (e) {
      print('Error completing onboarding: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Get first name from full name
  String _getFirstName(String fullName) {
    if (fullName.isEmpty) return '';
    List<String> nameParts = fullName.trim().split(' ');
    return nameParts[0];
  }

  Widget _buildNameStep() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final primaryColor = Color.fromARGB(255, 88, 13, 218);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final hintTextColor = isDarkMode ? Colors.grey[400] : Colors.grey;
    final borderColor = isDarkMode ? Colors.grey[700] : primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        TextField(
          controller: _nameController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: "Enter your name",
            hintStyle: TextStyle(color: hintTextColor),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: borderColor!),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: primaryColor),
            ),
            labelText: "Name",
            labelStyle: TextStyle(color: hintTextColor),
            floatingLabelStyle: TextStyle(color: primaryColor),
          ),
        ),
        SizedBox(height: 30),
        Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              if (_nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter your name'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              setState(() {
                _currentStep = 1;
              });
            },
            child: Text(
              "Next",
              style: GoogleFonts.inter(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRouteStep() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final primaryColor = Color.fromARGB(255, 88, 13, 218);
    final textColor = isDarkMode ? Colors.white70 : Colors.grey[800]!;
    final backgroundColor = isDarkMode ? Color(0xFF121212) : Colors.white;
    final borderColor = isDarkMode ? Colors.grey[700] : primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        Text(
          "Select your default route",
          style: GoogleFonts.inter(fontSize: 16, color: textColor),
        ),
        SizedBox(height: 20),
        _isLoading
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : _availableRoutes.isEmpty
            ? Center(
              child: Text(
                "No routes available",
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey,
                ),
              ),
            )
            : Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: borderColor!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedRoute.isEmpty ? null : _selectedRoute,
                  hint: Text(
                    "Select a route",
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : null,
                    ),
                  ),
                  dropdownColor: backgroundColor,
                  items:
                      _availableRoutes.map((String route) {
                        return DropdownMenuItem<String>(
                          value: route,
                          child: Text(
                            route,
                            style: TextStyle(color: textColor),
                          ),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedRoute = newValue;
                      });
                    }
                  },
                ),
              ),
            ),
        SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDarkMode ? Colors.grey[800] : Colors.grey[300],
                  foregroundColor: isDarkMode ? Colors.white70 : Colors.black,
                  minimumSize: Size(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _currentStep = 0;
                  });
                },
                child: Text("Back"),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: Size(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _completeOnboarding,
                child: Text(
                  "Finish",
                  style: GoogleFonts.inter(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get theme provider
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final primaryColor = Color.fromARGB(255, 88, 13, 218);
    final backgroundColor = isDarkMode ? Color(0xFF121212) : Colors.white;
    final textColor = isDarkMode ? Colors.white70 : Colors.black87;

    // Get display name (either "Hi" or "Hi, FirstName" if name is entered)
    String displayName = '';
    if (_nameController.text.isNotEmpty) {
      displayName = "Hi, ${_getFirstName(_nameController.text)}";
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Scrollable content
          SingleChildScrollView(
            child: Column(
              children: [
                // Purple header section
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.5,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 50), // Space for the menu icon
                      if (displayName.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Text(
                            displayName,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      Spacer(), // Add spacer to push text to bottom
                      Padding(
                        padding: const EdgeInsets.only(bottom: 0),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "COMPLETE\nYOUR\nPROFILE",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 30,
                  ),
                  decoration: BoxDecoration(color: backgroundColor),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Onboarding step tabs with Underline Indicator
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _currentStep = 0;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      "Your Name",
                                      style: TextStyle(
                                        color:
                                            _currentStep == 0
                                                ? primaryColor
                                                : textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Container(
                                      height: 3,
                                      color:
                                          _currentStep == 0
                                              ? primaryColor
                                              : Colors.transparent,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                if (_nameController.text.isNotEmpty) {
                                  setState(() {
                                    _currentStep = 1;
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Please enter your name first',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      "Default Route",
                                      style: TextStyle(
                                        color:
                                            _currentStep == 1
                                                ? primaryColor
                                                : textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Container(
                                      height: 3,
                                      color:
                                          _currentStep == 1
                                              ? primaryColor
                                              : Colors.transparent,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 30),

                      // Conditional content based on step
                      _currentStep == 0 ? _buildNameStep() : _buildRouteStep(),

                      // Add space at the bottom
                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
