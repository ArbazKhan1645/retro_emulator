import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Scans [assets/roms] and updates [pubspec.yaml] + [catalog.json].
///
/// Run from project root:
///   dart run tool/sync_rom_assets.dart
void main() {
  final projectRoot = _findProjectRoot();
  final romsDir = Directory(p.join(projectRoot.path, 'assets', 'roms'));

  if (!romsDir.existsSync()) {
    stderr.writeln('No assets/roms directory found at ${romsDir.path}');
    exit(1);
  }

  final games = <Map<String, dynamic>>[];
  final assetDirs = <String>{'assets/roms/'};

  void addGame({
    required String folderName,
    required String romRelativePath,
    String? coverRelativePath,
    required int sizeBytes,
  }) {
    final assetPath = 'assets/roms/$romRelativePath'.replaceAll('\\', '/');
    assetDirs.add('${p.dirname(assetPath)}/'.replaceAll('\\', '/'));

    games.add({
      'id': 'bundled_${assetPath.hashCode.abs()}',
      'title': _cleanTitle(folderName.isEmpty
          ? p.basenameWithoutExtension(romRelativePath)
          : folderName),
      'folder': folderName.isEmpty ? null : folderName,
      'rom': romRelativePath.replaceAll('\\', '/'),
      'cover': coverRelativePath?.replaceAll('\\', '/'),
      'size': sizeBytes,
    });
  }

  final rootRoms = <File>[];
  for (final entity in romsDir.listSync()) {
    if (entity is File && _isRom(entity.path)) {
      rootRoms.add(entity);
    }
  }

  for (final rom in rootRoms) {
    addGame(
      folderName: '',
      romRelativePath: p.basename(rom.path),
      sizeBytes: rom.lengthSync(),
    );
  }

  for (final entity in romsDir.listSync()) {
    if (entity is! Directory) continue;
    if (p.basename(entity.path).startsWith('.')) continue;

    final folderName = p.basename(entity.path);
    final romFiles = entity
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => _isRom(f.path))
        .toList();

    if (romFiles.isEmpty) continue;

    final primary = _pickPrimaryRom(romFiles);
    final relativeRom = p.relative(primary.path, from: romsDir.path);

    String? coverRelative;
    for (final name in [
      'cover.png',
      'cover.jpg',
      'cover.webp',
      'boxart.png',
      'boxart.jpg',
      'poster.png',
      'poster.jpg',
    ]) {
      final coverFile = File(p.join(entity.path, name));
      if (coverFile.existsSync()) {
        coverRelative = p.relative(coverFile.path, from: romsDir.path);
        assetDirs.add('assets/roms/$folderName/');
        break;
      }
    }

    addGame(
      folderName: folderName,
      romRelativePath: relativeRom,
      coverRelativePath: coverRelative,
      sizeBytes: primary.lengthSync(),
    );
  }

  games.sort((a, b) => (a['title'] as String).compareTo(b['title'] as String));

  final catalogFile = File(p.join(romsDir.path, 'catalog.json'));
  catalogFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
    'version': 1,
    'generatedAt': DateTime.now().toIso8601String(),
    'games': games,
  }));

  _updatePubspec(projectRoot, assetDirs);
  stdout.writeln('Synced ${games.length} bundled games into catalog.json');
  stdout.writeln('Updated pubspec.yaml with ${assetDirs.length} ROM asset paths');
  stdout.writeln('Now run: flutter pub get && flutter run');
}

Directory _findProjectRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 6; i++) {
    if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return Directory.current;
}

void _updatePubspec(Directory projectRoot, Set<String> assetDirs) {
  final pubspecFile = File(p.join(projectRoot.path, 'pubspec.yaml'));
  var content = pubspecFile.readAsStringSync();

  final sortedDirs = assetDirs.toList()..sort();
  final block = StringBuffer()
    ..writeln('    # ROM_ASSETS_BEGIN (dart run tool/sync_rom_assets.dart)')
    ..writeln('    - assets/roms/catalog.json');
  for (final dir in sortedDirs) {
    if (dir == 'assets/roms/') continue;
    block.writeln('    - $dir');
  }
  block.write('    # ROM_ASSETS_END');

  final pattern = RegExp(
    r'    # ROM_ASSETS_BEGIN.*?\n    # ROM_ASSETS_END',
    dotAll: true,
  );

  if (!pattern.hasMatch(content)) {
    stderr.writeln('Could not find ROM_ASSETS markers in pubspec.yaml');
    exit(1);
  }

  content = content.replaceFirst(pattern, block.toString());
  pubspecFile.writeAsStringSync(content);
}

bool _isRom(String path) {
  const exts = {'.bin', '.md', '.gen', '.smd', '.32x'};
  final ext = p.extension(path).toLowerCase();
  return exts.contains(ext);
}

File _pickPrimaryRom(List<File> files) {
  if (files.length == 1) return files.first;

  int score(File file) {
    final name = p.basename(file.path).toLowerCase();
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

  final sorted = List<File>.from(files)
    ..sort((a, b) => score(b).compareTo(score(a)));
  return sorted.first;
}

String _cleanTitle(String name) => name
    .replaceAll(RegExp(r'\(.*?\)'), '')
    .replaceAll(RegExp(r'\[.*?\]'), '')
    .replaceAll(RegExp(r'[_-]+'), ' ')
    .replaceAll(RegExp(r'  +'), ' ')
    .trim();
