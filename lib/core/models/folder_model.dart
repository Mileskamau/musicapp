import 'package:equatable/equatable.dart';

class FolderModel extends Equatable {
  final String path;
  final String name;
  final List<String> songIds;
  final int songCount;
  final String? coverArtId;

  const FolderModel({
    required this.path,
    required this.name,
    required this.songIds,
    required this.songCount,
    this.coverArtId,
  });

  factory FolderModel.fromSongPaths(String folderPath, List<String> songIds, String? firstSongId) {
    final name = folderPath.split(RegExp(r'[/\\]')).last;
    return FolderModel(
      path: folderPath,
      name: name.isNotEmpty ? name : folderPath,
      songIds: songIds,
      songCount: songIds.length,
      coverArtId: firstSongId,
    );
  }

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      path: json['path'] as String,
      name: json['name'] as String,
      songIds: List<String>.from(json['songIds'] ?? []),
      songCount: json['songCount'] as int? ?? 0,
      coverArtId: json['coverArtId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'songIds': songIds,
      'songCount': songCount,
      'coverArtId': coverArtId,
    };
  }

  FolderModel copyWith({
    String? path,
    String? name,
    List<String>? songIds,
    int? songCount,
    String? coverArtId,
  }) {
    return FolderModel(
      path: path ?? this.path,
      name: name ?? this.name,
      songIds: songIds ?? this.songIds,
      songCount: songCount ?? this.songCount,
      coverArtId: coverArtId ?? this.coverArtId,
    );
  }

  @override
  List<Object?> get props => [path, name, songIds, songCount, coverArtId];
}
