import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/game_model.dart';
import '../../../shared/services/cover_art_service.dart';
import 'library_provider.dart';

/// A game shipped inside the app bundle under [assets/roms/].
class ExploreGameModel {
  const ExploreGameModel({
    required this.id,
    required this.title,
    required this.assetPath,
    required this.fileName,
    required this.fileExtension,
    this.folderName,
    this.coverAssetPath,
    this.coverUrl,
    this.filesystemPath,
    this.fileSizeBytes = 0,
  });

  final String id;
  final String title;
  final String assetPath;
  final String fileName;
  final String fileExtension;
  final String? folderName;
  final String? coverAssetPath;
  final String? coverUrl;
  final String? filesystemPath;
  final int fileSizeBytes;

  bool get isFilesystemSource =>
      filesystemPath != null && filesystemPath!.isNotEmpty;

  String get romBaseName => p.basenameWithoutExtension(fileName);

  ExploreGameModel copyWith({
    String? coverUrl,
    String? coverAssetPath,
  }) {
    return ExploreGameModel(
      id: id,
      title: title,
      assetPath: assetPath,
      fileName: fileName,
      fileExtension: fileExtension,
      folderName: folderName,
      coverAssetPath: coverAssetPath ?? this.coverAssetPath,
      coverUrl: coverUrl ?? this.coverUrl,
      filesystemPath: filesystemPath,
      fileSizeBytes: fileSizeBytes,
    );
  }

  GameModel toGameModel(String romPath, {String? coverUrl}) {
    return GameModel(
      id: id,
      title: title,
      romPath: romPath,
      consolePlatform:
          AppConstants.extensionToConsole[fileExtension] ?? 'Sega Genesis',
      fileSizeBytes: fileSizeBytes,
      fileExtension: fileExtension,
      coverUrl: coverUrl,
      isInstalled: true,
      addedAt: DateTime.now(),
    );
  }
}

final bundledRomServiceProvider = Provider<BundledRomService>((ref) {
  return BundledRomService();
});

/// Lists and extracts ROM files bundled in [assets/roms/].
class BundledRomService {
  static const _romAssetPrefix = 'assets/roms/';
  static const _coverAssetPrefix = 'assets/covers/';
  static const _catalogAsset = 'assets/roms/catalog.json';

  Future<List<ExploreGameModel>> loadCatalog() async {
    final fromCatalog = await _loadFromCatalogJson();
    if (fromCatalog.isNotEmpty) return fromCatalog;

    final fromManifest = await _loadFromAssetManifest();
    if (fromManifest.isNotEmpty) return fromManifest;

    if (!kIsWeb) {
      return _loadFromFilesystem();
    }

    return [];
  }

  Future<List<ExploreGameModel>> _loadFromCatalogJson() async {
    try {
      final raw = await rootBundle.loadString(_catalogAsset);
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final entries = data['games'] as List<dynamic>? ?? [];

      final games = entries.map((entry) {
        final map = entry as Map<String, dynamic>;
        final romRelative = map['rom'] as String;
        final assetPath = '$_romAssetPrefix$romRelative'.replaceAll('\\', '/');
        final fileName = p.basename(assetPath);
        final ext = p.extension(fileName).toLowerCase();
        final coverRelative = map['cover'] as String?;
        final folder = map['folder'] as String?;

        return ExploreGameModel(
          id: map['id'] as String? ?? 'bundled_${assetPath.hashCode.abs()}',
          title: map['title'] as String? ?? _cleanTitle(fileName),
          assetPath: assetPath,
          fileName: fileName,
          fileExtension: ext,
          folderName: folder,
          coverAssetPath: coverRelative == null
              ? null
              : '$_romAssetPrefix$coverRelative'.replaceAll('\\', '/'),
          fileSizeBytes: (map['size'] as num?)?.toInt() ?? 0,
        );
      }).toList();

      games.sort((a, b) => a.title.compareTo(b.title));
      return games;
    } catch (_) {
      return [];
    }
  }

