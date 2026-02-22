import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nukkad/services/auth_service.dart';
import 'package:nukkad/utils/app_colors.dart';
import 'package:nukkad/widgets/custom_button.dart';
import 'package:nukkad/widgets/custom_textbox.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController mobileController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _submitting = false;
  final RegExp _phoneRegex = RegExp(r'^\d{10}$');

  @override
  void dispose() {
    mobileController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final phone = mobileController.text.trim();
    if (phone.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter your mobile number");
      return;
    }
    if (!_phoneRegex.hasMatch(phone)) {
      Fluttertoast.showToast(msg: "Enter a valid 10-digit mobile number");
      return;
    }

    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reset Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "New Password"),
            ),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Confirm Password"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Update"),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      newPasswordController.dispose();
      confirmPasswordController.dispose();
      return;
    }

    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    newPasswordController.dispose();
    confirmPasswordController.dispose();

    if (newPassword.length < 6) {
      Fluttertoast.showToast(msg: "Password must be at least 6 characters");
      return;
    }
    if (newPassword != confirmPassword) {
      Fluttertoast.showToast(msg: "Passwords do not match");
      return;
    }

    setState(() => _submitting = true);
    final ok = await _authService.resetPasswordByPhone(
      phone: phone,
      newPassword: newPassword,
    );
    setState(() => _submitting = false);

    if (ok) {
      Fluttertoast.showToast(msg: "Password updated successfully");
      if (mounted) Navigator.pop(context);
    } else {
      Fluttertoast.showToast(
        msg: "Unable to reset password. Check your phone number.",
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                /// 🔹 App Logo
                Image.asset(
                  'assets/images/app_icon.png',
                  height: 90,
                ),

                const SizedBox(height: 20),

                const Text(
                  "Forgot Password",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Enter your registered mobile number",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15),
                ),

                const SizedBox(height: 20),

                /// 🔹 Card
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
                  child: Column(
                    children: [

                      CustomTextBox(
                        controller: mobileController,
                        labelText: "Mobile Number",
                        prefixIcon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                      ),

                      const SizedBox(height: 20),

                      CustomButton(
                        text: _submitting ? "Updating..." : "Reset Password",
                        onPressed: _submitting ? null : _resetPassword,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                /// 🔹 Back to Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Remembered your password? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
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
}
