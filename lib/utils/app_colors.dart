import 'package:flutter/material.dart';

/// A central place to manage all app color codes.
/// Use these colors consistently across your app for a professional look.
class AppColors {
  // 🔹 Brand Colors
  /// Primary blue used for icons, buttons, accents
  static const Color primary = Color(0xFF1565C0);

  /// Slightly lighter blue for secondary emphasis
  static const Color secondary = Color(0xFF1E88E5);

  /// Very light blue for soft icon / card backgrounds
  static const Color accent = Color(0xFFE3F2FD);

  // 🔹 Backgrounds
  static const Color cardBackground = Color(0xFFF5F6FA);
  static const Color background = Color(0xFFFFFFFF);

  // 🔹 Text Colors
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);

  // 🔹 Border & Divider
  static const Color border = Color(0xFFE5E7EB);

  // 🔹 Status Colors
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // 🔹 Neutral Shades (for UI depth)
  static const Color grayLight = Color(0xFFF3F4F6);
  static const Color gray = Color(0xFF9CA3AF);
  static const Color grayDark = Color(0xFF4B5563);

  // 🔹 Gradients (Optional)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1878F3), Color(0xFF42A5F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
