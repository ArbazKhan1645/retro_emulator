import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../models/game_model.dart';
import '../../core/constants/app_constants.dart';

final romScannerProvider = Provider<RomScannerService>((ref) {
  return RomScannerService();
});

/// Progress snapshot emitted during a ROM scan operation.
class ScanProgress {
  /// Number of files processed so far.
  final int scanned;

  /// Total number of ROM files found in the scan directories.
  final int total;

  /// Filename currently being processed.
  final String currentFile;

  /// Whether the scan has completed.
  final bool isDone;

  /// Populated with all found games only when [isDone] is true.
  final List<GameModel> foundGames;

  const ScanProgress({
    this.scanned = 0,
    this.total = 0,
    this.currentFile = '',
    this.isDone = false,
    this.foundGames = const [],
  });

  /// Returns a progress value between 0.0 and 1.0.
  double get progressFraction =>
      total == 0 ? 0.0 : (scanned / total).clamp(0.0, 1.0);
}

/// Scans one or more directories for Sega Genesis ROM files and converts
/// them into [GameModel] instances.
///
/// Supported extensions: `.bin`, `.md`, `.gen`, `.smd`
///
/// Usage:
/// ```dart
/// await for (final progress in scanner.scan(['/path/to/roms'])) {
///   print('${progress.scanned}/${progress.total}: ${progress.currentFile}');
///   if (progress.isDone) print('Found ${progress.foundGames.length} ROMs');
/// }
/// ```
class RomScannerService {
  /// Scans the given [folders] for ROM files.
  ///
  /// Yields [ScanProgress] updates as each file is processed.
  /// The final emission has [ScanProgress.isDone] == true and contains
  /// all found [GameModel]s in [ScanProgress.foundGames].
  Stream<ScanProgress> scan(List<String> folders) async* {
    if (folders.isEmpty) {
      yield const ScanProgress(isDone: true);
      return;
    }

    // Collect all potential ROM paths first
    final allPaths = <String>[];
    for (final folder in folders) {
      final dir = Directory(folder);
      if (!await dir.exists()) continue;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (AppConstants.allSupportedExtensions.contains(ext)) {
            allPaths.add(entity.path);
          }
        }
      }
    }

    final total = allPaths.length;
    if (total == 0) {
      yield const ScanProgress(isDone: true, foundGames: []);
      return;
    }

    yield ScanProgress(total: total, scanned: 0);

    final foundGames = <GameModel>[];
    for (int i = 0; i < allPaths.length; i++) {
      final path = allPaths[i];
      final file = File(path);
      final size = await file.length();
      final ext = p.extension(path).toLowerCase();
      final name = p.basenameWithoutExtension(path);

      final game = GameModel(
        id: _generateId(path),
        title: _cleanTitle(name),
        romPath: path,
        consolePlatform: AppConstants.extensionToConsole[ext] ?? 'Sega Genesis',
        fileSizeBytes: size,
        fileExtension: ext,
        addedAt: DateTime.now(),
      );
      foundGames.add(game);

      yield ScanProgress(
        scanned: i + 1,
        total: total,
        currentFile: p.basename(path),
        isDone: i == allPaths.length - 1,
        foundGames: i == allPaths.length - 1 ? List.from(foundGames) : [],
      );
    }
  }

  /// Generates a deterministic ID from the file path.
  ///
  /// Combines path hash with a timestamp component to reduce collision risk
  /// when the same directory is re-scanned after files are added.
  String _generateId(String path) {
    final hash = path.hashCode.abs();
    return 'game_${hash}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Strips common ROM tagging conventions from the filename:
  /// - Parenthetical tags: `(USA)`, `(Europe)`, `(Beta)`, etc.
  /// - Bracketed flags: `[!]`, `[a1]`, etc.
  /// - Excess whitespace
  String _cleanTitle(String name) {
    return name
        .replaceAll(RegExp(r'\(.*?\)'), '')
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .replaceAll(RegExp(r'  +'), ' ')
        .trim();
  }
}
