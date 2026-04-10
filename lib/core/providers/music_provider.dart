import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart' hide SongModel;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import '../models/folder_model.dart';
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
final foldersProvider = FutureProvider<List<FolderModel>>((ref) async {
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

/// Add a song to a playlist
void addSongToPlaylist(WidgetRef ref, String playlistId, String songId) {
  final playlists = ref.read(userPlaylistsProvider);
  final updatedPlaylists = playlists.map((playlist) {
    if (playlist.id == playlistId) {
      if (playlist.songIds.contains(songId)) {
        return playlist; // Already in playlist
      }
      return playlist.copyWith(
        songIds: [...playlist.songIds, songId],
      );
    }
    return playlist;
  }).toList();
  ref.read(userPlaylistsProvider.notifier).state = updatedPlaylists;
}

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

// Glassmorphism Theme Provider
final glassmorphismProvider = StateProvider<bool>((ref) => false);

// Paginated Songs Provider
final paginatedSongsProvider = StateNotifierProvider<PaginatedSongsNotifier, AsyncValue<List<SongModel>>>((ref) {
  return PaginatedSongsNotifier(ref);
});

final currentPageProvider = StateProvider<int>((ref) => 0);

class PaginatedSongsNotifier extends StateNotifier<AsyncValue<List<SongModel>>> {
  final Ref ref;
  static const int pageSize = 200;
  int _currentPage = 0;
  List<SongModel> _allSongs = [];
  List<SongModel> _loadedSongs = [];
  bool _hasMore = true;
  bool _isLoading = false;

  PaginatedSongsNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadFirstPage();
  }

  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;

  Future<void> _loadFirstPage() async {
    try {
      final allSongs = await ref.read(allSongsProvider.future);
      _allSongs = allSongs;
      _loadedSongs = _allSongs.take(pageSize).toList();
      _hasMore = _allSongs.length > pageSize;
      state = AsyncValue.data(_loadedSongs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadNextPage() async {
    if (!_hasMore || _isLoading) return;
    
    _isLoading = true;
    _currentPage++;
    
    final start = _currentPage * pageSize;
    final end = (start + pageSize).clamp(0, _allSongs.length);
    
    if (start >= _allSongs.length) {
      _hasMore = false;
      _isLoading = false;
      return;
    }
    
    final newSongs = _allSongs.sublist(start, end);
    _loadedSongs.addAll(newSongs);
    _hasMore = end < _allSongs.length;
    
    _isLoading = false;
    state = AsyncValue.data(_loadedSongs);
  }

  Future<void> refresh() async {
    _currentPage = 0;
    _allSongs = [];
    _loadedSongs = [];
    _hasMore = true;
    state = const AsyncValue.loading();
    await _loadFirstPage();
  }
}
