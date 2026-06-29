import 'dart:convert';

/// Represents a save state for a game
class SaveStateModel {
  final String id;
  final String gameId;
  final int slotNumber;
  final String? name;
  final String? thumbnailPath;
  final DateTime timestamp;
  final int playTimeSeconds;
  final String statePath;

  const SaveStateModel({
    required this.id,
    required this.gameId,
    required this.slotNumber,
    this.name,
    this.thumbnailPath,
    required this.timestamp,
    this.playTimeSeconds = 0,
    required this.statePath,
  });

  SaveStateModel copyWith({
    String? id,
    String? gameId,
    int? slotNumber,
    String? name,
    String? thumbnailPath,
    DateTime? timestamp,
    int? playTimeSeconds,
    String? statePath,
  }) {
    return SaveStateModel(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      slotNumber: slotNumber ?? this.slotNumber,
      name: name ?? this.name,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      timestamp: timestamp ?? this.timestamp,
      playTimeSeconds: playTimeSeconds ?? this.playTimeSeconds,
      statePath: statePath ?? this.statePath,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'gameId': gameId,
        'slotNumber': slotNumber,
        'name': name,
        'thumbnailPath': thumbnailPath,
        'timestamp': timestamp.toIso8601String(),
        'playTimeSeconds': playTimeSeconds,
        'statePath': statePath,
      };

  factory SaveStateModel.fromJson(Map<String, dynamic> json) => SaveStateModel(
        id: json['id'] as String,
        gameId: json['gameId'] as String,
        slotNumber: json['slotNumber'] as int,
        name: json['name'] as String?,
        thumbnailPath: json['thumbnailPath'] as String?,
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
        playTimeSeconds: json['playTimeSeconds'] as int? ?? 0,
        statePath: json['statePath'] as String,
      );

  static SaveStateModel fromJsonString(String s) =>
      SaveStateModel.fromJson(jsonDecode(s) as Map<String, dynamic>);

  String toJsonString() => jsonEncode(toJson());

  String get displayName => name ?? 'Slot $slotNumber';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SaveStateModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
