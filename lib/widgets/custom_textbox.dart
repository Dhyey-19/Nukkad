import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nukkad/utils/app_colors.dart';

class CustomTextBox extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final TextInputType keyboardType;
  final int maxLines;
  final bool enabled;
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;

  const CustomTextBox({
    super.key,
    required this.controller,
    required this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.enabled = true,
    this.validator,
    this.autovalidateMode,
    this.inputFormatters,
    this.textInputAction,
    this.focusNode,
    this.onChanged,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final int effectiveMaxLines = obscureText ? 1 : maxLines;
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: effectiveMaxLines,
      enabled: enabled,
      validator: validator,
      autovalidateMode: autovalidateMode,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      scrollPadding: const EdgeInsets.only(bottom: 120.0), // 🔹 Smooth padding when keyboard opens
      focusNode: focusNode,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      enableSuggestions: !obscureText,
      autocorrect: !obscureText,
      cursorColor: AppColors.primary,
      style: const TextStyle(
        color: AppColors.textPrimary,
        height: 1.2, // Improved line-height readability
      ),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
        ),
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                color: AppColors.primary,
              )
            : null,
        suffixIcon: suffixIcon != null
            ? IconButton(
                icon: Icon(
                  suffixIcon,
                  color: AppColors.primary,
                ),
                onPressed: onSuffixTap,
              )
            : null,

        /// 🔹 Borders
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border), // Soft neutral border
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border), // Matches textFill/background well
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5, // Slightly thinner for professionalism
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // Hide border when disabled, rely on fill
        ),
      ),
    );
  }
}
