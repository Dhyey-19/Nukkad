import 'package:flutter/material.dart';
import 'package:nukkad/auth/login_screen.dart';
import 'package:nukkad/dashboard/business_registration_screen.dart';
import 'package:nukkad/dashboard/subscription_payment_screen.dart';
import 'package:nukkad/dashboard/business_create_offer_screen.dart';
import 'package:nukkad/services/business_service.dart';
import 'package:nukkad/services/subscription_service.dart';
import 'package:nukkad/services/auth_service.dart';
import 'package:nukkad/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class BusinessProfilePage extends StatefulWidget {
  const BusinessProfilePage({super.key});

  @override
  State<BusinessProfilePage> createState() => _BusinessProfilePageState();
}

class _BusinessProfilePageState extends State<BusinessProfilePage> {
  final BusinessService _businessService = BusinessService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final AuthService _authService = AuthService();

  Map<String, dynamic>? business;
  Map<String, dynamic>? subscription;
  String? userName;
  int? userId;
  int? businessId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('user_id');
    userName = prefs.getString('full_name');

    if (userId != null) {
      final businessData = await _businessService.getBusinessByUserId(userId!);
      final userData = await _authService.getUserById(userId!);
      final subscriptionData = await _subscriptionService.getSubscription(
        userId!,
      );

      setState(() {
        business = businessData != null
            ? {if (userData != null) ...userData, ...businessData}
            : businessData;
        if (businessData != null) {
          businessId = businessData['business_id'];
        }
        subscription = subscriptionData;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _getBusinessForCard() async {
    if (userId == null) return business;
    final b = await _businessService.getBusinessByUserId(userId!);
    final u = await _authService.getUserById(userId!);
    if (b == null) return business;
    return {if (u != null) ...u, ...b};
  }

  pw.Document _buildVisitingCardPdf({
    required Map<String, dynamic> businessData,
  }) {
    final pdf = pw.Document();

    final name = (businessData['business_name'] ?? 'Business').toString();
    final category = (businessData['business_category'] ?? '').toString();
    final description = (businessData['description'] ?? '').toString();
    final phone = (businessData['phone'] ?? '').toString();
    final email = (businessData['email'] ?? '').toString();
    final address = (businessData['address'] ?? '').toString();
    final website = (businessData['website'] ?? '').toString();

    const cardWidth = 252.0; // 3.5 inch * 72
    const cardHeight = 144.0; // 2 inch * 72

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(cardWidth, cardHeight),
        margin: const pw.EdgeInsets.all(12),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey300),
              boxShadow: const [
                pw.BoxShadow(
                  color: PdfColors.grey300,
                  blurRadius: 6,
                  offset: PdfPoint(0, 2),
                ),
              ],
            ),
            padding: const pw.EdgeInsets.all(10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 6,
                      height: 40,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.indigo,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            name,
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.black,
                            ),
                            maxLines: 1,
                          ),
                          if (category.isNotEmpty)
                            pw.Text(
                              category,
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: PdfColors.grey700,
                              ),
                              maxLines: 1,
                            ),
                          if (description.isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 2),
                              child: pw.Text(
                                description,
                                style: pw.TextStyle(
                                  fontSize: 7,
                                  color: PdfColors.grey700,
                                ),
                                maxLines: 2,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Container(height: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 6),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (phone.isNotEmpty)
                            _cardRow(
                              iconLabel: 'P',
                              iconColor: PdfColors.indigo,
                              value: phone,
                            ),
                          if (email.isNotEmpty)
                            _cardRow(
                              iconLabel: 'E',
                              iconColor: PdfColors.blue,
                              value: email,
                            ),
                          if (website.isNotEmpty)
                            _cardRow(
                              iconLabel: 'W',
                              iconColor: PdfColors.teal,
                              value: website,
                            ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Expanded(
                      flex: 4,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue50,
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              children: [
                                pw.Container(
                                  width: 12,
                                  height: 12,
                                  decoration: pw.BoxDecoration(
                                    color: PdfColors.orange,
                                    borderRadius: pw.BorderRadius.circular(3),
                                  ),
                                  child: pw.Center(
                                    child: pw.Text(
                                      'A',
                                      style: pw.TextStyle(
                                        fontSize: 7,
                                        color: PdfColors.white,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                pw.SizedBox(width: 6),
                                pw.Text(
                                  'Address',
                                  style: pw.TextStyle(
                                    fontSize: 7,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              address.isNotEmpty ? address : '—',
                              style: pw.TextStyle(fontSize: 7),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _cardRow({
    required String iconLabel,
    required PdfColor iconColor,
    required String value,
    int maxLines = 1,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 14,
            height: 14,
            decoration: pw.BoxDecoration(
              color: iconColor,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Center(
              child: pw.Text(
                iconLabel,
                style: pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 9),
              maxLines: maxLines,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareVisitingCardPdf() async {
    final data = await _getBusinessForCard();
    if (data == null) return;
    final pdf = _buildVisitingCardPdf(businessData: data);
    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename:
          '${(data['business_name'] ?? 'business').toString().replaceAll(' ', '_')}_card.pdf',
    );
  }

  Future<void> _shareVisitingCardImage() async {
    final data = await _getBusinessForCard();
    if (data == null) return;
    final pdf = _buildVisitingCardPdf(businessData: data);
    final bytes = await pdf.save();

    final raster = await Printing.raster(bytes, dpi: 200).first;
    final pngBytes = await raster.toPng();

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/visiting_card.png');
    await file.writeAsBytes(pngBytes, flush: true);

    await Share.shareXFiles([
      XFile(file.path, mimeType: 'image/png'),
    ], text: '${data['business_name'] ?? 'Business'} visiting card');
  }

  void logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    await prefs.remove('user_id');
    await prefs.remove('full_name');
    await prefs.remove('phone');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(userType: 'business'),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.primary,
          elevation: 0,
          foregroundColor: Colors.white,
          title: const Text("Profile"),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
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
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: AppColors.primary,
                              child: const Icon(
                                Icons.store,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              business?['business_name'] ??
                                  userName ??
                                  'Business',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              business?['business_category'] ??
                                  'Not registered',
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _miniStat(
                                  label: 'Views',
                                  value: '${business?['total_views'] ?? 0}',
                                ),
                                _miniStat(
                                  label: 'Enquiries',
                                  value: '${business?['total_enquiries'] ?? 0}',
                                ),
                                _miniStat(
                                  label: 'Rating',
                                  value: '${business?['rating_average'] ?? 0}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Subscription Status
                      if (subscription != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                subscription!['subscription_type'] == 'yearly'
                                ? Colors.green.withOpacity(0.08)
                                : AppColors.accent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  subscription!['subscription_type'] == 'yearly'
                                  ? Colors.green
                                  : AppColors.primary,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                subscription!['subscription_type'] == 'yearly'
                                    ? Icons.verified
                                    : Icons.info_outline,
                                color:
                                    subscription!['subscription_type'] ==
                                        'yearly'
                                    ? Colors.green
                                    : AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                subscription!['subscription_type'] == 'yearly'
                                    ? 'Yearly Subscription Active'
                                    : 'Free Plan - ${subscription!['connects_remaining'] ?? 0} connects remaining',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      subscription!['subscription_type'] ==
                                          'yearly'
                                      ? Colors.green
                                      : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const Divider(height: 32),

                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text("Edit Profile"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          if (userId != null && business != null) {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BusinessRegistrationScreen(
                                  userId: userId!,
                                  businessName:
                                      business!['business_name'] ?? '',
                                  businessCategory:
                                      business!['business_category'] ?? '',
                                  existingBusiness: business,
                                ),
                              ),
                            );
                            if (result == true) {
                              _loadData();
                            }
                          } else if (userId != null) {
                            // No business registered yet
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
                            if (result == true) {
                              _loadData();
                            }
                          }
                        },
                      ),

                      if (business != null && businessId != null)
                        ListTile(
                          leading: const Icon(Icons.local_offer),
                          title: const Text("Post Offer"),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BusinessCreateOfferScreen(
                                  businessId: businessId!,
                                ),
                              ),
                            );
                            if (result == true) {
                              // Refresh if needed
                            }
                          },
                        ),

                      ListTile(
                        leading: const Icon(Icons.payment),
                        title: const Text("Subscription & Payments"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SubscriptionPaymentScreen(),
                            ),
                          );
                          if (result == true) {
                            _loadData();
                          }
                        },
                      ),
                      if (business != null)
                        ListTile(
                          leading: const Icon(Icons.badge_outlined),
                          title: const Text("Share Visiting Card"),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () async {
                            await showModalBottomSheet(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                              ),
                              builder: (ctx) => SafeArea(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Share your visiting card",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ListTile(
                                        leading: const Icon(
                                          Icons.picture_as_pdf,
                                        ),
                                        title: const Text("Share as PDF"),
                                        onTap: () async {
                                          Navigator.pop(ctx);
                                          await _shareVisitingCardPdf();
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(
                                          Icons.image_outlined,
                                        ),
                                        title: const Text("Share as Image"),
                                        onTap: () async {
                                          Navigator.pop(ctx);
                                          await _shareVisitingCardImage();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text(
                          "Logout",
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () => logout(context),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _miniStat({required String label, required String value}) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
        ),
      ],
    );
  }
}
