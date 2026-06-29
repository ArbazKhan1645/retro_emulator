import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

enum AppThemeMode {
  dark,
  oledBlack,
  blueNeon,
  purple,
  retroCRT,
  cyberpunk,
  synthwave,
}

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme => _buildTheme(
        background: AppColors.background,
        surface: AppColors.surface,
        card: AppColors.card,
        primary: AppColors.primary,
      );

  static ThemeData getTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.oledBlack:
        return _buildTheme(
          background: AppColors.oledBackground,
          surface: AppColors.oledSurface,
          card: AppColors.oledCard,
          primary: AppColors.primary,
        );
      case AppThemeMode.blueNeon:
        return _buildTheme(
          background: AppColors.neonBlueBackground,
          surface: const Color(0xFF101823),
          card: const Color(0xFF17212E),
          primary: AppColors.neonBluePrimary,
        );
      case AppThemeMode.purple:
        return _buildTheme(
          background: AppColors.purpleBackground,
          surface: const Color(0xFF171520),
          card: const Color(0xFF1E1B29),
          primary: AppColors.purplePrimary,
        );
      case AppThemeMode.retroCRT:
        return _buildTheme(
          background: AppColors.crtBackground,
          surface: const Color(0xFF111713),
          card: const Color(0xFF18201B),
          primary: AppColors.crtGreen,
        );
      case AppThemeMode.cyberpunk:
        return _buildTheme(
          background: AppColors.cyberpunkBackground,
          surface: const Color(0xFF191711),
          card: const Color(0xFF211E16),
          primary: AppColors.cyberpunkYellow,
        );
      case AppThemeMode.synthwave:
        return _buildTheme(
          background: AppColors.synthwaveBackground,
          surface: const Color(0xFF1B151A),
          card: const Color(0xFF251C22),
          primary: AppColors.synthwavePrimary,
        );
      case AppThemeMode.dark:
        return darkTheme;
    }
  }

  static ThemeData _buildTheme({
    required Color background,
    required Color surface,
    required Color card,
    required Color primary,
  }) {
    final colorScheme = ColorScheme.dark(
      primary: primary,
      secondary: AppColors.neonCyan,
      surface: surface,
      error: AppColors.error,
      onPrimary: AppColors.overlay,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      onError: Colors.white,
    );
    final baseTextTheme =
        GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: card,
      dividerColor: AppColors.glassBorder,
      splashFactory: InkSparkle.splashFactory,
      textTheme: baseTextTheme.copyWith(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        displaySmall: AppTextStyles.displaySmall,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.displaySmall,
        iconTheme:
            const IconThemeData(color: AppColors.textSecondary, size: 22),
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: surface,
        elevation: 0,
        indicatorColor: primary.withOpacity(0.14),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? primary
                  : AppColors.textMuted,
              size: 22,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => AppTextStyles.labelSmall.copyWith(
                  color: states.contains(WidgetState.selected)
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                  fontWeight: states.contains(WidgetState.selected)
                      ? FontWeight.w600
                      : FontWeight.w500,
                )),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        useIndicator: true,
        indicatorColor: primary.withOpacity(.12),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        selectedIconTheme: IconThemeData(color: primary, size: 22),
        unselectedIconTheme:
            const IconThemeData(color: AppColors.textMuted, size: 22),
        selectedLabelTextStyle: AppTextStyles.labelLarge.copyWith(
          color: AppColors.textPrimary,
        ),
        unselectedLabelTextStyle: AppTextStyles.labelLarge.copyWith(
          color: AppColors.textMuted,
        ),
        minWidth: 76,
        minExtendedWidth: 224,
      ),
      cardTheme: CardThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
        labelStyle: AppTextStyles.bodyMedium,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: _inputBorder(AppColors.glassBorder),
        enabledBorder: _inputBorder(AppColors.glassBorder),
        focusedBorder: _inputBorder(primary, width: 1.5),
        errorBorder: _inputBorder(AppColors.error),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: AppColors.overlay,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: AppTextStyles.labelLarge,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: AppColors.overlay,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: AppTextStyles.labelLarge,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          side: const BorderSide(color: AppColors.glassBorder),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: AppTextStyles.labelLarge,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: AppColors.overlay,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 22),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        selectedColor: primary.withOpacity(0.14),
        disabledColor: surface,
        side: const BorderSide(color: AppColors.glassBorder),
        labelStyle: AppTextStyles.labelMedium,
        secondaryLabelStyle: AppTextStyles.labelMedium.copyWith(color: primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF222A35),
        contentTextStyle:
            AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 2,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: AppTextStyles.headlineMedium,
        contentTextStyle: AppTextStyles.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: AppColors.glassBorder,
        thumbColor: primary,
        overlayColor: primary.withOpacity(0.12),
        trackHeight: 3,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? Colors.white
                : AppColors.textMuted),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? primary
                : AppColors.glassBorder),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textSecondary,
        titleTextStyle: AppTextStyles.bodyLarge,
        subtitleTextStyle: AppTextStyles.bodySmall,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: AppColors.glassBorder,
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: AppColors.glassBorder,
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: AppTextStyles.labelLarge,
        unselectedLabelStyle: AppTextStyles.labelLarge,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
