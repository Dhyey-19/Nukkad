import 'package:flutter/material.dart';
import 'package:nukkad/services/business_service.dart';
import 'package:nukkad/services/offer_service.dart';
import 'package:nukkad/dashboard/enquiry_post_screen.dart';
import 'package:nukkad/services/saved_business_service.dart';
import 'package:nukkad/services/review_service.dart';
import 'package:nukkad/services/analytics_service.dart';
import 'package:nukkad/utils/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class BusinessLandingPage extends StatefulWidget {
  final int businessId;

  const BusinessLandingPage({super.key, required this.businessId});

  @override
  State<BusinessLandingPage> createState() => _BusinessLandingPageState();
}

class _BusinessLandingPageState extends State<BusinessLandingPage> {
  final BusinessService _businessService = BusinessService();
  final OfferService _offerService = OfferService();
  final SavedBusinessService _savedBusinessService = SavedBusinessService();
  final ReviewService _reviewService = ReviewService();
  final AnalyticsService _analyticsService = AnalyticsService();
  
  Map<String, dynamic>? business;
  List<Map<String, dynamic>> offers = [];
  List<Map<String, dynamic>> reviews = [];
  bool isLoading = true;
  int? currentUserId;
  String? currentUserRole;
  bool isSaved = false;
  int? userRating; // current user's rating if any
  bool _viewLogged = false;
  String _stringValue(dynamic value) => value?.toString().trim() ?? '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getInt('user_id');
    currentUserRole = prefs.getString('user_role');
    if (currentUserRole == 'customer' && currentUserId != null) {
      isSaved = await _savedBusinessService.isSaved(
        customerId: currentUserId!,
        businessId: widget.businessId,
      );
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final businessData = await _businessService.getBusinessById(widget.businessId);
      final offersData = await _offerService.getBusinessOffers(widget.businessId);
      final reviewsData = await _reviewService.getBusinessReviews(widget.businessId, limit: 20);
      
      if (businessData != null) {
        await _businessService.incrementBusinessViews(widget.businessId);
        if (!_viewLogged) {
          if (currentUserId == null) {
            final prefs = await SharedPreferences.getInstance();
            currentUserId = prefs.getInt('user_id');
          }
          await _analyticsService.logEvent(
            businessId: widget.businessId,
            eventType: 'view',
            userId: currentUserId,
          );
          _viewLogged = true;
        }
      }

      setState(() {
        business = businessData;
        offers = offersData;
        reviews = reviewsData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _callBusiness(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await _analyticsService.logEvent(
        businessId: widget.businessId,
        eventType: 'call',
        userId: currentUserId,
      );
      await launchUrl(uri);
    }
  }

  Future<void> _openMaps(double? lat, double? lon) async {
    if (lat == null || lon == null) return;
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    if (await canLaunchUrl(uri)) {
      await _analyticsService.logEvent(
        businessId: widget.businessId,
        eventType: 'direction',
        userId: currentUserId,
      );
      await launchUrl(uri);
    }
  }

  Future<void> _openEmail(String? email) async {
    if (email == null || email.trim().isEmpty) return;
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await _analyticsService.logEvent(
        businessId: widget.businessId,
        eventType: 'click',
        userId: currentUserId,
        metadata: {'action': 'email'},
      );
      await launchUrl(uri);
    }
  }

  Future<void> _openWebsite(String? website) async {
    if (website == null || website.trim().isEmpty) return;
    final url = website.startsWith('http') ? website : 'https://$website';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await _analyticsService.logEvent(
        businessId: widget.businessId,
        eventType: 'click',
        userId: currentUserId,
        metadata: {'action': 'website'},
      );
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openReviewSheet() async {
    if (currentUserId == null || currentUserRole != 'customer') return;

    final existing = await _reviewService.getUserReview(
      businessId: widget.businessId,
      customerId: currentUserId!,
    );

    int tempRating = existing?['rating'] as int? ?? 5;
    final TextEditingController controller = TextEditingController(
      text: existing?['review_text'] as String? ?? '',
    );

    // ignore: use_build_context_synchronously
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (context, setStateSheet) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Rate this business",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      final isFilled = starIndex <= tempRating;
                      return IconButton(
                        onPressed: () {
                          setStateSheet(() {
                            tempRating = starIndex;
                          });
                        },
                        icon: Icon(
                          isFilled ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    minLines: 3,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: "Add a short review (optional)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final ok = await _reviewService.upsertReview(
                          businessId: widget.businessId,
                          customerId: currentUserId!,
                          rating: tempRating,
                          reviewText: controller.text.trim().isEmpty
                              ? null
                              : controller.text.trim(),
                        );
                        if (!mounted) return;
                        if (ok) {
                          Navigator.pop(context);
                          // reload data to refresh rating + reviews list
                          _loadData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Thank you for your review.")),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Unable to submit review. Please try again.")),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Submit"),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _shareBusiness() async {
    if (business == null) return;

    final data = business!;
    final pdf = pw.Document();

    final businessName = (data['business_name'] ?? 'Business').toString();
    final category = (data['business_category'] ?? '').toString();
    final description = (data['description'] ?? '').toString();
    final phone = (data['phone'] ?? '').toString();
    final email = (data['email'] ?? '').toString();
    final address = (data['address'] ?? '').toString();
    final website = (data['website'] ?? '').toString();

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(24),
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 1),
            ),
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          businessName,
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (category.isNotEmpty)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 4),
                            child: pw.Text(
                              category,
                              style: pw.TextStyle(
                                fontSize: 12,
                                color: PdfColors.grey600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Text(
                        'Nukkad Business',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                if (description.isNotEmpty) ...[
                  pw.Text(
                    'About',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    description,
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                  pw.SizedBox(height: 16),
                ],
                pw.Text(
                  'Contact & Location',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                if (phone.isNotEmpty)
                  _pdfInfoRow('Phone', phone),
                if (email.isNotEmpty)
                  _pdfInfoRow('Email', email),
                if (address.isNotEmpty)
                  _pdfInfoRow('Address', address),
                if (website.isNotEmpty)
                  _pdfInfoRow('Website', website),
                pw.SizedBox(height: 20),
                if (offers.isNotEmpty) ...[
                  pw.Text(
                    'Current Offers',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: offers.map((offer) {
                      final title = (offer['offer_title'] ?? '').toString();
                      final description =
                          (offer['offer_description'] ?? '').toString();
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              title,
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            if (description.isNotEmpty)
                              pw.Text(
                                description,
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  pw.SizedBox(height: 16),
                ],
                pw.Spacer(),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Shared via Nukkad',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final bytes = await pdf.save();
    await _analyticsService.logEvent(
      businessId: widget.businessId,
      eventType: 'share',
      userId: currentUserId,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${businessName.replaceAll(' ', '_')}.pdf',
    );
  }

  pw.Widget _pdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 70,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(business?['business_name'] ?? 'Business'),
        actions: [
          if (currentUserRole == 'customer' && currentUserId != null)
            IconButton(
              tooltip: isSaved ? 'Saved' : 'Save',
              icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
              onPressed: () async {
                final customerId = currentUserId!;
                bool ok;
                if (isSaved) {
                  ok = await _savedBusinessService.unsaveBusiness(
                    customerId: customerId,
                    businessId: widget.businessId,
                  );
                } else {
                  ok = await _savedBusinessService.saveBusiness(
                    customerId: customerId,
                    businessId: widget.businessId,
                  );
                }
                if (ok && mounted) {
                  setState(() {
                    isSaved = !isSaved;
                  });
                }
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : business == null
              ? const Center(child: Text("Business not found"))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Business Header Image
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                        ),
                        child: business!['business_image'] != null
                            ? Image.network(
                                business!['business_image'],
                                fit: BoxFit.cover,
                              )
                            : const Icon(
                                Icons.storefront,
                                size: 80,
                                color: AppColors.primary,
                              ),
                      ),

                      // Business Info Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        business!['business_name'] ?? 'Unknown',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        business!['business_category'] ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (business!['is_verified'] == true)
                                  const Icon(
                                    Icons.verified,
                                    color: Colors.blue,
                                    size: 24,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  (business!['rating_average'] ?? 0).toString(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${business!['total_reviews'] ?? 0} reviews)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const Spacer(),
                                if (currentUserRole == 'customer' && currentUserId != null)
                                  TextButton.icon(
                                    onPressed: _openReviewSheet,
                                    icon: const Icon(Icons.rate_review_outlined, size: 18),
                                    label: const Text("Rate"),
                                  ),
                              ],
                            ),
                            if (_stringValue(business!['description']).isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 16),
                              Text(
                                _stringValue(business!['description']),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Contact & Location
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            if (_stringValue(business!['phone']).isNotEmpty)
                              _actionButton(
                                icon: Icons.phone,
                                label: 'Call',
                                value: _stringValue(business!['phone']),
                                onTap: () => _callBusiness(
                                  _stringValue(business!['phone']),
                                ),
                              ),
                            if (_stringValue(business!['address']).isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _actionButton(
                                icon: Icons.location_on,
                                label: 'Address',
                                value: _stringValue(business!['address']),
                                onTap: business!['latitude'] != null &&
                                        business!['longitude'] != null
                                    ? () => _openMaps(
                                          business!['latitude'].toDouble(),
                                          business!['longitude'].toDouble(),
                                        )
                                    : null,
                              ),
                            ],
                            if (_stringValue(business!['email']).isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _actionButton(
                                icon: Icons.email,
                                label: 'Email',
                                value: _stringValue(business!['email']),
                                onTap: () => _openEmail(
                                  _stringValue(business!['email']),
                                ),
                              ),
                            ],
                            if (_stringValue(business!['website']).isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _actionButton(
                                icon: Icons.language,
                                label: 'Website',
                                value: _stringValue(business!['website']),
                                onTap: () => _openWebsite(
                                  _stringValue(business!['website']),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Offers Section
                      if (offers.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "Current Offers",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 150,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: offers.length,
                            itemBuilder: (context, index) {
                              final offer = offers[index];
                              return Container(
                                width: 280,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.local_offer, color: Colors.orange),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            offer['offer_title'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (offer['offer_description'] != null)
                                      Expanded(
                                        child: Text(
                                          offer['offer_description'],
                                          style: const TextStyle(fontSize: 12),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      // Reviews Section
                      if (reviews.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "Recent Reviews",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: reviews.take(5).map((r) {
                              final rating = r['rating'] as int? ?? 0;
                              final text = (r['review_text'] ?? '').toString();
                              final userName =
                                  (r['nkd_users']?['full_name'] ?? 'Customer').toString();
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
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
                                        Row(
                                          children: List.generate(5, (index) {
                                            final starIndex = index + 1;
                                            return Icon(
                                              starIndex <= rating
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              size: 16,
                                              color: Colors.amber,
                                            );
                                          }),
                                        ),
                                      ],
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
                            }).toList(),
                          ),
                        ),
                      ],

                      // Action Buttons
                      if (currentUserRole == 'customer' && currentUserId != null) ...[
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EnquiryPostScreen(
                                          businessId: widget.businessId,
                                          businessName: business!['business_name'],
                                        ),
                                      ),
                                    );
                                    if (result == true) {
                                      await _analyticsService.logEvent(
                                        businessId: widget.businessId,
                                        eventType: 'click',
                                        userId: currentUserId,
                                        metadata: {'action': 'post_enquiry'},
                                      );
                                      _loadData();
                                    }
                                  },
                                  icon: const Icon(Icons.message),
                                  label: const Text("Post Enquiry"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _shareBusiness,
                                  icon: const Icon(Icons.share),
                                  label: const Text("Share Business"),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
