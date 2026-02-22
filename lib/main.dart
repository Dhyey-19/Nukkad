import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nukkad/auth/usertypeselection_screen.dart';
import 'package:nukkad/onboarding/onboarding_screen.dart';
import 'package:nukkad/dashboard/customer_dashboard.dart';
import 'package:nukkad/dashboard/business_dashboard.dart';
import 'package:nukkad/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://uvctjvdkuoeraujmcsry.supabase.co', // Replace with your Supabase URL
    anonKey: 'sb_publishable_4Mi8Ntrmr2bzpxxlEUjlYg_jadHlkRQ', // Replace with your Supabase anon key
  );

  final prefs = await SharedPreferences.getInstance();
  final bool isOnboarded = prefs.getBool('isOnboarded') ?? false;
  final String? userRole = prefs.getString('user_role');

  runApp(MyApp(isOnboarded: isOnboarded, userRole: userRole));
}

class MyApp extends StatelessWidget {
  final bool isOnboarded;
  final String? userRole;
  const MyApp({super.key, required this.isOnboarded, this.userRole});

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (!isOnboarded) {
      home = const OnboardingScreen();
    } else if (userRole != null) {
      if (userRole == 'customer') {
        home = const CustomerDashboard();
      } else if (userRole == 'business') {
        home = const BusinessDashboard();
      } else {
        home = const UserTypeSelectionScreen();
      }
    } else {
      home = const UserTypeSelectionScreen();
    }

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nukkad',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      home: home,
    );
  }
}
