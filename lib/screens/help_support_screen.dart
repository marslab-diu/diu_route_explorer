import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/sidebar.dart';
import '../providers/theme_provider.dart';

class HelpSupportScreen extends StatefulWidget {
  @override
  _HelpSupportScreenState createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  String currentTime = '';
  Timer? _timer;

  // List of FAQs
  final List<Map<String, String>> faqs = [
    {
      'question': 'How do I check the bus schedule?',
      'answer':
          'Select your preferred schedule type (Regular, Shuttle, or Friday) and then choose your route from the dropdown menu. The app will display all available start and departure times for that route.',
    },
    {
      'question': 'What do the different schedule types mean?',
      'answer':
          'Regular schedules are for normal weekdays (Saturday to Thursday), Shuttle schedules are for special shuttle services, and Friday schedules are specifically for Friday timings which may differ from regular weekdays.',
    },
    {
      'question': 'Can I set a default route?',
      'answer':
          'Yes! Go to Settings and select your preferred default route. This route will be automatically selected when you open the app next time.',
    },
    {
      'question': 'How do I get notifications about route changes?',
      'answer':
          'Make sure you have enabled push notifications in the Settings screen. The app will notify you about any changes to your favorite routes or general announcements.',
    },
    {
      'question': 'What should I do if the bus schedule is not loading?',
      'answer':
          'First, check your internet connection. If you\'re connected but still having issues, try using the refresh button at the top of the screen. The app also stores cached data that will be displayed if you\'re offline.',
    },
    {
      'question': 'How accurate are the bus timings?',
      'answer':
          'The timings are based on the official university schedule, but actual arrival and departure times may vary slightly due to traffic conditions or other unforeseen circumstances.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _updateTime();
    // Update time every minute
    _timer = Timer.periodic(Duration(minutes: 1), (timer) => _updateTime());
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

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': 'DIU Route Explorers Support Request'},
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw 'Could not launch $emailUri';
      }
    } catch (e) {
      print('Error launching email: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open email app. Please copy the email address manually.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get theme provider
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final primaryColor = Color.fromARGB(255, 88, 13, 218);
    final backgroundColor = isDarkMode ? Color(0xFF121212) : Colors.white;
    final cardBackgroundColor = isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor =
        isDarkMode ? Colors.grey[400]! : Colors.grey.shade700;
    final borderColor =
        isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;
    final shadowColor =
        isDarkMode
            ? Colors.black.withOpacity(0.3)
            : Colors.black.withOpacity(0.05);

    return Scaffold(
      backgroundColor: primaryColor,
      endDrawer: Sidebar(),
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
                        'Help & Support',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Builder(
                    builder:
                        (context) => IconButton(
                          icon: Icon(Icons.menu, color: Colors.white, size: 30),
                          onPressed: () {
                            Scaffold.of(context).openEndDrawer();
                          },
                        ),
                  ),
                ],
              ),
            ),
          ),

          // Modernized scrollable content area
          Positioned(
            top: 140,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.only(topRight: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Modern FAQ Section
                    Text(
                      'Frequently Asked Questions',
                      style: GoogleFonts.inter(
                        color: isDarkMode ? Colors.white : primaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 20),

                    // Modern FAQ List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: faqs.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: cardBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: shadowColor,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            collapsedShape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            collapsedBackgroundColor: cardBackgroundColor,
                            backgroundColor: cardBackgroundColor,
                            iconColor: primaryColor,
                            collapsedIconColor:
                                isDarkMode
                                    ? Colors.white
                                    : Colors.grey.shade700,
                            title: Text(
                              faqs[index]['question']!,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                                color: textColor,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  faqs[index]['answer']!,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 32),

                    // Modern Contact Section
                    Text(
                      'Contact Us',
                      style: GoogleFonts.inter(
                        color: isDarkMode ? Colors.white : primaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16),

                    Text(
                      'If you have any questions or need assistance, please feel free to contact us:',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: secondaryTextColor,
                      ),
                    ),
                    SizedBox(height: 20),

                    // Modern Email Cards
                    Column(
                      children: [
                        _buildContactCard(
                          email: 'abedin15-4919@diu.edu.bd',
                          context: context,
                          isDarkMode: isDarkMode,
                          cardBackgroundColor: cardBackgroundColor,
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          borderColor: borderColor,
                          primaryColor: primaryColor,
                        ),
                        SizedBox(height: 16),
                        _buildContactCard(
                          email: 'garodia15-5048@diu.edu.bd',
                          context: context,
                          isDarkMode: isDarkMode,
                          cardBackgroundColor: cardBackgroundColor,
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          borderColor: borderColor,
                          primaryColor: primaryColor,
                        ),
                      ],
                    ),

                    SizedBox(height: 32),

                    // Modern App Info Card
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: shadowColor,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About DIU Route Explorers',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'DIU Route Explorers is designed to help Daffodil International University students navigate the university bus system efficiently. The app provides up-to-date information on bus routes, schedules, and important announcements.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: secondaryTextColor,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'App Version: 1.0.1',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color:
                                  isDarkMode
                                      ? Colors.grey[500]
                                      : Colors.grey.shade600,
                            ),
                          ),
                        ],
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

  // Updated helper method with dark mode support
  Widget _buildContactCard({
    required String email,
    required BuildContext context,
    required bool isDarkMode,
    required Color cardBackgroundColor,
    required Color textColor,
    required Color secondaryTextColor,
    required Color borderColor,
    required Color primaryColor,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _launchEmail(email),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(isDarkMode ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.email_outlined, color: primaryColor, size: 20),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Support Email',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    email,
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.blue),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDarkMode ? Colors.grey[600] : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