  Future<List<ExploreGameModel>> _loadFromAssetManifest() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final allAssets = manifest.listAssets().toList();
    final assetSet = allAssets.toSet();

    final romPaths = allAssets.where(_isBundledRom).toList();
    if (romPaths.isEmpty) return [];

    final grouped = <String, List<String>>{};
    for (final assetPath in romPaths) {
      final relative = assetPath.substring(_romAssetPrefix.length);
      final segments =
          relative.split('/').where((part) => part.isNotEmpty).toList();

      if (segments.length <= 1) {
        grouped.putIfAbsent('', () => []).add(assetPath);
      } else {
        grouped.putIfAbsent(segments.first, () => []).add(assetPath);
      }
    }

    final games = <ExploreGameModel>[];
    for (final entry in grouped.entries) {
      if (entry.key.isEmpty) {
        for (final assetPath in entry.value) {
          games.add(await _buildGameFromRom(
            assetPath: assetPath,
            folderName: null,
            allAssets: assetSet,
          ));
        }
      } else {
        final primaryRom = _pickPrimaryRom(entry.value);
        games.add(await _buildGameFromRom(
          assetPath: primaryRom,
          folderName: entry.key,
          allAssets: assetSet,
        ));
      }
    }

    games.sort((a, b) => a.title.compareTo(b.title));
    return games;
  }

  Future<List<ExploreGameModel>> _loadFromFilesystem() async {
    for (final root in _filesystemRoots()) {
      final romsDir = Directory(p.join(root, 'assets', 'roms'));
      if (!await romsDir.exists()) continue;

      final games = await _scanFilesystemRoms(romsDir);
      if (games.isNotEmpty) return games;
    }
    return [];
  }

  List<String> _filesystemRoots() {
    final roots = <String>{Directory.current.path};

    try {
      final executable = Platform.resolvedExecutable;
      var dir = File(executable).parent;
      for (var i = 0; i < 8; i++) {
        roots.add(dir.path);
        final parent = dir.parent;
        if (parent.path == dir.path) break;
        dir = parent;
      }
    } catch (_) {}

    return roots.toList();
  }

  Future<List<ExploreGameModel>> _scanFilesystemRoms(Directory romsDir) async {
    final games = <ExploreGameModel>[];

    for (final entity in romsDir.listSync()) {
      if (entity is File && _isRomPath(entity.path)) {
        games.add(_buildGameFromFile(
          romFile: entity,
          folderName: null,
          romsDir: romsDir,
        ));
      }
    }

    for (final entity in romsDir.listSync()) {
      if (entity is! Directory) continue;
      if (p.basename(entity.path).startsWith('.')) continue;

      final folderName = p.basename(entity.path);
      final romFiles = entity
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => _isRomPath(f.path))
          .toList();
      if (romFiles.isEmpty) continue;

      games.add(_buildGameFromFile(
        romFile: _pickPrimaryRomFile(romFiles),
        folderName: folderName,
        romsDir: romsDir,
      ));
    }

    games.sort((a, b) => a.title.compareTo(b.title));
    return games;
  }

  ExploreGameModel _buildGameFromFile({
    required File romFile,
    required String? folderName,
    required Directory romsDir,
  }) {
    final fileName = p.basename(romFile.path);
    final ext = p.extension(fileName).toLowerCase();
    final title = folderName != null && folderName.isNotEmpty
        ? _cleanTitle(folderName)
        : _cleanTitle(p.basenameWithoutExtension(fileName));

    String? coverPath;
    if (folderName != null && folderName.isNotEmpty) {
      final folder = Directory(p.join(romsDir.path, folderName));
      for (final name in [
        'cover.png',
        'cover.jpg',
        'cover.webp',
        'boxart.png',
        'boxart.jpg',
      ]) {
        final coverFile = File(p.join(folder.path, name));
        if (coverFile.existsSync()) {
          coverPath = coverFile.path;
          break;
        }
      }
    }

    return ExploreGameModel(
      id: 'bundled_${romFile.path.hashCode.abs()}',
      title: title,
      assetPath: '',
      fileName: fileName,
      fileExtension: ext,
      folderName: folderName,
      coverAssetPath: coverPath,
      filesystemPath: romFile.path,
      fileSizeBytes: romFile.lengthSync(),
    );
  }

  Future<ExploreGameModel> _buildGameFromRom({
    required String assetPath,
    required String? folderName,
    required Set<String> allAssets,
  }) async {
    final fileName = p.basename(assetPath);
    final ext = p.extension(fileName).toLowerCase();
    final romBase = p.basenameWithoutExtension(fileName);
    final title = folderName != null && folderName.isNotEmpty
        ? _cleanTitle(folderName)
        : _cleanTitle(romBase);

    final coverAssetPath = _findCoverAsset(
      folderName: folderName,
      romBaseName: romBase,
      allAssets: allAssets,
    );

    int size = 0;
    try {
      final data = await rootBundle.load(assetPath);
      size = data.lengthInBytes;
    } catch (_) {}

    return ExploreGameModel(
      id: 'bundled_${assetPath.hashCode.abs()}',
      title: title,
      assetPath: assetPath,
      fileName: fileName,
      fileExtension: ext,
      folderName: folderName,
      coverAssetPath: coverAssetPath,
      fileSizeBytes: size,
    );
  }

  String? _findCoverAsset({
    required String? folderName,
    required String romBaseName,
    required Set<String> allAssets,
  }) {
    if (folderName != null && folderName.isNotEmpty) {
      final folderPrefix = '$_romAssetPrefix$folderName/';
      for (final name in [
        'cover.png',
        'cover.jpg',
        'cover.webp',
        'boxart.png',
        'boxart.jpg',
        'poster.png',
        'poster.jpg',
      ]) {
        final candidate = '$folderPrefix$name';
        if (allAssets.contains(candidate)) return candidate;
      }

      for (final coverExt in ['.png', '.jpg', '.webp']) {
        final candidate = '$_coverAssetPrefix$folderName$coverExt';
        if (allAssets.contains(candidate)) return candidate;
      }
    }

    for (final coverExt in ['.png', '.jpg', '.webp']) {
      final candidate = '$_coverAssetPrefix$romBaseName$coverExt';
      if (allAssets.contains(candidate)) return candidate;
    }

    return null;
  }

  String _pickPrimaryRom(List<String> paths) {
    if (paths.length == 1) return paths.first;

    int score(String path) {
      final name = p.basename(path).toLowerCase();
      var value = 0;
      if (name.endsWith('.md')) value += 12;
      if (name.endsWith('.bin')) value += 10;
      if (name.endsWith('.gen')) value += 9;
      if (name.endsWith('.smd')) value += 8;
      if (name.contains('(usa)') || name.contains('(u)')) value += 6;
      if (name.contains('(world)')) value += 5;
      if (name.contains('(europe)') || name.contains('(e)')) value += 4;
      if (name.contains('(japan)') || name.contains('(j)')) value += 3;
      if (name.contains('(beta)') || name.contains('(proto)')) value -= 4;
      return value;
    }

    final sorted = List<String>.from(paths)
      ..sort((a, b) => score(b).compareTo(score(a)));
    return sorted.first;
  }

  File _pickPrimaryRomFile(List<File> files) {
    return File(_pickPrimaryRom(files.map((f) => f.path).toList()));
  }

  Future<String> extractRom(ExploreGameModel game) async {
    if (game.isFilesystemSource) {
      final source = File(game.filesystemPath!);
      if (!await source.exists()) {
        throw StateError('Bundled ROM file not found: ${game.filesystemPath}');
      }

      final docs = await getApplicationDocumentsDirectory();
      final relative = game.folderName != null && game.folderName!.isNotEmpty
          ? p.join(game.folderName!, game.fileName)
          : game.fileName;
      final destPath =
          p.join(docs.path, 'retroverse', 'bundled_roms', relative);
      final destFile = File(destPath);

      if (!await destFile.exists()) {
        await destFile.parent.create(recursive: true);
        await source.copy(destPath);
      }

      return destPath;
    }

    final docs = await getApplicationDocumentsDirectory();
    final baseDir = Directory(p.join(docs.path, 'retroverse', 'bundled_roms'));

    final relative = game.assetPath.startsWith(_romAssetPrefix)
        ? game.assetPath.substring(_romAssetPrefix.length)
        : p.basename(game.assetPath);
    final destPath = p.join(baseDir.path, relative);
    final destFile = File(destPath);

    if (!await destFile.exists()) {
      await destFile.parent.create(recursive: true);
      final data = await rootBundle.load(game.assetPath);
      await destFile.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    }

    return destPath;
  }

  bool _isBundledRom(String path) {
    if (!path.startsWith(_romAssetPrefix)) return false;
    if (path.endsWith('/')) return false;
    if (p.basename(path) == 'catalog.json') return false;
    return _isRomPath(path);
  }

  bool _isRomPath(String path) {
    final fileName = p.basename(path).toLowerCase();
    if (fileName == '.gitkeep') return false;
    final ext = p.extension(path).toLowerCase();
    return AppConstants.allSupportedExtensions.contains(ext);
  }

  String _cleanTitle(String name) => name
      .replaceAll(RegExp(r'\(.*?\)'), '')
      .replaceAll(RegExp(r'\[.*?\]'), '')
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .replaceAll(RegExp(r'  +'), ' ')
      .trim();
}

