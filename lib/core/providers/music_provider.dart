import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart' hide SongModel;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import '../services/music_query_service.dart';
import 'audio_provider.dart';

// Music Query Service Provider
final musicQueryServiceProvider = Provider<MusicQueryService>((ref) {
  return MusicQueryService();
});

// Song sort state
enum SongSortOption {
  dateAdded,
  title,
  artist,
  album,
  duration,
}

final songSortProvider = StateProvider<SongSortOption>((ref) => SongSortOption.dateAdded);

// Convert sort option to on_audio_query types
(SongSortType, OrderType) _getSortParams(SongSortOption option) {
  switch (option) {
    case SongSortOption.dateAdded:
      return (SongSortType.DATE_ADDED, OrderType.DESC_OR_GREATER);
    case SongSortOption.title:
      return (SongSortType.TITLE, OrderType.ASC_OR_SMALLER);
    case SongSortOption.artist:
      return (SongSortType.ARTIST, OrderType.ASC_OR_SMALLER);
    case SongSortOption.album:
      return (SongSortType.ALBUM, OrderType.ASC_OR_SMALLER);
    case SongSortOption.duration:
      return (SongSortType.DURATION, OrderType.ASC_OR_SMALLER);
  }
}

// All Songs Provider - reacts to sort changes
final allSongsProvider = FutureProvider<List<SongModel>>((ref) async {
  final service = ref.watch(musicQueryServiceProvider);
  final sortOption = ref.watch(songSortProvider);
  final (sortType, orderType) = _getSortParams(sortOption);
  return service.querySongs(sortType: sortType, orderType: orderType);
});

// Albums Provider
final albumsProvider = FutureProvider<List<AlbumModel>>((ref) async {
  final service = ref.watch(musicQueryServiceProvider);
  return service.queryAlbums();
});

// Artists Provider
final artistsProvider = FutureProvider<List<ArtistModel>>((ref) async {
  final service = ref.watch(musicQueryServiceProvider);
  return service.queryArtists();
});

// Search Query Provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Filtered Songs Provider (for search)
final filteredSongsProvider = Provider<AsyncValue<List<SongModel>>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final allSongs = ref.watch(allSongsProvider);

  if (query.isEmpty) return allSongs;

  return allSongs.whenData((songs) {
    final lowerQuery = query.toLowerCase();
    return songs.where((song) {
      final title = song.title.toLowerCase();
      final artist = song.artist.toLowerCase();
      final album = song.album.toLowerCase();
      return title.contains(lowerQuery) ||
          artist.contains(lowerQuery) ||
          album.contains(lowerQuery);
    }).toList();
  });
});

// Song playback tracking state
final _songPlayCountsProvider = StateProvider<Map<String, int>>((ref) => {});
final _songLastPlayedProvider = StateProvider<Map<String, int>>((ref) => {});
final _favoriteSongIdsProvider = StateProvider<Set<String>>((ref) => {});

// Favorites persistence helper
Future<void> _saveFavorites(Set<String> favorites) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList('favorite_song_ids', favorites.toList());
}

Future<Set<String>> _loadFavorites() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getStringList('favorite_song_ids')?.toSet() ?? {};
}

// Recently Played Provider
final recentlyPlayedProvider = Provider<List<SongModel>>((ref) {
  final allSongs = ref.watch(allSongsProvider).valueOrNull ?? [];
  final lastPlayedMap = ref.watch(_songLastPlayedProvider);

  final played = allSongs.where((s) => lastPlayedMap.containsKey(s.id)).toList();
  played.sort((a, b) {
    final aTime = lastPlayedMap[a.id] ?? 0;
    final bTime = lastPlayedMap[b.id] ?? 0;
    return bTime.compareTo(aTime);
  });
  return played.take(50).toList();
});

// Most Played Provider
final mostPlayedProvider = Provider<List<SongModel>>((ref) {
  final allSongs = ref.watch(allSongsProvider).valueOrNull ?? [];
  final playCounts = ref.watch(_songPlayCountsProvider);

  final played = allSongs.where((s) => (playCounts[s.id] ?? 0) > 0).toList();
  played.sort((a, b) {
    final aCount = playCounts[a.id] ?? 0;
    final bCount = playCounts[b.id] ?? 0;
    return bCount.compareTo(aCount);
  });
  return played.take(50).toList();
});

// Favorites Provider
final favoritesProvider = Provider<List<SongModel>>((ref) {
  final allSongs = ref.watch(allSongsProvider).valueOrNull ?? [];
  final favoriteIds = ref.watch(_favoriteSongIdsProvider);
  return allSongs.where((s) => favoriteIds.contains(s.id)).toList();
});

// Recently Added Provider
final recentlyAddedProvider = Provider<List<SongModel>>((ref) {
  final allSongs = ref.watch(allSongsProvider).valueOrNull ?? [];
  final sorted = List<SongModel>.from(allSongs)
    ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
  return sorted.take(50).toList();
});

// Folders Provider
final foldersProvider = Provider<List<String>>((ref) {
  final service = ref.watch(musicQueryServiceProvider);
  return service.getFolders();
});

/// Initialize song tracking by reading the current audio service state.
/// Call this once at app startup.
void initializeSongTracking(WidgetRef ref) {
  final audioService = ref.read(audioServiceProvider);

  // Listen to song completion to update play counts
  audioService.onSongPlayed = (SongModel song) {
    final playCounts = Map<String, int>.from(ref.read(_songPlayCountsProvider));
    playCounts[song.id] = (playCounts[song.id] ?? 0) + 1;
    ref.read(_songPlayCountsProvider.notifier).state = playCounts;

    final lastPlayed = Map<String, int>.from(ref.read(_songLastPlayedProvider));
    lastPlayed[song.id] = DateTime.now().millisecondsSinceEpoch;
    ref.read(_songLastPlayedProvider.notifier).state = lastPlayed;
  };
}

/// Toggle a song's favorite status.
void toggleFavorite(WidgetRef ref, String songId) {
  final favorites = Set<String>.from(ref.read(_favoriteSongIdsProvider));
  if (favorites.contains(songId)) {
    favorites.remove(songId);
  } else {
    favorites.add(songId);
  }
  ref.read(_favoriteSongIdsProvider.notifier).state = favorites;
  _saveFavorites(favorites);
}

/// Check if a song is favorited.
bool isFavorite(WidgetRef ref, String songId) {
  return ref.read(_favoriteSongIdsProvider).contains(songId);
}

/// Load persisted favorites into provider. Call once at startup.
Future<void> loadPersistedFavorites(WidgetRef ref) async {
  final favorites = await _loadFavorites();
  ref.read(_favoriteSongIdsProvider.notifier).state = favorites;
}

// User Playlists State
final userPlaylistsProvider = StateProvider<List<PlaylistEntry>>((ref) => []);

/// A lightweight playlist entry for user-created playlists.
class PlaylistEntry {
  final String id;
  final String name;
  final List<String> songIds;

  PlaylistEntry({
    required this.id,
    required this.name,
    List<String>? songIds,
  }) : songIds = songIds ?? [];

  PlaylistEntry copyWith({String? name, List<String>? songIds}) {
    return PlaylistEntry(
      id: id,
      name: name ?? this.name,
      songIds: songIds ?? this.songIds,
    );
  }
}
