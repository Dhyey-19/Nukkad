import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nukkad/services/auth_service.dart';
import 'package:nukkad/utils/app_colors.dart';
import 'package:nukkad/widgets/custom_button.dart';
import 'package:nukkad/widgets/custom_textbox.dart';

class CustomerEditProfileScreen extends StatefulWidget {
  final int userId;
  final Map<String, dynamic>? existingUser;

  const CustomerEditProfileScreen({
    super.key,
    required this.userId,
    this.existingUser,
  });

  @override
  State<CustomerEditProfileScreen> createState() => _CustomerEditProfileScreenState();
}

class _CustomerEditProfileScreenState extends State<CustomerEditProfileScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.existingUser?['full_name'] ?? '';
    emailController.text = widget.existingUser?['email'] ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    final ok = await _authService.updateUser(
      userId: widget.userId,
      fullName: nameController.text.trim(),
      email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
    );
    setState(() => isLoading = false);
    if (ok) {
      Fluttertoast.showToast(msg: "Profile updated");
      if (mounted) Navigator.pop(context, true);
    } else {
      Fluttertoast.showToast(msg: "Failed to update profile", backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextBox(
                controller: nameController,
                labelText: "Full Name *",
                prefixIcon: Icons.person,
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
              ),
              const SizedBox(height: 16),
              CustomTextBox(
                controller: emailController,
                labelText: "Email (Optional)",
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  final email = (value ?? '').trim();
                  if (email.isEmpty) return null;
                  if (!_emailRegex.hasMatch(email)) {
                    return "Enter a valid email";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: isLoading ? "Saving..." : "Save",
                onPressed: isLoading ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }
}

