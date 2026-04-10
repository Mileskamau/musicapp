import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';
import '../models/background_settings.dart';
import '../providers/background_provider.dart';
import '../providers/audio_provider.dart';
import '../theme/app_theme.dart';

class AnimatedBackground extends ConsumerStatefulWidget {
  final Widget child;
  final double scrollOffset;

  const AnimatedBackground({
    super.key,
    required this.child,
    this.scrollOffset = 0,
  });

  @override
  ConsumerState<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends ConsumerState<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _transitionController;
  late AnimationController _particleController;
  String? _previousImagePath;
  String? _currentImagePath;
  PaletteGenerator? _paletteGenerator;
  Color _dominantColor = AppTheme.primaryColor;
  StreamSubscription? _songSubscription;

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _songSubscription = ref.read(audioServiceProvider).currentIndexStream.listen((_) {
      final settings = ref.read(backgroundSettingsProvider);
      if (settings.mode == BackgroundMode.albumArt || 
          settings.mode == BackgroundMode.blurredAlbumArt) {
        _updateAlbumArt();
      }
    });
  }

  @override
  void dispose() {
    _transitionController.dispose();
    _particleController.dispose();
    _songSubscription?.cancel();
    super.dispose();
  }

  Future<void> _updateAlbumArt() async {
    final currentSong = ref.read(currentSongProvider);
    if (currentSong?.albumArt != null && mounted) {
      await _extractColors(currentSong!.albumArt!);
    }
  }

  Future<void> _extractColors(String? imagePath) async {
    if (imagePath == null) return;
    try {
      final imageProvider = FileImage(File(imagePath));
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 16,
      );
      if (mounted) {
        setState(() {
          _paletteGenerator = paletteGenerator;
          _dominantColor = paletteGenerator.dominantColor?.color ?? AppTheme.primaryColor;
        });
      }
    } catch (e) {
      // Color extraction failed
    }
  }

  String? _getCurrentBackgroundImage(BackgroundSettings settings, String? currentAlbumArt) {
    String? imagePath;

    switch (settings.mode) {
      case BackgroundMode.none:
        return null;
      case BackgroundMode.custom:
        imagePath = settings.customImagePath;
        break;
      case BackgroundMode.albumArt:
        imagePath = currentAlbumArt;
        break;
      case BackgroundMode.blurredAlbumArt:
        imagePath = currentAlbumArt;
        break;
    }

    if (imagePath != null && imagePath != _currentImagePath) {
      _previousImagePath = _currentImagePath;
      _currentImagePath = imagePath;
    }

    return imagePath;
  }

  String? _getTimeBasedImage(BackgroundSettings settings) {
    if (!settings.enableTimeBasedBackground) return null;

    final hour = DateTime.now().hour;
    String? imagePath;

    if (hour >= 5 && hour < 12) {
      imagePath = settings.morningImagePath;
    } else if (hour >= 12 && hour < 17) {
      imagePath = settings.afternoonImagePath;
    } else if (hour >= 17 && hour < 20) {
      imagePath = settings.eveningImagePath;
    } else {
      imagePath = settings.nightImagePath;
    }

    return imagePath;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(backgroundSettingsProvider);
    final currentSong = ref.watch(currentSongProvider);
    final isBlurMode = settings.mode == BackgroundMode.blurredAlbumArt;
    
    String? imagePath;
    
    if (settings.enableTimeBasedBackground) {
      imagePath = _getTimeBasedImage(settings);
    } else {
      imagePath = _getCurrentBackgroundImage(settings, currentSong?.albumArt);
    }

    if (imagePath != null) {
      _extractColors(imagePath);
    }

    return Stack(
      children: [
        // Background layer
        if (settings.mode != BackgroundMode.none && imagePath != null)
          _buildBackgroundImage(settings, imagePath, isBlurMode)
        else
          Container(color: AppTheme.backgroundColor),

        // Particle effect layer
        if (settings.enableParticles && imagePath != null)
          _buildParticleEffect(settings),

        // Overlay layer
        if (settings.mode != BackgroundMode.none && imagePath != null)
          _buildOverlay(settings),

        // Content
        widget.child,
      ],
    );
  }

  Widget _buildBackgroundImage(BackgroundSettings settings, String imagePath, bool isBlurMode) {
    final parallaxOffset = settings.enableParallax ? widget.scrollOffset * 0.3 : 0.0;

    Widget backgroundWidget = Transform.translate(
      offset: Offset(0, -parallaxOffset),
      child: Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(color: AppTheme.backgroundColor);
        },
      ),
    );

    if (isBlurMode || settings.blurIntensity > 0) {
      backgroundWidget = ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: isBlurMode ? settings.blurIntensity : settings.blurIntensity / 2,
            sigmaY: isBlurMode ? settings.blurIntensity : settings.blurIntensity / 2,
          ),
          child: backgroundWidget,
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: backgroundWidget,
    );
  }

  Widget _buildOverlay(BackgroundSettings settings) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Colors.black.withOpacity(settings.darkOverlayOpacity),
        ),
      ),
    );
  }

  Widget _buildParticleEffect(BackgroundSettings settings) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(
            animationValue: _particleController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class ParticlePainter extends CustomPainter {
  final double animationValue;
  final Random _random = Random(42);
  final int particleCount = 30;

  ParticlePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < particleCount; i++) {
      final x = (_random.nextDouble() * size.width + 
                 animationValue * 50 * (i % 2 == 0 ? 1 : -1)) % size.width;
      final y = (_random.nextDouble() * size.height + 
                 animationValue * 30 * (i % 3 == 0 ? 1 : -1)) % size.height;
      final radius = 2.0 + _random.nextDouble() * 3.0;
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}

final extractedColorsProvider = Provider<PaletteGenerator?>((ref) {
  final settings = ref.watch(backgroundSettingsProvider);
  final currentSong = ref.watch(currentSongProvider);
  
  if (!settings.syncWithAlbumColors) return null;
  
  return null;
});

class AlbumColorExtractor extends ConsumerStatefulWidget {
  final Widget child;

  const AlbumColorExtractor({super.key, required this.child});

  @override
  ConsumerState<AlbumColorExtractor> createState() => _AlbumColorExtractorState();
}

class _AlbumColorExtractorState extends ConsumerState<AlbumColorExtractor> {
  PaletteGenerator? _palette;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(backgroundSettingsProvider);
    final currentSong = ref.watch(currentSongProvider);

    if (settings.syncWithAlbumColors && currentSong?.albumArt != null) {
      _extractColors(currentSong!.albumArt!);
    }

    return widget.child;
  }

  Future<void> _extractColors(String imagePath) async {
    try {
      final imageProvider = FileImage(File(imagePath));
      _palette = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 16,
      );
    } catch (e) {
      // Ignore
    }
  }
}