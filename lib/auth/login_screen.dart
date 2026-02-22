import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nukkad/auth/forgotpassword_screen.dart';
import 'package:nukkad/services/auth_service.dart';
import 'package:nukkad/utils/app_colors.dart';
import 'package:nukkad/widgets/custom_button.dart';
import 'package:nukkad/widgets/custom_textbox.dart';
import 'package:nukkad/auth/signup_screen.dart';
import 'package:nukkad/dashboard/customer_dashboard.dart';
import 'package:nukkad/dashboard/business_dashboard.dart';
import 'package:nukkad/dashboard/admin_dashboard.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  final String userType;

  const LoginScreen({super.key, required this.userType});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FocusNode _passwordFocus = FocusNode();
  final RegExp _phoneRegex = RegExp(r'^\d{10}$');

  bool rememberMe = false;
  bool obscurePassword = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRemembered();
  }

  @override
  void dispose() {
    mobileController.dispose();
    passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _loadRemembered() async {
    final prefs = await SharedPreferences.getInstance();
    final remembered = prefs.getBool('remember_me') ?? false;
    final phone = prefs.getString('remember_phone');
    if (remembered && phone != null) {
      setState(() {
        rememberMe = true;
        mobileController.text = phone;
      });
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
                Image.asset('assets/images/app_icon.png', height: 90),

                const SizedBox(height: 20),

                const Text(
                  "Welcome Back!",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                /// 🔹 Login Card
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
                          controller: mobileController,
                          labelText: "Mobile Number",
                          prefixIcon: Icons.phone,
                          keyboardType: TextInputType.phone,
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
                          onFieldSubmitted: (_) {
                            _passwordFocus.requestFocus();
                          },
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
                          textInputAction: TextInputAction.done,
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
                          onSuffixTap: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Checkbox(
                              activeColor: AppColors.primary,
                              value: rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  rememberMe = value!;
                                });
                              },
                            ),
                            const Text("Remember me"),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              child: const Text("Forgot password?"),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        CustomButton(
                          text: isLoading ? "Logging in..." : "Login",
                          onPressed: isLoading ? null : () async {
                            FocusScope.of(context).unfocus();
                            if (!(_formKey.currentState?.validate() ?? false)) {
                              return;
                            }

                            setState(() {
                              isLoading = true;
                            });

                            try {
                              final authService = AuthService();
                              final user = await authService.login(
                                mobileController.text.trim(),
                                passwordController.text.trim(),
                              );

                              if (user != null) {
                                // Check if role matches userType
                                if (user['role'] == widget.userType.toLowerCase()) {
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setString('user_role', user['role']);
                                  await prefs.setInt('user_id', user['user_id']);
                                  await prefs.setString('full_name', user['full_name']);
                                  await prefs.setString('phone', user['phone']);
                                  await prefs.setBool('remember_me', rememberMe);
                                  if (rememberMe) {
                                    await prefs.setString('remember_phone', user['phone']);
                                  } else {
                                    await prefs.remove('remember_phone');
                                  }

                                  if (widget.userType.toLowerCase() == "customer") {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const CustomerDashboard(),
                                      ),
                                    );
                                  } else if (widget.userType.toLowerCase() == "admin") {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const AdminDashboard(),
                                      ),
                                    );
                                  } else {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const BusinessDashboard(),
                                      ),
                                    );
                                  }
                                } else {
                                  Fluttertoast.showToast(
                                    msg: "This account is registered as ${user['role']}. Please login from the correct section.",
                                    toastLength: Toast.LENGTH_LONG,
                                  );
                                }
                              } else {
                                Fluttertoast.showToast(
                                  msg: "Invalid mobile number or password",
                                  backgroundColor: Colors.red,
                                );
                              }
                            } catch (e) {
                              Fluttertoast.showToast(
                                msg: "Login failed. Please try again.",
                                backgroundColor: Colors.red,
                              );
                            } finally {
                              if (mounted) {
                                setState(() {
                                  isLoading = false;
                                });
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                /// 🔹 Signup Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SignupScreen(userType: widget.userType),
                          ),
                        );
                      },
                      child: const Text(
                        "Sign up now",
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
