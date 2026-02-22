import 'package:flutter/material.dart';
import 'package:nukkad/dashboard/business_landing_page.dart';
import 'package:nukkad/services/saved_business_service.dart';
import 'package:nukkad/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerSavedScreen extends StatefulWidget {
  const CustomerSavedScreen({super.key});

  @override
  State<CustomerSavedScreen> createState() => _CustomerSavedScreenState();
}

class _CustomerSavedScreenState extends State<CustomerSavedScreen> {
  final SavedBusinessService _savedBusinessService = SavedBusinessService();
  int? customerId;
  bool isLoading = true;
  List<Map<String, dynamic>> saved = [];

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    customerId = prefs.getInt('user_id');

    if (customerId == null) {
      setState(() {
        saved = [];
        isLoading = false;
      });
      return;
    }

    final rows = await _savedBusinessService.getSavedBusinesses(
      customerId: customerId!,
    );
    setState(() {
      saved = rows;
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
          title: const Text("Saved"),
        ),
        body: RefreshIndicator(
          onRefresh: _loadSaved,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : saved.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark_border,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "No saved businesses",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Tap bookmark on any business to save it",
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
                  itemCount: saved.length,
                  itemBuilder: (context, index) {
                    final row = saved[index];
                    final business =
                        row['nkd_businesses'] as Map<String, dynamic>?;
                    if (business == null) return const SizedBox.shrink();
                    return Dismissible(
                      key: ValueKey(row['saved_id'] ?? business['business_id']),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Remove saved business'),
                            content: const Text(
                              'Remove this business from saved list?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  'Remove',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                        return confirm == true;
                      },
                      onDismissed: (_) async {
                        if (customerId != null) {
                          await _savedBusinessService.unsaveBusiness(
                            customerId: customerId!,
                            businessId: business['business_id'],
                          );
                        }
                        _loadSaved();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                        child: ListTile(
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.storefront,
                              color: AppColors.primary,
                            ),
                          ),
                          title: Text(business['business_name'] ?? 'Business'),
                          subtitle: Text(business['business_category'] ?? ''),
                          trailing: const Icon(
                            Icons.bookmark,
                            color: AppColors.primary,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BusinessLandingPage(
                                  businessId: business['business_id'],
                                ),
                              ),
                            ).then((_) => _loadSaved());
                          },
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
