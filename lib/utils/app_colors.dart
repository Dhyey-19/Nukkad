import 'package:flutter/material.dart';

/// A central place to manage all app color codes.
/// Professionally tuned palette for a modern, clean UI.
class AppColors {
  // 🔹 Brand Colors - Modern Professional Blue
  /// Primary blue used for icons, buttons, accents
  static const Color primary = Color(0xFF2563EB); // Tailwind blue-600

  /// Slightly lighter blue for secondary emphasis
  static const Color secondary = Color(0xFF3B82F6); // Tailwind blue-500

  /// Very light blue for soft icon / card backgrounds
  static const Color accent = Color(0xFFEFF6FF); // Tailwind blue-50

  // 🔹 Backgrounds
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF9FAFB); // Elegant off-white (gray-50)

  // 🔹 Text Colors
  static const Color textPrimary = Color(0xFF1F2937); // Soft black (gray-800)
  static const Color textSecondary = Color(0xFF4B5563); // Gray-600
  static const Color textHint = Color(0xFF9CA3AF); // Gray-400

  // 🔹 Border & Divider
  static const Color border = Color(0xFFE5E7EB); // Gray-200

  // 🔹 Input Fields
  static const Color inputFill = Color(0xFFF3F4F6); // Gray-100

  // 🔹 Status Colors
  static const Color success = Color(0xFF10B981); // Emerald-500
  static const Color error = Color(0xFFEF4444); // Red-500
  static const Color warning = Color(0xFFF59E0B); // Amber-500
  static const Color info = Color(0xFF3B82F6); // Blue-500

  // 🔹 Neutral Shades (for UI depth)
  static const Color grayLight = Color(0xFFF3F4F6); // Gray-100
  static const Color gray = Color(0xFF9CA3AF); // Gray-400
  static const Color grayDark = Color(0xFF374151); // Gray-700

  // 🔹 Gradients (Optional)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)], // Blue-500 to Blue-700
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
