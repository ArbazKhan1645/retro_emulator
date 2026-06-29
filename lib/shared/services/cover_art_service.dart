import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../models/game_model.dart';
import 'metadata_service.dart';

final coverArtServiceProvider = Provider<CoverArtService>((ref) {
  return CoverArtService(metadata: ref.read(metadataServiceProvider));
});

/// Resolves cover art for local ROMs using LibRetro thumbnails and IGDB.
class CoverArtService {
  CoverArtService({
    required MetadataService metadata,
    Dio? dio,
  })  : _metadata = metadata,
        _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 6),
              receiveTimeout: const Duration(seconds: 6),
            ));

  final MetadataService _metadata;
  final Dio _dio;

  static const _libretroSystem = 'Sega - Mega Drive - Genesis';
  static const _libretroTypes = [
    'Named_Boxarts',
    'Named_Titles',
    'Named_Snaps',
  ];

  /// Resolves a cover URL from ROM naming candidates (LibRetro + IGDB title).
  Future<String?> resolveCoverForRomNames(Iterable<String> names) async {
    final tried = <String>{};
    for (final raw in names) {
      final variants = <String>{
        raw.trim(),
        _cleanRomName(raw),
        raw.replaceAll(' ~ ', ' ').trim(),
      };
      for (final name in variants) {
        if (name.isEmpty || !tried.add(name)) continue;
        final libretroUrl = await _findLibretroCover(name);
        if (libretroUrl != null) return libretroUrl;
      }
    }
    return null;
  }

  /// Fills [coverUrl] (and IGDB metadata when available) for [game].
  Future<GameModel> resolve(GameModel game) async {
    if (game.coverUrl != null && game.coverUrl!.isNotEmpty) {
      return game;
    }

    final romBaseName = p.basenameWithoutExtension(game.romPath);
    final libretroUrl = await resolveCoverForRomNames([
      romBaseName,
      _cleanRomName(romBaseName),
    ]);
    if (libretroUrl != null) {
      return _metadata.enrichGame(game.copyWith(coverUrl: libretroUrl));
    }

    return _metadata.enrichGame(game);
  }

  Future<String?> _findLibretroCover(String romBaseName) async {
    for (final type in _libretroTypes) {
      final url = _libretroUrl(romBaseName, type);
      if (await _urlExists(url)) return url;
    }
    return null;
  }

  String _libretroUrl(String romBaseName, String type) {
    return 'https://thumbnails.libretro.com/'
        '${Uri.encodeComponent(_libretroSystem)}/'
        '${Uri.encodeComponent(type)}/'
        '${Uri.encodeComponent(romBaseName)}.png';
  }

  Future<bool> _urlExists(String url) async {
    try {
      final response = await _dio.head(
        url,
        options: Options(
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  String _cleanRomName(String name) => name
      .replaceAll(RegExp(r'\(.*?\)'), '')
      .replaceAll(RegExp(r'\[.*?\]'), '')
      .replaceAll(RegExp(r'  +'), ' ')
      .trim();
}
