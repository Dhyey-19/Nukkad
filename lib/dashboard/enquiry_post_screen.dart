import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nukkad/services/enquiry_service.dart';
import 'package:nukkad/utils/app_colors.dart';
import 'package:nukkad/widgets/custom_button.dart';
import 'package:nukkad/widgets/custom_textbox.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnquiryPostScreen extends StatefulWidget {
  final int businessId;
  final String businessName;

  const EnquiryPostScreen({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  @override
  State<EnquiryPostScreen> createState() => _EnquiryPostScreenState();
}

class _EnquiryPostScreenState extends State<EnquiryPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  final FocusNode _messageFocus = FocusNode();

  bool isLoading = false;
  int? customerId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    customerId = prefs.getInt('user_id');
    if (mounted) setState(() {});
  }

  Future<void> _submitEnquiry() async {
    if (_formKey.currentState!.validate()) {
      if (customerId == null) {
        Fluttertoast.showToast(msg: "Please login again");
        return;
      }

      setState(() {
        isLoading = true;
      });

      try {
        final enquiryService = EnquiryService();
        final result = await enquiryService.createEnquiry(
          customerId: customerId!,
          businessId: widget.businessId,
          enquiryTitle: titleController.text.trim(),
          enquiryMessage: messageController.text.trim(),
        );

        if (result != null) {
          Fluttertoast.showToast(
            msg: "Enquiry sent successfully!",
            backgroundColor: Colors.green,
          );
          Navigator.pop(context, true);
        } else {
          Fluttertoast.showToast(
            msg: "Failed to send enquiry. Please try again.",
            backgroundColor: Colors.red,
          );
        }
      } catch (e) {
        Fluttertoast.showToast(msg: "Error: $e", backgroundColor: Colors.red);
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text("Post Enquiry"),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Business Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Sending enquiry to:",
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              widget.businessName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                CustomTextBox(
                  controller: titleController,
                  labelText: "Enquiry Title *",
                  prefixIcon: Icons.title,
                  textInputAction: TextInputAction.next,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(80),
                  ],
                  validator: (value) {
                    final title = (value ?? '').trim();
                    if (title.isEmpty) {
                      return "Please enter enquiry title";
                    }
                    if (title.length < 3) {
                      return "Title is too short";
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _messageFocus.requestFocus(),
                ),

                const SizedBox(height: 16),

                CustomTextBox(
                  controller: messageController,
                  labelText: "Message *",
                  prefixIcon: Icons.message,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  focusNode: _messageFocus,
                  textInputAction: TextInputAction.newline,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(500),
                  ],
                  validator: (value) {
                    final message = (value ?? '').trim();
                    if (message.isEmpty) {
                      return "Please enter your message";
                    }
                    if (message.length < 10) {
                      return "Message is too short";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                CustomButton(
                  text: isLoading ? "Sending..." : "Send Enquiry",
                  onPressed: isLoading ? null : _submitEnquiry,
                ),

                const SizedBox(height: 16),
                const Text(
                  "Note: Your enquiry will be sent to the business owner.",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    messageController.dispose();
    _messageFocus.dispose();
    super.dispose();
  }
}
