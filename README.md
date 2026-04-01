# MusicPly - Premium Music Player App

A fully functional Android music player app built with Flutter featuring a modern dark theme inspired by Spotify, smooth animations, and a clean, premium UI/UX. MusicPly scans your device for audio files and provides a rich playback experience with playlists, search, queue management, and a beautiful animated now-playing screen.

---

## Table of Contents

- [Features](#features)
- [Screenshots](#screenshots)
- [Project Structure](#project-structure)
- [Architecture](#architecture)
- [Dependencies](#dependencies)
- [Getting Started](#getting-started)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage Guide](#usage-guide)
- [Screen Breakdown](#screen-breakdown)
- [State Management](#state-management)
- [Audio Engine](#audio-engine)
- [Data Models](#data-models)
- [Theme & Design System](#theme--design-system)
- [Animations](#animations)
- [Building for Release](#building-for-release)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)
- [Changelog](#changelog)

---

## Features

### Core Playback
- Play, pause, stop, next, previous controls
- Seek bar with drag support and real-time position tracking
- Shuffle mode with toggle
- Loop modes: Off, All, One
- Playback speed control (0.5x - 2.0x)
- Volume control
- Background audio playback via `audio_service`
- Gapless playback support
- Crossfade support (toggle in settings)

### Music Library
- Automatic scanning of device audio files using `on_audio_query`
- Display songs, albums, artists, and folders
- Tabbed library view with Songs, Albums, Artists, Folders
- Sort by title, artist, album, duration, date added
- Album artwork display via `QueryArtworkWidget`
- Song metadata: title, artist, album, duration, file size, MIME type

### Search
- Real-time search with instant results
- Search by song name, artist, or album
- Browse categories: Pop, Rock, Hip Hop, Electronic, Jazz, Classical, R&B, Country, Metal, Indie, Podcasts, Live

### Playlists
- Create custom playlists with name
- Smart playlists: Recently Played, Most Played, Favorites, Recently Added
- Play all songs in a playlist
- Shuffle playlist
- Delete playlists
- Add songs to queue

### Now Playing Screen
- Full-screen animated player with rotating album art
- Gradient background based on album art colors
- Swipe left/right to change songs
- Swipe down to minimize
- Progress bar with drag-to-seek
- Favorite/unfavorite toggle
- Song info dialog

### Mini Player
- Persistent mini player at bottom of screen
- Shows current song title, artist, and album art
- Play/pause, next, previous controls
- Tap to expand to full Now Playing screen
- Linear progress indicator

### Settings
- **Appearance**: Enable/disable animations, accent color picker, default screen selection
- **Audio**: Audio quality (Low/Medium/High/Ultra), Replay Gain toggle
- **Playback**: Crossfade toggle, Gapless playback toggle, Equalizer (coming soon), Sleep Timer
- **Storage**: Clear cache, Storage location info
- **About**: Version info, Open source licenses, Privacy policy

### UI/UX
- Modern dark theme with Spotify-inspired color palette
- Smooth micro-interactions and animations (fade, scale, slide)
- Rounded cards with gradients and shadows
- Bottom navigation bar with animated icons
- Responsive design for different screen sizes
- Loading shimmer effects
- Snackbars and bottom sheets for user feedback
- Modal bottom sheets for song/album/artist options

---

## Project Structure

```
musicply/
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml          # Permissions & app config
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart       # App-wide constants
│   │   ├── models/
│   │   │   ├── song_model.dart          # Song data model (Hive)
│   │   │   ├── playlist_model.dart      # Playlist data model (Hive)
│   │   │   ├── album_model.dart         # Album data model
│   │   │   └── artist_model.dart        # Artist data model
│   │   ├── providers/
│   │   │   ├── audio_provider.dart      # Riverpod audio providers
│   │   │   ├── music_provider.dart      # Riverpod music query providers
│   │   │   └── equalizer_provider.dart  # Riverpod equalizer providers
│   │   ├── services/
│   │   │   ├── audio_service.dart       # AudioEngineService (just_audio)
│   │   │   └── music_query_service.dart # Device music scanning
│   │   └── theme/
│   │       └── app_theme.dart           # Dark theme & design system
│   ├── features/
│   │   ├── home/
│   │   │   └── presentation/
│   │   │       └── home_screen.dart     # Home screen
│   │   ├── library/
│   │   │   └── presentation/
│   │   │       └── library_screen.dart  # Library (Songs/Albums/Artists/Folders)
│   │   ├── search/
│   │   │   └── presentation/
│   │   │       └── search_screen.dart   # Search screen
│   │   ├── playlists/
│   │   │   └── presentation/
│   │   │       └── playlists_screen.dart # Playlists screen
│   │   ├── player/
│   │   │   └── presentation/
│   │   │       ├── now_playing_screen.dart # Full-screen player
│   │   │       ├── mini_player.dart     # Persistent mini player
│   │   │       └── equalizer_screen.dart # Audio equalizer UI
│   │   └── settings/
│   │       └── presentation/
│   │           └── settings_screen.dart # Settings screen
│   └── main.dart                        # App entry point & navigation
├── pubspec.yaml                         # Dependencies & project config
├── README.md                            # This file
└── test/
    └── widget_test.dart                 # Widget tests
```

### File Descriptions

| File | Purpose |
|------|---------|
| `main.dart` | App entry point. Initializes Hive, sets system UI, defines routes (`/now-playing`, `/settings`), and contains the `MainScreen` widget with bottom navigation and `IndexedStack` for tab switching. |
| `app_constants.dart` | All app-wide constants: animation durations, spacing, sizes, Hive box names, Shared Preferences keys, equalizer presets, sleep timer options, playback speed options. |
| `app_theme.dart` | Complete Material 3 dark theme definition. Includes color palette (Spotify green primary, purple accent), text styles, gradients, and all component theming (buttons, cards, sliders, dialogs, etc.). |
| `song_model.dart` | Song data model with Hive annotations for local persistence. Fields: id, title, artist, album, albumId, uri, duration, size, dateAdded, dateModified, track, year, isFavorite, playCount, lastPlayed. Includes safe parsing from `on_audio_query` data. |
| `playlist_model.dart` | Playlist data model with Hive annotations. Fields: id, name, songIds, createdAt, updatedAt, description, isSmartPlaylist. |
| `audio_service.dart` | `AudioEngineService` - Singleton service wrapping `just_audio`. Creates `AndroidEqualizer` and `AndroidLoudnessEnhancer` at construction and attaches them via `AudioPipeline`. Manages playlist loading, playback controls, shuffle, loop modes, speed, volume, sleep timer, and exposes streams for reactive UI updates. |
| `music_query_service.dart` | `MusicQueryService` - Singleton service wrapping `on_audio_query`. Handles permission requests, queries songs/albums/artists from device storage, and converts `on_audio_query` models to app models. |
| `audio_provider.dart` | 16 Riverpod providers exposing audio state: currentSong, queue, isPlaying, position, duration, shuffle, loopMode, playbackSpeed, playerState, processingState, currentIndex, progress, formattedPosition, formattedDuration, hasNext, hasPrevious. |
| `music_provider.dart` | 5 Riverpod providers for music data: allSongsProvider, albumsProvider, artistsProvider, searchQueryProvider, filteredSongsProvider. |
| `equalizer_provider.dart` | 8 Riverpod providers for equalizer state: equalizerServiceProvider, equalizerEnabledProvider, currentPresetProvider, bandValuesProvider, bassBoostProvider, virtualizerProvider, loudnessEnhancerProvider, availablePresetsProvider. |
| `mini_player.dart` | Persistent mini player widget. Shows current song info, album art, progress bar, and play/pause/next/previous controls. Animated slide-in and fade. |
| `equalizer_screen.dart` | Full-screen equalizer with enable toggle, preset selector (Normal, Rock, Pop, Jazz, Classical, Bass Boost, Treble Boost, Vocal, Electronic, Hip Hop), 5 frequency band sliders, bass boost, virtualizer, and loudness enhancer controls. |
| `home_screen.dart` | Home screen with greeting, quick play grid (All Songs, Recently Added, Shuffle All, Song Count), and horizontal scrollable lists for Recently Added, All Songs, and Newest sections. |
| `library_screen.dart` | Tabbed library with Songs list, Albums grid, Artists list, and Folders tab. Includes sort, search, song options (play, queue, add to playlist, info), album detail (songs by album), and artist detail (songs by artist). |
| `search_screen.dart` | Search bar with real-time filtering. Browse categories grid when no query. Search results as song tiles with artwork, title, artist, album, and options menu. |
| `playlists_screen.dart` | Smart playlists grid (Recently Played, Most Played, Favorites, Recently Added) and user playlists list. Create playlist dialog, playlist options (play, shuffle, rename, delete), and playlist detail view. |
| `now_playing_screen.dart` | Full-screen player with rotating album art, song info, progress bar, playback controls (shuffle, previous, play/pause, next, repeat), and extra controls (devices, queue, equalizer, share). Includes song options menu and queue management. |
| `settings_screen.dart` | Comprehensive settings with Appearance (animations, accent color, default screen), Audio (quality, replay gain), Playback (crossfade, gapless, equalizer, sleep timer), Storage (clear cache, storage location), and About (version, licenses, privacy policy). |

---

## Architecture

MusicPly follows a clean architecture approach with feature-based organization:

```
┌─────────────────────────────────────────────────┐
│                  Presentation                    │
│  (Screens, Widgets, Riverpod Providers)          │
├─────────────────────────────────────────────────┤
│                    Domain                        │
│  (Models: SongModel, PlaylistModel, etc.)        │
├─────────────────────────────────────────────────┤
│                     Data                         │
│  (Services: AudioEngineService, MusicQueryService)│
└─────────────────────────────────────────────────┘
```

### Layers

1. **Presentation Layer** (`features/*/presentation/`)
   - UI screens and widgets
   - Riverpod providers for reactive state
   - User interaction handling
   - Navigation logic

2. **Domain Layer** (`core/models/`)
   - Data models with Hive annotations
   - Business logic (formatting, calculations)
   - Value equality via Equatable

3. **Data Layer** (`core/services/`)
   - `AudioEngineService`: Audio playback via just_audio
   - `MusicQueryService`: Device music scanning via on_audio_query
   - Data conversion between library models and app models

### State Management

State management is handled by **Riverpod** with a mix of:
- `Provider` for synchronous computed values
- `StreamProvider` for reactive audio streams
- `FutureProvider` for async data loading
- `StateProvider` for simple mutable state

See [State Management](#state-management) for details.

---

## Dependencies

### Audio Playback
| Package | Version | Purpose |
|---------|---------|---------|
| `just_audio` | ^0.9.36 | High-quality audio playback engine |
| `audio_service` | ^0.18.12 | Background audio service for Android |
| `audio_session` | ^0.1.18 | Audio session management & focus handling |

### Local Music Library
| Package | Version | Purpose |
|---------|---------|---------|
| `on_audio_query` | ^2.9.0 | Query device audio files, albums, artists |
| `permission_handler` | ^11.1.0 | Handle runtime permissions (storage, audio) |

### State Management
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_riverpod` | ^2.4.9 | Reactive state management framework |
| `riverpod_annotation` | ^2.3.3 | Riverpod code generation annotations |

### Local Storage
| Package | Version | Purpose |
|---------|---------|---------|
| `hive` | ^2.2.3 | Lightweight NoSQL database |
| `hive_flutter` | ^1.1.0 | Hive Flutter integration |
| `shared_preferences` | ^2.2.2 | Simple key-value storage for settings |

### UI & Animations
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_animate` | ^4.3.0 | Declarative animations (fade, scale, slide) |
| `cached_network_image` | ^3.3.0 | Image caching (for network album art) |
| `shimmer` | ^3.0.0 | Loading shimmer effects |

### Icons
| Package | Version | Purpose |
|---------|---------|---------|
| `cupertino_icons` | ^1.0.8 | iOS-style icons |
| `font_awesome_flutter` | ^10.6.0 | Font Awesome icon pack |

### Utilities
| Package | Version | Purpose |
|---------|---------|---------|
| `path_provider` | ^2.1.1 | Access device file system paths |
| `uuid` | ^4.2.1 | Generate unique IDs for playlists |
| `equatable` | ^2.0.5 | Value equality for models |
| `json_annotation` | ^4.8.1 | JSON serialization annotations |

### Dev Dependencies
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_lints` | ^6.0.0 | Dart linting rules |
| `hive_generator` | ^2.0.1 | Generate Hive adapters |
| `build_runner` | ^2.4.7 | Code generation runner |
| `riverpod_generator` | ^2.3.9 | Riverpod code generation |
| `json_serializable` | ^6.7.1 | JSON serialization code gen |

---

## Getting Started

### Prerequisites

- **Flutter SDK**: 3.10.4 or higher
- **Dart SDK**: 3.10.4 or higher (included with Flutter)
- **Android Studio** or **VS Code** with Flutter extensions
- **Android SDK**: API level 21+ (Android 5.0+)
- **Physical Android device** or emulator with music files
- **Java/Kotlin**: JDK 17+ (for Android builds)

### System Requirements

- Windows 10+, macOS 10.15+, or Linux
- 8 GB RAM minimum (16 GB recommended)
- 10 GB free disk space for Flutter SDK + Android SDK

---

## Installation

### 1. Install Flutter

Follow the official Flutter installation guide: [https://docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install)

Verify installation:
```bash
flutter doctor
```

### 2. Clone the Repository

```bash
git clone <repository-url>
cd musicply
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Generate Hive Adapters (if needed)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 5. Run the App

```bash
flutter run
```

Or specify a device:
```bash
flutter devices           # List available devices
flutter run -d <device-id>  # Run on specific device
```

---

## Configuration

### Android Permissions

The app requires the following permissions, configured in `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Read audio files from external storage (Android < 13) -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
                 android:maxSdkVersion="32" />

<!-- Write external storage (for cache) -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

<!-- Read media audio files (Android 13+) -->
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
```

Permissions are requested at runtime via `permission_handler`. The app first requests `READ_MEDIA_AUDIO` (Android 13+), then falls back to `READ_EXTERNAL_STORAGE` for older devices.

### Routes

Defined in `main.dart`:

| Route | Screen | Description |
|-------|--------|-------------|
| `/` | `MainScreen` | Main screen with bottom navigation |
| `/now-playing` | `NowPlayingScreen` | Full-screen player |
| `/settings` | `SettingsScreen` | App settings |

### Hive Boxes

| Box Name | Purpose | Contents |
|----------|---------|----------|
| `favorites` | Favorite songs | Song IDs and metadata |
| `playlists` | User playlists | Playlist names, song IDs |
| `settings` | App settings | Theme, quality, etc. |
| `recent` | Recently played | Song IDs with timestamps |
| `most_played` | Play counts | Song IDs with count |

### Shared Preferences Keys

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `theme` | String | `dark` | Theme mode |
| `accent_color` | String | `#1DB954` | Accent color hex |
| `animations` | bool | `true` | Enable animations |
| `default_screen` | String | `home` | Startup screen |
| `audio_quality` | String | `high` | Audio quality |
| `crossfade` | bool | `false` | Enable crossfade |
| `gapless` | bool | `true` | Enable gapless |
| `replay_gain` | bool | `false` | Enable replay gain |

---

## Usage Guide

### Playing Music

1. Open the app — it automatically scans your device for music files
2. Navigate to the **Library** tab
3. Browse by **Songs**, **Albums**, **Artists**, or **Folders**
4. Tap any song to start playback
5. The **mini player** appears at the bottom showing the current song
6. Tap the mini player to open the **full Now Playing screen**

### Quick Play from Home

1. On the **Home** screen, use the quick play grid:
   - **All Songs**: Play all songs in order
   - **Recently Added**: Play 20 most recently added songs
   - **Shuffle All**: Shuffle all songs
   - **Song Count**: Shows total song count
2. Browse horizontal lists for Recently Added, All Songs, and Newest
3. Tap **See All** to view all songs in a section

### Searching for Music

1. Tap the **Search** tab
2. Type a song name, artist, or album in the search bar
3. Results update in real-time as you type
4. Tap a result to play it
5. Browse category cards (Pop, Rock, etc.) to search by genre
6. Tap the X button to clear search

### Managing Playlists

1. Go to the **Playlists** tab
2. View **Smart Playlists**: Recently Played, Most Played, Favorites, Recently Added
3. Create a custom playlist:
   - Tap the **+** button in the app bar
   - Enter a playlist name
   - Tap **Create**
4. Tap a playlist to view its songs
5. Use the **more menu** on a playlist for options: Play, Shuffle, Rename, Delete
6. Use the **play button** to start playback of all songs in a playlist

### Using the Queue

1. While playing a song, tap the **queue icon** in the Now Playing screen
2. View all songs in the current queue
3. Tap a song to jump to it
4. Tap the **X** button on a song to remove it from the queue
5. Songs are added to queue via **song options** in Library or Search

### Song Options

In the Library or Search screens, tap the **three-dot menu** on any song:
- **Play**: Start playing this song
- **Add to Queue**: Add to the end of the current queue
- **Add to Playlist**: Add to a playlist (coming soon)
- **Song Info**: View title, artist, album, duration, file size

### Album & Artist Details

1. In the Library **Albums** tab, tap an album to see its songs
2. In the Library **Artists** tab, tap an artist to see their songs
3. Use the **more menu** on an artist to Play All or Shuffle their songs
4. Tap any song in the detail view to play it

### Now Playing Controls

On the full Now Playing screen:
- **Tap play/pause** button to toggle playback
- **Drag the seek bar** to jump to a position
- **Tap previous/next** to change songs
- **Swipe left/right** on album art to change songs
- **Swipe down** to minimize back to the mini player
- **Tap heart icon** to favorite/unfavorite
- **Tap shuffle** to toggle shuffle mode
- **Tap repeat** to cycle through loop modes (Off → All → One)

### Extra Controls

Below the main controls in Now Playing:
- **Devices**: View output devices (not yet implemented)
- **Queue**: View and manage the current queue
- **Equalizer**: Adjust audio frequencies (coming soon)
- **Share**: Show current song info

### Settings

Navigate to **Settings** via the profile icon on the Home screen or the Settings tab:

#### Appearance
- **Enable Animations**: Toggle smooth transitions on/off
- **Accent Color**: Choose from 5 color options (green, purple, red, yellow, blue)
- **Default Screen**: Choose which tab opens on startup (Home, Library, Search, Playlists)

#### Audio
- **Audio Quality**: Low (128kbps), Medium (192kbps), High (320kbps), Ultra (Lossless)
- **Replay Gain**: Normalize volume across tracks

#### Playback
- **Crossfade**: Smooth transitions between tracks
- **Gapless Playback**: No silence between tracks
- **Equalizer**: Adjust audio frequencies (coming soon)
- **Sleep Timer**: Stop playback after 5, 10, 15, 30, 45, 60, 90, or 120 minutes

#### Storage
- **Clear Cache**: Free up storage space
- **Storage Location**: View storage info

#### About
- **Version**: App version (1.0.0)
- **Licenses**: Open source license page
- **Privacy Policy**: View privacy policy

---

## Screen Breakdown

### Home Screen (`home_screen.dart`)

**Layout:**
- SliverAppBar with greeting ("Good Morning/Afternoon/Evening")
- Notifications and Profile icons
- Quick Play grid (2x2): All Songs, Recently Added, Shuffle All, Song Count
- Horizontal scrollable lists: Recently Added, All Songs, Newest
- "See All" buttons open bottom sheet with all songs

**Features:**
- Dynamic greeting based on time of day
- Animated entry for all elements
- Song count display
- Quick play buttons for immediate playback

### Library Screen (`library_screen.dart`)

**Layout:**
- SliverAppBar with Sort and Search actions
- TabBar: Songs, Albums, Artists, Folders

**Songs Tab:**
- ListView of all songs with artwork, title, artist, album, duration
- Tap to play, more menu for options
- Animated entry with staggered delays

**Albums Tab:**
- GridView (2 columns) of album cards
- Album artwork, name, artist
- Tap to view album songs in bottom sheet

**Artists Tab:**
- ListView of artist tiles with avatar, name, album/song counts
- Tap to view artist songs in bottom sheet
- More menu for Play All / Shuffle

**Folders Tab:**
- Placeholder for future folder browsing

### Search Screen (`search_screen.dart`)

**Layout:**
- SliverAppBar with "Search" title
- Search bar with real-time filtering
- Browse categories grid (12 categories) when no query
- Search results as ListView when searching

**Features:**
- Instant search as you type
- Clear button to reset search
- Category cards pre-fill search query
- Song results with artwork, title, artist, album
- More menu for song options

### Playlists Screen (`playlists_screen.dart`)

**Layout:**
- SliverAppBar with + button for creating playlists
- Smart Playlists grid (2x2): Recently Played, Most Played, Favorites, Recently Added
- User Playlists list (10 placeholder playlists)

**Features:**
- Create playlist dialog with name input
- Smart playlist cards with colored icons
- Playlist tiles with play and more buttons
- Playlist detail view with song list

### Now Playing Screen (`now_playing_screen.dart`)

**Layout:**
- Header with back button and "NOW PLAYING" label, more options menu
- Rotating album art in circular container with gradient glow
- Song title and artist with favorite button
- Progress bar with drag support and time labels
- Main controls: Shuffle, Previous, Play/Pause, Next, Repeat
- Extra controls: Devices, Queue, Equalizer, Share

**Features:**
- Album art rotates while playing
- Swipe gestures on album art (left=next, right=previous)
- Animated entry for all elements
- Real-time progress tracking
- Queue management via bottom sheet
- Song options: Add to Playlist, Add to Favorites, Song Info, Sleep Timer

### Mini Player (`mini_player.dart`)

**Layout:**
- Linear progress indicator at top
- Row: Album art, song info (title + artist), playback controls
- Controls: Previous, Play/Pause, Next

**Features:**
- Appears when a song is playing
- Animated slide-in from bottom
- Tap to open Now Playing screen
- Real-time progress indicator
- Animated playback controls

### Settings Screen (`settings_screen.dart`)

**Layout:**
- SliverAppBar with "Settings" title
- Sections: Appearance, Audio, Playback, Storage, About
- Each section in a rounded card container
- List tiles with icons, titles, subtitles, and trailing widgets

**Features:**
- Toggle switches for boolean settings
- Radio list tiles for multi-option settings
- Dialog pickers for accent color, default screen, audio quality, sleep timer
- License page integration

---

## State Management

MusicPly uses **Riverpod** for state management with 16+ providers:

### Audio Providers (`audio_provider.dart`)

| Provider | Type | Returns | Description |
|----------|------|---------|-------------|
| `audioServiceProvider` | `Provider` | `AudioEngineService` | Audio service singleton |
| `currentSongProvider` | `StreamProvider` | `SongModel?` | Currently playing song |
| `queueProvider` | `StreamProvider` | `List<SongModel>` | Current queue |
| `isPlayingProvider` | `StreamProvider` | `bool` | Playback state |
| `positionProvider` | `StreamProvider` | `Duration` | Current position |
| `durationProvider` | `StreamProvider` | `Duration?` | Song duration |
| `shuffleProvider` | `StreamProvider` | `bool` | Shuffle enabled |
| `loopModeProvider` | `StreamProvider` | `LoopMode` | Current loop mode |
| `playbackSpeedProvider` | `StreamProvider` | `double` | Playback speed |
| `playerStateProvider` | `StreamProvider` | `PlayerState` | Player state |
| `processingStateProvider` | `StreamProvider` | `ProcessingState` | Processing state |
| `currentIndexProvider` | `StreamProvider` | `int` | Current index in queue |
| `progressProvider` | `Provider` | `double` | Progress (0.0-1.0) |
| `formattedPositionProvider` | `Provider` | `String` | "m:ss" formatted position |
| `formattedDurationProvider` | `Provider` | `String` | "m:ss" formatted duration |
| `hasNextProvider` | `Provider` | `bool` | Has next song |
| `hasPreviousProvider` | `Provider` | `bool` | Has previous song |
| `isBufferingProvider` | `Provider` | `bool` | Is buffering |
| `isLoadingProvider` | `Provider` | `bool` | Is loading |

### Music Providers (`music_provider.dart`)

| Provider | Type | Returns | Description |
|----------|------|---------|-------------|
| `musicQueryServiceProvider` | `Provider` | `MusicQueryService` | Music query service |
| `allSongsProvider` | `FutureProvider` | `List<SongModel>` | All device songs |
| `albumsProvider` | `FutureProvider` | `List<AlbumModel>` | All albums |
| `artistsProvider` | `FutureProvider` | `List<ArtistModel>` | All artists |
| `searchQueryProvider` | `StateProvider` | `String` | Current search query |
| `filteredSongsProvider` | `Provider` | `AsyncValue<List<SongModel>>` | Filtered search results |

---

## Audio Engine

The `AudioEngineService` is a singleton wrapping `just_audio` for all playback. Android audio effects (`AndroidEqualizer`, `AndroidLoudnessEnhancer`) are created at service instantiation and attached to the `AudioPlayer` via `AudioPipeline`:

```dart
class AudioEngineService {
  // Singleton pattern
  static final AudioEngineService _instance = AudioEngineService._internal();
  factory AudioEngineService() => _instance;

  // Audio effects created before the player and attached via AudioPipeline
  final AndroidEqualizer _equalizer = AndroidEqualizer();
  final AndroidLoudnessEnhancer _loudnessEnhancer = AndroidLoudnessEnhancer();

  late final AudioPlayer _audioPlayer = AudioPlayer(
    audioPipeline: AudioPipeline(
      androidAudioEffects: [_equalizer, _loudnessEnhancer],
    ),
  );

  // Core methods
  Future<void> loadPlaylist(List<SongModel> songs, {int initialIndex = 0});
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> next();
  Future<void> previous();
  Future<void> seek(Duration position);
  Future<void> seekToIndex(int index);
  Future<void> toggleShuffle();
  Future<void> setLoopMode(LoopMode mode);
  Future<void> cycleLoopMode();
  Future<void> setPlaybackSpeed(double speed);
  Future<void> setVolume(double volume);
  Future<void> addToQueue(SongModel song);
  Future<void> removeFromQueue(int index);
  Future<void> moveInQueue(int oldIndex, int newIndex);
  Future<void> clearQueue();
}
```

> **Note:** `just_audio` requires Android audio effects to be passed at `AudioPlayer` construction time via `AudioPipeline`. Effects cannot be added after the player is created. The `EqualizerService.init()` receives the pre-created effects and loads saved settings onto them.

### Streams

| Stream | Type | Description |
|--------|------|-------------|
| `playerStateStream` | `PlayerState` | Play/pause/buffering state |
| `positionStream` | `Duration` | Current playback position |
| `durationStream` | `Duration?` | Total song duration |
| `playingStream` | `bool` | Is currently playing |
| `processingStateStream` | `ProcessingState` | Loading/buffering/ready |
| `currentIndexStream` | `int` | Current queue index |
| `queueStream` | `List<SongModel>` | Current queue |
| `shuffleStream` | `bool` | Shuffle enabled |
| `loopModeStream` | `LoopMode` | Current loop mode |
| `playbackSpeedStream` | `double` | Playback speed |

---

## Data Models

### SongModel

```dart
class SongModel extends Equatable {
  final String id;           // Unique ID from media store
  final String title;        // Song title
  final String artist;       // Artist name
  final String album;        // Album name
  final String albumId;      // Album ID from media store
  final String uri;          // File path / URI
  final String? albumArt;    // Album art path (nullable)
  final int duration;        // Duration in milliseconds
  final int size;            // File size in bytes
  final String? displayName; // Display name
  final String? mimeType;    // MIME type (e.g., "audio/mpeg")
  final int dateAdded;       // Unix timestamp when added
  final int dateModified;    // Unix timestamp when modified
  final String? composer;    // Composer (nullable)
  final String? genre;       // Genre (nullable)
  final int track;           // Track number
  final int year;            // Release year
  final bool isFavorite;     // User favorited
  final int playCount;       // Number of times played
  final int lastPlayed;      // Unix timestamp of last play
}
```

**Computed Properties:**
- `fileExists`: Checks if the audio file exists on disk (`File(uri).existsSync()`)
- `folderPath`: Parent directory path (handles both `/` and `\` separators)
- `formattedDuration`: "MM:SS" formatted duration
- `formattedSize`: Human-readable file size (B, KB, MB)

### PlaylistModel

```dart
class PlaylistModel extends Equatable {
  final String id;              // Unique ID (UUID)
  final String name;            // Playlist name
  final List<String> songIds;   // Song IDs in playlist
  final int createdAt;          // Unix timestamp
  final int updatedAt;          // Unix timestamp
  final String? description;    // Optional description
  final bool isSmartPlaylist;   // Auto-generated playlist
}
```

---

## Theme & Design System

### Color Palette

| Color | Hex | Usage |
|-------|-----|-------|
| Primary | `#1DB954` | Spotify green - buttons, accents, active states |
| Secondary | `#1ED760` | Lighter green - gradients |
| Accent | `#6366F1` | Purple - secondary accents |
| Background | `#121212` | App background |
| Surface | `#1E1E1E` | Cards, containers |
| Card | `#282828` | Card backgrounds |
| Text Primary | `#FFFFFF` | Main text |
| Text Secondary | `#B3B3B3` | Subtitles, descriptions |
| Text Tertiary | `#727272` | Hints, disabled text |
| Error | `#FF5252` | Error states |
| Success | `#4CAF50` | Success states |
| Warning | `#FFC107` | Warning states |

### Typography

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| headlineLarge | 32px | Bold | Page titles |
| headlineMedium | 24px | Bold | Section titles, greetings |
| headlineSmall | 20px | SemiBold | Subsection titles |
| titleLarge | 18px | SemiBold | Card titles |
| titleMedium | 16px | Medium | List titles |
| titleSmall | 14px | Medium | Small titles |
| bodyLarge | 16px | Normal | Body text |
| bodyMedium | 14px | Normal | Secondary text |
| bodySmall | 12px | Normal | Tertiary text |
| labelLarge | 14px | Medium | Button labels |
| labelMedium | 12px | Medium | Small labels |
| labelSmall | 10px | Medium | Tiny labels |

### Spacing

| Token | Value |
|-------|-------|
| spacingXS | 4.0 |
| spacingS | 8.0 |
| spacingM | 16.0 |
| spacingL | 24.0 |
| spacingXL | 32.0 |
| spacingXXL | 48.0 |

### Component Theming

All Material components are themed via `AppTheme.darkTheme`:
- **AppBar**: Transparent background, no elevation
- **Cards**: Dark card color, rounded 16px, no elevation
- **Buttons**: Primary color, rounded 12px, no elevation
- **Sliders**: Primary active track, dark inactive, round thumb
- **Dialogs**: Surface color, rounded 20px
- **Bottom Sheets**: Surface color, rounded top corners
- **Snackbars**: Card color, rounded 12px, floating behavior
- **Input Fields**: Surface fill, rounded 12px, primary focus border

---

## Animations

The app uses `flutter_animate` for declarative animations:

| Animation | Duration | Usage |
|-----------|----------|-------|
| Fast | 200ms | Button presses, quick transitions |
| Normal | 300ms | Page transitions, element entry |
| Slow | 500ms | Complex animations |
| Very Slow | 800ms | Background transitions |

### Animation Types

- **Fade**: Element opacity from 0 to 1
- **Scale**: Element size from smaller to full
- **Slide**: Element position offset
- **Rotate**: Album art rotation (continuous while playing)

### Staggered Animations

Lists use staggered delays:
```dart
.animate().fadeIn(delay: (index * 30).ms).slideX(begin: 0.1)
```

---

## Building for Release

### Android APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (for Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Split APKs by ABI

```bash
flutter build apk --split-per-abi --release
```

### Build Configuration

- **Min SDK**: 21 (Android 5.0)
- **Target SDK**: 34 (Android 14)
- **Compile SDK**: 34
- **Kotlin**: 1.9.0
- **Gradle**: 8.1.0

### Signing

For release builds, configure signing in `android/app/build.gradle`:

```groovy
android {
    signingConfigs {
        release {
            storeFile file('path/to/keystore.jks')
            storePassword 'your-store-password'
            keyAlias 'your-key-alias'
            keyPassword 'your-key-password'
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

---

## Troubleshooting

### No Music Found

- Ensure music files exist on the device
- Check that storage permissions are granted
- Go to Settings > Apps > MusicPly > Permissions and enable Storage/Audio
- Try restarting the app after granting permissions

### Type 'string' is not subtype of type 'int'

This error occurs when the `on_audio_query` library returns string values for integer fields. The app includes a `_parseInt()` helper in `SongModel.fromMap()` that safely handles this conversion.

### Could Not Load Music

- Verify storage permissions are granted
- Ensure the device has audio files in standard locations (Music, Downloads, etc.)
- Check that the files are valid audio formats (MP3, AAC, FLAC, OGG, WAV, etc.)
- Try the Retry button on the error screen

### Audio Not Playing

- Check that the device volume is up
- Ensure no other app is using the audio session
- Verify the audio file is not corrupted
- Check the file path exists and is accessible
- Look for error Snackbars on the Home screen — the app listens to `playbackErrorStream` and displays messages like "No playable files found" or "File not found — removed from queue"
- Run `flutter run` and watch logcat for errors from `just_audio` or `audio_service`
- If the equalizer fails to initialize, playback continues without it (wrapped in try-catch)

### Build Errors

```bash
# Clean build cache
flutter clean

# Reinstall dependencies
flutter pub get

# Regenerate Hive adapters
flutter pub run build_runner build --delete-conflicting-outputs

# Check for issues
flutter doctor -v
```

### Permission Issues on Android 13+

Android 13+ uses `READ_MEDIA_AUDIO` instead of `READ_EXTERNAL_STORAGE`. The app handles both cases, but if issues persist:

1. Go to Settings > Apps > MusicPly > Permissions
2. Grant "Music and audio" permission
3. Restart the app

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Follow the official Dart style guide
- Use `flutter_lints` for linting
- Run `flutter analyze` before committing
- Format code with `dart format .`

### Commit Messages

Use conventional commits:
- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation
- `style:` for formatting changes
- `refactor:` for code refactoring
- `test:` for adding tests
- `chore:` for maintenance

---

## License

This project is licensed under the MIT License. See the LICENSE file for details.

---

## Changelog

### v1.0.1 (Bug Fixes)

- **Fixed audio playback**: `AndroidEqualizer` and `AndroidLoudnessEnhancer` were created but never attached to the `AudioPlayer`. In `just_audio`, audio effects must be passed at player construction time via `AudioPipeline`. Effects are now created as fields on `AudioEngineService` and passed to `AudioPlayer(audioPipeline: AudioPipeline(androidAudioEffects: [...]))`.
- **Fixed equalizer crash**: `EqualizerService.init()` is now wrapped in try-catch so playback continues even if the equalizer API is unavailable on the device.
- **Fixed `folderPath` on Windows**: The `SongModel.folderPath` getter now handles both `/` and `\` path separators using `RegExp(r'[/\\]')` instead of only forward slashes.
- **Updated `EqualizerService.init()` signature**: Now accepts pre-created `AndroidEqualizer` and `AndroidLoudnessEnhancer` instances instead of creating its own, ensuring they are the same objects attached to the player.

### v1.0.0

- Initial release with full music player functionality

---

## Acknowledgments

- [Flutter](https://flutter.dev/) - The UI framework
- [just_audio](https://pub.dev/packages/just_audio) - Audio playback engine
- [on_audio_query](https://pub.dev/packages/on_audio_query) - Device music scanning
- [Riverpod](https://pub.dev/packages/flutter_riverpod) - State management
- [flutter_animate](https://pub.dev/packages/flutter_animate) - Animations
- [Hive](https://pub.dev/packages/hive) - Local database
- Spotify - Design inspiration

---

**MusicPly** - Your premium music experience
