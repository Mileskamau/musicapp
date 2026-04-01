import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/song_model.dart' as app;

/// Parse song maps in a background isolate for large libraries.
List<app.SongModel> _parseSongsIsolate(List<Map<String, dynamic>> rawMaps) {
  return rawMaps.map((map) => app.SongModel.fromMap(map)).toList();
}

class MusicQueryService {
  static final MusicQueryService _instance = MusicQueryService._internal();
  factory MusicQueryService() => _instance;
  MusicQueryService._internal();

  final OnAudioQuery _audioQuery = OnAudioQuery();

  List<app.SongModel> _cachedSongs = [];
  List<AlbumModel> _cachedAlbums = [];
  List<ArtistModel> _cachedArtists = [];

  // Current sort state
  SongSortType _currentSortType = SongSortType.DATE_ADDED;
  OrderType _currentOrderType = OrderType.DESC_OR_GREATER;

  List<app.SongModel> get songs => _cachedSongs;
  List<AlbumModel> get albums => _cachedAlbums;
  List<ArtistModel> get artists => _cachedArtists;
  SongSortType get currentSortType => _currentSortType;
  OrderType get currentOrderType => _currentOrderType;

  /// Check current permission status without requesting.
  Future<bool> hasPermission() async {
    if (Platform.isAndroid) {
      final audioStatus = await Permission.audio.status;
      if (audioStatus.isGranted) return true;
      final storageStatus = await Permission.storage.status;
      return storageStatus.isGranted;
    }
    return true;
  }

  /// Request storage/audio permissions.
  /// Returns [PermissionStatus] to handle permanent denial.
  Future<PermissionStatus> requestPermissionDetailed() async {
    if (Platform.isAndroid) {
      var status = await Permission.audio.request();
      if (status.isGranted) return status;

      status = await Permission.storage.request();
      return status;
    }
    return PermissionStatus.granted;
  }

  Future<bool> requestPermission() async {
    final status = await requestPermissionDetailed();
    return status.isGranted;
  }

  /// Query all songs from the device.
  /// Uses isolate computation for large libraries (>1000 songs) to avoid UI jank.
  Future<List<app.SongModel>> querySongs({
    SongSortType sortType = SongSortType.DATE_ADDED,
    OrderType orderType = OrderType.DESC_OR_GREATER,
  }) async {
    // Store current sort state
    _currentSortType = sortType;
    _currentOrderType = orderType;

    final hasPermission = await requestPermission();
    if (!hasPermission) return [];

    final rawSongs = await _audioQuery.querySongs(
      sortType: sortType,
      orderType: orderType,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    final rawMaps = rawSongs.map((song) => Map<String, dynamic>.from(song.getMap)).toList();

    // Use isolate for large libraries to prevent UI jank
    if (rawMaps.length > 1000) {
      _cachedSongs = await compute(_parseSongsIsolate, rawMaps);
    } else {
      _cachedSongs = rawMaps.map((map) => app.SongModel.fromMap(map)).toList();
    }

    return _cachedSongs;
  }

  /// Force a fresh scan, clearing cached data.
  Future<List<app.SongModel>> rescanSongs({
    SongSortType sortType = SongSortType.DATE_ADDED,
    OrderType orderType = OrderType.DESC_OR_GREATER,
  }) async {
    _cachedSongs = [];
    _cachedAlbums = [];
    _cachedArtists = [];
    return querySongs(sortType: sortType, orderType: orderType);
  }

  /// Query all albums from the device.
  Future<List<AlbumModel>> queryAlbums() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return [];

    _cachedAlbums = await _audioQuery.queryAlbums(
      sortType: AlbumSortType.ALBUM,
      orderType: OrderType.ASC_OR_SMALLER,
      ignoreCase: true,
    );
    return _cachedAlbums;
  }

  /// Query all artists from the device.
  Future<List<ArtistModel>> queryArtists() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return [];

    _cachedArtists = await _audioQuery.queryArtists(
      sortType: ArtistSortType.ARTIST,
      orderType: OrderType.ASC_OR_SMALLER,
      ignoreCase: true,
    );
    return _cachedArtists;
  }

  /// Query songs by album ID.
  Future<List<app.SongModel>> querySongsByAlbum(int albumId) async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return [];

    final rawSongs = await _audioQuery.queryAudiosFrom(
      AudiosFromType.ALBUM_ID,
      albumId,
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
    );

    return rawSongs
        .map((song) => app.SongModel.fromMap(Map<String, dynamic>.from(song.getMap)))
        .toList();
  }

  /// Query songs by artist ID.
  Future<List<app.SongModel>> querySongsByArtist(int artistId) async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return [];

    final rawSongs = await _audioQuery.queryAudiosFrom(
      AudiosFromType.ARTIST_ID,
      artistId,
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
    );

    return rawSongs
        .map((song) => app.SongModel.fromMap(Map<String, dynamic>.from(song.getMap)))
        .toList();
  }

  /// Search songs by query string.
  List<app.SongModel> searchSongs(String query) {
    if (query.isEmpty) return _cachedSongs;
    final lowerQuery = query.toLowerCase();
    return _cachedSongs.where((song) {
      return song.title.toLowerCase().contains(lowerQuery) ||
          song.artist.toLowerCase().contains(lowerQuery) ||
          song.album.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get unique folders containing music files.
  List<String> getFolders() {
    final folders = <String>{};
    for (final song in _cachedSongs) {
      final folder = song.folderPath;
      if (folder.isNotEmpty) {
        folders.add(folder);
      }
    }
    final sorted = folders.toList()..sort();
    return sorted;
  }

  /// Get songs in a specific folder.
  List<app.SongModel> getSongsByFolder(String folderPath) {
    return _cachedSongs.where((song) => song.folderPath == folderPath).toList();
  }

  /// Get recently added songs (sorted by date).
  List<app.SongModel> getRecentlyAdded({int limit = 20}) {
    final sorted = List<app.SongModel>.from(_cachedSongs)
      ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    return sorted.take(limit).toList();
  }

  /// Get songs that have been played (playCount > 0), sorted by lastPlayed.
  List<app.SongModel> getRecentlyPlayed({int limit = 50}) {
    final played = _cachedSongs.where((s) => s.lastPlayed > 0).toList()
      ..sort((a, b) => b.lastPlayed.compareTo(a.lastPlayed));
    return played.take(limit).toList();
  }

  /// Get most played songs sorted by playCount.
  List<app.SongModel> getMostPlayed({int limit = 50}) {
    final played = _cachedSongs.where((s) => s.playCount > 0).toList()
      ..sort((a, b) => b.playCount.compareTo(a.playCount));
    return played.take(limit).toList();
  }

  /// Get favorite songs.
  List<app.SongModel> getFavorites() {
    return _cachedSongs.where((s) => s.isFavorite).toList();
  }

  /// Update a song in the cache (e.g., after favorite or play count change).
  void updateSongInCache(app.SongModel updatedSong) {
    final index = _cachedSongs.indexWhere((s) => s.id == updatedSong.id);
    if (index != -1) {
      _cachedSongs[index] = updatedSong;
    }
  }
}
