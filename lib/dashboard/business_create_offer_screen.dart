import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nukkad/services/offer_service.dart';
import 'package:nukkad/utils/app_colors.dart';
import 'package:nukkad/widgets/custom_button.dart';
import 'package:nukkad/widgets/custom_textbox.dart';
import 'package:fluttertoast/fluttertoast.dart';

class BusinessCreateOfferScreen extends StatefulWidget {
  final int businessId;

  const BusinessCreateOfferScreen({super.key, required this.businessId});

  @override
  State<BusinessCreateOfferScreen> createState() => _BusinessCreateOfferScreenState();
}

class _BusinessCreateOfferScreenState extends State<BusinessCreateOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController discountPercentageController = TextEditingController();
  final TextEditingController discountAmountController = TextEditingController();
  final TextEditingController offerCodeController = TextEditingController();
  final FocusNode _descriptionFocus = FocusNode();
  final FocusNode _percentFocus = FocusNode();
  final FocusNode _amountFocus = FocusNode();
  final FocusNode _codeFocus = FocusNode();

  DateTime? startDate;
  DateTime? endDate;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Create Offer"),
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, physics: const BouncingScrollPhysics(), 
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextBox(
                controller: titleController,
                labelText: "Offer Title *",
                prefixIcon: Icons.title,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  final title = (value ?? '').trim();
                  if (title.isEmpty) {
                    return "Please enter offer title";
                  }
                  if (title.length < 3) {
                    return "Title is too short";
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _descriptionFocus.requestFocus(),
              ),

              const SizedBox(height: 16),

              CustomTextBox(
                controller: descriptionController,
                labelText: "Offer Description",
                prefixIcon: Icons.description,
                maxLines: 3,
                focusNode: _descriptionFocus,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _percentFocus.requestFocus(),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: CustomTextBox(
                      controller: discountPercentageController,
                      labelText: "Discount % (Optional)",
                      prefixIcon: Icons.percent,
                      keyboardType: TextInputType.number,
                      focusNode: _percentFocus,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) {
                        final text = (value ?? '').trim();
                        if (text.isEmpty) return null;
                        final percent = int.tryParse(text);
                        if (percent == null) {
                          return "Enter a valid percentage";
                        }
                        if (percent <= 0 || percent > 100) {
                          return "Percentage must be 1-100";
                        }
                        if (discountAmountController.text.trim().isNotEmpty) {
                          return "Use either % or amount";
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _amountFocus.requestFocus(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextBox(
                      controller: discountAmountController,
                      labelText: "Discount Amount ₹ (Optional)",
                      prefixIcon: Icons.currency_rupee,
                      keyboardType: TextInputType.number,
                      focusNode: _amountFocus,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) {
                        final text = (value ?? '').trim();
                        if (text.isEmpty) return null;
                        final amount = int.tryParse(text);
                        if (amount == null) {
                          return "Enter a valid amount";
                        }
                        if (amount <= 0) {
                          return "Amount must be greater than 0";
                        }
                        if (discountPercentageController.text.trim().isNotEmpty) {
                          return "Use either % or amount";
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _codeFocus.requestFocus(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              CustomTextBox(
                controller: offerCodeController,
                labelText: "Offer Code (Optional)",
                prefixIcon: Icons.code,
                focusNode: _codeFocus,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(20),
                ],
              ),

              const SizedBox(height: 16),

              // Start Date
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        startDate = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Start Date & Time *",
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            Text(
                              startDate != null
                                  ? "${startDate!.day}/${startDate!.month}/${startDate!.year} ${startDate!.hour}:${startDate!.minute.toString().padLeft(2, '0')}"
                                  : "Select start date",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // End Date
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        endDate = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "End Date & Time *",
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            Text(
                              endDate != null
                                  ? "${endDate!.day}/${endDate!.month}/${endDate!.year} ${endDate!.hour}:${endDate!.minute.toString().padLeft(2, '0')}"
                                  : "Select end date",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              CustomButton(
                text: isLoading ? "Creating..." : "Create Offer",
                onPressed: isLoading ? null : _createOffer,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createOffer() async {
    if (_formKey.currentState!.validate()) {
      if (startDate == null || endDate == null) {
        Fluttertoast.showToast(msg: "Please select start and end dates");
        return;
      }

      if (endDate!.isBefore(startDate!)) {
        Fluttertoast.showToast(msg: "End date must be after start date");
        return;
      }

      setState(() {
        isLoading = true;
      });

      try {
        final offerService = OfferService();
        final result = await offerService.createOffer(
          businessId: widget.businessId,
          offerTitle: titleController.text.trim(),
          offerDescription: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
          startDate: startDate!,
          endDate: endDate!,
          discountPercentage: discountPercentageController.text.trim().isEmpty
              ? null
              : double.tryParse(discountPercentageController.text.trim()),
          discountAmount: discountAmountController.text.trim().isEmpty
              ? null
              : double.tryParse(discountAmountController.text.trim()),
          offerCode: offerCodeController.text.trim().isEmpty
              ? null
              : offerCodeController.text.trim(),
        );

        if (result != null) {
          Fluttertoast.showToast(
            msg: "Offer created successfully!",
            backgroundColor: Colors.green,
          );
          Navigator.pop(context, true);
        } else {
          Fluttertoast.showToast(
            msg: "Failed to create offer. Please try again.",
            backgroundColor: Colors.red,
          );
        }
      } catch (e) {
        Fluttertoast.showToast(
          msg: "Error: $e",
          backgroundColor: Colors.red,
        );
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
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    discountPercentageController.dispose();
    discountAmountController.dispose();
    offerCodeController.dispose();
    _descriptionFocus.dispose();
    _percentFocus.dispose();
    _amountFocus.dispose();
    _codeFocus.dispose();
    super.dispose();
  }
}
