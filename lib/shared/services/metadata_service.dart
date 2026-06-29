import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_model.dart';
import '../../core/constants/api_constants.dart';

final metadataServiceProvider = Provider<MetadataService>((ref) {
  return MetadataService();
});

/// Fetches and enriches game metadata from the IGDB API.
///
/// Authentication is handled automatically via Twitch OAuth client credentials.
/// The access token is cached and refreshed when it expires.
///
/// Example:
/// ```dart
/// final service = ref.read(metadataServiceProvider);
/// final enriched = await service.enrichGame(myGame);
/// ```
class MetadataService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(milliseconds: 10000),
    receiveTimeout: const Duration(milliseconds: 15000),
  ));

  String? _accessToken;
  DateTime? _tokenExpiry;

  /// IGDB platform ID for Sega Genesis / Mega Drive.
  static const int _genesisPlatformId = 29;

  /// Returns a valid Twitch OAuth access token, refreshing it if necessary.
  ///
  /// Returns null if the token cannot be obtained (e.g., network failure
  /// or invalid credentials in [ApiConstants]).
  Future<String?> _getAccessToken() async {
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken;
    }

    try {
      final response = await _dio.post(
        ApiConstants.igdbAuthUrl,
        queryParameters: {
          'client_id': ApiConstants.igdbClientId,
          'client_secret': ApiConstants.igdbClientSecret,
          'grant_type': 'client_credentials',
        },
      );
      _accessToken = response.data['access_token'] as String?;
      final expiresIn = response.data['expires_in'] as int? ?? 3600;
      // Subtract 60 s as a safety buffer before actual expiry
      _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60));
      return _accessToken;
    } catch (e) {
      return null;
    }
  }

  /// Searches IGDB for a game by [title] on the Sega Genesis platform.
  ///
  /// Returns the raw IGDB game object as a [Map], or null if:
  /// - No token can be obtained
  /// - No matching game is found
  /// - A network/API error occurs
  Future<Map<String, dynamic>?> fetchGameMetadata(String title) async {
    final token = await _getAccessToken();
    if (token == null) return null;

    try {
      final response = await _dio.post(
        '${ApiConstants.igdbBaseUrl}${ApiConstants.igdbGames}',
        options: Options(headers: {
          'Client-ID': ApiConstants.igdbClientId,
          'Authorization': 'Bearer $token',
          'Content-Type': 'text/plain',
        }),
        data: '''
fields name, summary, cover.image_id, screenshots.image_id,
       involved_companies.company.name, involved_companies.developer,
       genres.name, first_release_date, total_rating;
search "$title";
where platforms = ($_genesisPlatformId);
limit 1;
''',
      );

      final games = response.data as List<dynamic>;
      if (games.isEmpty) return null;
      return games.first as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Enriches a [GameModel] with data fetched from IGDB.
  ///
  /// Fields populated when available:
  /// - [GameModel.description] (IGDB summary)
  /// - [GameModel.coverUrl] (high-res cover image URL)
  /// - [GameModel.backgroundUrl] (first screenshot URL)
  /// - [GameModel.screenshotUrls] (all screenshot URLs)
  /// - [GameModel.developer]
  /// - [GameModel.genre] (first genre)
  /// - [GameModel.releaseYear]
  /// - [GameModel.rating] (IGDB total_rating / 20 → 0–5 scale)
  /// - [GameModel.igdbId]
  ///
  /// Returns the original [game] unchanged if metadata cannot be fetched.
  Future<GameModel> enrichGame(GameModel game) async {
    final data = await fetchGameMetadata(game.title);
    if (data == null) return game;

    String? coverUrl;
    String? backgroundUrl;
    List<String> screenshots = [];

    // ── Cover ──────────────────────────────────────────────────────────────
    final cover = data['cover'] as Map<String, dynamic>?;
    if (cover != null) {
      final imageId = cover['image_id'] as String?;
      if (imageId != null) {
        coverUrl =
            '${ApiConstants.igdbImageBase}/${ApiConstants.igdbCoverLarge}/$imageId.jpg';
      }
    }

    // ── Screenshots ────────────────────────────────────────────────────────
    final rawScreenshots = data['screenshots'] as List<dynamic>? ?? [];
    for (final s in rawScreenshots) {
      final imageId = (s as Map<String, dynamic>)['image_id'] as String?;
      if (imageId != null) {
        screenshots.add(
          '${ApiConstants.igdbImageBase}/${ApiConstants.igdbScreenshotBig}/$imageId.jpg',
        );
      }
    }
    if (screenshots.isNotEmpty) backgroundUrl = screenshots.first;

    // ── Developer ──────────────────────────────────────────────────────────
    String? developer;
    final companies = data['involved_companies'] as List<dynamic>? ?? [];
    for (final c in companies) {
      final map = c as Map<String, dynamic>;
      if (map['developer'] == true) {
        developer =
            (map['company'] as Map<String, dynamic>?)?['name'] as String?;
        break;
      }
    }

    // ── Genre ──────────────────────────────────────────────────────────────
    final genres = data['genres'] as List<dynamic>? ?? [];
    final genre = genres.isNotEmpty
        ? (genres.first as Map<String, dynamic>)['name'] as String?
        : null;

    // ── Release year ───────────────────────────────────────────────────────
    int? releaseYear;
    final releaseTimestamp = data['first_release_date'] as int?;
    if (releaseTimestamp != null) {
      releaseYear =
          DateTime.fromMillisecondsSinceEpoch(releaseTimestamp * 1000).year;
    }

    // ── Rating ─────────────────────────────────────────────────────────────
    // Convert IGDB 0-100 total_rating to a 0.0–5.0 scale
    final totalRating = (data['total_rating'] as num?)?.toDouble();
    final rating = totalRating != null ? totalRating / 20.0 : 0.0;

    return game.copyWith(
      description: data['summary'] as String?,
      coverUrl: coverUrl,
      backgroundUrl: backgroundUrl,
      screenshotUrls: screenshots,
      developer: developer,
      genre: genre,
      releaseYear: releaseYear,
      rating: rating,
      igdbId: data['id']?.toString(),
    );
  }
}
