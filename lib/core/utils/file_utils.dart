import 'dart:io';
import 'package:path/path.dart' as p;
import '../constants/app_constants.dart';

/// File system utility functions
class FileUtils {
  FileUtils._();

  /// Returns true if the file is a supported ROM
  static bool isSupportedRom(String path) {
    final ext = p.extension(path).toLowerCase();
    return AppConstants.allSupportedExtensions.contains(ext);
  }

  /// Get console name from file extension
  static String consoleFromExtension(String path) {
    final ext = p.extension(path).toLowerCase();
    return AppConstants.extensionToConsole[ext] ?? 'Unknown';
  }

  /// Get file size in bytes
  static Future<int> getFileSize(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (_) {}
    return 0;
  }

  /// Recursively scan directory for ROMs
  static Future<List<String>> scanDirectory(
    String dirPath, {
    bool recursive = true,
  }) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return [];

    final romPaths = <String>[];
    await for (final entity in dir.list(recursive: recursive)) {
      if (entity is File && isSupportedRom(entity.path)) {
        romPaths.add(entity.path);
      }
    }
    return romPaths;
  }

  /// Get filename without extension from a path
  static String fileNameWithoutExt(String path) {
    return p.basenameWithoutExtension(path);
  }

  /// Ensure directory exists
  static Future<Directory> ensureDir(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Copy a file
  static Future<File?> copyFile(String source, String destination) async {
    try {
      final src = File(source);
      if (!await src.exists()) return null;
      return await src.copy(destination);
    } catch (e) {
      return null;
    }
  }

  /// Delete a file safely
  static Future<bool> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (_) {}
    return false;
  }
}
