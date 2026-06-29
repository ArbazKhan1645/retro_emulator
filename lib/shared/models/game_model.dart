import 'dart:convert';

/// Represents a Sega Genesis ROM game in the library
class GameModel {
  final String id;
  final String title;
  final String? description;
  final String consolePlatform;
  final String romPath;
  final String? coverUrl;
  final String? backgroundUrl;
  final List<String> screenshotUrls;
  final String? developer;
  final String? publisher;
  final String? genre;
  final int? releaseYear;
  final double rating;
  final bool isFavorite;
  final int playTimeSeconds;
  final DateTime? lastPlayed;
  final int fileSizeBytes;
  final String fileExtension;
  final double completionPercent;
  final bool isInstalled;
  final String? igdbId;
  final DateTime addedAt;

  const GameModel({
    required this.id,
    required this.title,
    this.description,
    this.consolePlatform = 'Sega Genesis',
    required this.romPath,
    this.coverUrl,
    this.backgroundUrl,
    this.screenshotUrls = const [],
    this.developer,
    this.publisher,
    this.genre,
    this.releaseYear,
    this.rating = 0.0,
    this.isFavorite = false,
    this.playTimeSeconds = 0,
    this.lastPlayed,
    this.fileSizeBytes = 0,
    this.fileExtension = '.bin',
    this.completionPercent = 0.0,
    this.isInstalled = true,
    this.igdbId,
    required this.addedAt,
  });

  GameModel copyWith({
    String? id,
    String? title,
    String? description,
    String? consolePlatform,
    String? romPath,
    String? coverUrl,
    String? backgroundUrl,
    List<String>? screenshotUrls,
    String? developer,
    String? publisher,
    String? genre,
    int? releaseYear,
    double? rating,
    bool? isFavorite,
    int? playTimeSeconds,
    DateTime? lastPlayed,
    int? fileSizeBytes,
    String? fileExtension,
    double? completionPercent,
    bool? isInstalled,
    String? igdbId,
    DateTime? addedAt,
  }) {
    return GameModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      consolePlatform: consolePlatform ?? this.consolePlatform,
      romPath: romPath ?? this.romPath,
      coverUrl: coverUrl ?? this.coverUrl,
      backgroundUrl: backgroundUrl ?? this.backgroundUrl,
      screenshotUrls: screenshotUrls ?? this.screenshotUrls,
      developer: developer ?? this.developer,
      publisher: publisher ?? this.publisher,
      genre: genre ?? this.genre,
      releaseYear: releaseYear ?? this.releaseYear,
      rating: rating ?? this.rating,
      isFavorite: isFavorite ?? this.isFavorite,
      playTimeSeconds: playTimeSeconds ?? this.playTimeSeconds,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      fileExtension: fileExtension ?? this.fileExtension,
      completionPercent: completionPercent ?? this.completionPercent,
      isInstalled: isInstalled ?? this.isInstalled,
      igdbId: igdbId ?? this.igdbId,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'consolePlatform': consolePlatform,
        'romPath': romPath,
        'coverUrl': coverUrl,
        'backgroundUrl': backgroundUrl,
        'screenshotUrls': screenshotUrls,
        'developer': developer,
        'publisher': publisher,
        'genre': genre,
        'releaseYear': releaseYear,
        'rating': rating,
        'isFavorite': isFavorite,
        'playTimeSeconds': playTimeSeconds,
        'lastPlayed': lastPlayed?.toIso8601String(),
        'fileSizeBytes': fileSizeBytes,
        'fileExtension': fileExtension,
        'completionPercent': completionPercent,
        'isInstalled': isInstalled,
        'igdbId': igdbId,
        'addedAt': addedAt.toIso8601String(),
      };

  factory GameModel.fromJson(Map<String, dynamic> json) => GameModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        consolePlatform: json['consolePlatform'] as String? ?? 'Sega Genesis',
        romPath: json['romPath'] as String,
        coverUrl: json['coverUrl'] as String?,
        backgroundUrl: json['backgroundUrl'] as String?,
        screenshotUrls: (json['screenshotUrls'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
        developer: json['developer'] as String?,
        publisher: json['publisher'] as String?,
        genre: json['genre'] as String?,
        releaseYear: json['releaseYear'] as int?,
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        isFavorite: json['isFavorite'] as bool? ?? false,
        playTimeSeconds: json['playTimeSeconds'] as int? ?? 0,
        lastPlayed: json['lastPlayed'] != null
            ? DateTime.tryParse(json['lastPlayed'] as String)
            : null,
        fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
        fileExtension: json['fileExtension'] as String? ?? '.bin',
        completionPercent:
            (json['completionPercent'] as num?)?.toDouble() ?? 0.0,
        isInstalled: json['isInstalled'] as bool? ?? true,
        igdbId: json['igdbId'] as String?,
        addedAt: DateTime.tryParse(json['addedAt'] as String? ?? '') ??
            DateTime.now(),
      );

  static GameModel fromJsonString(String jsonStr) =>
      GameModel.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);

  String toJsonString() => jsonEncode(toJson());

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is GameModel && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'GameModel(id: $id, title: $title)';
}
