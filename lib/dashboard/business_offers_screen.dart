import 'package:flutter/material.dart';
import 'package:nukkad/services/business_service.dart';
import 'package:nukkad/services/offer_service.dart';
import 'package:nukkad/dashboard/business_create_offer_screen.dart';
import 'package:nukkad/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

class BusinessOffersPage extends StatefulWidget {
  const BusinessOffersPage({super.key});

  @override
  State<BusinessOffersPage> createState() => _BusinessOffersPageState();
}

class _BusinessOffersPageState extends State<BusinessOffersPage> {
  final BusinessService _businessService = BusinessService();
  final OfferService _offerService = OfferService();

  List<Map<String, dynamic>> offers = [];
  int? userId;
  int? businessId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getInt('user_id');

      if (userId != null) {
        final business = await _businessService.getBusinessByUserId(userId!);
        if (business != null) {
          businessId = business['business_id'];
          final offersData = await _offerService.getBusinessOffers(businessId!);

          setState(() {
            offers = offersData;
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
      print('Error loading offers: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteOffer(int offerId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Offer'),
        content: const Text('Are you sure you want to delete this offer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _offerService.deleteOffer(offerId);
      if (success) {
        Fluttertoast.showToast(msg: "Offer deleted successfully");
        _loadOffers();
      } else {
        Fluttertoast.showToast(
          msg: "Failed to delete offer",
          backgroundColor: Colors.red,
        );
      }
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
        title: const Text("Offers"),
      ),
      floatingActionButton: businessId != null
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        BusinessCreateOfferScreen(businessId: businessId!),
                  ),
                );
                if (result == true) {
                  _loadOffers();
                }
              },
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
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
                    const SizedBox(height: 16),
                    Text(
                      "No offers yet",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Tap + to create your first offer",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: businessId == null
                          ? null
                          : () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BusinessCreateOfferScreen(
                                    businessId: businessId!,
                                  ),
                                ),
                              );
                              if (result == true) {
                                _loadOffers();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Offer'),
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
                      child: Row(
                        children: [
                          Text(
                            '${offers.length} active offers',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: businessId == null
                                ? null
                                : () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            BusinessCreateOfferScreen(
                                              businessId: businessId!,
                                            ),
                                      ),
                                    );
                                    if (result == true) {
                                      _loadOffers();
                                    }
                                  },
                            child: const Text('New Offer'),
                          ),
                        ],
                      ),
                    );
                  }
                  return _offerTile(offers[index - 1]);
                },
              ),
      ),
    );
  }

  Widget _offerTile(Map<String, dynamic> offer) {
    final endDate = offer['end_date'] != null
        ? DateTime.parse(offer['end_date'])
        : null;
    final isExpired = endDate != null && endDate.isBefore(DateTime.now());
    final isActive = offer['is_active'] == true && !isExpired;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isExpired
            ? Border.all(color: Colors.red.withOpacity(0.3))
            : isActive
            ? Border.all(color: Colors.green.withOpacity(0.3))
            : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.green.withOpacity(0.1)
                  : isExpired
                  ? Colors.red.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.local_offer,
              color: isActive
                  ? Colors.green
                  : isExpired
                  ? Colors.red
                  : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        offer['offer_title'] ?? 'Offer',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (isExpired)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'EXPIRED',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                if (offer['offer_description'] != null)
                  Text(
                    offer['offer_description'],
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                if (endDate != null)
                  Text(
                    "Valid till ${DateFormat('dd MMM yyyy').format(endDate)}",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                if (offer['discount_percentage'] != null ||
                    offer['discount_amount'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      offer['discount_percentage'] != null
                          ? "${offer['discount_percentage']}% OFF"
                          : "₹${offer['discount_amount']} OFF",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete',
                child: const Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                _deleteOffer(offer['offer_id']);
              }
            },
          ),
        ],
      ),
    );
  }
}
