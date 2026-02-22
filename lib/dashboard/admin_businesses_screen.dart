import 'package:flutter/material.dart';
import 'package:nukkad/services/admin_service.dart';
import 'package:nukkad/utils/app_colors.dart';

class AdminBusinessesScreen extends StatefulWidget {
  const AdminBusinessesScreen({super.key});

  @override
  State<AdminBusinessesScreen> createState() => _AdminBusinessesScreenState();
}

class _AdminBusinessesScreenState extends State<AdminBusinessesScreen> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> businesses = [];
  bool isLoading = true;
  bool showUnverified = false;

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
  }

  Future<void> _loadBusinesses() async {
    setState(() => isLoading = true);
    final data = await _adminService.getBusinesses(
      isVerified: showUnverified ? false : null,
    );
    setState(() {
      businesses = data;
      isLoading = false;
    });
  }

  Future<void> _toggleVerify(Map<String, dynamic> business) async {
    final current = business['is_verified'] == true;
    final ok = await _adminService.updateBusinessStatus(
      businessId: business['business_id'],
      isVerified: !current,
    );
    if (ok) {
      _loadBusinesses();
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> business) async {
    final current = business['is_active'] == true;
    final ok = await _adminService.updateBusinessStatus(
      businessId: business['business_id'],
      isActive: !current,
    );
    if (ok) {
      _loadBusinesses();
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
          title: const Text('Businesses'),
          actions: [
            IconButton(
              icon: Icon(
                showUnverified ? Icons.verified : Icons.verified_outlined,
              ),
              tooltip: showUnverified ? 'Show all' : 'Show unverified',
              onPressed: () {
                setState(() => showUnverified = !showUnverified);
                _loadBusinesses();
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadBusinesses,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : businesses.isEmpty
              ? Center(
                  child: Text(
                    showUnverified
                        ? 'No unverified businesses.'
                        : 'No businesses found.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: businesses.length,
                  itemBuilder: (context, index) {
                    final b = businesses[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.storefront,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  b['business_name'] ?? 'Business',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  b['business_category'] ?? '',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon: Icon(
                                  b['is_verified'] == true
                                      ? Icons.verified
                                      : Icons.verified_outlined,
                                  color: b['is_verified'] == true
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                tooltip: 'Toggle verification',
                                onPressed: () => _toggleVerify(b),
                              ),
                              IconButton(
                                icon: Icon(
                                  b['is_active'] == true
                                      ? Icons.toggle_on
                                      : Icons.toggle_off,
                                  color: b['is_active'] == true
                                      ? Colors.green
                                      : Colors.redAccent,
                                ),
                                tooltip: 'Toggle active',
                                onPressed: () => _toggleActive(b),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
