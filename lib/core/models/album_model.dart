import 'package:equatable/equatable.dart';

class AlbumModel extends Equatable {
  final String id;
  final String name;
  final String artist;
  final String? albumArt;
  final int numberOfSongs;
  final int year;

  const AlbumModel({
    required this.id,
    required this.name,
    required this.artist,
    this.albumArt,
    required this.numberOfSongs,
    required this.year,
  });

  factory AlbumModel.fromMap(Map<String, dynamic> map) {
    return AlbumModel(
      id: map['album_id']?.toString() ?? '',
      name: map['album'] ?? 'Unknown Album',
      artist: map['artist'] ?? 'Unknown Artist',
      albumArt: map['album_art'],
      numberOfSongs: map['numsongs'] ?? 0,
      year: map['minyear'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'album_id': id,
      'album': name,
      'artist': artist,
      'album_art': albumArt,
      'numsongs': numberOfSongs,
      'minyear': year,
    };
  }

  AlbumModel copyWith({
    String? id,
    String? name,
    String? artist,
    String? albumArt,
    int? numberOfSongs,
    int? year,
  }) {
    return AlbumModel(
      id: id ?? this.id,
      name: name ?? this.name,
      artist: artist ?? this.artist,
      albumArt: albumArt ?? this.albumArt,
      numberOfSongs: numberOfSongs ?? this.numberOfSongs,
      year: year ?? this.year,
    );
  }

  @override
  List<Object?> get props => [id, name, artist, albumArt, numberOfSongs, year];
}
