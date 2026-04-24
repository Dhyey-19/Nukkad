import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nukkad/services/business_service.dart';
import 'package:nukkad/services/auth_service.dart';
import 'package:nukkad/utils/app_colors.dart';
import 'package:nukkad/widgets/custom_button.dart';
import 'package:nukkad/widgets/custom_textbox.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:geolocator/geolocator.dart';

class BusinessRegistrationScreen extends StatefulWidget {
  final int userId;
  final String businessName;
  final String businessCategory;
  final Map<String, dynamic>? existingBusiness;

  const BusinessRegistrationScreen({
    super.key,
    required this.userId,
    required this.businessName,
    required this.businessCategory,
    this.existingBusiness,
  });

  @override
  State<BusinessRegistrationScreen> createState() =>
      _BusinessRegistrationScreenState();
}

class _BusinessRegistrationScreenState
    extends State<BusinessRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final FocusNode _descriptionFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();
  final FocusNode _cityFocus = FocusNode();
  final FocusNode _stateFocus = FocusNode();
  final FocusNode _pincodeFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _websiteFocus = FocusNode();
  final RegExp _phoneRegex = RegExp(r'^\d{10}$');
  final RegExp _pincodeRegex = RegExp(r'^\d{6}$');
  final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  final RegExp _websiteRegex = RegExp(r'^(https?://)?[\w.-]+\.[a-z]{2,}(/.*)?$');

  double? _latitude;
  double? _longitude;
  bool _isLocating = false;
  bool _locationDenied = false;

  bool isLoading = false;
  List<String> categories = [];
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.businessCategory.isNotEmpty
        ? widget.businessCategory
        : widget.existingBusiness?['business_category'];
    _fetchCategories();
    _prefillData();
  }

  void _prefillData() {
    businessNameController.text = widget.existingBusiness?['business_name'] ??
        (widget.businessName.isNotEmpty ? widget.businessName : '');
    if (widget.existingBusiness != null) {
      descriptionController.text =
          widget.existingBusiness!['description'] ?? '';
      addressController.text = widget.existingBusiness!['address'] ?? '';
      cityController.text = widget.existingBusiness!['city'] ?? '';
      stateController.text = widget.existingBusiness!['state'] ?? '';
      pincodeController.text = widget.existingBusiness!['pincode'] ?? '';
      phoneController.text = widget.existingBusiness!['phone'] ?? '';
      emailController.text = widget.existingBusiness!['email'] ?? '';
      websiteController.text = widget.existingBusiness!['website'] ?? '';
      final lat = widget.existingBusiness!['latitude'];
      final lon = widget.existingBusiness!['longitude'];
      if (lat != null && lon != null) {
        _latitude = (lat as num).toDouble();
        _longitude = (lon as num).toDouble();
      }
    }
  }

  Future<void> _captureLocation() async {
    setState(() {
      _isLocating = true;
    });

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() {
          _locationDenied = true;
        });
        Fluttertoast.showToast(
          msg: "Location services are disabled",
          backgroundColor: Colors.red,
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locationDenied = true;
        });
        Fluttertoast.showToast(
          msg: "Location permission denied",
          backgroundColor: Colors.red,
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationDenied = false;
      });
      Fluttertoast.showToast(msg: "Location captured successfully");
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Unable to get location",
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  Future<void> _fetchCategories() async {
    final authService = AuthService();
    categories = await authService.fetchBusinessCategories();
    setState(() {});
  }

  Future<void> _submitRegistration() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (selectedCategory == null || selectedCategory!.isEmpty) {
      Fluttertoast.showToast(msg: "Please select a business category");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final authService = AuthService();
      final user = await authService.getUserById(widget.userId);
      if (user == null) {
        Fluttertoast.showToast(
          msg: "Session expired. Please log in again.",
          backgroundColor: Colors.red,
        );
        if (mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
        return;
      }

      final businessService = BusinessService();
      final result = await businessService.createOrUpdateBusiness(
        userId: widget.userId,
        businessName: businessNameController.text.trim(),
        businessCategory: selectedCategory ?? widget.businessCategory,
        description: descriptionController.text.trim(),
        address: addressController.text.trim(),
        city: cityController.text.trim(),
        state: stateController.text.trim(),
        pincode: pincodeController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        phone: phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
        email: emailController.text.trim().isEmpty
            ? null
            : emailController.text.trim(),
        website: websiteController.text.trim().isEmpty
            ? null
            : websiteController.text.trim(),
      );

      if (result != null) {
        Fluttertoast.showToast(
          msg: "Business registered successfully! You have 5 free connects.",
          toastLength: Toast.LENGTH_LONG,
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        Fluttertoast.showToast(
          msg: "Registration failed. Please try again.",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Complete Business Registration"),
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
              Text(
                widget.existingBusiness != null
                    ? "Update your business details"
                    : "Add your business details to get started",
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              CustomTextBox(
                controller: businessNameController,
                labelText: "Business Name",
                prefixIcon: Icons.storefront,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  final name = (value ?? '').trim();
                  if (name.isEmpty) {
                    return "Please enter business name";
                  }
                  if (name.length < 2) {
                    return "Business name is too short";
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _descriptionFocus.requestFocus(),
              ),

              const SizedBox(height: 16),

              // Business Category
              DropdownSearch<String>(
                selectedItem: selectedCategory,
                items: (String filter, LoadProps? props) async {
                  if (filter.isEmpty) return categories;
                  return categories
                      .where(
                        (c) => c.toLowerCase().contains(filter.toLowerCase()),
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
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.category),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedItem ?? "Business Category",
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  menuProps: const MenuProps(backgroundColor: Colors.white),
                ),
              ),

              const SizedBox(height: 16),

              CustomTextBox(
                controller: descriptionController,
                labelText: "Business Description",
                prefixIcon: Icons.description,
                maxLines: 3,
                focusNode: _descriptionFocus,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _addressFocus.requestFocus(),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.my_location, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Business Location",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _latitude != null && _longitude != null
                                ? "Location captured"
                                : _locationDenied
                                ? "Location not available"
                                : "Use current location for nearby search",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _isLocating ? null : _captureLocation,
                      child: Text(_isLocating ? "Locating..." : "Use Location"),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              CustomTextBox(
                controller: addressController,
                labelText: "Address",
                prefixIcon: Icons.location_on,
                maxLines: 2,
                focusNode: _addressFocus,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _cityFocus.requestFocus(),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: CustomTextBox(
                      controller: cityController,
                      labelText: "City",
                      prefixIcon: Icons.location_city,
                      focusNode: _cityFocus,
                      textInputAction: TextInputAction.next,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) {
                        final city = (value ?? '').trim();
                        if (city.isEmpty) {
                          return "Enter city";
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _stateFocus.requestFocus(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextBox(
                      controller: stateController,
                      labelText: "State",
                      prefixIcon: Icons.map,
                      focusNode: _stateFocus,
                      textInputAction: TextInputAction.next,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) {
                        final state = (value ?? '').trim();
                        if (state.isEmpty) {
                          return "Enter state";
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _pincodeFocus.requestFocus(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              CustomTextBox(
                controller: pincodeController,
                labelText: "Pincode",
                prefixIcon: Icons.pin,
                keyboardType: TextInputType.number,
                focusNode: _pincodeFocus,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                validator: (value) {
                  final pin = (value ?? '').trim();
                  if (pin.isEmpty) {
                    return "Enter pincode";
                  }
                  if (!_pincodeRegex.hasMatch(pin)) {
                    return "Enter a valid 6-digit pincode";
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
              ),

              const SizedBox(height: 16),

              CustomTextBox(
                controller: phoneController,
                labelText: "Business Phone (Optional)",
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                focusNode: _phoneFocus,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  final phone = (value ?? '').trim();
                  if (phone.isEmpty) return null;
                  if (!_phoneRegex.hasMatch(phone)) {
                    return "Enter a valid 10-digit phone";
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _emailFocus.requestFocus(),
              ),

              const SizedBox(height: 16),

              CustomTextBox(
                controller: emailController,
                labelText: "Business Email (Optional)",
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                focusNode: _emailFocus,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  final email = (value ?? '').trim();
                  if (email.isEmpty) return null;
                  if (!_emailRegex.hasMatch(email)) {
                    return "Enter a valid email";
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _websiteFocus.requestFocus(),
              ),

              const SizedBox(height: 16),

              CustomTextBox(
                controller: websiteController,
                labelText: "Website (Optional)",
                prefixIcon: Icons.language,
                keyboardType: TextInputType.url,
                focusNode: _websiteFocus,
                textInputAction: TextInputAction.done,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  final site = (value ?? '').trim();
                  if (site.isEmpty) return null;
                  if (!_websiteRegex.hasMatch(site)) {
                    return "Enter a valid website";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              CustomButton(
                text: isLoading
                    ? (widget.existingBusiness != null
                          ? "Updating..."
                          : "Registering...")
                    : (widget.existingBusiness != null
                          ? "Update Profile"
                          : "Complete Registration"),
                onPressed: isLoading ? null : _submitRegistration,
              ),

              const SizedBox(height: 16),

              const Text(
                "Note: You'll get 5 free connects to start. Upgrade to yearly subscription (₹365) for unlimited connects.",
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    descriptionController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();
    phoneController.dispose();
    emailController.dispose();
    websiteController.dispose();
    businessNameController.dispose();
    _descriptionFocus.dispose();
    _addressFocus.dispose();
    _cityFocus.dispose();
    _stateFocus.dispose();
    _pincodeFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _websiteFocus.dispose();
    super.dispose();
  }
}
