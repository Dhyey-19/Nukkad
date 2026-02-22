import 'package:flutter/material.dart';
import 'package:nukkad/utils/app_colors.dart';

class CustomerPrivacyScreen extends StatelessWidget {
  const CustomerPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          foregroundColor: Colors.white,
          title: const Text("Privacy Policy"),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Text(
              '''
Nukkad respects your privacy.

We only collect essential information such as:
• Name
• Phone number
• Location (to show nearby shops)

Your data is used only to:
• Help you find local businesses
• Improve app experience

We do NOT:
• Sell your data
• Share personal details without consent
• Track unnecessary activity

Location access is used only when required.
You can control permissions anytime from your device settings.

For any privacy concerns, contact us at:
dtechcode1946@gmail.com
            ''',
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
