import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nukkad/utils/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerHelpSupportScreen extends StatefulWidget {
  const CustomerHelpSupportScreen({super.key});

  @override
  State<CustomerHelpSupportScreen> createState() => _CustomerHelpSupportScreenState();
}

class _CustomerHelpSupportScreenState extends State<CustomerHelpSupportScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _callSupport() async {
    final uri = Uri.parse("tel:+919724277321");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _emailSupport() async {
    final uri = Uri.parse(
      "mailto:dtechcode1946@gmail.com?subject=Nukkad Support",
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _whatsAppSupport() async {
    final uri = Uri.parse(
      "https://wa.me/919724277321?text=${Uri.encodeComponent("Hi, I need help with Nukkad app")}",
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _submitFeedback() async {
    final message = _feedbackController.text.trim();
    if (message.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your feedback")),
      );
      return;
    }
    if (message.length < 10) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Feedback is too short")),
      );
      return;
    }
    setState(() => _submitting = true);

    // For now, just open an email draft with the feedback text.
    final body = Uri.encodeComponent(message);
    final uri = Uri.parse(
      "mailto:dtechcode1946@gmail.com?subject=Nukkad Customer Feedback&body=$body",
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }

    setState(() => _submitting = false);
    if (!mounted) return;
    _feedbackController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Feedback draft opened in email.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text("Help & Support"),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Quick help",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _supportTile(
              icon: Icons.call,
              title: "Call Support",
              subtitle: "+91 97242 77321",
              onTap: _callSupport,
            ),
            _supportTile(
              icon: Icons.email,
              title: "Email Support",
              subtitle: "dtechcode1946@gmail.com",
              onTap: _emailSupport,
            ),
            _supportTile(
              icon: Icons.chat,
              title: "WhatsApp Support",
              subtitle: "Chat with us on WhatsApp",
              onTap: _whatsAppSupport,
            ),
            const SizedBox(height: 24),
            Text(
              "FAQs",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            _faqItem(
              question: "How do I book or contact a business?",
              answer:
                  "Open the business page and use the Call or Address buttons to contact them directly. Some businesses may also have an Email or Website listed.",
            ),
            _faqItem(
              question: "What are the business timings?",
              answer:
                  "Timings are shown on the business page if the owner has added them. If not visible, please call the business to confirm before visiting.",
            ),
            _faqItem(
              question: "How do I cancel or change my enquiry?",
              answer:
                  "You can contact the business directly using the phone number on their page. We recommend calling them as soon as possible for any changes.",
            ),
            _faqItem(
              question: "How can I save my favourite businesses?",
              answer:
                  "Tap the bookmark icon on a business page to save it. You can view all saved businesses from the Saved tab in your dashboard.",
            ),
            const SizedBox(height: 24),
            Text(
              "Send us feedback",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tell us what is working well or what we should improve.",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _feedbackController,
                minLines: 3,
                maxLines: 5,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(500),
                ],
                decoration: const InputDecoration(
                  hintText: "Type your feedback here...",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Send feedback"),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _supportTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }

  Widget _faqItem({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
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
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Text(
            answer,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
