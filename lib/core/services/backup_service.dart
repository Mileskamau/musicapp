import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:crypto/crypto.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import '../models/lyrics_model.dart';
import '../models/background_settings.dart';
import '../constants/app_constants.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService();
});

class BackupResult {
  final bool isSuccess;
  final String? errorMessage;
  final bool requiresMigration;
  final int? backupSchemaVersion;

  BackupResult({
    required this.isSuccess,
    this.errorMessage,
    this.requiresMigration = false,
    this.backupSchemaVersion,
  });
}

class BackupService {
  /// Check if a backup file has a valid format and schema
  Future<BackupResult> validateBackup(File file) async {
    try {
      final content = await file.readAsString();
      final backupData = json.decode(content) as Map<String, dynamic>;

      // Check for required fields
      if (!backupData.containsKey('schemaVersion') && !backupData.containsKey('version')) {
        return BackupResult(
          isSuccess: false,
          errorMessage: 'Invalid backup file: missing version information',
        );
      }

      // Get schema version
      final schemaVersion = backupData['schemaVersion'] as int? ?? 1;
      final backupVersion = backupData['version'] as String? ?? '1.0.0';

      // Verify checksum if present
      if (backupData.containsKey('checksum')) {
        final storedChecksum = backupData['checksum'] as String;
        final calculatedChecksum = _calculateChecksum(content, schemaVersion);
        if (storedChecksum != calculatedChecksum) {
          return BackupResult(
            isSuccess: false,
            errorMessage: 'Backup file is corrupted (checksum mismatch)',
          );
        }
      }

      // Check if backup is from a newer version
      if (schemaVersion > AppConstants.currentSchemaVersion) {
        return BackupResult(
          isSuccess: true,
          requiresMigration: true,
          backupSchemaVersion: schemaVersion,
          errorMessage: 'This backup was created with a newer version of musiq (v$backupVersion). Restoring may cause issues.',
        );
      }

      return BackupResult(
        isSuccess: true,
        backupSchemaVersion: schemaVersion,
        requiresMigration: schemaVersion < AppConstants.currentSchemaVersion,
      );
    } catch (e) {
      return BackupResult(
        isSuccess: false,
        errorMessage: 'Failed to read backup file: Invalid format',
      );
    }
  }

  String _calculateChecksum(String content, int schemaVersion) {
    final data = '$content$schemaVersion';
    return md5.convert(utf8.encode(data)).toString();
  }

  Future<File?> exportBackup() async {
    try {
      final backupData = <String, dynamic>{};

      final favoritesBox = await Hive.openBox<List<String>>(AppConstants.favoritesBox);
      final playlistsBox = await Hive.openBox<PlaylistModel>(AppConstants.playlistsBox);
      final recentBox = await Hive.openBox<List<String>>(AppConstants.recentBox);
      final mostPlayedBox = await Hive.openBox<List<String>>(AppConstants.mostPlayedBox);
      final lyricsBox = await Hive.openBox<LyricsModel>(AppConstants.lyricsBox);
      final backgroundBox = await Hive.openBox<BackgroundSettings>(AppConstants.backgroundBox);

      // Include schema version
      backupData['schemaVersion'] = AppConstants.currentSchemaVersion;
      backupData['version'] = AppConstants.appVersion;
      backupData['timestamp'] = DateTime.now().toIso8601String();
      
      backupData['favorites'] = favoritesBox.values.map((e) => e.toList()).toList();
      backupData['recent'] = recentBox.values.map((e) => e.toList()).toList();
      backupData['mostPlayed'] = mostPlayedBox.values.map((e) => e.toList()).toList();
      backupData['playlists'] = playlistsBox.values.map((p) => p.toMap()).toList();
      backupData['lyrics'] = lyricsBox.values.map((l) => {
        'songId': l.songId,
        'lyricsText': l.lyricsText,
        'isUserProvided': l.isUserProvided,
        'source': l.source,
        'fetchedAt': l.fetchedAt.toIso8601String(),
      }).toList();

      final backgroundSettings = backgroundBox.get('settings');
      if (backgroundSettings != null) {
        backupData['backgroundSettings'] = {
          'modeIndex': backgroundSettings.modeIndex,
          'customImagePath': backgroundSettings.customImagePath,
          'blurIntensity': backgroundSettings.blurIntensity,
          'darkOverlayOpacity': backgroundSettings.darkOverlayOpacity,
          'enableParallax': backgroundSettings.enableParallax,
          'syncWithAlbumColors': backgroundSettings.syncWithAlbumColors,
          'enableParticles': backgroundSettings.enableParticles,
        };
      }

      final jsonString = json.encode(backupData);
      
      // Add checksum
      final checksum = _calculateChecksum(jsonString, AppConstants.currentSchemaVersion);
      final dataWithChecksum = json.decode(jsonString) as Map<String, dynamic>;
      dataWithChecksum['checksum'] = checksum;
      final finalJsonString = json.encode(dataWithChecksum);
      
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFile = File('${directory.path}/musiq_backup_$timestamp.json');
      await backupFile.writeAsString(finalJsonString);

      return backupFile;
    } catch (e) {
      return null;
    }
  }

