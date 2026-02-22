import 'package:flutter/material.dart';
import 'package:nukkad/utils/app_colors.dart';
import 'package:nukkad/auth/login_screen.dart';

class UserTypeSelectionScreen extends StatelessWidget {
  const UserTypeSelectionScreen({super.key});

  void _navigateToRegister(BuildContext context, String userType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(userType: userType),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              const SizedBox(height: 40),

              /// 🔹 App Logo
              Center(
                child: Image.asset(
                  'assets/images/app_icon.png',
                  height: 90,
                ),
              ),

              const SizedBox(height: 24),

              /// 🔹 Welcome Text
              Text(
                "Welcome to Nukkad",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Choose how you want to continue",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 40),

              /// 🔹 Business Card
              _userTypeCard(
                context,
                title: "Business",
                subtitle: "Grow your business & reach customers",
                icon: Icons.storefront,
                onTap: () => _navigateToRegister(context, "business"),
              ),

              const SizedBox(height: 20),

              /// 🔹 Customer Card
              _userTypeCard(
                context,
                title: "Customer",
                subtitle: "Discover nearby shops & services",
                icon: Icons.person,
                onTap: () => _navigateToRegister(context, "customer"),
              ),

              const SizedBox(height: 20),

              /// 🔹 Admin Card
              _userTypeCard(
                context,
                title: "Admin",
                subtitle: "Manage businesses, users & categories",
                icon: Icons.admin_panel_settings,
                onTap: () => _navigateToRegister(context, "admin"),
              ),

              const Spacer(),

              Text(
                "Local Businesses, Real Connections",
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Reusable Card Widget
  Widget _userTypeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 30,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
