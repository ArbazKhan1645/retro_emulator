import 'package:flutter/material.dart';

/// Console metadata and branding info
class ConsoleInfo {
  final String id;
  final String name;
  final String shortName;
  final List<String> extensions;
  final Color primaryColor;
  final Color accentColor;
  final String iconPath;
  final String manufacturer;
  final int releaseYear;

  const ConsoleInfo({
    required this.id,
    required this.name,
    required this.shortName,
    required this.extensions,
    required this.primaryColor,
    required this.accentColor,
    this.iconPath = '',
    required this.manufacturer,
    required this.releaseYear,
  });

  static const ConsoleInfo genesis = ConsoleInfo(
    id: 'genesis',
    name: 'Sega Genesis',
    shortName: 'GEN',
    extensions: ['.bin', '.md', '.gen', '.smd'],
    primaryColor: Color(0xFF1A3FA4),
    accentColor: Color(0xFF00AEEF),
    manufacturer: 'Sega',
    releaseYear: 1988,
  );

  static const ConsoleInfo megaDrive = ConsoleInfo(
    id: 'megadrive',
    name: 'Sega Mega Drive',
    shortName: 'MD',
    extensions: ['.bin', '.md', '.gen', '.smd'],
    primaryColor: Color(0xFF1A3FA4),
    accentColor: Color(0xFF00AEEF),
    manufacturer: 'Sega',
    releaseYear: 1988,
  );

  static ConsoleInfo fromExtension(String ext) {
    switch (ext.toLowerCase()) {
      case '.bin':
      case '.md':
      case '.gen':
      case '.smd':
        return genesis;
      default:
        return genesis;
    }
  }

  static const List<ConsoleInfo> supported = [genesis];
}
