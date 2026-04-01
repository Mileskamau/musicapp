import 'package:equatable/equatable.dart';

class ArtistModel extends Equatable {
  final String id;
  final String name;
  final int numberOfAlbums;
  final int numberOfTracks;

  const ArtistModel({
    required this.id,
    required this.name,
    required this.numberOfAlbums,
    required this.numberOfTracks,
  });

  factory ArtistModel.fromMap(Map<String, dynamic> map) {
    return ArtistModel(
      id: map['artist_id']?.toString() ?? '',
      name: map['artist'] ?? 'Unknown Artist',
      numberOfAlbums: map['number_of_albums'] ?? 0,
      numberOfTracks: map['number_of_tracks'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'artist_id': id,
      'artist': name,
      'number_of_albums': numberOfAlbums,
      'number_of_tracks': numberOfTracks,
    };
  }

  ArtistModel copyWith({
    String? id,
    String? name,
    int? numberOfAlbums,
    int? numberOfTracks,
  }) {
    return ArtistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      numberOfAlbums: numberOfAlbums ?? this.numberOfAlbums,
      numberOfTracks: numberOfTracks ?? this.numberOfTracks,
    );
  }

  @override
  List<Object?> get props => [id, name, numberOfAlbums, numberOfTracks];
}