  Future<BackupResult> importBackup(File file, {bool forceRestore = false}) async {
    try {
      // Validate first
      final validation = await validateBackup(file);
      if (!validation.isSuccess) {
        return validation;
      }

      // If newer version and not forcing, warn user
      if (validation.requiresMigration && !forceRestore) {
        return BackupResult(
          isSuccess: false,
          errorMessage: 'This backup was created with a newer version of musiq. Restoring may cause issues. Continue anyway?',
          requiresMigration: true,
          backupSchemaVersion: validation.backupSchemaVersion,
        );
      }

      final content = await file.readAsString();
      final backupData = json.decode(content) as Map<String, dynamic>;

      final favoritesBox = await Hive.openBox<List<String>>(AppConstants.favoritesBox);
      final playlistsBox = await Hive.openBox<PlaylistModel>(AppConstants.playlistsBox);
      final recentBox = await Hive.openBox<List<String>>(AppConstants.recentBox);
      final mostPlayedBox = await Hive.openBox<List<String>>(AppConstants.mostPlayedBox);
      final lyricsBox = await Hive.openBox<LyricsModel>(AppConstants.lyricsBox);
      final backgroundBox = await Hive.openBox<BackgroundSettings>(AppConstants.backgroundBox);

      await favoritesBox.clear();
      await playlistsBox.clear();
      await recentBox.clear();
      await mostPlayedBox.clear();
      await lyricsBox.clear();

      // Migrate and restore data
      final schemaVersion = validation.backupSchemaVersion ?? 1;
      final migratedData = _migrateData(backupData, schemaVersion);

      if (migratedData['favorites'] != null) {
        for (int i = 0; i < (migratedData['favorites'] as List).length; i++) {
          await favoritesBox.put(i.toString(), List<String>.from(migratedData['favorites'][i]));
        }
      }

      if (migratedData['playlists'] != null) {
        for (final p in migratedData['playlists']) {
          final playlist = PlaylistModel.fromMap(p);
          await playlistsBox.put(playlist.id, playlist);
        }
      }

      if (migratedData['recent'] != null) {
        for (int i = 0; i < (migratedData['recent'] as List).length; i++) {
          await recentBox.put(i.toString(), List<String>.from(migratedData['recent'][i]));
        }
      }

      if (migratedData['mostPlayed'] != null) {
        for (int i = 0; i < (migratedData['mostPlayed'] as List).length; i++) {
          await mostPlayedBox.put(i.toString(), List<String>.from(migratedData['mostPlayed'][i]));
        }
      }

      if (migratedData['lyrics'] != null) {
        for (final l in migratedData['lyrics']) {
          final lyrics = LyricsModel(
            songId: l['songId'] ?? '',
            lyricsText: l['lyricsText'] ?? '',
            isUserProvided: l['isUserProvided'] ?? false,
            source: l['source'] ?? 0,
            fetchedAt: l['fetchedAt'] != null ? DateTime.parse(l['fetchedAt']) : DateTime.now(),
          );
          await lyricsBox.put(lyrics.songId, lyrics);
        }
      }

      if (migratedData['backgroundSettings'] != null) {
        final bgSettings = migratedData['backgroundSettings'];
        final settings = BackgroundSettings(
          modeIndex: bgSettings['modeIndex'] ?? 0,
          customImagePath: bgSettings['customImagePath'],
          blurIntensity: (bgSettings['blurIntensity'] ?? 10.0).toDouble(),
          darkOverlayOpacity: (bgSettings['darkOverlayOpacity'] ?? 0.5).toDouble(),
          enableParallax: bgSettings['enableParallax'] ?? true,
          syncWithAlbumColors: bgSettings['syncWithAlbumColors'] ?? false,
          enableParticles: bgSettings['enableParticles'] ?? false,
        );
        await backgroundBox.put('settings', settings);
      }

      return BackupResult(isSuccess: true);
    } catch (e) {
      return BackupResult(
        isSuccess: false,
        errorMessage: 'Failed to restore backup: ${e.toString()}',
      );
    }
  }

  /// Migrate data from older schema versions to current
  Map<String, dynamic> _migrateData(Map<String, dynamic> data, int fromVersion) {
    var migratedData = Map<String, dynamic>.from(data);
    
    // Migration logic for future versions
    // Example: if (fromVersion < 2) { // add migration logic }
    
    return migratedData;
  }

  Future<File?> pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  Future<String?> pickSaveLocation() async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Backup',
      fileName: 'musiq_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    return result;
  }
}
