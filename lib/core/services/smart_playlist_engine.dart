import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import '../models/smart_playlist_model.dart';
import '../constants/app_constants.dart';
import '../providers/music_provider.dart';

final smartPlaylistEngineProvider = Provider<SmartPlaylistEngine>((ref) {
  return SmartPlaylistEngine(ref);
});

class SmartPlaylistEngine {
  final Ref _ref;
  
  // Cache for evaluation results
  final Map<String, _EvaluationCache> _cache = {};

  SmartPlaylistEngine(this._ref);

  Future<void> refreshAllSmartPlaylists() async {
    final playlistBox = await Hive.openBox<PlaylistModel>(AppConstants.playlistsBox);
    final allSongs = _ref.read(allSongsProvider).valueOrNull ?? [];
    
    for (final playlist in playlistBox.values) {
      if (playlist.isSmartPlaylist && playlist.smartPlaylistType != null) {
        await refreshPlaylist(playlist, allSongs);
      }
    }
  }

  Future<void> refreshPlaylist(PlaylistModel playlist, List<SongModel> allSongs) async {
    if (!playlist.isSmartPlaylist || playlist.smartPlaylistType == null) {
      return;
    }

    try {
      final rules = _parseRules(playlist.smartPlaylistType!);
      if (rules == null) return;

      // Check cache first
      final cacheKey = _getCacheKey(playlist.smartPlaylistType!, allSongs);
      if (_cache.containsKey(cacheKey)) {
        final cached = _cache[cacheKey]!;
        if (cached.isValid(allSongs)) {
          // Use cached result
          final updatedPlaylist = playlist.copyWith(
            songIds: cached.songIds,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          );
          final playlistBox = await Hive.openBox<PlaylistModel>(AppConstants.playlistsBox);
          await playlistBox.put(playlist.id, updatedPlaylist);
          return;
        }
      }

      // Use isolate for large libraries
      final songIds = await _evaluateRulesInIsolate(
        songs: allSongs,
        rulesJson: playlist.smartPlaylistType!,
      );

      // Cache the result
      _cache[cacheKey] = _EvaluationCache(
        songIds: songIds,
        songListHash: _hashSongs(allSongs),
        rulesHash: playlist.smartPlaylistType!.hashCode,
      );

      final updatedPlaylist = playlist.copyWith(
        songIds: songIds,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      final playlistBox = await Hive.openBox<PlaylistModel>(AppConstants.playlistsBox);
      await playlistBox.put(playlist.id, updatedPlaylist);
    } catch (e) {
      // Failed to refresh smart playlist
    }
  }

  String _getCacheKey(String rulesJson, List<SongModel> songs) {
    return '${rulesJson.hashCode}_${_hashSongs(songs)}';
  }

  String _hashSongs(List<SongModel> songs) {
    // Simple hash based on song count and IDs
    return '${songs.length}_${songs.isNotEmpty ? songs.first.id : 0}_${songs.isNotEmpty ? songs.last.id : 0}';
  }

  static Future<List<String>> _evaluateRulesInIsolate({
    required List<SongModel> songs,
    required String rulesJson,
  }) async {
    return compute(_evaluateRules, _IsolateParams(songs: songs, rulesJson: rulesJson));
  }

  static List<String> _evaluateRules(_IsolateParams params) {
    try {
      final map = json.decode(params.rulesJson);
      final rule = SmartPlaylistRule(
        rules: List<Map<String, dynamic>>.from(map['rules'] ?? []),
        logicIndex: map['logicIndex'] ?? 0,
      );
      
      final matchingSongs = rule.filterSongs(params.songs);
      return matchingSongs.map((s) => s.id).toList();
    } catch (e) {
      return [];
    }
  }

  SmartPlaylistRule? _parseRules(String rulesJson) {
    try {
      final map = json.decode(rulesJson);
      return SmartPlaylistRule(
        rules: List<Map<String, dynamic>>.from(map['rules'] ?? []),
        logicIndex: map['logicIndex'] ?? 0,
      );
    } catch (e) {
      return null;
    }
  }

  Future<PlaylistModel> createSmartPlaylist({
    required String name,
    required SmartPlaylistRule rules,
    String? description,
  }) async {
    final allSongs = _ref.read(allSongsProvider).valueOrNull ?? [];
    final matchingSongs = rules.filterSongs(allSongs);
    final songIds = matchingSongs.map((s) => s.id).toList();

    final playlist = PlaylistModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      songIds: songIds,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      isSmartPlaylist: true,
      smartPlaylistType: json.encode({
        'rules': rules.rules,
        'logicIndex': rules.logicIndex,
      }),
    );

    final playlistBox = await Hive.openBox<PlaylistModel>(AppConstants.playlistsBox);
    await playlistBox.put(playlist.id, playlist);

    return playlist;
  }

  Future<void> updateSmartPlaylistRules(
    String playlistId,
    SmartPlaylistRule newRules,
  ) async {
    final playlistBox = await Hive.openBox<PlaylistModel>(AppConstants.playlistsBox);
    final playlist = playlistBox.get(playlistId);
    if (playlist == null || !playlist.isSmartPlaylist) return;

    final allSongs = _ref.read(allSongsProvider).valueOrNull ?? [];
    final matchingSongs = newRules.filterSongs(allSongs);
    final songIds = matchingSongs.map((s) => s.id).toList();

    final updatedPlaylist = playlist.copyWith(
      songIds: songIds,
      smartPlaylistType: json.encode({
        'rules': newRules.rules,
        'logicIndex': newRules.logicIndex,
      }),
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await playlistBox.put(playlistId, updatedPlaylist);
  }

  Future<PlaylistModel> convertToNormalPlaylist(String playlistId) async {
    final playlistBox = await Hive.openBox<PlaylistModel>(AppConstants.playlistsBox);
    final playlist = playlistBox.get(playlistId);
    if (playlist == null) throw Exception('Playlist not found');

    final updatedPlaylist = playlist.copyWith(
      isSmartPlaylist: false,
      smartPlaylistType: null,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await playlistBox.put(playlistId, updatedPlaylist);
    return updatedPlaylist;
  }

  List<String> getAvailableGenres() {
    final allSongs = _ref.read(allSongsProvider).valueOrNull ?? [];
    final genres = <String>{};
    
    for (final song in allSongs) {
      if (song.genre != null && song.genre!.isNotEmpty) {
        genres.add(song.genre!);
      }
    }
    
    return genres.toList()..sort();
  }

  List<String> getAvailableArtists() {
    final allSongs = _ref.read(allSongsProvider).valueOrNull ?? [];
    final artists = <String>{};
    
    for (final song in allSongs) {
      artists.add(song.artist);
    }
    
    return artists.toList()..sort();
  }

  List<String> getAvailableAlbums() {
    final allSongs = _ref.read(allSongsProvider).valueOrNull ?? [];
    final albums = <String>{};
    
    for (final song in allSongs) {
      albums.add(song.album);
    }
    
    return albums.toList()..sort();
  }
}

class _IsolateParams {
  final List<SongModel> songs;
  final String rulesJson;

  _IsolateParams({required this.songs, required this.rulesJson});
}

class _EvaluationCache {
  final List<String> songIds;
  final String songListHash;
  final int rulesHash;

  _EvaluationCache({
    required this.songIds,
    required this.songListHash,
    required this.rulesHash,
  });

  bool isValid(List<SongModel> songs) {
    final currentHash = '${songs.length}_${songs.isNotEmpty ? songs.first.id : 0}_${songs.isNotEmpty ? songs.last.id : 0}';
    return currentHash == songListHash;
  }
}
