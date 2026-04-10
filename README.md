# musiq - Premium Music Player App

> **Platform Support: Currently Android only.** iOS support is planned for a future release. The app may compile on iOS but some features (equalizer, audio output switching, advanced audio effects) will be unavailable. See [Why Android First?](#why-android-first) for details.

A fully functional Android music player app built with Flutter featuring a modern dark theme inspired by Spotify, smooth animations, and a clean, premium UI/UX. musiq scans your device for audio files and provides a rich playback experience with playlists, search, queue management, and a beautiful animated now-playing screen.

---

## Table of Contents

- [Features](#features)
- [New Features (v1.2.0 - Premium Pack)](#new-features-v120---premium-pack)
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
- **NEW**: Add songs to multiple playlists at once

### Now Playing Screen
- Full-screen animated player with rotating album art
- Gradient background based on album art colors
- Swipe left/right to change songs
- Swipe down to minimize
- Progress bar with drag-to-seek
- Favorite/unfavorite toggle
- Song info dialog
- **NEW**: Audio output device selection
- **NEW**: Share song info via system share sheet

### Mini Player
- Persistent mini player at bottom of screen
- Shows current song title, artist, and album art
- Play/pause, next, previous controls
- Tap to expand to full Now Playing screen
- Linear progress indicator

### Settings
- **Appearance**: Enable/disable animations, accent color picker, default screen selection
- **Audio**: Audio quality (Low/Medium/High/Ultra), Replay Gain toggle
- **Playback**: Crossfade toggle, Gapless playback toggle, **Equalizer** (now available), Sleep Timer
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

## New Features (v1.1.0)

### Feature 1: Folders Tab in Library

The Folders tab has been fully implemented, allowing users to browse their music collection organized by folder structure on their device.

**FolderModel**
```dart
class FolderModel extends Equatable {
  final String path;        // Absolute folder path
  final String name;         // Last segment of path
  final List<String> songIds; // IDs of songs in folder
  final int songCount;      // Number of songs
  final String? coverArtId; // First song's album art for thumbnail
}
```

**Implementation Details:**
- Folders are automatically discovered by scanning all song file paths
- System folders like `/Android/data/`, `/Android/obb/`, `/.thumbnails/`, etc. are automatically ignored
- Folders are sorted alphabetically (A-Z)
- Each folder tile displays album art from the first song in the folder
- Folder options menu provides: Play All, Shuffle, Add to Queue

**Usage:**
1. Navigate to Library tab
2. Tap the Folders tab
3. Browse folders or tap to view songs within
4. Use the more menu (⋮) on any folder for Play/Shuffle/Queue options

### Feature 2: Add to Playlist from Song Options

Users can now add songs to playlists directly from the song options menu. The implementation supports multi-select functionality.

**AddToPlaylistDialog**
- Shows all user-created playlists with checkboxes
- Allows selecting multiple playlists at once
- "Add to Selected" button adds the song to all chosen playlists
- "Create new playlist" option within the dialog
- Automatically adds song to newly created playlist

**Implementation Details:**
- Located at `lib/features/playlists/presentation/widgets/add_to_playlist_dialog.dart`
- Uses Riverpod for state management with `userPlaylistsProvider`
- Prevents duplicate entries (songs already in playlist are marked as "Already in playlist")
- Shows success snackbar after adding

**Usage:**
1. In Library or Search, tap the three-dot menu on any song
2. Select "Add to Playlist"
3. Select one or more playlists using checkboxes
4. Tap "Add (N)" to add the song
5. Or tap "New Playlist" to create and add in one step

### Feature 3: Equalizer Integration (Full)

The equalizer is now fully functional and accessible from multiple locations in the app.

**Equalizer Features:**
- Enable/disable equalizer toggle
- 12 presets: Normal, Flat, Bass Boost, Treble Boost, Rock, Pop, Jazz, Classical, Dance, Electronic, Hip Hop, R&B, Acoustic
- 5-band equalizer with frequency labels: 60Hz, 230Hz, 910Hz, 3.6kHz, 14kHz
- Individual band adjustment (-12dB to +12dB)
- Bass Boost control (0-1000)
- Virtualizer control (0-1000)
- Loudness Enhancer control
- Reset to Defaults button
- Settings persist across app restarts

**Accessible From:**
- Settings → Playback → Equalizer
- Now Playing → Equalizer icon (extra controls)

**Implementation Details:**
- `EqualizerService` at `lib/core/services/equalizer_service.dart`
- Uses Android's native `AndroidEqualizer` and `AndroidLoudnessEnhancer` via `just_audio`
- All settings saved to SharedPreferences
- Gracefully handles devices without equalizer support

**Usage:**
1. Tap the equalizer icon from Now Playing or Settings
2. Toggle the equalizer on/off
3. Choose a preset or adjust bands manually
4. Use Bass Boost, Virtualizer, and Loudness Enhancer sliders
5. Tap "Reset to Defaults" to restore flat EQ

### Feature 4: Audio Output Device Selector

Users can now switch between audio output devices (Speaker, Wired Headphones, Bluetooth) directly from the Now Playing screen.

**AudioOutputService**
```dart
class AudioOutputService {
  // Methods
  Future<void> init();
  Future<List<OutputDevice>> getOutputDevices();
  Future<bool> setOutputDevice(OutputDevice device);
  
  // Streams
  Stream<OutputDevice> get currentDeviceStream;
  Stream<List<OutputDevice>> get availableDevicesStream;
  
  // Current device
  OutputDevice get currentDevice;
}
```

**Supported Devices:**
- Speaker (always available)
- Wired Headphones (detected when plugged in)
- Bluetooth (detected when connected)

**Implementation Details:**
- Flutter service at `lib/core/services/audio_output_service.dart`
- Native Android implementation in `MainActivity.kt` using MethodChannel
- Uses Android's `AudioManager` for device switching
- Automatically detects and lists available devices

**Native Android Code (MainActivity.kt):**
```kotlin
MethodChannel methods:
- getCurrentDevice: Returns current output device ID
- getAvailableDevices: Returns list of connected devices
- setOutputDevice: Switches audio output to specified device
```

**Usage:**
1. While playing a song, tap the Devices icon (📱) in Now Playing
2. A bottom sheet shows available output devices
3. Select your preferred output (Speaker, Headphones, Bluetooth)
4. Audio immediately switches to the selected device

### Feature 5: Share Song Info
Users can now share information about the currently playing song via the system's share sheet.

**Share Features:**
- Share song title, artist, and album info
- Uses `share_plus` package for cross-platform sharing
- Available from Now Playing screen

**Implementation Details:**
- Uses `share_plus` package (v7.2.1+)
- Share text format: `Now playing: "Song Title" by Artist from album "Album Name"`
- Opens native share sheet with pre-filled text

**Usage:**
1. While playing a song, tap the Share icon (📤) in Now Playing
2. Tap "Share via apps" to open the system share sheet
3. Choose an app to share (Messages, Email, etc.)

---

## New Features (v1.2.0 - Premium Pack)

### Feature 1: Dynamic Background Image System (Creative Core)

A revolutionary background system that transforms the app's visual experience with custom images, album art synchronization, and dynamic effects.

**BackgroundSettings Model**
```dart
class BackgroundSettings {
  final BackgroundMode mode; // none, custom, albumArt, blurredAlbumArt
  final String? customImagePath; // local file path
  final double blurIntensity; // 0.0 to 20.0
  final double darkOverlayOpacity; // 0.0 to 0.8
  final bool enableParallax; // subtle movement on scroll
  final bool syncWithAlbumColors; // sync UI colors with album art
  final bool enableParticles; // floating particle effect
  final bool enableTimeBasedBackground; // different images for morning/afternoon/evening/night
}
```

**Background Modes:**
- **None**: Solid dark/light theme background (default)
- **Custom Image**: User picks from gallery with blur/overlay sliders
- **Album Art Sync**: Background = current song's album art, updates on track change
- **Blurred Album Art**: Heavy blur + dark overlay on album art

**Implementation Details:**
- **Model**: `BackgroundSettings` in `core/models/background_settings.dart`
- **Provider**: `backgroundSettingsProvider` in `core/providers/background_provider.dart`
- **Widget**: `AnimatedBackground` in `core/widgets/animated_background.dart`
- **Persistence**: Hive box `background`
- **Parallax Effect**: Background moves at 30% of scroll speed for depth
- **Color Extraction**: Uses `palette_generator` to extract dominant colors from album art
- **Particle Effect**: Subtle floating dots using CustomPainter and `sensors_plus`

**Creative Bonus Features:**
- **Morphing Transitions**: 300ms AnimatedCrossFade when background changes
- **Live Album Color Extraction**: Dynamically adjusts Now Playing accent color
- **Particle System**: Floating dots that respond to device tilt
- **Time-based Background**: Different images for morning (5-12), afternoon (12-17), evening (17-20), night (20-5)
- **Blur Zoom on Long Press**: Long-press album art in Now Playing to zoom and blur background

**Usage:**
1. Navigate to Settings → Appearance → Background Image
2. Choose mode: None, Custom, Album Art, or Blurred Album Art
3. For Custom: tap "Select Image" to pick from gallery
4. Adjust blur and overlay sliders
5. Enable Advanced Effects: Parallax, Color Sync, Particles, Time-based
6. Background applies immediately without restart

---

### Feature 2: Integrated Lyrics Viewer with LRC Support

Display synchronized or plain lyrics for the current song, fetched from online APIs or user-provided.

**LyricsModel**
```dart
class LyricsModel {
  final String songId;
  final String? lyricsText; // plain lyrics
  final List<LyricLine>? lrcLines; // synchronized lyrics
  final bool isUserProvided;
  final int source; // 0=local, 1=lrclib, 2=ovh, 3=musixmatch, 4=user
  final DateTime fetchedAt;
}

class LyricLine {
  final Duration timestamp; // for synchronized lyrics
  final String text;
}
```

**Data Flow:**
1. Check local Hive cache first
2. Query online providers (LRCLIB, OVH)
3. Parse LRC format into `LyricLine` objects
4. Cache results in Hive

**Implementation Details:**
- **Model**: `LyricsModel`, `LyricLine` in `core/models/lyrics_model.dart`
- **Service**: `LyricsService` in `core/services/lyrics_service.dart`
- **UI**: `LyricsViewer` in `features/player/presentation/lyrics_viewer.dart`
- **Providers**: LRCLIB (free, no API key), OVH (free), Musixmatch (optional)
- **Persistence**: Hive box `lyrics`

**UI Features:**
- **Lyrics Tab**: New tab in Now Playing alongside Queue
- **Synchronized Lyrics**: Highlights current line based on position stream
- **Auto-scroll**: Automatically scrolls to active line (toggle in settings)
- **Plain Lyrics**: Scrollable text view
- **Manual Input**: Bottom sheet for user-contributed lyrics (plain or LRC format)
- **Offline Mode**: Settings → Playback → Lyrics Source (Online, Offline, User Only)

**Usage:**
1. Play a song with available lyrics
2. In Now Playing, tap the Lyrics tab
3. View synchronized or plain lyrics
4. Toggle auto-scroll on/off
5. Tap "Add Lyrics" to manually add or paste lyrics
6. Lyrics update automatically when song changes

---

### Feature 3: Smart Playlists (Rule-Based)

Create dynamic playlists based on rules (genre, artist, play count, year, rating) that automatically update.

**SmartPlaylistRule Model**
```dart
enum SmartRuleField {
  artist, album, genre, year, playCount, lastPlayed, rating, title
}

enum SmartRuleOperator {
  equals, notEquals, contains, notContains, 
  greaterThan, lessThan, greaterThanOrEqual, lessThanOrEqual
}

enum SmartRuleLogic { and, or }

class SmartRule {
  final int fieldIndex;
  final int operatorIndex;
  final String value;
}

class SmartPlaylistRule {
  final List<Map<String, dynamic>> rules; // JSON-serialized rules
  final int logicIndex; // and/or
}
```

**Smart Playlist Engine:**
- Evaluates rules against all songs in library
- Runs on app startup, after library scan, and periodically
- Updates playlist song IDs and lastRefreshed timestamp

**Implementation Details:**
- **Model**: `SmartRule`, `SmartPlaylistRule` in `core/models/smart_playlist_model.dart`
- **Engine**: `SmartPlaylistEngine` in `core/services/smart_playlist_engine.dart`
- **Persistence**: Rules stored as JSON in PlaylistModel.smartPlaylistType

**UI Features:**
- Create smart playlist via FAB "+ Smart Playlist"
- Wizard-like flow: Name → Add Conditions → Preview → Save
- Conditions: Field (artist/genre/year/playCount/etc.) + Operator + Value
- Live preview of matching song count
- Smart playlists marked with special icon (Icons.auto_awesome)
- "Refresh Now" and "Edit Rules" in playlist options
- "Convert to Normal Playlist" to freeze current songs

**Usage:**
1. Go to Playlists tab
2. Tap FAB → "Smart Playlist"
3. Enter playlist name
4. Add rules (e.g., "genre equals Rock AND playCount greaterThan 5")
5. Preview matching songs count
6. Save - playlist auto-populates
7. Playlist updates automatically when library changes

---

### Feature 4: Tag Editor (ID3 Metadata)

Edit song metadata (title, artist, album, genre, year, track number, album art) and write changes back to the audio file.

**Implementation Details:**
- **Service**: `TagEditorService` in `core/services/tag_editor_service.dart`
- **UI**: `TagEditorScreen` in `features/player/presentation/tag_editor_screen.dart`
- **Permissions**: Requires WRITE_EXTERNAL_STORAGE (Android < 11) or MANAGE_EXTERNAL_STORAGE (Android 11+)
- Uses `on_audio_query` for metadata reading

**Supported Tags:**
- Title, Artist, Album
- Genre, Year, Track Number
- Composer (if available)
- Album Art (via image picker)

**UI Features:**
- Access from song options menu → "Edit Tags"
- Full-screen edit form with all editable fields
- Current album art shown with "Change" button
- Save button with progress indicator
- Warning: "Editing tags may affect file sorting"
- Success/error snackbar feedback

**Permissions:**
- Requests media library or storage permissions
- Shows rationale dialog before requesting
- Graceful fallback if permissions denied (read-only mode)

**Usage:**
1. In Library/Search, tap the three-dot menu on any song
2. Select "Edit Tags" (if file is writable and permissions granted)
3. Modify title, artist, album, genre, year, track number
4. Tap "Change" to select new album art
5. Tap "Save" to write changes
6. See success/error message

---

### Feature 5: Android Auto & Car Support

Make musiq appear in car dashboards and allow browsing/playback via car controls.

**Implementation Details:**
- **Service**: `AudioEngineService` extends `BaseAudioHandler` from `audio_service`
- **MediaSession**: The existing audio_service integration already exposes MediaSession for Android Auto
- **Manifest**: Requires car intent filters in AndroidManifest.xml

**Android Auto Features:**
- App appears in Android Auto launcher when phone connected to car
- Browse: Playlists, Albums, Artists, Folders
- Playback controls: Play, Pause, Next, Previous, Seek
- Voice search: "Play [song name]"

**Configuration:**
In `android/app/src/main/AndroidManifest.xml`:
```xml
<!-- Android Auto configuration -->
<meta-data
    android:name="android.media.car.application"
    android:resource="@xml/automotive_app_desc" />
```

**User Setting:**
- Settings → Playback → "Car Mode": "Optimize for Android Auto" (placeholder toggle)
- Enables Android Auto service when supported

**Usage:**
1. Connect phone to car via USB or Bluetooth
2. Open Android Auto on car display
3. Find "musiq" in the app launcher
4. Browse and play music using car controls
5. Use voice commands: "Play artist X", "Play song Y"

---

### Feature 6: Backup & Restore (Playlists, Statistics, Settings)

Export/import all user data to a single JSON file for backup and restore.

**Backup Data:**
- All Hive boxes: favorites, playlists, recent, most_played, settings, lyrics, background_settings
- Smart playlist rules (in playlists box)
- SharedPreferences settings

**Implementation Details:**
- **Service**: `BackupService` in `core/services/backup_service.dart`
- **File Format**: JSON with version and timestamp
- **UI**: Settings → Storage → "Backup Now" and "Restore from Backup"

**Backup Features:**
- Single JSON file containing all data
- Version tracking for compatibility
- Timestamp for backup identification
- Progress indicator for large data

**Restore Features:**
- Validates backup file before restore
- Overwrites existing data (with warning)
- Imports: favorites, playlists, recent, most played, lyrics, background settings

**UI Features:**
- "Backup Now" button → saves to device
- "Restore from Backup" button → picks JSON file
- Shows last backup timestamp
- Warning dialog before restore

**Usage:**
1. Navigate to Settings → Storage
2. Tap "Backup Now" to save all data
3. Tap "Restore from Backup" to pick a backup file
4. Confirm restore - all data replaced
5. App behaves identically to original

---

## Project Structure

```
musiq/
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml          # Permissions & app config
│       └── kotlin/.../MainActivity.kt   # Audio output native code
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart       # App-wide constants
│   │   ├── models/
│   │   │   ├── song_model.dart           # Song data model
│   │   │   ├── playlist_model.dart        # Playlist data model
│   │   │   ├── album_model.dart           # Album data model
│   │   │   ├── artist_model.dart          # Artist data model
│   │   │   ├── folder_model.dart          # Folder data model
│   │   │   ├── background_settings.dart   # NEW: Background settings model
│   │   │   ├── lyrics_model.dart          # NEW: Lyrics model
│   │   │   └── smart_playlist_model.dart  # NEW: Smart playlist rules model
│   │   ├── providers/
│   │   │   ├── audio_provider.dart         # Riverpod audio providers
│   │   │   ├── music_provider.dart         # Riverpod music query providers
│   │   │   ├── equalizer_provider.dart     # Riverpod equalizer providers
│   │   │   └── background_provider.dart    # NEW: Background settings provider
│   │   ├── services/
│   │   │   ├── audio_service.dart          # AudioEngineService (just_audio)
│   │   │   ├── music_query_service.dart    # Device music scanning
│   │   │   ├── equalizer_service.dart      # Equalizer control
│   │   │   ├── audio_output_service.dart   # Audio output device control
│   │   │   ├── lyrics_service.dart         # NEW: Lyrics fetching service
│   │   │   ├── smart_playlist_engine.dart # NEW: Smart playlist engine
│   │   │   ├── tag_editor_service.dart     # NEW: Tag metadata editor
│   │   │   └── backup_service.dart         # NEW: Backup/restore service
│   │   ├── widgets/
│   │   │   └── animated_background.dart    # NEW: Animated background widget
│   │   └── theme/
│   │       └── app_theme.dart              # Dark theme & design system
│   ├── features/
│   │   ├── home/
│   │   │   └── presentation/
│   │   │       └── home_screen.dart        # Home screen
│   │   ├── library/
│   │   │   └── presentation/
│   │   │       └── library_screen.dart     # Library (Songs/Albums/Artists/Folders)
│   │   ├── search/
│   │   │   └── presentation/
│   │   │       └── search_screen.dart       # Search screen
│   │   ├── playlists/
│   │   │   └── presentation/
│   │   │       ├── playlists_screen.dart   # Playlists screen
│   │   │       └── widgets/
│   │   │           └── add_to_playlist_dialog.dart # Add to playlist dialog
│   │   ├── player/
│   │   │   └── presentation/
│   │   │       ├── now_playing_screen.dart  # Full-screen player
│   │   │       ├── mini_player.dart         # Persistent mini player
│   │   │       ├── equalizer_screen.dart    # Audio equalizer UI
│   │   │       ├── lyrics_viewer.dart       # NEW: Lyrics viewer widget
│   │   │       └── tag_editor_screen.dart   # NEW: Tag editor screen
│   │   └── settings/
│   │       └── presentation/
│   │           └── settings_screen.dart     # Settings screen
│   └── main.dart                            # App entry point & navigation
├── pubspec.yaml                             # Dependencies & project config
├── README.md                                # This file
└── test/
    └── widget_test.dart                     # Widget tests
```
musiq/
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml          # Permissions & app config
│       └── kotlin/.../MainActivity.kt   # Audio output native code
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart       # App-wide constants
│   │   ├── models/
│   │   │   ├── song_model.dart         # Song data model
│   │   │   ├── playlist_model.dart     # Playlist data model
│   │   │   ├── album_model.dart        # Album data model
│   │   │   ├── artist_model.dart       # Artist data model
│   │   │   └── folder_model.dart       # NEW: Folder data model
│   │   ├── providers/
│   │   │   ├── audio_provider.dart     # Riverpod audio providers
│   │   │   ├── music_provider.dart     # Riverpod music query providers
│   │   │   └── equalizer_provider.dart # Riverpod equalizer providers
│   │   ├── services/
│   │   │   ├── audio_service.dart      # AudioEngineService (just_audio)
│   │   │   ├── music_query_service.dart# Device music scanning
│   │   │   ├── equalizer_service.dart   # Equalizer control
│   │   │   └── audio_output_service.dart# NEW: Audio output device control
│   │   └── theme/
│   │       └── app_theme.dart          # Dark theme & design system
│   ├── features/
│   │   ├── home/
│   │   │   └── presentation/
│   │   │       └── home_screen.dart    # Home screen
│   │   ├── library/
│   │   │   └── presentation/
│   │   │       └── library_screen.dart # Library (Songs/Albums/Artists/Folders)
│   │   ├── search/
│   │   │   └── presentation/
│   │   │       └── search_screen.dart  # Search screen
│   │   ├── playlists/
│   │   │   └── presentation/
│   │   │       ├── playlists_screen.dart      # Playlists screen
│   │   │       └── widgets/
│   │   │           └── add_to_playlist_dialog.dart # NEW: Add to playlist dialog
│   │   ├── player/
│   │   │   └── presentation/
│   │   │       ├── now_playing_screen.dart     # Full-screen player
│   │   │       ├── mini_player.dart            # Persistent mini player
│   │   │       └── equalizer_screen.dart       # Audio equalizer UI
│   │   └── settings/
│   │       └── presentation/
│   │           └── settings_screen.dart        # Settings screen
│   └── main.dart                               # App entry point & navigation
├── pubspec.yaml                                # Dependencies & project config
├── README.md                                   # This file
└── test/
    └── widget_test.dart                        # Widget tests
```

### File Descriptions (Updated)

| File | Purpose |
|------|---------|
| `main.dart` | App entry point. Initializes Hive, sets system UI, defines routes (`/now-playing`, `/settings`, `/equalizer`), and contains the `MainScreen` widget with bottom navigation and `IndexedStack` for tab switching. |
| `app_constants.dart` | All app-wide constants: animation durations, spacing, sizes, Hive box names, Shared Preferences keys, equalizer presets, sleep timer options, playback speed options. |
| `app_theme.dart` | Complete Material 3 dark theme definition. Includes color palette (Spotify green primary, purple accent), text styles, gradients, and all component theming (buttons, cards, sliders, dialogs, etc.). |
| `song_model.dart` | Song data model with Hive annotations for local persistence. Fields: id, title, artist, album, albumId, uri, duration, size, dateAdded, dateModified, track, year, isFavorite, playCount, lastPlayed. Includes safe parsing from `on_audio_query` data. |
| `playlist_model.dart` | Playlist data model with Hive annotations. Fields: id, name, songIds, createdAt, updatedAt, description, isSmartPlaylist. |
| `folder_model.dart` | **NEW** Folder data model. Fields: path, name, songIds, songCount, coverArtId. |
| `audio_service.dart` | `AudioEngineService` - Singleton service wrapping `just_audio`. Creates `AndroidEqualizer` and `AndroidLoudnessEnhancer` at construction and attaches them via `AudioPipeline`. Manages playlist loading, playback controls, shuffle, loop modes, speed, volume, sleep timer, and exposes streams for reactive UI updates. |
| `music_query_service.dart` | `MusicQueryService` - Singleton service wrapping `on_audio_query`. Handles permission requests, queries songs/albums/artists from device storage, converts `on_audio_query` models to app models, and provides folder discovery. |
| `audio_output_service.dart` | **NEW** `AudioOutputService` - Singleton service for managing audio output devices. Uses MethodChannel to communicate with native Android code for device switching (Speaker, Wired Headphones, Bluetooth). |
| `equalizer_service.dart` | `EqualizerService` - Service for managing Android equalizer, bass boost, virtualizer, and loudness enhancer. All settings persist via SharedPreferences. |
| `audio_provider.dart` | 16 Riverpod providers exposing audio state: currentSong, queue, isPlaying, position, duration, shuffle, loopMode, playbackSpeed, playerState, processingState, currentIndex, progress, formattedPosition, formattedDuration, hasNext, hasPrevious. |
| `music_provider.dart` | Riverpod providers for music data including: allSongsProvider, albumsProvider, artistsProvider, searchQueryProvider, filteredSongsProvider, foldersProvider. |
| `equalizer_provider.dart` | 8 Riverpod providers for equalizer state: equalizerServiceProvider, equalizerEnabledProvider, currentPresetProvider, bandValuesProvider, bassBoostProvider, virtualizerProvider, loudnessEnhancerProvider, availablePresetsProvider. |
| `mini_player.dart` | Persistent mini player widget. Shows current song info, album art, progress bar, and play/pause/next/previous controls. Animated slide-in and fade. |
| `equalizer_screen.dart` | Full-screen equalizer with enable toggle, preset selector (Normal, Rock, Pop, Jazz, Classical, Bass Boost, Treble Boost, Vocal, Electronic, Hip Hop), 5 frequency band sliders, bass boost, virtualizer, and loudness enhancer controls. |
| `home_screen.dart` | Home screen with greeting, quick play grid (All Songs, Recently Added, Shuffle All, Song Count), and horizontal scrollable lists for Recently Added, All Songs, and Newest sections. |
| `library_screen.dart` | Tabbed library with Songs list, Albums grid, Artists list, and Folders tab. Includes sort, search, song options (play, queue, add to playlist, info), album detail (songs by album), and artist detail (songs by artist). |
| `add_to_playlist_dialog.dart` | **NEW** Dialog widget for adding songs to playlists. Supports multi-select, create new playlist, and prevents duplicates. |
| `search_screen.dart` | Search bar with real-time filtering. Browse categories grid when no query. Search results as song tiles with artwork, title, artist, album, and options menu. |
| `playlists_screen.dart` | Smart playlists grid (Recently Played, Most Played, Favorites, Recently Added) and user playlists list. Create playlist dialog, playlist options (play, shuffle, rename, delete), and playlist detail view. |
| `now_playing_screen.dart` | Full-screen player with rotating album art, song info, progress bar, playback controls (shuffle, previous, play/pause, next, repeat), and extra controls (devices, queue, equalizer, share). Includes song options menu, queue management, **audio output device selection**, and **share functionality**. |
| `settings_screen.dart` | Comprehensive settings with Appearance (animations, accent color, default screen), Audio (quality, replay gain), Playback (crossfade, gapless, equalizer, sleep timer), Storage (clear cache, storage location), and About (version, licenses, privacy policy). |

---

## Why Android First?

This app is currently developed for Android first. Here's why:

1. **Low-level Audio APIs**: Android provides more granular control over audio routing and effects through APIs like `AudioManager`, `AudioFlinger`, and platform-specific audio effects (equalizer, bass boost, virtualizer). These are deeply integrated with Android's audio subsystem.

2. **MediaStore Access**: The `on_audio_query` plugin provides excellent access to Android's MediaStore database, enabling fast and efficient media scanning. iOS has stricter file system access limitations.

3. **Audio Session Management**: Android's `audio_session` package offers fine-grained control over audio focus,ducking, and interruption handling that aligns better with our feature requirements.

4. **Platform-Specific Plugins**: Several key features (audio output switching, Android equalizer) require native Android implementation that would need separate iOS equivalents.

**iOS Roadmap**: While iOS support is on the roadmap, it requires significant additional development for:
- Alternative to Android's equalizer (using AVAudioEngine)
- iOS MediaPlayer framework integration
- File access via File app integration

Some features will remain Android-exclusive due to platform limitations.

---

## Architecture

musiq follows a clean architecture approach with feature-based organization:

```
┌─────────────────────────────────────────────────┐
│                  Presentation                    │
│  (Screens, Widgets, Riverpod Providers)          │
├─────────────────────────────────────────────────┤
│                    Domain                        │
│  (Models: SongModel, PlaylistModel, FolderModel) │
├─────────────────────────────────────────────────┤
│                     Data                         │
│  (Services: AudioEngineService, MusicQueryService,│
│   AudioOutputService, EqualizerService)          │
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
   - `AudioOutputService`: Audio output device management
   - `EqualizerService`: Audio equalizer and effects
   - Data conversion between library models and app models

### State Management

State management is handled by **Riverpod** with a mix of:
- `Provider` for synchronous computed values
- `StreamProvider` for reactive audio streams
- `FutureProvider` for async data loading
- `StateProvider` for simple mutable state

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
| `on_audio_query` | ^2.9.0 | Query device audio files, albums, artists, folders |
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
| `share_plus` | ^7.2.1 | **NEW (v1.1.0)** System share sheet |

### Premium Pack Dependencies (v1.2.0)
| Package | Version | Purpose |
|---------|---------|---------|
| `image_picker` | ^1.0.7 | Select custom background images |
| `palette_generator` | ^0.3.3+4 | Extract colors from album art |
| `http` | ^1.2.0 | Fetch lyrics from online APIs |
| `file_picker` | ^6.1.1 | Pick backup/restore files |
| `sensors_plus` | ^4.0.2 | Device tilt for particle effects |
| `image` | ^4.1.7 | Image processing for blur/resize |

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
| `/equalizer` | `EqualizerScreen` | Audio equalizer |

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
| `equalizer_enabled` | bool | `false` | Equalizer enabled state |
| `equalizer_preset` | String | `Normal` | Selected EQ preset |
| `equalizer_band_values` | List | [0,0,0,0,0] | Individual band values |
| `bass_boost` | double | `0.0` | Bass boost level |
| `virtualizer` | double | `0.0` | Virtualizer level |
| `loudness_enhancer` | double | `0.0` | Loudness enhancer level |

---

## Usage Guide

### Playing Music

1. Open the app — it automatically scans your device for music files
2. Navigate to the **Library** tab
3. Browse by **Songs**, **Albums**, **Artists**, or **Folders**
4. Tap any song to start playback
5. The **mini player** appears at the bottom showing the current song
6. Tap the mini player to open the **full Now Playing screen**

### Browsing by Folders (NEW)

1. Navigate to the **Library** tab
2. Tap the **Folders** tab
3. Browse folders containing music files
4. Tap a folder to see all songs within it
5. Use the **more menu** (⋮) for Play All, Shuffle, or Add to Queue

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

### Adding Songs to Playlists (NEW)

1. In Library or Search, tap the **three-dot menu** on any song
2. Select **Add to Playlist**
3. Select one or more playlists using checkboxes
4. Tap **Add (N)** to add the song
5. Or tap **New Playlist** to create and add in one step

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
- **Add to Playlist**: Add to a playlist (NEW: multi-select support)
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

### Extra Controls (Updated)

Below the main controls in Now Playing:
- **Devices** (NEW): View and select audio output devices
- **Queue**: View and manage the current queue
- **Equalizer** (NEW): Adjust audio frequencies
- **Share** (NEW): Share song info via system share sheet

### Using the Equalizer (NEW)

1. Tap the **Equalizer** icon in Now Playing or Settings
2. Toggle the equalizer on
3. Choose a preset (Rock, Pop, Jazz, etc.) or adjust bands manually
4. Use Bass Boost, Virtualizer, and Loudness Enhancer sliders for fine-tuning
5. Settings are saved automatically

### Selecting Audio Output (NEW)

1. Tap the **Devices** icon in Now Playing
2. Select your preferred output:
   - **Speaker**: Built-in phone speaker
   - **Wired Headphones**: Connected via headphone jack
   - **Bluetooth**: Connected via Bluetooth
3. Audio switches immediately to the selected device

### Sharing Music (NEW)

1. Tap the **Share** icon in Now Playing
2. Tap "Share via apps" to open the system share sheet
3. Choose an app to share the song info

### Settings

Navigate to **Settings** via the profile icon on the Home screen or the Settings tab:

#### Appearance
- **Enable Animations**: Toggle smooth transitions on/off
- **Accent Color**: Choose from 5 color options (green, purple, red, yellow, blue)
- **Default Screen**: Choose which tab opens on startup (Home, Library, Search, Playlists)

#### Audio
- **Audio Quality**: Low (128kbps), Medium (192kbps), High (320kbps), Ultra (Lossless)
- **Replay Gain**: Normalize volume across tracks

#### Playback (Updated)
- **Crossfade**: Smooth transitions between tracks
- **Gapless Playback**: No silence between tracks
- **Equalizer**: Adjust audio frequencies (NOW AVAILABLE)
- **Sleep Timer**: Stop playback after 5, 10, 15, 30, 45, 60, 90, or 120 minutes

#### Storage
- **Clear Cache**: Free up storage space
- **Storage Location**: View storage info

#### About
- **Version**: App version (1.1.0)
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

### Library Screen (`library_screen.dart`) - UPDATED

**Layout:**
- SliverAppBar with Sort and Search actions
- TabBar: Songs, Albums, Artists, Folders

**Songs Tab:**
- ListView of all songs with artwork, title, artist, album, duration
- Tap to play, more menu for options (including Add to Playlist)
- Animated entry with staggered delays

**Albums Tab:**
- GridView (2 columns) of album cards
- Album artwork, name, artist
- Tap to view album songs in bottom sheet

**Artists Tab:**
- ListView of artist tiles with avatar, name, album/song counts
- Tap to view artist songs in bottom sheet
- More menu for Play All / Shuffle

**Folders Tab (NEW):**
- ListView of folders containing music
- Folder thumbnail shows album art from first song
- Folder name and song count displayed
- More menu for Play All, Shuffle, Add to Queue

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
- More menu for song options (including Add to Playlist)

### Playlists Screen (`playlists_screen.dart`)

**Layout:**
- SliverAppBar with + button for creating playlists
- Smart Playlists grid (2x2): Recently Played, Most Played, Favorites, Recently Added
- User Playlists list

**Features:**
- Create playlist dialog with name input
- Smart playlist cards with colored icons
- Playlist tiles with play and more buttons
- Playlist detail view with song list
- Add to Playlist dialog accessible from song options

### Now Playing Screen (`now_playing_screen.dart`) - UPDATED

**Layout:**
- Header with back button and "NOW PLAYING" label, more options menu
- Rotating album art in circular container with gradient glow
- Song title and artist with favorite button
- Progress bar with drag support and time labels
- Main controls: Shuffle, Previous, Play/Pause, Next, Repeat
- Extra controls: Devices (NEW), Queue, Equalizer (NEW), Share (NEW)

**Features:**
- Album art rotates while playing
- Swipe gestures on album art (left=next, right=previous)
- Animated entry for all elements
- Real-time progress tracking
- Queue management via bottom sheet
- Song options: Add to Playlist, Add to Favorites, Song Info, Sleep Timer
- **NEW**: Audio output device selection
- **NEW**: Share via system share sheet

### Equalizer Screen (`equalizer_screen.dart`) - UPDATED

**Layout:**
- Header with back button and title
- Enable/disable toggle
- Preset selector (horizontal scrolling chips)
- 5-band equalizer sliders
- Bass Boost, Virtualizer, Loudness Enhancer controls
- Reset to Defaults button

**Features:**
- Enable/disable equalizer globally
- 12 preset options
- Manual band adjustment
- Real-time audio processing
- Settings persist across sessions

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
- Equalizer access from Playback section

---

## State Management

musiq uses **Riverpod** for state management with 16+ providers:

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
| `foldersProvider` | `Provider` | `List<FolderModel>` | **NEW** All music folders |
| `searchQueryProvider` | `StateProvider` | `String` | Current search query |
| `filteredSongsProvider` | `Provider` | `AsyncValue<List<SongModel>>` | Filtered search results |
| `userPlaylistsProvider` | `StateProvider` | `List<PlaylistEntry>` | User playlists |

### Equalizer Providers (`equalizer_provider.dart`)

| Provider | Type | Returns | Description |
|----------|------|---------|-------------|
| `equalizerServiceProvider` | `Provider` | `EqualizerService` | Equalizer service singleton |
| `equalizerEnabledProvider` | `StreamProvider` | `bool` | Equalizer enabled state |
| `currentPresetProvider` | `StreamProvider` | `String` | Current preset name |
| `bandValuesProvider` | `StreamProvider` | `List<double>` | Band values |
| `bassBoostProvider` | `StreamProvider` | `double` | Bass boost level |
| `virtualizerProvider` | `StreamProvider` | `double` | Virtualizer level |
| `loudnessEnhancerProvider` | `StreamProvider` | `double` | Loudness enhancer level |
| `availablePresetsProvider` | `Provider` | `List<String>` | Available presets |

---

## Audio Engine

The `AudioEngineService` is a singleton wrapping `just_audio` for all playback. Android audio effects (`AndroidEqualizer`, `AndroidLoudnessEnhancer`) are created at service instantiation and attached to the `AudioPlayer` via `AudioPipeline`:

```dart
class AudioEngineService extends BaseAudioHandler {
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
  void setSleepTimer(Duration duration);
  void cancelSleepTimer();
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
| `sleepTimerStream` | `Duration?` | Sleep timer remaining |

### Audio Output Service (NEW)

The `AudioOutputService` manages audio output device selection:

```dart
class AudioOutputService {
  static final AudioOutputService _instance = AudioOutputService._internal();
  factory AudioOutputService() => _instance;

  // Methods
  Future<void> init();
  Future<List<OutputDevice>> getOutputDevices();
  Future<bool> setOutputDevice(OutputDevice device);
  
  // Streams
  Stream<OutputDevice> get currentDeviceStream;
  Stream<List<OutputDevice>> get availableDevicesStream;
  
  // Current device
  OutputDevice get currentDevice;
  
  // Icon helper
  IconData getDeviceIcon(OutputDevice device);
}

enum OutputDeviceType {
  speaker,
  wiredHeadphones,
  bluetooth,
  unknown,
}

class OutputDevice {
  final String id;
  final String name;
  final OutputDeviceType type;
  final bool isConnected;
}
```

Communication with native Android code is done via MethodChannel (`com.musiq.audio/output`).

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
  final List<String> songIds;  // Song IDs in playlist
  final int createdAt;          // Unix timestamp
  final int updatedAt;          // Unix timestamp
  final String? description;    // Optional description
  final bool isSmartPlaylist;   // Auto-generated playlist
}
```

### FolderModel (NEW)

```dart
class FolderModel extends Equatable {
  final String path;           // Absolute folder path
  final String name;          // Last segment of path
  final List<String> songIds; // IDs of songs in folder
  final int songCount;        // Number of songs
  final String? coverArtId;   // First song's album art for thumbnail
}
```

### PlaylistEntry (Runtime)

```dart
class PlaylistEntry {
  final String id;
  final String name;
  final List<String> songIds;

  PlaylistEntry copyWith({String? name, List<String>? songIds});
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
- Go to Settings > Apps > musiq > Permissions and enable Storage/Audio
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

### Equalizer Not Working

- Some Android devices or audio output paths (e.g., Bluetooth) may not support equalizer
- The app will show a snackbar if equalizer is not supported
- Try switching to a different audio output device

### Audio Output Device Not Changing

- Ensure the device is connected (for Bluetooth/headphones)
- Some devices may not support audio routing
- Try disconnecting and reconnecting the device

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

1. Go to Settings > Apps > musiq > Permissions
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

### v1.2.0 (Premium Pack)

#### Feature 1: Dynamic Background Image System
- **NEW** Created `BackgroundSettings` model with background mode options
- **NEW** Created `backgroundSettingsProvider` for persistence
- **NEW** Created `AnimatedBackground` widget with parallax, blur, overlay effects
- **NEW** Custom image support with gallery picker
- **NEW** Album art sync mode - background changes with current song
- **NEW** Blurred album art mode with heavy blur + dark overlay
- **NEW** Parallax scrolling effect (30% scroll speed)
- **NEW** Creative bonus: Particle effect using `sensors_plus`
- **NEW** Creative bonus: Color extraction using `palette_generator`
- **NEW** Creative bonus: Time-based background (morning/afternoon/evening/night)
- **NEW** Settings → Appearance → Background Image section

#### Feature 2: Integrated Lyrics Viewer
- **NEW** Created `LyricsModel` and `LyricLine` models
- **NEW** Created `LyricsService` with LRCLIB and OVH API support
- **NEW** Created `LyricsViewer` widget with synchronized lyrics
- **NEW** LRC format parsing with timestamp alignment
- **NEW** Plain lyrics display
- **NEW** User-contributed lyrics (manual input)
- **NEW** Auto-scroll toggle
- **NEW** Lyrics tab in Now Playing screen
- **NEW** Settings: Lyrics Source (Online/Offline/User Only)

#### Feature 3: Smart Playlists
- **NEW** Created `SmartRule` and `SmartPlaylistRule` models
- **NEW** Created `SmartPlaylistEngine` service
- **NEW** Rule-based playlist filtering (genre, artist, play count, year, etc.)
- **NEW** Multiple operators (equals, contains, greaterThan, etc.)
- **NEW** AND/OR logic for combining rules
- **NEW** Wizard-like UI for creating smart playlists
- **NEW** Live preview of matching song count
- **NEW** Auto-refresh on library changes
- **NEW** "Convert to Normal Playlist" option
- **NEW** Special icon for smart playlists

#### Feature 4: Tag Editor
- **NEW** Created `TagEditorService` for metadata editing
- **NEW** Created `TagEditorScreen` UI
- **NEW** Edit title, artist, album, genre, year, track number
- **NEW** Change album art via image picker
- **NEW** Song options menu integration
- **NEW** Permission handling for Android 11+

#### Feature 5: Android Auto Support
- **NEW** Audio service configured for Android Auto
- **NEW** MediaSession integration via `audio_service`
- **NEW** Car mode settings placeholder
- **NEW** AndroidManifest configuration for car intent filters

#### Feature 6: Backup & Restore
- **NEW** Created `BackupService` for data export/import
- **NEW** Export all data to JSON (favorites, playlists, recent, most played, lyrics, settings)
- **NEW** Import from backup file
- **NEW** Settings → Storage → Backup Now / Restore from Backup
- **NEW** Shows last backup timestamp
- **NEW** Warning before restore

#### Infrastructure Updates
- **NEW** Hive adapters: BackgroundSettings, LyricsModel, LyricLine, SmartRule, SmartPlaylistRule
- **NEW** New SharedPreferences keys: lyricsModeKey, lyricsAutoScrollKey, carModeKey, lastBackupKey
- **NEW** New Hive boxes: background, lyrics
- **NEW** Route for tag editor screen

### v1.1.0 (New Features)

#### Feature 1: Folders Tab
- **NEW** Implemented full folder browsing in Library
- Created `FolderModel` for folder data
- Added folder discovery in `MusicQueryService`
- System folders automatically ignored
- Album art thumbnails for folders
- Folder options: Play All, Shuffle, Add to Queue

#### Feature 2: Add to Playlist
- **NEW** Added "Add to Playlist" option in song options
- Created `AddToPlaylistDialog` widget
- Multi-select playlist support
- Create new playlist from dialog
- Prevents duplicate entries

#### Feature 3: Equalizer Integration
- **NEW** Full equalizer functionality now available
- Accessible from Settings and Now Playing
- 12 presets with customizable bands
- Bass Boost, Virtualizer, Loudness Enhancer
- Settings persist across app restarts

#### Feature 4: Audio Output Device Selection
- **NEW** Created `AudioOutputService`
- Added native Android MethodChannel in `MainActivity.kt`
- Switch between Speaker, Wired Headphones, Bluetooth
- Available from Now Playing screen

#### Feature 5: Share Song
- **NEW** Added share functionality using `share_plus`
- Share song title, artist, album via system share sheet
- Available from Now Playing screen

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
- [share_plus](https://pub.dev/packages/share_plus) - System share sheet
- [image_picker](https://pub.dev/packages/image_picker) - Image selection
- [palette_generator](https://pub.dev/packages/palette_generator) - Color extraction
- [http](https://pub.dev/packages/http) - Network requests for lyrics
- [file_picker](https://pub.dev/packages/file_picker) - File selection for backup
- [sensors_plus](https://pub.dev/packages/sensors_plus) - Device sensors for particles
- Spotify - Design inspiration

---

**musiq** - Your premium music experience
