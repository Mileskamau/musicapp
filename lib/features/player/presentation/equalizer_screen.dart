import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/equalizer_provider.dart';
import '../../../core/services/equalizer_service.dart';

class EqualizerScreen extends ConsumerStatefulWidget {
  const EqualizerScreen({super.key});

  @override
  ConsumerState<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends ConsumerState<EqualizerScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: AppConstants.normalAnimation,
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eqService = ref.watch(equalizerServiceProvider);
    final isSupportedAsync = ref.watch(equalizerSupportedProvider);
    final isSupported = isSupportedAsync.valueOrNull ?? false;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              AppTheme.backgroundColor,
              AppTheme.backgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingL,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Show iOS warning
                      if (Platform.isIOS)
                        _buildIOSWarning(),
                      // Show Android-specific warning if not supported
                      if (!Platform.isIOS && !isSupported)
                        _buildUnsupportedWarning(),
                      _buildEnableToggle(eqService),
                      const SizedBox(height: AppConstants.spacingXL),
                      _buildPresetSelector(eqService),
                      const SizedBox(height: AppConstants.spacingXL),
                      _buildBandSliders(eqService),
                      const SizedBox(height: AppConstants.spacingXL),
                      _buildLoudnessEnhancer(eqService),
                      const SizedBox(height: AppConstants.spacingXL),
                      _buildResetButton(eqService),
                      const SizedBox(height: AppConstants.spacingXXL),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIOSWarning() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: AppTheme.warningColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppTheme.warningColor,
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Text(
              'Equalizer is not supported on iOS.',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.warningColor),
            ),
          ),
        ],
      ),
    ).animate(controller: _slideController).fadeIn().slideY(begin: -0.1);
  }

  Widget _buildUnsupportedWarning() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: AppTheme.warningColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppTheme.warningColor,
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Text(
              'Equalizer is not supported with the current audio output (Bluetooth).',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.warningColor),
            ),
          ),
        ],
      ),
    ).animate(controller: _slideController).fadeIn().slideY(begin: -0.1);
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ).animate(controller: _slideController).fadeIn().slideX(begin: -0.1),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Equalizer',
                  style: AppTheme.headlineMedium,
                ).animate(controller: _slideController).fadeIn(delay: 100.ms),
                const SizedBox(height: 4),
                Text(
                  'Customize your audio experience',
                  style: AppTheme.bodySmall,
                ).animate(controller: _slideController).fadeIn(delay: 200.ms),
              ],
            ),
          ),
          const Icon(
            Icons.equalizer_rounded,
            color: AppTheme.primaryColor,
            size: 32,
          ).animate(controller: _slideController).fadeIn(delay: 300.ms).scale(),
        ],
      ),
    );
  }

  Widget _buildEnableToggle(EqualizerService eqService) {
    return StreamBuilder<bool>(
      stream: eqService.enabledStream,
      initialData: eqService.isEnabled,
      builder: (context, snapshot) {
        final isEnabled = snapshot.data ?? false;

        return Container(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            border: Border.all(
              color: isEnabled
                  ? AppTheme.primaryColor.withOpacity(0.5)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isEnabled
                      ? AppTheme.primaryColor.withOpacity(0.2)
                      : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: Icon(
                  isEnabled ? Icons.graphic_eq_rounded : Icons.equalizer_rounded,
                  color: isEnabled ? AppTheme.primaryColor : AppTheme.textTertiary,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Equalizer',
                      style: AppTheme.titleMedium,
                    ),
                    Text(
                      isEnabled ? 'Enabled' : 'Disabled',
                      style: AppTheme.bodySmall.copyWith(
                        color: isEnabled ? AppTheme.primaryColor : AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: (value) => eqService.setEnabled(value),
                activeThumbColor: AppTheme.primaryColor,
              ),
            ],
          ),
        ).animate(controller: _slideController).fadeIn(delay: 400.ms).slideY(begin: 0.1);
      },
    );
  }

  Widget _buildPresetSelector(EqualizerService eqService) {
    return StreamBuilder<String>(
      stream: eqService.presetStream,
      initialData: eqService.currentPreset,
      builder: (context, snapshot) {
        final currentPreset = snapshot.data ?? 'Normal';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Presets',
              style: AppTheme.headlineSmall,
            ).animate(controller: _slideController).fadeIn(delay: 500.ms),
            const SizedBox(height: AppConstants.spacingM),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: eqService.availablePresets.length,
                itemBuilder: (context, index) {
                  final preset = eqService.availablePresets[index];
                  final isSelected = preset == currentPreset;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        preset,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryColor,
                      backgroundColor: AppTheme.surfaceColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onSelected: (_) => eqService.setPreset(preset),
                    ),
                  );
                },
              ),
            ),
          ],
        ).animate(controller: _slideController).fadeIn(delay: 500.ms).slideY(begin: 0.1);
      },
    );
  }

  Widget _buildBandSliders(EqualizerService eqService) {
    return StreamBuilder<List<double>>(
      stream: eqService.bandValuesStream,
      initialData: eqService.bandValues,
      builder: (context, snapshot) {
        final bandValues = snapshot.data ?? [0.0, 0.0, 0.0, 0.0, 0.0];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Frequency Bands',
                  style: AppTheme.headlineSmall,
                ),
                StreamBuilder<bool>(
                  stream: eqService.enabledStream,
                  initialData: eqService.isEnabled,
                  builder: (context, enabledSnap) {
                    final isEnabled = enabledSnap.data ?? false;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? AppTheme.primaryColor.withOpacity(0.1)
                            : AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isEnabled ? 'ACTIVE' : 'OFF',
                        style: AppTheme.labelSmall.copyWith(
                          color: isEnabled ? AppTheme.primaryColor : AppTheme.errorColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ).animate(controller: _slideController).fadeIn(delay: 600.ms),
            const SizedBox(height: AppConstants.spacingL),
            Container(
              height: 280,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingS,
                vertical: AppConstants.spacingM,
              ),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(AppConstants.equalizerBandCount, (index) {
                  final value = bandValues[index];
                  return _buildBandSlider(
                    index: index,
                    value: value,
                    label: AppConstants.equalizerBandLabels[index],
                    onChanged: (v) => eqService.setBandValue(index, v),
                    isEnabled: eqService.isEnabled,
                  );
                }),
              ),
            ).animate(controller: _slideController).fadeIn(delay: 700.ms).scale(
                  begin: const Offset(0.95, 0.95),
                ),
          ],
        );
      },
    );
  }

  Widget _buildBandSlider({
    required int index,
    required double value,
    required String label,
    required ValueChanged<double> onChanged,
    required bool isEnabled,
  }) {
    final normalizedValue = ((value + 12) / 24).clamp(0.0, 1.0);

    return Expanded(
      child: Column(
        children: [
          Text(
            '${value.toStringAsFixed(0)} dB',
            style: AppTheme.labelSmall.copyWith(
              color: isEnabled
                  ? AppTheme.primaryColor
                  : AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  activeTrackColor: isEnabled
                      ? AppTheme.primaryColor
                      : AppTheme.textTertiary,
                  inactiveTrackColor: AppTheme.surfaceColor,
                  thumbColor: isEnabled
                      ? AppTheme.primaryColor
                      : AppTheme.textTertiary,
                  overlayColor: AppTheme.primaryColor.withOpacity(0.2),
                ),
                child: Slider(
                  value: normalizedValue,
                  onChanged: isEnabled
                      ? (v) {
                          final db = v * 24 - 12; // Convert 0-1 to -12 to +12 dB
                          onChanged(db);
                        }
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildBassBoost(EqualizerService eqService) {
    return StreamBuilder<double>(
      stream: eqService.bassBoostStream,
      initialData: eqService.bassBoost,
      builder: (context, snapshot) {
        final value = snapshot.data ?? 0.0;
        final normalizedValue = value / AppConstants.bassBoostMax;

        return Container(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.surround_sound_rounded,
                    color: AppTheme.accentColor,
                    size: 20,
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  Text('Bass Boost', style: AppTheme.titleSmall),
                  const Spacer(),
                  Text(
                    '${(normalizedValue * 100).toStringAsFixed(0)}%',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.accentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingS),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: AppTheme.accentColor,
                  inactiveTrackColor: AppTheme.surfaceColor,
                  thumbColor: AppTheme.accentColor,
                  overlayColor: AppTheme.accentColor.withOpacity(0.2),
                ),
                child: Slider(
                  value: normalizedValue,
                  onChanged: eqService.isEnabled
                      ? (v) => eqService.setBassBoost(v * AppConstants.bassBoostMax)
                      : null,
                ),
              ),
            ],
          ),
        ).animate(controller: _slideController).fadeIn(delay: 800.ms).slideY(begin: 0.1);
      },
    );
  }

  Widget _buildVirtualizer(EqualizerService eqService) {
    return StreamBuilder<double>(
      stream: eqService.virtualizerStream,
      initialData: eqService.virtualizer,
      builder: (context, snapshot) {
        final value = snapshot.data ?? 0.0;
        final normalizedValue = value / AppConstants.virtualizerMax;

        return Container(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.speaker_rounded,
                    color: AppTheme.warningColor,
                    size: 20,
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  Text('Virtualizer', style: AppTheme.titleSmall),
                  const Spacer(),
                  Text(
                    '${(normalizedValue * 100).toStringAsFixed(0)}%',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.warningColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingS),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: AppTheme.warningColor,
                  inactiveTrackColor: AppTheme.surfaceColor,
                  thumbColor: AppTheme.warningColor,
                  overlayColor: AppTheme.warningColor.withOpacity(0.2),
                ),
                child: Slider(
                  value: normalizedValue,
                  onChanged: eqService.isEnabled
                      ? (v) => eqService.setVirtualizer(v * AppConstants.virtualizerMax)
                      : null,
                ),
              ),
            ],
          ),
        ).animate(controller: _slideController).fadeIn(delay: 900.ms).slideY(begin: 0.1);
      },
    );
  }

  Widget _buildLoudnessEnhancer(EqualizerService eqService) {
    return StreamBuilder<double>(
      stream: eqService.loudnessStream,
      initialData: eqService.loudnessEnhancer,
      builder: (context, snapshot) {
        final value = snapshot.data ?? 0.0;
        final range = AppConstants.loudnessEnhancerMax - AppConstants.loudnessEnhancerMin;
        final normalizedValue =
            ((value - AppConstants.loudnessEnhancerMin) / range).clamp(0.0, 1.0);

        return Container(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.volume_up_rounded,
                    color: AppTheme.successColor,
                    size: 20,
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  Text('Loudness Enhancer', style: AppTheme.titleSmall),
                  const Spacer(),
                  Text(
                    '${(value / 100).toStringAsFixed(0)} dB',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.successColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingS),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: AppTheme.successColor,
                  inactiveTrackColor: AppTheme.surfaceColor,
                  thumbColor: AppTheme.successColor,
                  overlayColor: AppTheme.successColor.withOpacity(0.2),
                ),
                child: Slider(
                  value: normalizedValue,
                  onChanged: eqService.isEnabled
                      ? (v) {
                          final db =
                              v * range + AppConstants.loudnessEnhancerMin;
                          eqService.setLoudnessEnhancer(db);
                        }
                      : null,
                ),
              ),
            ],
          ),
        ).animate(controller: _slideController).fadeIn(delay: 1000.ms).slideY(begin: 0.1);
      },
    );
  }

  Widget _buildResetButton(EqualizerService eqService) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          await eqService.reset();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Equalizer reset to defaults'),
                backgroundColor: AppTheme.cardColor,
              ),
            );
          }
        },
        icon: const Icon(Icons.restart_alt_rounded),
        label: const Text('Reset to Defaults'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.errorColor,
          side: BorderSide(color: AppTheme.errorColor.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
        ),
      ),
    ).animate(controller: _slideController).fadeIn(delay: 1100.ms).slideY(begin: 0.1);
  }
}
