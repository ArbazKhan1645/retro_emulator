import 'package:flutter/material.dart';

extension BuildContextExtensions on BuildContext {
  // === THEME ===
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  // === MEDIA QUERY ===
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  EdgeInsets get padding => MediaQuery.of(this).padding;
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;
  bool get isTablet => screenWidth >= 600;
  bool get isDesktop => screenWidth >= 1024;
  bool get isLandscape =>
      MediaQuery.of(this).orientation == Orientation.landscape;

  // === SNACKBAR ===
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(this).colorScheme.error : null,
      ),
    );
  }

  // === NAVIGATION ===
  void pop<T>([T? result]) => Navigator.of(this).pop(result);
}
