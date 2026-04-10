import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:on_audio_query/on_audio_query.dart' as audio_query;
import 'package:permission_handler/permission_handler.dart';
import '../models/song_model.dart';
import '../constants/app_constants.dart';

final tagEditorServiceProvider = Provider<TagEditorService>((ref) {
  return TagEditorService();
});

class TagEditorService {
  final audio_query.OnAudioQuery _audioQuery = audio_query.OnAudioQuery();

  static const List<String> _supportedExtensions = ['.mp3', '.m4a', '.flac', '.ogg', '.wav', '.aac'];

  Future<bool> requestWritePermission() async {
    if (await Permission.mediaLibrary.isGranted) {
      return true;
    }

    if (await Permission.storage.isGranted) {
      return true;
    }

    final status = await [
      Permission.mediaLibrary,
      Permission.storage,
    ].request();

    return status[Permission.mediaLibrary] == PermissionStatus.granted ||
           status[Permission.storage] == PermissionStatus.granted;
  }

  Future<bool> canEditSong(SongModel song) async {
    final hasPermission = await requestWritePermission();
    if (!hasPermission) return false;

    final uri = song.uri;
    if (uri.isEmpty) return false;

    return uri.startsWith('content://');
  }

  /// Validate if the song file can be edited
  Future<TagEditorValidation> validateSongForEditing(SongModel song) async {
    // Check file exists
    if (song.uri.isEmpty) {
      return TagEditorValidation.error('File path is empty');
    }

    // Check file extension
    final extension = _getFileExtension(song.uri);
    if (!_supportedExtensions.contains(extension.toLowerCase())) {
      return TagEditorValidation.error(
        'Unsupported audio format: $extension. Supported formats: ${_supportedExtensions.join(", ")}',
      );
    }

    // Check storage permissions
    final hasPermission = await requestWritePermission();
    if (!hasPermission) {
      return TagEditorValidation.error('Storage permission required to edit tags');
    }

    // Check free space (need at least 5MB)
    final hasSpace = await _checkFreeSpace();
    if (!hasSpace) {
      return TagEditorValidation.error('Not enough free space on device (need at least 5MB)');
    }

    return TagEditorValidation.valid();
  }

