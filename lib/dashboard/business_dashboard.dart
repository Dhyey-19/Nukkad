import 'package:flutter/material.dart';
import 'business_home_screen.dart';
import 'business_enquiries_screen.dart';
import 'business_offers_screen.dart';
import 'business_analytics_screen.dart';
import 'business_profile_page.dart';
import 'package:nukkad/utils/app_colors.dart';

class BusinessDashboard extends StatefulWidget {
  const BusinessDashboard({super.key});

  @override
  State<BusinessDashboard> createState() => _BusinessDashboardState();
}

class _BusinessDashboardState extends State<BusinessDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    BusinessHomePage(),
    BusinessEnquiriesPage(),
    BusinessOffersPage(),
    BusinessAnalyticsPage(),
    BusinessProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.call), label: "Enquiries"),
          BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: "Offers"),
          BottomNavigationBarItem(icon: Icon(Icons.insights), label: "Analytics"),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: "Profile"),
        ],
      ),
    );
  }
}
