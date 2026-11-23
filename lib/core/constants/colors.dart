import 'package:flutter/material.dart';

/// Casama Design System Color Tokens
class CasamaColors {
  // Brand Core Colors
  static const Color primaryCoral = Color(0xFFE87968);
  static const Color deepTeal = Color(0xFF3F7772);
  static const Color midnightNavy = Color(0xFF1C2E4A);
  static const Color dustyBlue = Color(0xFF52677D);
  static const Color ivory = Color(0xFFBDC4D4);

  // Backgrounds & Surfaces
  static const Color warmCream = Color(0xFFFFF8F1);
  static const Color softNeutral = Color(0xFFF3F5F4);
  static const Color white = Color(0xFFFFFFFF);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color borderGray = Color(0xFFDCE3E0);

  // Typography
  static const Color ink = Color(0xFF1C2E4A);
  static const Color textSecondary = Color(0xFF607078);
  static const Color textMuted = Color(0xFF9EABB2);

  // Accent & Semantic
  static const Color warmGold = Color(0xFFF4B544);
  static const Color successGreen = Color(0xFF388E3C);
  static const Color successBg = Color(0xFFE8F5E9);
  static const Color warningOrange = Color(0xFFF57C00);
  static const Color warningBg = Color(0xFFFFF3E0);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color errorBg = Color(0xFFFFEBEE);

  // Status Chips
  static const Color homeGreen = Color(0xFF2E7D32);
  static const Color homeBg = Color(0xFFE8F5E9);
  static const Color outGray = Color(0xFF757575);
  static const Color outBg = Color(0xFFEEEEEE);

  // Quick Action Tile Accents
  static const Color tileParcels = Color(0xFFFFECE8);
  static const Color tileMaintenance = Color(0xFFE8F1F5);
  static const Color tileLostFound = Color(0xFFE8F5F1);
  static const Color tileChat = Color(0xFFEBF0FA);

  // Dark Mode Tokens
  static const Color darkBackground = Color(0xFF0F1A2B);
  static const Color darkSurface = Color(0xFF18263D);
  static const Color darkCard = Color(0xFF1E2F4A);
  static const Color darkBorder = Color(0xFF2C4164);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Dark Mode Quick Action Tile Accents
  static const Color darkTileParcels = Color(0xFF332025);
  static const Color darkTileMaintenance = Color(0xFF1A2B3D);
  static const Color darkTileLostFound = Color(0xFF19322F);
  static const Color darkTileChat = Color(0xFF20263D);

  // Bills & Payments
  static const Color tileBills = Color(0xFFFFF3E0);
  static const Color tileBillsIcon = Color(0xFFF57C00);
  static const Color darkTileBills = Color(0xFF332B1A);
  static const Color tileChoreRoulette = Color(0xFFFCE4EC);
  static const Color darkTileChoreRoulette = Color(0xFF381E28);
}

/// Convenience BuildContext extension for dynamic light/dark theming
extension CasamaThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get scaffoldBg =>
      isDark ? CasamaColors.darkBackground : CasamaColors.warmCream;
  Color get surfaceColor =>
      isDark ? CasamaColors.darkSurface : CasamaColors.white;
  Color get cardColor =>
      isDark ? CasamaColors.darkCard : CasamaColors.cardSurface;
  Color get borderColor =>
      isDark ? CasamaColors.darkBorder : CasamaColors.borderGray;

  Color get textColor => isDark ? CasamaColors.darkText : CasamaColors.ink;
  Color get textSecondaryColor =>
      isDark ? CasamaColors.darkTextSecondary : CasamaColors.textSecondary;
  Color get textMutedColor =>
      isDark ? CasamaColors.darkTextMuted : CasamaColors.textMuted;

  Color get tileParcelsColor =>
      isDark ? CasamaColors.darkTileParcels : CasamaColors.tileParcels;
  Color get tileMaintenanceColor =>
      isDark ? CasamaColors.darkTileMaintenance : CasamaColors.tileMaintenance;
  Color get tileLostFoundColor =>
      isDark ? CasamaColors.darkTileLostFound : CasamaColors.tileLostFound;
  Color get tileChatColor =>
      isDark ? CasamaColors.darkTileChat : CasamaColors.tileChat;
}
