import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nukkad/services/auth_service.dart';
import 'package:nukkad/utils/app_colors.dart';
import 'package:nukkad/widgets/custom_button.dart';
import 'package:nukkad/widgets/custom_textbox.dart';
import 'package:nukkad/dashboard/business_registration_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupScreen extends StatefulWidget {
  final String userType;

  const SignupScreen({super.key, required this.userType});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController businessCategoryController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FocusNode _mobileFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();
  final FocusNode _businessNameFocus = FocusNode();
  final RegExp _phoneRegex = RegExp(r'^\d{10}$');

  bool obscurePassword = true;
  bool isSubmitting = false;

  List<String> categories = [];
  bool isLoadingCategories = true;
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final authService = AuthService();
    categories = await authService.fetchBusinessCategories();
    setState(() {
      isLoadingCategories = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: SingleChildScrollView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, physics: const BouncingScrollPhysics(), 
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/app_icon.png', height: 90),
                const SizedBox(height: 20),

                const Text(
                  "Create Account",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomTextBox(
                          controller: nameController,
                          labelText: "Full Name",
                          prefixIcon: Icons.person,
                          textInputAction: TextInputAction.next,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (value) {
                            final name = (value ?? '').trim();
                            if (name.isEmpty) {
                              return "Please enter full name";
                            }
                            if (name.length < 2) {
                              return "Full name is too short";
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _mobileFocus.requestFocus(),
                        ),
                        const SizedBox(height: 16),

                        CustomTextBox(
                          controller: mobileController,
                          labelText: "Mobile Number",
                          prefixIcon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          focusNode: _mobileFocus,
                          textInputAction: TextInputAction.next,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          validator: (value) {
                            final phone = (value ?? '').trim();
                            if (phone.isEmpty) {
                              return "Please enter mobile number";
                            }
                            if (!_phoneRegex.hasMatch(phone)) {
                              return "Enter a valid 10-digit mobile number";
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) =>
                              _passwordFocus.requestFocus(),
                        ),
                        const SizedBox(height: 16),

                        CustomTextBox(
                          controller: passwordController,
                          labelText: "Password",
                          prefixIcon: Icons.lock,
                          obscureText: obscurePassword,
                          suffixIcon: obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          focusNode: _passwordFocus,
                          textInputAction: TextInputAction.next,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (value) {
                            final password = (value ?? '').trim();
                            if (password.isEmpty) {
                              return "Please enter password";
                            }
                            if (password.length < 6) {
                              return "Password must be at least 6 characters";
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) =>
                              _confirmPasswordFocus.requestFocus(),
                          onSuffixTap: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextBox(
                          controller: confirmPasswordController,
                          labelText: "Confirm Password",
                          prefixIcon: Icons.lock_outline,
                          obscureText: obscurePassword,
                          focusNode: _confirmPasswordFocus,
                          textInputAction:
                              widget.userType.toLowerCase() == 'business'
                              ? TextInputAction.next
                              : TextInputAction.done,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (value) {
                            final confirm = (value ?? '').trim();
                            if (confirm.isEmpty) {
                              return "Please confirm password";
                            }
                            if (confirm != passwordController.text.trim()) {
                              return "Passwords do not match";
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) {
                            if (widget.userType.toLowerCase() == 'business') {
                              _businessNameFocus.requestFocus();
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        /// 🔹 Business-only fields
                        if (widget.userType.toLowerCase() == 'business') ...[
                          CustomTextBox(
                            controller: businessNameController,
                            labelText: "Business Name",
                            prefixIcon: Icons.business,
                            focusNode: _businessNameFocus,
                            textInputAction: TextInputAction.done,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (value) {
                              final name = (value ?? '').trim();
                              if (name.isEmpty) {
                                return "Please enter business name";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          /// Dropdown
                          DropdownSearch<String>(
                            selectedItem: selectedCategory,

                            items: (String filter, LoadProps? props) async {
                              if (filter.isEmpty) return categories;
                              return categories
                                  .where(
                                    (c) => c.toLowerCase().contains(
                                      filter.toLowerCase(),
                                    ),
                                  )
                                  .toList();
                            },

                            onChanged: (value) {
                              setState(() {
                                selectedCategory = value;
                              });
                            },

                            dropdownBuilder: (context, selectedItem) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 16,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.category),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        selectedItem ?? "Business Category",
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },

                            popupProps: PopupProps.menu(
                              showSearchBox: true,
                              menuProps: const MenuProps(
                                backgroundColor: Colors
                                    .white, // <-- Set background color here
                              ),
                              searchFieldProps: TextFieldProps(
                                decoration: InputDecoration(
                                  hintText: "Search category",
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              itemBuilder:
                                  (context, item, isSelected, isDisabled) =>
                                      ListTile(
                                        leading: const Icon(
                                          Icons.storefront,
                                          color: AppColors.primary,
                                        ),
                                        title: Text(item),
                                      ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        CustomButton(
                          text: "Create Account",
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  FocusScope.of(context).unfocus();
                                  if (!(_formKey.currentState?.validate() ??
                                      false)) {
                                    return;
                                  }
                                  if (widget.userType.toLowerCase() ==
                                      'business') {
                                    if (selectedCategory == null ||
                                        selectedCategory!.isEmpty) {
                                      Fluttertoast.showToast(
                                        msg: "Please select a category",
                                      );
                                      return;
                                    }
                                  }

                                  setState(() => isSubmitting = true);
                                  final authService = AuthService();
                                  final exists = await authService
                                      .isPhoneRegistered(
                                        mobileController.text.trim(),
                                      );
                                  if (exists) {
                                    Fluttertoast.showToast(
                                      msg: "Mobile number already registered",
                                      backgroundColor: Colors.red,
                                    );
                                    setState(() => isSubmitting = false);
                                    return;
                                  }
                                  final success = await authService.signup(
                                    fullName: nameController.text.trim(),
                                    phone: mobileController.text.trim(),
                                    password: passwordController.text.trim(),
                                    role: widget.userType.toLowerCase(),
                                    businessName:
                                        widget.userType.toLowerCase() ==
                                            'business'
                                        ? businessNameController.text.trim()
                                        : null,
                                    businessCategory:
                                        widget.userType.toLowerCase() ==
                                            'business'
                                        ? selectedCategory
                                        : null,
                                  );

                                  if (success) {
                                    Fluttertoast.showToast(
                                      msg: "Account created successfully!",
                                    );
                                    final user = await authService.login(
                                      mobileController.text.trim(),
                                      passwordController.text.trim(),
                                    );
                                    if (user != null) {
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      await prefs.setInt(
                                        'user_id',
                                        user['user_id'],
                                      );
                                      await prefs.setString(
                                        'user_role',
                                        user['role'],
                                      );
                                      await prefs.setString(
                                        'full_name',
                                        user['full_name'],
                                      );
                                      await prefs.setString(
                                        'phone',
                                        user['phone'],
                                      );

                                      if (widget.userType.toLowerCase() ==
                                          'business') {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                BusinessRegistrationScreen(
                                                  userId: user['user_id'],
                                                  businessName:
                                                      businessNameController
                                                          .text
                                                          .trim(),
                                                  businessCategory:
                                                      selectedCategory ?? '',
                                                ),
                                          ),
                                        );
                                        setState(() => isSubmitting = false);
                                        return;
                                      }
                                    } else {
                                      Fluttertoast.showToast(
                                        msg:
                                            "Account created. Please login to continue.",
                                      );
                                    }
                                    Navigator.pop(context);
                                  } else {
                                    Fluttertoast.showToast(
                                      msg: "Signup failed. Try again.",
                                    );
                                  }
                                  setState(() => isSubmitting = false);
                                },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
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
    nameController.dispose();
    mobileController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    businessNameController.dispose();
    businessCategoryController.dispose();
    _mobileFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _businessNameFocus.dispose();
    super.dispose();
  }
}
