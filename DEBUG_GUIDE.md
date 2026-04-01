# MusicPly Debug Guide

## Current Status

The app structure is complete with all screens and components implemented. The errors you're seeing are expected and will be resolved by running the build commands.

## Errors and Solutions

### 1. Missing Dependencies
**Error**: `Target of URI doesn't exist: 'package:flutter_riverpod/flutter_riverpod.dart'`

**Solution**: Run the following command to install all dependencies:
```bash
cd musicply
flutter pub get
```

### 2. Missing Hive Adapters
**Error**: `Target of URI hasn't been generated: 'package:musicply/core/models/song_model.g.dart'`

**Solution**: Run the following command to generate Hive adapters:
```bash
flutter pub run build_runner build
```

This will generate:
- `lib/core/models/song_model.g.dart`
- `lib/core/models/playlist_model.g.dart`

### 3. CardTheme/DialogTheme Type Errors (FIXED)
**Error**: `The argument type 'CardTheme' can't be assigned to the parameter type 'CardThemeData?'`

**Solution**: This has been fixed in the code. The theme now uses `CardThemeData` and `DialogThemeData` instead of `CardTheme` and `DialogTheme`.

## Step-by-Step Setup

### Step 1: Install Dependencies
```bash
cd musicply
flutter pub get
```

### Step 2: Generate Hive Adapters
```bash
flutter pub run build_runner build
```

### Step 3: Run the App
```bash
flutter run
```

### Step 4: Build for Release (Optional)
```bash
flutter build apk --release
```

## Common Issues

### Issue: "flutter command not found"
**Solution**: Make sure Flutter is installed and added to your PATH.
- Download Flutter from: https://flutter.dev/docs/get-started/install
- Add Flutter to your PATH

### Issue: "No connected devices"
**Solution**: Connect an Android device or start an emulator:
```bash
flutter devices
flutter emulators --launch <emulator_name>
```

### Issue: "Gradle build failed"
**Solution**: Clean and rebuild:
```bash
flutter clean
flutter pub get
flutter run
```

### Issue: "Permission denied" on Android
**Solution**: The app requires storage permissions. Make sure to grant them when prompted.

## Testing the App

1. **Install dependencies**: `flutter pub get`
2. **Generate Hive adapters**: `flutter pub run build_runner build`
3. **Run on device**: `flutter run`
4. **Test features**:
   - Navigate between tabs (Home, Library, Search, Playlists, Settings)
   - Tap on songs to open Now Playing screen
   - Use mini player controls
   - Test search functionality
   - Create playlists
   - Adjust settings

## Expected Behavior

After running the app, you should see:
- Modern dark theme with gradients
- Smooth animations between screens
- Bottom navigation with animated icons
- Home screen with quick play and recommendations
- Library with Songs, Albums, Artists, Folders tabs
- Search with categories
- Playlists with smart playlists
- Settings with customization options
- Mini player at bottom
- Full-screen Now Playing screen

## Next Steps After Setup

1. **Add actual audio files**: Place music files on your device
2. **Test audio playback**: The app will scan for audio files
3. **Customize theme**: Adjust colors in Settings
4. **Create playlists**: Add songs to playlists
5. **Test all features**: Explore all screens and functionality

## Support

If you encounter any issues:
1. Check this debug guide
2. Review the README.md
3. Check IMPLEMENTATION_SUMMARY.md for feature details
4. Create an issue in the repository

---

**MusicPly** - Your premium music experience 🎵
