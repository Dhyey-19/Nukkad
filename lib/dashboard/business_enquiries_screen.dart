import 'package:flutter/material.dart';
import 'package:nukkad/services/business_service.dart';
import 'package:nukkad/services/enquiry_service.dart';
import 'package:nukkad/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class BusinessEnquiriesPage extends StatefulWidget {
  const BusinessEnquiriesPage({super.key});

  @override
  State<BusinessEnquiriesPage> createState() => _BusinessEnquiriesPageState();
}

class _BusinessEnquiriesPageState extends State<BusinessEnquiriesPage> {
  final BusinessService _businessService = BusinessService();
  final EnquiryService _enquiryService = EnquiryService();

  List<Map<String, dynamic>> enquiries = [];
  int? userId;
  int? businessId;
  bool isLoading = true;
  bool showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    _loadEnquiries();
  }

  Future<void> _loadEnquiries() async {
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
          final enquiriesData = await _enquiryService.getBusinessEnquiries(
            businessId!,
          );

          setState(() {
            enquiries = enquiriesData;
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
      print('Error loading enquiries: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(int enquiryId) async {
    await _enquiryService.markEnquiryAsRead(enquiryId);
    _loadEnquiries();
  }

  Future<void> _callCustomer(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<bool> _deleteEnquiry(int enquiryId) async {
    final ok = await _enquiryService.deleteEnquiry(
      enquiryId: enquiryId,
      businessId: businessId,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete enquiry.')),
      );
    }
    return ok;
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
        title: const Text("Enquiries"),
      ),
      body: RefreshIndicator(
        onRefresh: _loadEnquiries,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : enquiries.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      "No enquiries yet",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Your enquiries will appear here",
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
                itemCount: enquiries.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('All'),
                            selected: !showUnreadOnly,
                            onSelected: (_) =>
                                setState(() => showUnreadOnly = false),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Unread'),
                            selected: showUnreadOnly,
                            onSelected: (_) =>
                                setState(() => showUnreadOnly = true),
                          ),
                          const Spacer(),
                          Text(
                            '${enquiries.length} total',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final item = enquiries[index - 1];
                  if (showUnreadOnly && item['is_read'] == true) {
                    return const SizedBox.shrink();
                  }
                  return _enquiryTile(item);
                },
              ),
      ),
    );
  }

  Widget _enquiryTile(Map<String, dynamic> enquiry) {
    final isUnread = enquiry['is_read'] == false;
    final date = enquiry['created_at'] != null
        ? DateFormat(
            'dd MMM yyyy, hh:mm a',
          ).format(DateTime.parse(enquiry['created_at']))
        : 'Recently';
    final status = enquiry['status'] ?? 'pending';
    final statusColor = status == 'pending'
        ? Colors.orange
        : status == 'responded'
        ? Colors.green
        : status == 'completed'
        ? Colors.blueGrey
        : Colors.grey;

    return Dismissible(
      key: ValueKey(enquiry['enquiry_id']),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Enquiry'),
            content: const Text(
              'Are you sure you want to delete this enquiry?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
        if (confirm != true) return false;
        return await _deleteEnquiry(enquiry['enquiry_id']);
      },
      onDismissed: (_) {
        setState(() {
          enquiries.removeWhere(
            (e) => e['enquiry_id'] == enquiry['enquiry_id'],
          );
        });
      },
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
      child: GestureDetector(
        onTap: () {
          _showEnquiryDetails(enquiry);
          if (isUnread) {
            _markAsRead(enquiry['enquiry_id']);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isUnread
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isUnread
                      ? AppColors.primary.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.message,
                  color: isUnread ? AppColors.primary : Colors.grey,
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
                            enquiry['customer_name'] ?? 'Customer',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: isUnread
                                  ? Colors.black
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                        if (isUnread)
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
                    const SizedBox(height: 4),
                    Text(
                      enquiry['enquiry_title'] ?? 'Enquiry',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            date,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (enquiry['customer_phone'] != null)
                IconButton(
                  icon: const Icon(Icons.phone, color: Colors.green),
                  onPressed: () => _callCustomer(enquiry['customer_phone']),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEnquiryDetails(Map<String, dynamic> enquiry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, physics: const BouncingScrollPhysics(), 
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    enquiry['enquiry_title'] ?? 'Enquiry',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _detailRow('Customer', enquiry['customer_name'] ?? 'N/A'),
                  if (enquiry['customer_phone'] != null)
                    _detailRow('Phone', enquiry['customer_phone']),
                  if (enquiry['customer_email'] != null)
                    _detailRow('Email', enquiry['customer_email']),
                  const Divider(),
                  const Text(
                    'Message:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(enquiry['enquiry_message'] ?? ''),
                  if (enquiry['response_message'] != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const Text(
                      'Your Response:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(enquiry['response_message']),
                  ],
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
