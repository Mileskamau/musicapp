class AppConstants {
  // App Info
  static const String appName = 'MusicPly';
  static const String appVersion = '1.0.0+1';
  
  // Hive Box Names
  static const String favoritesBox = 'favorites';
  static const String playlistsBox = 'playlists';
  static const String settingsBox = 'settings';
  static const String recentBox = 'recent';
  static const String mostPlayedBox = 'most_played';
  static const String favoritesSongIdsBox = 'favorite_song_ids';
  
  // Shared Preferences Keys
  static const String themeKey = 'theme';
  static const String accentColorKey = 'accent_color';
  static const String animationsKey = 'animations';
  static const String defaultScreenKey = 'default_screen';
  static const String audioQualityKey = 'audio_quality';
  static const String crossfadeKey = 'crossfade';
  static const String gaplessKey = 'gapless';
  static const String replayGainKey = 'replay_gain';
  static const String sleepTimerKey = 'sleep_timer';
  static const String playbackSpeedKey = 'playback_speed';
  static const String volumeKey = 'volume';
  static const String shuffleKey = 'shuffle';
  static const String loopModeKey = 'loop_mode';
  static const String equalizerEnabledKey = 'equalizer_enabled';
  static const String equalizerPresetKey = 'equalizer_preset';
  static const String equalizerBandValuesKey = 'equalizer_band_values';
  static const String bassBoostKey = 'bass_boost';
  static const String virtualizerKey = 'virtualizer';
  static const String loudnessEnhancerKey = 'loudness_enhancer';
  
  // Audio Quality Options
  static const String qualityLow = 'low';
  static const String qualityMedium = 'medium';
  static const String qualityHigh = 'high';
  static const String qualityUltra = 'ultra';
  
  // Default Values
  static const bool defaultAnimations = true;
  static const String defaultScreen = 'home';
  static const String defaultAudioQuality = qualityHigh;
  static const double defaultCrossfade = 0.0;
  static const bool defaultGapless = true;
  static const bool defaultReplayGain = false;
  static const double defaultVolume = 1.0;
  static const double defaultPlaybackSpeed = 1.0;
  
  // Pagination
  static const int songPageSize = 100;
  static const int recentPlaylistLimit = 50;
  static const int mostPlayedPlaylistLimit = 50;
  
  // Song playback threshold for counting as "played" (percentage of duration)
  static const double playedThreshold = 0.8;
  
  // Artwork sizes
  static const int artworkCacheWidth = 200;
  static const int artworkCacheHeight = 200;
  static const int artworkCacheWidthLarge = 800;
  static const int artworkCacheHeightLarge = 800;
  
  // Notification channel
  static const String notificationChannelId = 'musicply_playback';
  static const String notificationChannelName = 'Music Playback';
  static const int notificationId = 1;
  
  // Equalizer bands
  static const int equalizerBandCount = 5;
  static const List<String> equalizerBandLabels = ['60Hz', '230Hz', '910Hz', '3.6kHz', '14kHz'];
  static const double equalizerMinLevel = -1500.0; // millibels
  static const double equalizerMaxLevel = 1500.0; // millibels
  static const double bassBoostMin = 0.0;
  static const double bassBoostMax = 1000.0;
  static const double virtualizerMin = 0.0;
  static const double virtualizerMax = 1000.0;
  static const double loudnessEnhancerMin = -3000.0; // millibels
  static const double loudnessEnhancerMax = 3000.0; // millibels
  
  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
  static const Duration verySlowAnimation = Duration(milliseconds: 800);
  
  // Sizes
  static const double miniPlayerHeight = 72.0;
  static const double bottomNavHeight = 60.0;
  static const double albumArtSize = 56.0;
  static const double largeAlbumArtSize = 280.0;
  static const double borderRadius = 12.0;
  static const double largeBorderRadius = 20.0;
  
  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  
  // Equalizer Presets - Normal is flat (all zeros)
  static const Map<String, List<double>> equalizerPresets = {
    'Normal': [0.0, 0.0, 0.0, 0.0, 0.0],
    'Flat': [0.0, 0.0, 0.0, 0.0, 0.0],
    'Bass Boost': [6.0, 4.0, 0.0, 0.0, 0.0],
    'Treble Boost': [0.0, 0.0, 0.0, 4.0, 6.0],
    'Rock': [4.0, 2.0, -1.0, 2.0, 4.0],
    'Pop': [-1.0, 2.0, 4.0, 2.0, -1.0],
    'Jazz': [3.0, 1.0, 0.0, 1.0, 3.0],
    'Classical': [4.0, 2.0, 0.0, 2.0, 4.0],
    'Dance': [5.0, 3.0, 0.0, 2.0, 4.0],
    'Electronic': [5.0, 2.0, 0.0, 3.0, 5.0],
    'Hip Hop': [5.0, 3.0, 0.0, 1.0, 3.0],
    'R&B': [3.0, 2.0, 0.0, 2.0, 3.0],
    'Acoustic': [3.0, 1.0, 0.0, 2.0, 3.0],
  };
  
  // Sleep Timer Options (in minutes)
  static const List<int> sleepTimerOptions = [5, 10, 15, 30, 45, 60, 90, 120];
  
  // Playback Speed Options
  static const List<double> playbackSpeedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
}
