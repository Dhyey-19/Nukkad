import 'package:flutter/material.dart';
import 'package:nukkad/services/business_service.dart';
import 'package:nukkad/services/offer_service.dart';
import 'package:nukkad/services/enquiry_service.dart';
import 'package:nukkad/services/subscription_service.dart';
import 'package:nukkad/utils/app_colors.dart';
import 'package:nukkad/dashboard/business_registration_screen.dart';
import 'package:nukkad/dashboard/business_enquiries_screen.dart';
import 'package:nukkad/dashboard/business_offers_screen.dart';
import 'package:nukkad/dashboard/business_analytics_screen.dart';
import 'package:nukkad/dashboard/subscription_payment_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class BusinessHomePage extends StatefulWidget {
  const BusinessHomePage({super.key});

  @override
  State<BusinessHomePage> createState() => _BusinessHomePageState();
}

class _BusinessHomePageState extends State<BusinessHomePage> {
  final BusinessService _businessService = BusinessService();
  final OfferService _offerService = OfferService();
  final EnquiryService _enquiryService = EnquiryService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  Map<String, dynamic>? business;
  List<Map<String, dynamic>> offers = [];
  List<Map<String, dynamic>> enquiries = [];
  Map<String, dynamic>? subscription;
  int? userId;
  int? businessId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getInt('user_id');

      if (userId != null) {
        // Load business data
        final businessData = await _businessService.getBusinessByUserId(
          userId!,
        );

        if (businessData != null) {
          businessId = businessData['business_id'];

          // Load offers
          final offersData = await _offerService.getBusinessOffers(businessId!);

          // Load recent enquiries
          final enquiriesData = await _enquiryService.getBusinessEnquiries(
            businessId!,
          );

          // Load subscription
          final subscriptionData = await _subscriptionService.getSubscription(
            userId!,
          );

          setState(() {
            business = businessData;
            offers = offersData;
            enquiries = enquiriesData.take(3).toList(); // Show only 3 recent
            subscription = subscriptionData;
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text("Dashboard"),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, 
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()), 
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _welcomeCard(),

                    const SizedBox(height: 16),
                    _quickActions(context),

                    const SizedBox(height: 24),
                    _sectionTitle("Business Stats"),
                    const SizedBox(height: 12),
                    _statsGrid(),

                    const SizedBox(height: 24),
                    _sectionTitle("Your Offers"),
                    const SizedBox(height: 12),
                    _offers(),

                    const SizedBox(height: 24),
                    _sectionTitle("Recent Enquiries"),
                    const SizedBox(height: 12),
                    _recentEnquiries(),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  /// ================= WELCOME CARD =================
  Widget _welcomeCard() {
    final businessName = business?['business_name'] ?? 'Your Business';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome, $businessName 👋",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            business != null
                ? "Your business is live and visible to customers nearby."
                : "Complete your business registration to get started.",
            style: const TextStyle(color: Colors.black54),
          ),
          if (business == null && userId != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BusinessRegistrationScreen(
                        userId: userId!,
                        businessName: '',
                        businessCategory: '',
                      ),
                    ),
                  );
                  if (result == true) _loadData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Complete Profile'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _actionChip(
            label: 'Offers',
            icon: Icons.local_offer,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BusinessOffersPage()),
            ),
          ),
          _actionChip(
            label: 'Enquiries',
            icon: Icons.message,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BusinessEnquiriesPage()),
            ),
          ),
          _actionChip(
            label: 'Analytics',
            icon: Icons.insights,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BusinessAnalyticsPage()),
            ),
          ),
          _actionChip(
            label: 'Plan',
            icon: Icons.verified,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SubscriptionPaymentScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  /// ================= STATS GRID =================
  Widget _statsGrid() {
    final totalViews = business?['total_views'] ?? 0;
    final totalEnquiries = business?['total_enquiries'] ?? 0;
    final activeOffers = offers.length;
    final subscriptionStatus = subscription?['subscription_type'] == 'yearly'
        ? 'Active'
        : subscription?['connects_remaining'] != null
        ? '${subscription!['connects_remaining']} Connects'
        : 'Free';

    final stats = [
      {
        "title": "Total Views",
        "value": totalViews.toString(),
        "icon": Icons.visibility,
      },
      {
        "title": "Enquiries",
        "value": totalEnquiries.toString(),
        "icon": Icons.call,
      },
      {
        "title": "Active Offers",
        "value": activeOffers.toString(),
        "icon": Icons.local_offer,
      },
      {
        "title": "Subscription",
        "value": subscriptionStatus,
        "icon": Icons.verified,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  stat["icon"] as IconData,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                stat["value"] as String,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                stat["title"] as String,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ================= OFFERS =================
  Widget _offers() {
    if (offers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          "No active offers. Create your first offer!",
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: offers.take(3).map((offer) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_offer, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer['offer_title'] ?? 'Offer',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (offer['end_date'] != null)
                      Text(
                        "Valid till ${DateFormat('dd MMM yyyy').format(DateTime.parse(offer['end_date']))}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// ================= RECENT ENQUIRIES =================
  Widget _recentEnquiries() {
    if (enquiries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          "No enquiries yet. Your enquiries will appear here.",
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BusinessEnquiriesPage()),
            ),
            child: const Text('View all'),
          ),
        ),
        ...enquiries.map((e) {
          final date = e['created_at'] != null
              ? DateFormat('dd MMM').format(DateTime.parse(e['created_at']))
              : 'Recently';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (e['is_read'] == false)
                        ? AppColors.accent
                        : Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: (e['is_read'] == false)
                        ? AppColors.primary
                        : Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              e['customer_name'] ?? 'Customer',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (e['is_read'] == false)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      Text(
                        e['enquiry_title'] ?? 'Enquiry',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        date,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.black45,
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  /// ================= SECTION TITLE =================
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}
