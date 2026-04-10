import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'lyrics_model.g.dart';

@HiveType(typeId: 4)
class LyricsModel extends Equatable {
  @HiveField(0)
  final String songId;
  
  @HiveField(1)
  final String? lyricsText;
  
  @HiveField(2)
  final List<LyricLine>? lrcLines;
  
  @HiveField(3)
  final bool isUserProvided;
  
  @HiveField(4)
  final int source;
  
  @HiveField(5)
  final DateTime fetchedAt;

  LyricsModel({
    required this.songId,
    this.lyricsText,
    this.lrcLines,
    this.isUserProvided = false,
    this.source = 0,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  bool get hasLrc => lrcLines != null && lrcLines!.isNotEmpty;
  bool get hasPlainLyrics => lyricsText != null && lyricsText!.isNotEmpty;
  bool get hasLyrics => hasLrc || hasPlainLyrics;

  LyricsModel copyWith({
    String? songId,
    String? lyricsText,
    List<LyricLine>? lrcLines,
    bool? isUserProvided,
    int? source,
    DateTime? fetchedAt,
  }) {
    return LyricsModel(
      songId: songId ?? this.songId,
      lyricsText: lyricsText ?? this.lyricsText,
      lrcLines: lrcLines ?? this.lrcLines,
      isUserProvided: isUserProvided ?? this.isUserProvided,
      source: source ?? this.source,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }

  @override
  List<Object?> get props => [songId, lyricsText, lrcLines, isUserProvided, source, fetchedAt];
}

@HiveType(typeId: 5)
class LyricLine extends Equatable {
  @HiveField(0)
  final Duration timestamp;
  
  @HiveField(1)
  final String text;

  LyricLine({
    required this.timestamp,
    required this.text,
  });

  String get formattedTimestamp {
    final minutes = timestamp.inMinutes;
    final seconds = (timestamp.inSeconds % 60).toString().padLeft(2, '0');
    final millis = ((timestamp.inMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0');
    return '[$minutes:$seconds.$millis]';
  }

  @override
  List<Object?> get props => [timestamp, text];
}

enum LyricsSource {
  local,
  lrclib,
  ovh,
  musixmatch,
  user,
}

enum LyricsMode {
  auto,
  offline,
  userOnly,
}