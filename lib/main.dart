import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/services/audio_service.dart';
import 'core/providers/music_provider.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/library/presentation/library_screen.dart';
import 'features/search/presentation/search_screen.dart';
import 'features/playlists/presentation/playlists_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/player/presentation/mini_player.dart';
import 'features/player/presentation/now_playing_screen.dart';
import 'features/player/presentation/equalizer_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch any errors during initialization to prevent white screen
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  // Initialize Hive
  try {
    await Hive.initFlutter();
  } catch (e) {
    // Hive init failure is non-fatal, app can still run
  }

  // Initialize audio service for background playback
  // Wrapped in try-catch: if it fails, the app should still launch
  try {
    await AudioEngineService().init();
  } catch (e) {
    // Audio service init can fail if previous instance wasn't properly
    // disposed (e.g., app killed by Android and restarted).
    // The app will still work; audio can be initialized later on demand.
  }

  // Set preferred orientations
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (e) {
    // Non-fatal
  }

  // Set system UI overlay style
  try {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppTheme.surfaceColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  } catch (e) {
    // Non-fatal
  }

  runZonedGuarded(
    () => runApp(const ProviderScope(child: MusicPlyApp())),
    (error, stack) {
      // Log but don't crash the app
    },
  );
}

class MusicPlyApp extends StatelessWidget {
  const MusicPlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
      routes: {
        '/now-playing': (context) => const NowPlayingScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/equalizer': (context) => const EqualizerScreen(),
      },
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Widget> _screens = const [
    HomeScreen(),
    LibraryScreen(),
    SearchScreen(),
    PlaylistsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AppConstants.normalAnimation,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Load persisted favorites (non-fatal if it fails)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          loadPersistedFavorites(ref);
        } catch (e) {
          // Favorites load failure is non-fatal
        }
        try {
          initializeSongTracking(ref);
        } catch (e) {
          // Song tracking init failure is non-fatal
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  /// Jump to a specific tab index (used for cross-tab navigation).
  void jumpToTab(int index) {
    _onTabTapped(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          FadeTransition(
            opacity: _fadeAnimation,
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),

          // Mini player
          Positioned(
            left: 0,
            right: 0,
            bottom: AppConstants.bottomNavHeight,
            child: const MiniPlayer(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingM,
            vertical: AppConstants.spacingS,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.library_music_rounded, 'Library'),
              _buildNavItem(2, Icons.search_rounded, 'Search'),
              _buildNavItem(3, Icons.queue_music_rounded, 'Playlists'),
              _buildNavItem(4, Icons.settings_rounded, 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppConstants.fastAnimation,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: AppConstants.fastAnimation,
              transform: Matrix4.identity()..scale(isSelected ? 1.2 : 1.0),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textTertiary,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: AppConstants.fastAnimation,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textTertiary,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
