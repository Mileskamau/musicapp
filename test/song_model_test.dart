import 'package:flutter_test/flutter_test.dart';
import 'package:musiq/core/models/song_model.dart';

void main() {
  group('SongModel.fromMap', () {
    test('should parse int values correctly', () {
      final map = {
        '_id': 123,
        'title': 'Test Song',
        'artist': 'Test Artist',
        'album': 'Test Album',
        'album_id': 456,
        '_data': '/path/to/song.mp3',
        'duration': 240000,
        '_size': 5000000,
        'date_added': 1700000000,
        'date_modified': 1700001000,
        'track': 1,
        'year': 2024,
      };

      final song = SongModel.fromMap(map);

      expect(song.id, '123');
      expect(song.title, 'Test Song');
      expect(song.artist, 'Test Artist');
      expect(song.album, 'Test Album');
      expect(song.albumId, '456');
      expect(song.uri, '/path/to/song.mp3');
      expect(song.duration, 240000);
      expect(song.size, 5000000);
      expect(song.dateAdded, 1700000000);
      expect(song.dateModified, 1700001000);
      expect(song.track, 1);
      expect(song.year, 2024);
    });

    test('should parse string values for int fields (type string is not subtype of type int fix)', () {
      final map = {
        '_id': '123',
        'title': 'Test Song',
        'artist': 'Test Artist',
        'album': 'Test Album',
        'album_id': '456',
        '_data': '/path/to/song.mp3',
        'duration': '240000',
        '_size': '5000000',
        'date_added': '1700000000',
        'date_modified': '1700001000',
        'track': '3',
        'year': '2024',
      };

      final song = SongModel.fromMap(map);

      expect(song.id, '123');
      expect(song.duration, 240000);
      expect(song.size, 5000000);
      expect(song.dateAdded, 1700000000);
      expect(song.dateModified, 1700001000);
      expect(song.track, 3);
      expect(song.year, 2024);
    });

    test('should handle mixed string and int types', () {
      final map = {
        '_id': 123,
        'title': 'Mixed Song',
        'artist': 'Mixed Artist',
        'album': 'Mixed Album',
        'album_id': '456',
        '_data': '/path/to/mixed.mp3',
        'duration': '180000',
        '_size': 3000000,
        'date_added': '1700000000',
        'date_modified': 1700001000,
        'track': '7',
        'year': 2023,
      };

      final song = SongModel.fromMap(map);

      expect(song.id, '123');
      expect(song.duration, 180000);
      expect(song.size, 3000000);
      expect(song.track, 7);
      expect(song.year, 2023);
    });

    test('should handle null values with defaults', () {
      final map = <String, dynamic>{
        '_id': null,
        'title': null,
        'artist': null,
        'album': null,
      };

      final song = SongModel.fromMap(map);

      expect(song.id, '');
      expect(song.title, 'Unknown');
      expect(song.artist, 'Unknown Artist');
      expect(song.album, 'Unknown Album');
      expect(song.duration, 0);
      expect(song.size, 0);
      expect(song.dateAdded, 0);
      expect(song.track, 0);
      expect(song.year, 0);
    });

    test('should handle empty map', () {
      final map = <String, dynamic>{};

      final song = SongModel.fromMap(map);

      expect(song.id, '');
      expect(song.title, 'Unknown');
      expect(song.duration, 0);
      expect(song.size, 0);
    });

    test('should handle double values for int fields', () {
      final map = {
        '_id': 123.0,
        'title': 'Double Song',
        'artist': 'Double Artist',
        'album': 'Double Album',
        'album_id': 456.0,
        '_data': '/path/to/double.mp3',
        'duration': 240000.0,
        '_size': 5000000.0,
        'date_added': 1700000000.0,
        'date_modified': 1700001000.0,
        'track': 1.0,
        'year': 2024.0,
      };

      final song = SongModel.fromMap(map);

      expect(song.id, '123');
      expect(song.duration, 240000);
      expect(song.size, 5000000);
      expect(song.track, 1);
      expect(song.year, 2024);
    });
  });

  group('SongModel.copyWith', () {
    test('should copy with new values', () {
      final song = SongModel(
        id: '1',
        title: 'Original',
        artist: 'Artist',
        album: 'Album',
        albumId: '10',
        uri: '/path/song.mp3',
        duration: 180000,
        size: 3000000,
        dateAdded: 1700000000,
        dateModified: 1700001000,
        track: 1,
        year: 2024,
      );

      final updated = song.copyWith(
        title: 'Updated Title',
        isFavorite: true,
        playCount: 5,
      );

      expect(updated.id, '1');
      expect(updated.title, 'Updated Title');
      expect(updated.artist, 'Artist');
      expect(updated.isFavorite, true);
      expect(updated.playCount, 5);
      expect(updated.lastPlayed, 0);
    });

    test('should preserve values not specified in copyWith', () {
      final song = SongModel(
        id: '1',
        title: 'Song',
        artist: 'Artist',
        album: 'Album',
        albumId: '10',
        uri: '/path/song.mp3',
        duration: 180000,
        size: 3000000,
        dateAdded: 1700000000,
        dateModified: 1700001000,
        track: 1,
        year: 2024,
        isFavorite: true,
        playCount: 3,
      );

      final updated = song.copyWith(playCount: 10);

      expect(updated.isFavorite, true);
      expect(updated.playCount, 10);
      expect(updated.title, 'Song');
    });
  });

  group('SongModel.formattedDuration', () {
    test('should format duration correctly', () {
      final song = SongModel(
        id: '1',
        title: 'Song',
        artist: 'Artist',
        album: 'Album',
        albumId: '10',
        uri: '/path/song.mp3',
        duration: 245000, // 4:05
        size: 3000000,
        dateAdded: 1700000000,
        dateModified: 1700001000,
        track: 1,
        year: 2024,
      );

      expect(song.formattedDuration, '04:05');
    });

    test('should format zero duration', () {
      final song = SongModel(
        id: '1',
        title: 'Song',
        artist: 'Artist',
        album: 'Album',
        albumId: '10',
        uri: '/path/song.mp3',
        duration: 0,
        size: 3000000,
        dateAdded: 1700000000,
        dateModified: 1700001000,
        track: 1,
        year: 2024,
      );

      expect(song.formattedDuration, '00:00');
    });

    test('should format long duration', () {
      final song = SongModel(
        id: '1',
        title: 'Song',
        artist: 'Artist',
        album: 'Album',
        albumId: '10',
        uri: '/path/song.mp3',
        duration: 661000, // 11:01
        size: 3000000,
        dateAdded: 1700000000,
        dateModified: 1700001000,
        track: 1,
        year: 2024,
      );

      expect(song.formattedDuration, '11:01');
    });
  });

  group('SongModel.formattedSize', () {
    test('should format bytes', () {
      final song = SongModel(
        id: '1',
        title: 'Song',
        artist: 'Artist',
        album: 'Album',
        albumId: '10',
        uri: '/path/song.mp3',
        duration: 180000,
        size: 500,
        dateAdded: 1700000000,
        dateModified: 1700001000,
        track: 1,
        year: 2024,
      );

      expect(song.formattedSize, '500 B');
    });

    test('should format kilobytes', () {
      final song = SongModel(
        id: '1',
        title: 'Song',
        artist: 'Artist',
        album: 'Album',
        albumId: '10',
        uri: '/path/song.mp3',
        duration: 180000,
        size: 5120,
        dateAdded: 1700000000,
        dateModified: 1700001000,
        track: 1,
        year: 2024,
      );

      expect(song.formattedSize, '5.0 KB');
    });

    test('should format megabytes', () {
      final song = SongModel(
        id: '1',
        title: 'Song',
        artist: 'Artist',
        album: 'Album',
        albumId: '10',
        uri: '/path/song.mp3',
        duration: 180000,
        size: 5242880, // 5 MB
        dateAdded: 1700000000,
        dateModified: 1700001000,
        track: 1,
        year: 2024,
      );

      expect(song.formattedSize, '5.0 MB');
    });
  });

  group('SongModel equality', () {
    test('equal songs should be equal', () {
      final song1 = SongModel.fromMap({
        '_id': 1,
        'title': 'Song',
        'artist': 'Artist',
        'album': 'Album',
        'duration': 180000,
      });

      final song2 = SongModel.fromMap({
        '_id': 1,
        'title': 'Song',
        'artist': 'Artist',
        'album': 'Album',
        'duration': 180000,
      });

      expect(song1, equals(song2));
    });

    test('different songs should not be equal', () {
      final song1 = SongModel.fromMap({'_id': 1, 'title': 'Song A'});
      final song2 = SongModel.fromMap({'_id': 2, 'title': 'Song B'});

      expect(song1, isNot(equals(song2)));
    });
  });

  group('SongModel.toMap', () {
    test('should convert to map correctly', () {
      final song = SongModel(
        id: '123',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        albumId: '456',
        uri: '/path/to/song.mp3',
        duration: 240000,
        size: 5000000,
        dateAdded: 1700000000,
        dateModified: 1700001000,
        track: 1,
        year: 2024,
      );

      final map = song.toMap();

      expect(map['_id'], '123');
      expect(map['title'], 'Test Song');
      expect(map['artist'], 'Test Artist');
      expect(map['album'], 'Test Album');
      expect(map['album_id'], '456');
      expect(map['_data'], '/path/to/song.mp3');
      expect(map['duration'], 240000);
      expect(map['_size'], 5000000);
    });
  });

  group('SongModel.folderPath', () {
    test('should extract folder path correctly', () {
      final song = SongModel(
        id: '1',
        title: 'Song',
        artist: 'Artist',
        album: 'Album',
        albumId: '10',
        uri: '/storage/emulated/0/Music/Artist/song.mp3',
        duration: 180000,
        size: 3000000,
        dateAdded: 1700000000,
        dateModified: 1700001000,
        track: 1,
        year: 2024,
      );

      expect(song.folderPath, '/storage/emulated/0/Music/Artist');
    });

    test('should return empty for empty uri', () {
      final song = SongModel(
        id: '1',
        title: 'Song',
        artist: 'Artist',
        album: 'Album',
        albumId: '10',
        uri: '',
        duration: 180000,
        size: 3000000,
        dateAdded: 1700000000,
        dateModified: 1700001000,
        track: 1,
        year: 2024,
      );

      expect(song.folderPath, '');
    });
  });
}
