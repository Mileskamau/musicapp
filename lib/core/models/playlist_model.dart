import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'playlist_model.g.dart';

@HiveType(typeId: 1)
class PlaylistModel extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String? description;
  
  @HiveField(3)
  final List<String> songIds;
  
  @HiveField(4)
  final String? coverArt;
  
  @HiveField(5)
  final int createdAt;
  
  @HiveField(6)
  final int updatedAt;
  
  @HiveField(7)
  final bool isSmartPlaylist;
  
  @HiveField(8)
  final String? smartPlaylistType;

  const PlaylistModel({
    required this.id,
    required this.name,
    this.description,
    required this.songIds,
    this.coverArt,
    required this.createdAt,
    required this.updatedAt,
    this.isSmartPlaylist = false,
    this.smartPlaylistType,
  });

  factory PlaylistModel.fromMap(Map<String, dynamic> map) {
    return PlaylistModel(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Untitled',
      description: map['description'],
      songIds: List<String>.from(map['songIds'] ?? []),
      coverArt: map['coverArt'],
      createdAt: map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: map['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      isSmartPlaylist: map['isSmartPlaylist'] ?? false,
      smartPlaylistType: map['smartPlaylistType'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'songIds': songIds,
      'coverArt': coverArt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isSmartPlaylist': isSmartPlaylist,
      'smartPlaylistType': smartPlaylistType,
    };
  }

  PlaylistModel copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? songIds,
    String? coverArt,
    int? createdAt,
    int? updatedAt,
    bool? isSmartPlaylist,
    String? smartPlaylistType,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      songIds: songIds ?? this.songIds,
      coverArt: coverArt ?? this.coverArt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSmartPlaylist: isSmartPlaylist ?? this.isSmartPlaylist,
      smartPlaylistType: smartPlaylistType ?? this.smartPlaylistType,
    );
  }

  int get songCount => songIds.length;

  String get formattedCreatedAt {
    final date = DateTime.fromMillisecondsSinceEpoch(createdAt);
    return '${date.day}/${date.month}/${date.year}';
  }

  String get formattedUpdatedAt {
    final date = DateTime.fromMillisecondsSinceEpoch(updatedAt);
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        songIds,
        coverArt,
        createdAt,
        updatedAt,
        isSmartPlaylist,
        smartPlaylistType,
      ];
}
