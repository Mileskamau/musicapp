import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:musiq/main.dart';
import 'package:musiq/features/settings/presentation/settings_screen.dart';
import 'package:musiq/features/playlists/presentation/playlists_screen.dart';
import 'package:musiq/features/search/presentation/search_screen.dart';
import 'package:musiq/features/library/presentation/library_screen.dart';

void main() {
  testWidgets('App should render without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MusicPlyApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Bottom navigation should have 5 tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MusicPlyApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Playlists'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Home screen should display greeting', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MusicPlyApp(),
      ),
    );

    await tester.pumpAndSettle();

    final hour = DateTime.now().hour;
    String expectedGreeting;
    if (hour < 12) {
      expectedGreeting = 'Morning';
    } else if (hour < 17) {
      expectedGreeting = 'Afternoon';
    } else {
      expectedGreeting = 'Evening';
    }

    expect(find.textContaining(expectedGreeting), findsOneWidget);
  });

  testWidgets('Settings screen should render', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Audio'), findsOneWidget);
    expect(find.text('Playback'), findsOneWidget);
    expect(find.text('Storage'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
  });

  testWidgets('Settings screen has rescan library option', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Rescan Library'), findsOneWidget);
  });

  testWidgets('Settings screen has equalizer option', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Equalizer'), findsOneWidget);
  });

  testWidgets('Settings screen has sleep timer option', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sleep Timer'), findsOneWidget);
  });

  testWidgets('Playlists screen should render smart playlists', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: PlaylistsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Smart Playlists'), findsOneWidget);
    expect(find.text('Recently Played'), findsOneWidget);
    expect(find.text('Most Played'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Recently Added'), findsOneWidget);
  });

  testWidgets('Search screen should render categories', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SearchScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Pop'), findsOneWidget);
    expect(find.text('Rock'), findsOneWidget);
    expect(find.text('Jazz'), findsOneWidget);
  });

  testWidgets('Library screen should have 4 tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LibraryScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Songs'), findsOneWidget);
    expect(find.text('Albums'), findsOneWidget);
    expect(find.text('Artists'), findsOneWidget);
    expect(find.text('Folders'), findsOneWidget);
  });
}
