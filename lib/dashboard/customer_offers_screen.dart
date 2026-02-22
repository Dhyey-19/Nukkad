import 'package:flutter/material.dart';
import 'package:nukkad/dashboard/business_landing_page.dart';
import 'package:nukkad/services/offer_service.dart';
import 'package:nukkad/utils/app_colors.dart';
import 'package:intl/intl.dart';

class CustomerOffersScreen extends StatefulWidget {
  const CustomerOffersScreen({super.key});

  @override
  State<CustomerOffersScreen> createState() => _CustomerOffersScreenState();
}

class _CustomerOffersScreenState extends State<CustomerOffersScreen> {
  final OfferService _offerService = OfferService();
  bool isLoading = true;
  List<Map<String, dynamic>> offers = [];

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    setState(() => isLoading = true);
    final rows = await _offerService.getActiveOffers();
    setState(() {
      offers = rows;
      isLoading = false;
    });
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
          title: const Text("Offers"),
        ),
        body: RefreshIndicator(
          onRefresh: _loadOffers,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : offers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_offer_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "No offers available",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Check nearby businesses for fresh deals",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: offers.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          '${offers.length} offers available',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      );
                    }
                    final offer = offers[index - 1];
                    final business =
                        offer['nkd_businesses'] as Map<String, dynamic>?;
                    final businessName =
                        business?['business_name'] ?? 'Business';
                    final endDate = offer['end_date'] != null
                        ? DateTime.tryParse(offer['end_date'])
                        : null;
                    final subtitle = endDate != null
                        ? 'Valid till ${DateFormat('dd MMM yyyy').format(endDate)}'
                        : 'Limited time';
                    return GestureDetector(
                      onTap: () {
                        if (business?['business_id'] != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BusinessLandingPage(
                                businessId: business!['business_id'],
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.local_offer,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    offer['offer_title'] ?? 'Offer',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    businessName,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
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
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
