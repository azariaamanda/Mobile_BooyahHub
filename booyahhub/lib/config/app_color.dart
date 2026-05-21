import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand Colors (Gold/Emas dari desain)
  static const Color primary = Color(0xFFC9A227);      // Emas utama
  static const Color primaryLight = Color(0xFFE8D5A8);  // Emas muda
  static const Color primaryDark = Color(0xFF8B6914);   // Emas tua
  static const Color accent = Color(0xFF10B981);        // Hijau accent (success)
  static const Color accentRed = Color(0xFF8B1A00);     // Merah accent (error/warning)

  // Base Colors (Dark Theme)
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Background (Dark)
  static const Color background = Color(0xFF020C15);    // Biru gelap tua
  static const Color backgroundCard = Color(0xFF05121D); // Biru gelap
  static const Color backgroundInput = Color(0xFF0A1A26); // Input field

  // Surface
  static const Color surface = Color(0xFF0F1F2C);
  static const Color surfaceVariant = Color(0xFF1A2B38);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);    // Putih
  static const Color textSecondary = Color(0xFFC4C7CB);  // Abu-abu terang
  static const Color textHint = Color(0xFF8E8E93);       // Abu-abu hint
  static const Color textDisabled = Color(0xFF5C5F66);   // Abu-abu gelap
  static const Color textGold = Color(0xFFC9A227);       // Emas untuk highlight

  // Input
  static const Color inputBorder = Color(0xFF2A3A48);
  static const Color inputBorderFocused = Color(0xFFC9A227);
  static const Color inputIcon = Color(0xFF8E8E93);
  static const Color inputFill = Color(0xFF0A1A26);

  // Button
  static const Color buttonPrimary = Color(0xFFC9A227);
  static const Color buttonPrimaryDisabled = Color(0xFF5C4A15);
  static const Color buttonText = Color(0xFF020C15);
  static const Color buttonSecondary = Color(0xFF2A3A48);
  static const Color buttonSecondaryText = Color(0xFFC4C7CB);

  // Status Colors
  static const Color success = Color(0xFF10B981);     // Hijau
  static const Color warning = Color(0xFFF5C400);     // Kuning
  static const Color error = Color(0xFFF44336);       // Merah
  static const Color info = Color(0xFF3B82F6);        // Biru
  static const Color urgent = Color(0xFF8B1A00);      // Merah tua (untuk urgent)

  // Divider
  static const Color divider = Color(0xFF1E2D3A);

  // Chip / Tag
  static const Color chipActive = Color(0xFF1E2D3A);
  static const Color chipActiveText = Color(0xFFC9A227);
  static const Color chipInactive = Color(0xFF1A2B38);
  static const Color chipInactiveText = Color(0xFF8E8E93);

  // Shadow
  static const Color shadow = Color(0x1A000000);

  // Chart / Graph
  static const Color chartPrimary = Color(0xFFC9A227);
  static const Color chartSecondary = Color(0xFF10B981);
  static const Color chartTertiary = Color(0xFFE4E2E2);
  static const Color chartBar = Color(0xFF2A3A48);
}