final exploreGamesProvider =
    AsyncNotifierProvider<ExploreGamesNotifier, List<ExploreGameModel>>(
  ExploreGamesNotifier.new,
);

class ExploreGamesNotifier extends AsyncNotifier<List<ExploreGameModel>> {
  @override
  Future<List<ExploreGameModel>> build() async {
    final games = await ref.read(bundledRomServiceProvider).loadCatalog();
    Future.microtask(() => _enrichCoversInBackground(games));
    return games;
  }

  Future<void> _enrichCoversInBackground(List<ExploreGameModel> games) async {
    final coverArt = ref.read(coverArtServiceProvider);

    for (final game in games) {
      if (game.coverUrl != null && game.coverUrl!.isNotEmpty) continue;
      if (game.coverAssetPath != null && game.coverAssetPath!.isNotEmpty) {
        continue;
      }

      final coverUrl = await coverArt.resolveCoverForRomNames(_coverCandidates(game));
      if (coverUrl == null) continue;

      final current = state.valueOrNull;
      if (current == null) continue;

      state = AsyncData(
        current
            .map((g) => g.id == game.id ? g.copyWith(coverUrl: coverUrl) : g)
            .toList(),
      );
    }
  }

  List<String> _coverCandidates(ExploreGameModel game) => [
        game.romBaseName,
        if (game.folderName != null && game.folderName!.isNotEmpty)
          game.folderName!,
        p.basenameWithoutExtension(game.filesystemPath ?? ''),
      ];
}

final exploreGameInstallerProvider = Provider<ExploreGameInstaller>((ref) {
  return ExploreGameInstaller(ref);
});

class ExploreGameInstaller {
  ExploreGameInstaller(this._ref);
  final Ref _ref;

  Future<GameModel> install(ExploreGameModel explore) async {
    final romPath = await _ref
        .read(bundledRomServiceProvider)
        .extractRom(explore);

    final library = _ref.read(libraryProvider);
    try {
      final existing = library.games.firstWhere((g) => g.id == explore.id);
      if (existing.romPath.isNotEmpty) return existing;
    } catch (_) {}

    final file = File(romPath);
    final size = await file.length();

    final cover = explore.coverUrl ?? explore.coverAssetPath;
    final game = explore
        .toGameModel(romPath, coverUrl: cover)
        .copyWith(fileSizeBytes: size);

    await _ref.read(libraryProvider.notifier).addGame(game);
    if (game.coverUrl == null || game.coverUrl!.isEmpty) {
      await _ref.read(libraryProvider.notifier).fetchMetadata(game.id);
    }
    return game;
  }
}
