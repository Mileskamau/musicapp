import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/lyrics_model.dart';
import '../models/song_model.dart';
import '../constants/app_constants.dart';

final lyricsServiceProvider = Provider<LyricsService>((ref) {
  return LyricsService();
});

class LyricsService {
  static const String _lrclibBaseUrl = 'https://lrclib.net/api/get';
  static const String _ovhBaseUrl = 'https://api.lyrics.ovh/v1';

  Future<LyricsModel?> fetchLyrics(SongModel song) async {
    final lyricsBox = await Hive.openBox<LyricsModel>(AppConstants.lyricsBox);
    
    final cachedLyrics = lyricsBox.get(song.id);
    if (cachedLyrics != null && cachedLyrics.hasLyrics) {
      return cachedLyrics;
    }

    final lyricsMode = LyricsMode.auto;

    if (lyricsMode == LyricsMode.userOnly) {
      return null;
    }

    if (lyricsMode == LyricsMode.offline) {
      return cachedLyrics;
    }

    LyricsModel? onlineLyrics;

    onlineLyrics = await _fetchFromLrclib(song);
    if (onlineLyrics == null) {
      onlineLyrics = await _fetchFromOvh(song);
    }

    if (onlineLyrics != null) {
      await lyricsBox.put(song.id, onlineLyrics);
      return onlineLyrics;
    }

    return cachedLyrics;
  }

  Future<LyricsModel?> _fetchFromLrclib(SongModel song) async {
    try {
      final queryParams = {
        'artist_name': song.artist,
        'track_name': song.title,
        'album_name': song.album,
        'duration': (song.duration ~/ 1000).toString(),
      };

      final uri = Uri.parse(_lrclibBaseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['syncLyrics'] != null) {
          final lrcLines = _parseLrc(data['syncLyrics']);
          return LyricsModel(
            songId: song.id,
            lrcLines: lrcLines,
            source: LyricsSource.lrclib.index,
          );
        } else if (data['plainLyrics'] != null) {
          return LyricsModel(
            songId: song.id,
            lyricsText: data['plainLyrics'],
            source: LyricsSource.lrclib.index,
          );
        }
      }
    } catch (e) {
      // LRCLIB fetch failed, try next provider
    }
    return null;
  }

  Future<LyricsModel?> _fetchFromOvh(SongModel song) async {
    try {
      final uri = Uri.parse('$_ovhBaseUrl/${Uri.encodeComponent(song.artist)}/${Uri.encodeComponent(song.title)}');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['lyrics'] != null && data['lyrics'].isNotEmpty) {
          return LyricsModel(
            songId: song.id,
            lyricsText: data['lyrics'],
            source: LyricsSource.ovh.index,
          );
        }
      }
    } catch (e) {
      // OVH fetch failed
    }
    return null;
  }

  List<LyricLine> _parseLrc(String lrcContent) {
    final lines = <LyricLine>[];
    final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');

    for (final line in lrcContent.split('\n')) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final millisStr = match.group(3)!;
        final millis = int.parse(millisStr.padRight(3, '0'));
        final text = match.group(4)?.trim() ?? '';

        if (text.isNotEmpty) {
          lines.add(LyricLine(
            timestamp: Duration(minutes: minutes, seconds: seconds, milliseconds: millis),
            text: text,
          ));
        }
      }
    }

    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return lines;
  }

  Future<void> saveUserLyrics(SongModel song, String lyrics, {bool isLrc = false}) async {
    final lyricsBox = await Hive.openBox<LyricsModel>(AppConstants.lyricsBox);
    
    List<LyricLine>? lrcLines;
    if (isLrc) {
      lrcLines = _parseLrc(lyrics);
    }

    final lyricsModel = LyricsModel(
      songId: song.id,
      lyricsText: isLrc ? null : lyrics,
      lrcLines: lrcLines,
      isUserProvided: true,
      source: LyricsSource.user.index,
    );

    await lyricsBox.put(song.id, lyricsModel);
  }

  Future<void> deleteLyrics(String songId) async {
    final lyricsBox = await Hive.openBox<LyricsModel>(AppConstants.lyricsBox);
    await lyricsBox.delete(songId);
  }

  Future<LyricsModel?> getCachedLyrics(String songId) async {
    final lyricsBox = await Hive.openBox<LyricsModel>(AppConstants.lyricsBox);
    return lyricsBox.get(songId);
  }
}