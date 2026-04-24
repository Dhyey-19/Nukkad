import 'package:flutter/material.dart';
import 'package:nukkad/services/business_service.dart';
import 'package:nukkad/services/analytics_service.dart';
import 'package:nukkad/services/review_service.dart';
import 'package:nukkad/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class BusinessAnalyticsPage extends StatefulWidget {
  const BusinessAnalyticsPage({super.key});

  @override
  State<BusinessAnalyticsPage> createState() => _BusinessAnalyticsPageState();
}

class _BusinessAnalyticsPageState extends State<BusinessAnalyticsPage> {
  final BusinessService _businessService = BusinessService();
  final ReviewService _reviewService = ReviewService();
  final AnalyticsService _analyticsService = AnalyticsService();

  Map<String, dynamic>? business;
  List<Map<String, dynamic>> reviews = [];
  List<int> weeklyViews = const [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId != null) {
        final b = await _businessService.getBusinessByUserId(userId);
        if (b != null) {
          final bId = b['business_id'] as int;
          final reviewList = await _reviewService.getBusinessReviews(bId, limit: 10);
          final views = await _analyticsService.getDailyEventCounts(
            businessId: bId,
            eventType: 'view',
            days: 7,
          );

          setState(() {
            business = b;
            reviews = reviewList;
            weeklyViews = views;
            isLoading = false;
          });
          return;
        }
      }

      setState(() {
        business = null;
        reviews = [];
        weeklyViews = const [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.primary,
          elevation: 0,
          foregroundColor: Colors.white,
          title: const Text("Analytics"),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : business == null
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        "Complete your business profile to see your analytics and reviews.",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()), 
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// KPI CARDS
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: "Total Views",
                                  value: "${business!['total_views'] ?? 0}",
                                  icon: Icons.visibility,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  title: "Total Enquiries",
                                  value: "${business!['total_enquiries'] ?? 0}",
                                  icon: Icons.call,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _StatCard(
                            title: "Total Reviews",
                            value: "${business!['total_reviews'] ?? 0}",
                            icon: Icons.rate_review,
                          ),

                          const SizedBox(height: 24),

                          /// CHART SECTION
                          const Text(
                            "Weekly Performance",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          _barChart(),

                          const SizedBox(height: 24),

                          /// RATINGS & REVIEWS
                          const Text(
                            "Ratings & Reviews",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          _ratingSummary(),
                          const SizedBox(height: 12),
                          if (reviews.isEmpty)
                            Text(
                              "You haven't received any reviews yet.",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            )
                          else
                            Column(
                              children: reviews.map(_reviewTile).toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _ratingSummary() {
    final rawRating = business?['rating_average'];
    final doubleRating = rawRating is num ? rawRating.toDouble() : 0.0;
    final totalReviews = business?['total_reviews'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Text(
            doubleRating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    return Icon(
                      starIndex <= doubleRating.round()
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 18,
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  "$totalReviews reviews",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewTile(Map<String, dynamic> review) {
    final rating = review['rating'] as int? ?? 0;
    final text = (review['review_text'] ?? '').toString();
    final userName =
        (review['nkd_users']?['full_name'] ?? 'Customer').toString();
    final createdAt = review['created_at'];
    String? dateLabel;

    if (createdAt != null) {
      try {
        dateLabel = DateFormat('dd MMM yyyy')
            .format(DateTime.parse(createdAt as String));
      } catch (_) {
        dateLabel = null;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10, top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                userName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (dateLabel != null)
                Text(
                  dateLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              return Icon(
                starIndex <= rating ? Icons.star : Icons.star_border,
                size: 16,
                color: Colors.amber,
              );
            }),
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Weekly Views Bar Chart
  Widget _barChart() {
    final data = weeklyViews.isEmpty ? List<int>.filled(7, 0) : weeklyViews;
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final maxHeight = maxValue == 0 ? 1 : maxValue;
    final start = DateTime.now().subtract(const Duration(days: 6));
    final labels = List<String>.generate(7, (i) {
      final day = start.add(Duration(days: i));
      return DateFormat('E').format(day);
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(data.length, (index) {
          final value = data[index];
          final height = (value / maxHeight) * 120 + 8;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 16,
                height: height,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                labels[index],
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// KPI CARD
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
