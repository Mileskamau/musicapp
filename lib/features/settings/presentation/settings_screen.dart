import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/music_provider.dart';
import '../../../core/services/audio_engine.dart';
import '../../../core/services/music_query_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _animationsEnabled = AppConstants.defaultAnimations;
  bool _crossfadeEnabled = false;
  bool _gaplessEnabled = AppConstants.defaultGapless;
  bool _replayGainEnabled = AppConstants.defaultReplayGain;
  String _audioQuality = AppConstants.qualityHigh;
  String _defaultScreen = 'home';
  bool _glassmorphismEnabled = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _animationsEnabled = prefs.getBool(AppConstants.animationsKey) ?? AppConstants.defaultAnimations;
      _crossfadeEnabled = prefs.getBool(AppConstants.crossfadeKey) ?? false;
      _gaplessEnabled = prefs.getBool(AppConstants.gaplessKey) ?? AppConstants.defaultGapless;
      _replayGainEnabled = prefs.getBool(AppConstants.replayGainKey) ?? AppConstants.defaultReplayGain;
      _audioQuality = prefs.getString(AppConstants.audioQualityKey) ?? AppConstants.qualityHigh;
      _defaultScreen = prefs.getString(AppConstants.defaultScreenKey) ?? 'home';
      _glassmorphismEnabled = prefs.getBool(AppConstants.glassmorphismKey) ?? false;
      _loaded = true;
    });
    
    // Also update the provider
    ref.read(glassmorphismProvider.notifier).state = _glassmorphismEnabled;
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Settings',
                style: AppTheme.headlineMedium.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ).animate().fadeIn(duration: AppConstants.normalAnimation),
              titlePadding: const EdgeInsets.only(
                left: AppConstants.spacingL,
                bottom: AppConstants.spacingM,
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Appearance
                  _buildSectionTitle('Appearance'),
                  const SizedBox(height: AppConstants.spacingM),
                  _buildAppearanceSettings(),

                  const SizedBox(height: AppConstants.spacingXL),

                  // Audio
                  _buildSectionTitle('Audio'),
                  const SizedBox(height: AppConstants.spacingM),
                  _buildAudioSettings(),

                  const SizedBox(height: AppConstants.spacingXL),

                  // Playback
                  _buildSectionTitle('Playback'),
                  const SizedBox(height: AppConstants.spacingM),
                  _buildPlaybackSettings(),

                  const SizedBox(height: AppConstants.spacingXL),

                  // Storage
                  _buildSectionTitle('Storage'),
                  const SizedBox(height: AppConstants.spacingM),
                  _buildStorageSettings(),

                  const SizedBox(height: AppConstants.spacingXL),

                  // About
                  _buildSectionTitle('About'),
                  const SizedBox(height: AppConstants.spacingM),
                  _buildAboutSettings(),

                  const SizedBox(height: AppConstants.spacingXXL),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTheme.headlineSmall,
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildAppearanceSettings() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            'Enable Animations',
            'Smooth transitions and micro-interactions',
            Icons.animation_rounded,
            _animationsEnabled,
            (value) {
              setState(() => _animationsEnabled = value);
              _saveBool(AppConstants.animationsKey, value);
            },
          ),
          _buildDivider(),
          _buildListTile(
            'Accent Color',
            'Customize app accent color',
            Icons.palette_rounded,
            onTap: () {
              _showAccentColorPicker();
            },
          ),
          _buildDivider(),
          _buildListTile(
            'Default Screen',
            'Choose startup screen',
            Icons.home_rounded,
            trailing: Text(
              _defaultScreen.capitalize(),
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.primaryColor,
              ),
            ),
            onTap: () {
              _showDefaultScreenPicker();
            },
          ),
          _buildDivider(),
          _buildSwitchTile(
            'Glassmorphism Theme',
            'Enable translucent, frosted-glass surfaces',
            Icons.blur_on_rounded,
            _glassmorphismEnabled,
            (value) {
              setState(() => _glassmorphismEnabled = value);
              _saveBool(AppConstants.glassmorphismKey, value);
              // Also update the provider for real-time theme switching
              ref.read(glassmorphismProvider.notifier).state = value;
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildAudioSettings() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Column(
        children: [
          _buildListTile(
            'Audio Quality',
            'Streaming and download quality',
            Icons.high_quality_rounded,
            trailing: Text(
              _audioQuality.capitalize(),
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.primaryColor,
              ),
            ),
            onTap: () {
              _showAudioQualityPicker();
            },
          ),
          _buildDivider(),
          _buildSwitchTile(
            'Replay Gain',
            'Normalize volume across tracks',
            Icons.volume_up_rounded,
            _replayGainEnabled,
            (value) {
              setState(() => _replayGainEnabled = value);
              _saveBool(AppConstants.replayGainKey, value);
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildPlaybackSettings() {
    final audioService = AudioEngineService();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            'Crossfade',
            'Smooth transition between tracks',
            Icons.blur_on_rounded,
            _crossfadeEnabled,
            (value) {
              setState(() => _crossfadeEnabled = value);
              _saveBool(AppConstants.crossfadeKey, value);
            },
          ),
          _buildDivider(),
          _buildSwitchTile(
            'Gapless Playback',
            'No silence between tracks',
            Icons.airline_stops_rounded,
            _gaplessEnabled,
            (value) {
              setState(() => _gaplessEnabled = value);
              _saveBool(AppConstants.gaplessKey, value);
            },
          ),
          _buildDivider(),
          _buildListTile(
            'Equalizer',
            'Adjust audio frequencies',
            Icons.equalizer_rounded,
            onTap: () {
              Navigator.pushNamed(context, '/equalizer');
            },
          ),
          _buildDivider(),
          _buildSleepTimerTile(audioService),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildSleepTimerTile(AudioEngineService audioService) {
    final sleepRemaining = audioService.sleepTimerRemaining;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingL,
        vertical: AppConstants.spacingS,
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Icon(
          sleepRemaining != null ? Icons.timer_rounded : Icons.bedtime_rounded,
          color: AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        'Sleep Timer',
        style: AppTheme.titleMedium,
      ),
      subtitle: Text(
        sleepRemaining != null
            ? 'Remaining: ${sleepRemaining.inMinutes}m ${sleepRemaining.inSeconds % 60}s'
            : 'Stop playback after time',
        style: AppTheme.bodySmall.copyWith(
          color: sleepRemaining != null ? AppTheme.warningColor : null,
        ),
      ),
      trailing: sleepRemaining != null
          ? IconButton(
              icon: const Icon(Icons.close_rounded, color: AppTheme.errorColor),
              onPressed: () {
                audioService.cancelSleepTimer();
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sleep timer cancelled')),
                );
              },
            )
          : const Icon(Icons.chevron_right_rounded),
      onTap: () {
        _showSleepTimerDialog(audioService);
      },
    );
  }

  Widget _buildStorageSettings() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Column(
        children: [
          _buildListTile(
            'Rescan Library',
            'Clear cache and rescan for music files',
            Icons.refresh_rounded,
            onTap: () {
              _showRescanDialog();
            },
          ),
          _buildDivider(),
          _buildListTile(
            'Clear Cache',
            'Free up storage space',
            Icons.cleaning_services_rounded,
            onTap: () {
              _showClearCacheDialog();
            },
          ),
          _buildDivider(),
          _buildListTile(
            'Storage Location',
            'Choose download location',
            Icons.folder_rounded,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Storage Location'),
                  content: const Text('Music is loaded from your device\'s external storage. No custom location needed.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1);
  }

  Widget _buildAboutSettings() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Column(
        children: [
          _buildListTile(
            'Version',
            AppConstants.appVersion,
            Icons.info_rounded,
          ),
          _buildDivider(),
          _buildListTile(
            'Licenses',
            'Open source licenses',
            Icons.description_rounded,
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: AppConstants.appName,
                applicationVersion: AppConstants.appVersion,
              );
            },
          ),
          _buildDivider(),
          _buildListTile(
            'Privacy Policy',
            'Read our privacy policy',
            Icons.privacy_tip_rounded,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Privacy Policy'),
                  content: const SingleChildScrollView(
                    child: Text(
                      'MusicPly Privacy Policy\n\n'
                      'Last updated: 2024\n\n'
                      '1. Data Collection\n'
                      'MusicPly only accesses music files stored on your device. '
                      'We do not collect, store, or transmit any personal data.\n\n'
                      '2. Permissions\n'
                      'The app requires storage/audio permissions to display your music library. '
                      'No other permissions are requested.\n\n'
                      '3. Third Parties\n'
                      'This app does not share data with any third parties.\n\n'
                      '4. Contact\n'
                      'For questions, contact us at support@musicply.app',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1);
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingL,
        vertical: AppConstants.spacingS,
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: AppTheme.titleMedium,
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.bodySmall,
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildListTile(
    String title,
    String subtitle,
    IconData icon, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingL,
        vertical: AppConstants.spacingS,
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: AppTheme.titleMedium,
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.bodySmall,
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: AppConstants.spacingL + 56,
      endIndent: AppConstants.spacingL,
    );
  }

  void _showAccentColorPicker() {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.accentColor,
      AppTheme.errorColor,
      AppTheme.warningColor,
      AppTheme.successColor,
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Accent Color'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: colors.map((color) {
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showDefaultScreenPicker() {
    final screens = ['home', 'library', 'search', 'playlists'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Default Screen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: screens.map((screen) {
              return RadioListTile<String>(
                title: Text(screen.capitalize()),
                value: screen,
                groupValue: _defaultScreen,
                onChanged: (value) {
                  setState(() {
                    _defaultScreen = value!;
                  });
                  _saveString(AppConstants.defaultScreenKey, value!);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showAudioQualityPicker() {
    final qualities = [
      AppConstants.qualityLow,
      AppConstants.qualityMedium,
      AppConstants.qualityHigh,
      AppConstants.qualityUltra,
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Audio Quality'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: qualities.map((quality) {
              return RadioListTile<String>(
                title: Text(quality.capitalize()),
                value: quality,
                groupValue: _audioQuality,
                onChanged: (value) {
                  setState(() {
                    _audioQuality = value!;
                  });
                  _saveString(AppConstants.audioQualityKey, value!);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showSleepTimerDialog(AudioEngineService audioService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Text('Sleep Timer', style: AppTheme.headlineSmall),
            ),
            if (audioService.sleepTimerRemaining != null) ...[
              ListTile(
                leading: const Icon(Icons.timer_rounded, color: AppTheme.warningColor),
                title: Text(
                  'Remaining: ${audioService.sleepTimerRemaining!.inMinutes}m ${audioService.sleepTimerRemaining!.inSeconds % 60}s',
                  style: const TextStyle(color: AppTheme.warningColor),
                ),
                onTap: () {
                  audioService.cancelSleepTimer();
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sleep timer cancelled')),
                  );
                },
              ),
              const Divider(height: 1),
            ],
            ...AppConstants.sleepTimerOptions.map((minutes) => ListTile(
              title: Text('$minutes minutes'),
              onTap: () {
                audioService.setSleepTimer(Duration(minutes: minutes));
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sleep timer set: $minutes minutes')),
                );
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showRescanDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rescan Library'),
        content: const Text(
          'This will clear the cached library and scan your device for music files again. '
          'This may take a moment for large libraries.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Rescanning library...'),
                    duration: Duration(seconds: 10),
                  ),
                );
              }
              await MusicQueryService().rescanSongs();
              ref.invalidate(allSongsProvider);
              ref.invalidate(albumsProvider);
              ref.invalidate(artistsProvider);
              if (mounted) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Library rescanned successfully')),
                );
              }
            },
            child: const Text('Rescan'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear all cached data. Continue?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