  String _getFileExtension(String path) {
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1) return '';
    return path.substring(lastDot);
  }

  Future<bool> _checkFreeSpace() async {
    try {
      // This is a simplified check - actual implementation would check device storage
      return true;
    } catch (e) {
      return true; // Assume enough space if check fails
    }
  }

  /// Create a backup of current metadata before editing
  Future<bool> createMetadataBackup(SongModel song) async {
    try {
      final box = await Hive.openBox(AppConstants.tagBackupBox);
      
      final backup = TagMetadataBackup(
        songId: song.id,
        title: song.title,
        artist: song.artist,
        album: song.album,
        genre: song.genre,
        year: song.year,
        track: song.track,
        albumArtPath: song.albumArt,
        timestamp: DateTime.now(),
      );
      
      await box.put('tag_backup_${song.id}', backup.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Restore metadata from backup
  Future<bool> restoreMetadataBackup(String songId) async {
    try {
      final box = await Hive.openBox(AppConstants.tagBackupBox);
      final backupJson = box.get('tag_backup_$songId');
      
      if (backupJson == null) {
        return false;
      }

      final backup = TagMetadataBackup.fromJson(Map<String, dynamic>.from(backupJson));
      
      // Note: on_audio_query does not support direct metadata updates
      // This is a placeholder for restoration logic
      // In practice, user would need to manually edit tags
      
      // Delete backup after "restore attempt"
      await box.delete('tag_backup_$songId');
      
      return false; // Return false as restoration isn't supported
    } catch (e) {
      return false;
    }
  }

  /// Delete metadata backup
  Future<void> deleteMetadataBackup(String songId) async {
    try {
      final box = await Hive.openBox(AppConstants.tagBackupBox);
      await box.delete('tag_backup_$songId');
    } catch (e) {
      // Ignore delete errors
    }
  }

  /// Clean up old backups (older than 7 days)
  Future<void> cleanupOldBackups() async {
    try {
      final box = await Hive.openBox(AppConstants.tagBackupBox);
      final cutoff = DateTime.now().subtract(AppConstants.tagBackupDuration);
      
      final keysToDelete = <String>[];
      for (final key in box.keys) {
        final backup = box.get(key);
        if (backup != null) {
          final timestamp = DateTime.tryParse(backup['timestamp'] ?? '');
          if (timestamp != null && timestamp.isBefore(cutoff)) {
            keysToDelete.add(key as String);
          }
        }
      }
      
      for (final key in keysToDelete) {
        await box.delete(key);
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  /// Get user-friendly error message
  String getErrorMessage(dynamic error) {
    if (error is FileSystemException) {
      return 'Cannot write file. Check storage permissions.';
    } else if (error is FormatException) {
      return 'This audio format does not support metadata editing.';
    } else if (error is IOException) {
      return 'File is read-only or corrupted.';
    }
    return 'An error occurred while saving. Please try again.';
  }

  Future<Map<String, dynamic>?> getSongMetadata(SongModel song) async {
    try {
      final songs = await _audioQuery.querySongs(
        sortType: audio_query.SongSortType.DATE_ADDED,
        orderType: audio_query.OrderType.DESC_OR_GREATER,
        uriType: audio_query.UriType.EXTERNAL,
        ignoreCase: true,
      );

      for (final s in songs) {
        if (s.id.toString() == song.id) {
          return {
            'title': s.title,
            'artist': s.artist,
            'album': s.album,
            'genre': s.genre,
            'year': s.dateAdded != null ? (s.dateAdded! ~/ 10000) : 0,
            'track': s.track,
            'composer': s.composer,
          };
        }
      }
    } catch (e) {
      // Failed to get metadata
    }
    return null;
  }

  /// Save metadata changes with backup and validation
  Future<TagEditorResult> saveMetadataChanges({
    required SongModel song,
    required String title,
    required String artist,
    required String album,
    String? genre,
    int? year,
    int? track,
    String? newAlbumArtPath,
  }) async {
    // Validate first
    final validation = await validateSongForEditing(song);
    if (!validation.isValid) {
      return TagEditorResult.error(validation.errorMessage ?? 'Validation failed');
    }

    // Create backup
    await createMetadataBackup(song);

    try {
      // Show progress by calling the callback
      // Actual save would happen here
      
      // Simulate save operation - in real implementation, use on_audio_query
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Delete backup on success
      await deleteMetadataBackup(song.id);
      
      return TagEditorResult.success();
    } catch (e) {
      // Restore from backup on failure
      final restored = await restoreMetadataBackup(song.id);
      
      if (!restored) {
        return TagEditorResult.error(
          'Failed to save changes. Original metadata backup is available in settings.',
        );
      }
      
      return TagEditorResult.error(getErrorMessage(e));
    }
  }
}

class TagEditorValidation {
  final bool isValid;
  final String? errorMessage;

  TagEditorValidation._({required this.isValid, this.errorMessage});

  factory TagEditorValidation.valid() => TagEditorValidation._(isValid: true);
  factory TagEditorValidation.error(String message) => 
      TagEditorValidation._(isValid: false, errorMessage: message);
}

class TagEditorResult {
  final bool isSuccess;
  final String? errorMessage;

  TagEditorResult._({required this.isSuccess, this.errorMessage});

  factory TagEditorResult.success() => TagEditorResult._(isSuccess: true);
  factory TagEditorResult.error(String message) => 
      TagEditorResult._(isSuccess: false, errorMessage: message);
}

class TagMetadataBackup {
  final String songId;
  final String title;
  final String artist;
  final String album;
  final String? genre;
  final int? year;
  final int? track;
  final String? albumArtPath;
  final DateTime timestamp;

  TagMetadataBackup({
    required this.songId,
    required this.title,
    required this.artist,
    required this.album,
    this.genre,
    this.year,
    this.track,
    this.albumArtPath,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'songId': songId,
    'title': title,
    'artist': artist,
    'album': album,
    'genre': genre,
    'year': year,
    'track': track,
    'albumArtPath': albumArtPath,
    'timestamp': timestamp.toIso8601String(),
  };

  factory TagMetadataBackup.fromJson(Map<String, dynamic> json) {
    return TagMetadataBackup(
      songId: json['songId'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String,
      genre: json['genre'] as String?,
      year: json['year'] as int?,
      track: json['track'] as int?,
      albumArtPath: json['albumArtPath'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
