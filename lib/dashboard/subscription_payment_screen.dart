import 'package:flutter/material.dart';
import 'package:nukkad/services/subscription_service.dart';
import 'package:nukkad/services/business_service.dart';
import 'package:nukkad/utils/app_colors.dart';
import 'package:nukkad/widgets/custom_button.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionPaymentScreen extends StatefulWidget {
  const SubscriptionPaymentScreen({super.key});

  @override
  State<SubscriptionPaymentScreen> createState() => _SubscriptionPaymentScreenState();
}

class _SubscriptionPaymentScreenState extends State<SubscriptionPaymentScreen> {
  bool isLoading = false;
  int? userId;
  int? businessId;
  Map<String, dynamic>? currentSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('user_id');
    
    if (userId != null) {
      final subscriptionService = SubscriptionService();
      currentSubscription = await subscriptionService.getSubscription(userId!);
      
      // Get business ID
      final businessService = BusinessService();
      final business = await businessService.getBusinessByUserId(userId!);
      businessId = business?['business_id'];
      setState(() {});
    }
  }

  Future<void> _processPayment() async {
    if (userId == null || businessId == null) {
      Fluttertoast.showToast(msg: "Please complete business registration first");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Generate a transaction ID (in real app, integrate with payment gateway)
      final transactionId = "TXN${DateTime.now().millisecondsSinceEpoch}";
      
      final subscriptionService = SubscriptionService();
      final result = await subscriptionService.createYearlySubscription(
        userId: userId!,
        businessId: businessId!,
        transactionId: transactionId,
      );

      if (result != null) {
        Fluttertoast.showToast(
          msg: "Payment successful! Your yearly subscription is now active.",
          backgroundColor: Colors.green,
          toastLength: Toast.LENGTH_LONG,
        );
        Navigator.pop(context, true);
      } else {
        Fluttertoast.showToast(
          msg: "Payment failed. Please try again.",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error: $e",
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isYearlyActive = currentSubscription?['subscription_type'] == 'yearly' &&
                          currentSubscription?['is_active'] == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Subscription Plans"),
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, physics: const BouncingScrollPhysics(), 
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Current Subscription Status
            if (currentSubscription != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: isYearlyActive
                      ? Colors.green.withOpacity(0.08)
                      : AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isYearlyActive ? Colors.green : AppColors.primary,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isYearlyActive ? Icons.check_circle : Icons.info_outline,
                          color: isYearlyActive ? Colors.green : AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isYearlyActive ? "Active Subscription" : "Current Plan",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isYearlyActive ? Colors.green : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Plan: ${currentSubscription!['subscription_type']?.toString().toUpperCase() ?? 'Free'}",
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (currentSubscription!['subscription_type'] != 'yearly')
                      Text(
                        "Connects: ${currentSubscription!['connects_remaining'] ?? 0} remaining",
                        style: const TextStyle(fontSize: 14),
                      ),
                  ],
                ),
              ),

            // Yearly Plan Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "POPULAR",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Yearly Subscription",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "₹",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "365",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          "/year",
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _featureItem(Icons.check_circle, "Unlimited Connects"),
                  _featureItem(Icons.check_circle, "No daily charges"),
                  _featureItem(Icons.check_circle, "Priority support"),
                  _featureItem(Icons.check_circle, "Enhanced visibility"),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: isYearlyActive
                        ? "Already Subscribed"
                        : isLoading
                            ? "Processing..."
                            : "Subscribe Now - ₹365",
                    onPressed: isYearlyActive || isLoading ? null : _processPayment,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Free Plan Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    "Free Plan",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _featureItem(Icons.check_circle, "5 Free Connects", color: Colors.grey),
                  _featureItem(Icons.check_circle, "Basic features", color: Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureItem(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color ?? AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: color ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
