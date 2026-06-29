import 'package:flutter/material.dart';

/// A restrained, product-focused palette used throughout the application.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF080B10);
  static const Color surface = Color(0xFF0E131B);
  static const Color card = Color(0xFF141A23);
  static const Color cardHover = Color(0xFF1A222E);
  static const Color overlay = Color(0xFF05070A);

  static const Color primary = Color(0xFFC9A96E);
  static const Color primaryLight = Color(0xFFE1C58F);
  static const Color primaryDark = Color(0xFFA7834D);

  // Kept as semantic aliases for existing features, with subdued values.
  static const Color neonCyan = Color(0xFF80A8B1);
  static const Color hotPink = Color(0xFFC98392);
  static const Color neonGreen = Color(0xFF78A486);
  static const Color goldenYellow = Color(0xFFC9A96E);
  static const Color electricBlue = Color(0xFF8095BE);

  static const Color textPrimary = Color(0xFFF5F2EB);
  static const Color textSecondary = Color(0xFFB1B6BF);
  static const Color textMuted = Color(0xFF777F8C);
  static const Color textHint = Color(0xFF4E5663);
  static const Color glassWhite = Color(0x0AFFFFFF);
  static const Color glassBorder = Color(0xFF252D38);
  static const Color glassDark = Color(0x52000000);

  static const Color success = Color(0xFF63AC82);
  static const Color warning = Color(0xFFD0A050);
  static const Color error = Color(0xFFD96868);
  static const Color info = Color(0xFF67AEB8);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0x000B0E13), background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient cardGradient = LinearGradient(
    colors: [cardHover, card],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient cyberGradient = LinearGradient(
    colors: [background, Color(0xFF0E131A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const RadialGradient glowGradient = RadialGradient(
    colors: [Color(0x245B8DEF), Colors.transparent],
    radius: 0.8,
  );

  static const Color oledBackground = Color(0xFF000000);
  static const Color oledSurface = Color(0xFF0A0C0F);
  static const Color oledCard = Color(0xFF111419);
  static const Color neonBluePrimary = Color(0xFF8298C0);
  static const Color neonBlueBackground = Color(0xFF0A111B);
  static const Color purplePrimary = Color(0xFF9B8CB9);
  static const Color purpleBackground = Color(0xFF100F17);
  static const Color synthwavePrimary = Color(0xFFB4778D);
  static const Color synthwaveBackground = Color(0xFF151015);
  static const Color synthwaveAccent = Color(0xFF8EA5B5);
  static const Color crtGreen = Color(0xFF6F9F7C);
  static const Color crtBackground = Color(0xFF0B100D);
  static const Color cyberpunkYellow = Color(0xFFC09D58);
  static const Color cyberpunkBackground = Color(0xFF12100C);
  static const Color cyberpunkCyan = Color(0xFF799DA3);
}
