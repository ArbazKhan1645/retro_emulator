import 'dart:convert';

/// A play session record
class PlayHistoryModel {
  final String id;
  final String gameId;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;

  const PlayHistoryModel({
    required this.id,
    required this.gameId,
    required this.startTime,
    this.endTime,
    this.durationSeconds = 0,
  });

  PlayHistoryModel copyWith({
    String? id,
    String? gameId,
    DateTime? startTime,
    DateTime? endTime,
    int? durationSeconds,
  }) {
    return PlayHistoryModel(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'gameId': gameId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'durationSeconds': durationSeconds,
      };

  factory PlayHistoryModel.fromJson(Map<String, dynamic> json) =>
      PlayHistoryModel(
        id: json['id'] as String,
        gameId: json['gameId'] as String,
        startTime: DateTime.tryParse(json['startTime'] as String? ?? '') ??
            DateTime.now(),
        endTime: json['endTime'] != null
            ? DateTime.tryParse(json['endTime'] as String)
            : null,
        durationSeconds: json['durationSeconds'] as int? ?? 0,
      );

  static PlayHistoryModel fromJsonString(String s) =>
      PlayHistoryModel.fromJson(jsonDecode(s) as Map<String, dynamic>);

  String toJsonString() => jsonEncode(toJson());
}
