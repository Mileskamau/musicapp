import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'song_model.g.dart';

@HiveType(typeId: 0)
class SongModel extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String artist;
  
  @HiveField(3)
  final String album;
  
  @HiveField(4)
  final String albumId;
  
  @HiveField(5)
  final String uri;
  
  @HiveField(6)
  final String? albumArt;
  
  @HiveField(7)
  final int duration;
  
  @HiveField(8)
  final int size;
  
  @HiveField(9)
  final String? displayName;
  
  @HiveField(10)
  final String? mimeType;
  
  @HiveField(11)
  final int dateAdded;
  
  @HiveField(12)
  final int dateModified;
  
  @HiveField(13)
  final String? composer;
  
  @HiveField(14)
  final String? genre;
  
  @HiveField(15)
  final int track;
  
  @HiveField(16)
  final int year;
  
  @HiveField(17)
  final bool isFavorite;
  
  @HiveField(18)
  final int playCount;
  
  @HiveField(19)
  final int lastPlayed;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.albumId,
    required this.uri,
    this.albumArt,
    required this.duration,
    required this.size,
    this.displayName,
    this.mimeType,
    required this.dateAdded,
    required this.dateModified,
    this.composer,
    this.genre,
    required this.track,
    required this.year,
    this.isFavorite = false,
    this.playCount = 0,
    this.lastPlayed = 0,
  });

  /// Safely parse an integer value from dynamic input.
  /// Handles String, int, double, and null values from platform channel data.
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  factory SongModel.fromMap(Map<String, dynamic> map) {
    return SongModel(
      id: map['_id']?.toString() ?? '',
      title: (map['title'] ?? 'Unknown').toString(),
      artist: (map['artist'] ?? 'Unknown Artist').toString(),
      album: (map['album'] ?? 'Unknown Album').toString(),
      albumId: map['album_id']?.toString() ?? '',
      uri: (map['_data'] ?? '').toString(),
      albumArt: map['album_art']?.toString(),
      duration: _parseInt(map['duration']),
      size: _parseInt(map['_size']),
      displayName: map['_display_name']?.toString(),
      mimeType: map['mime_type']?.toString(),
      dateAdded: _parseInt(map['date_added']),
      dateModified: _parseInt(map['date_modified']),
      composer: map['composer']?.toString(),
      genre: map['genre']?.toString(),
      track: _parseInt(map['track']),
      year: _parseInt(map['year']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'album_id': albumId,
      '_data': uri,
      'album_art': albumArt,
      'duration': duration,
      '_size': size,
      '_display_name': displayName,
      'mime_type': mimeType,
      'date_added': dateAdded,
      'date_modified': dateModified,
      'composer': composer,
      'genre': genre,
      'track': track,
      'year': year,
    };
  }

  SongModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? albumId,
    String? uri,
    String? albumArt,
    int? duration,
    int? size,
    String? displayName,
    String? mimeType,
    int? dateAdded,
    int? dateModified,
    String? composer,
    String? genre,
    int? track,
    int? year,
    bool? isFavorite,
    int? playCount,
    int? lastPlayed,
  }) {
    return SongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumId: albumId ?? this.albumId,
      uri: uri ?? this.uri,
      albumArt: albumArt ?? this.albumArt,
      duration: duration ?? this.duration,
      size: size ?? this.size,
      displayName: displayName ?? this.displayName,
      mimeType: mimeType ?? this.mimeType,
      dateAdded: dateAdded ?? this.dateAdded,
      dateModified: dateModified ?? this.dateModified,
      composer: composer ?? this.composer,
      genre: genre ?? this.genre,
      track: track ?? this.track,
      year: year ?? this.year,
      isFavorite: isFavorite ?? this.isFavorite,
      playCount: playCount ?? this.playCount,
      lastPlayed: lastPlayed ?? this.lastPlayed,
    );
  }

  /// Check if the song file exists on the device.
  /// Cached after first check to avoid repeated synchronous file system calls.
  bool? _fileExistsCache;
  bool get fileExists {
    _fileExistsCache ??= uri.isNotEmpty && File(uri).existsSync();
    return _fileExistsCache!;
  }

  /// Get the folder path containing this song.
  String get folderPath {
    if (uri.isEmpty) return '';
    final lastSlash = uri.lastIndexOf(RegExp(r'[/\\]'));
    return lastSlash >= 0 ? uri.substring(0, lastSlash) : '';
  }

  String get formattedDuration {
    final minutes = (duration / 60000).floor();
    final seconds = ((duration % 60000) / 1000).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  List<Object?> get props => [
        id,
        title,
        artist,
        album,
        albumId,
        uri,
        albumArt,
        duration,
        size,
        displayName,
        mimeType,
        dateAdded,
        dateModified,
        composer,
        genre,
        track,
        year,
        isFavorite,
        playCount,
        lastPlayed,
      ];
}
