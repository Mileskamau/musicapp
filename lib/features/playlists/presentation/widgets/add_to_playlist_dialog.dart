import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/song_model.dart';
import '../../../../core/providers/music_provider.dart';

class AddToPlaylistDialog extends ConsumerStatefulWidget {
  final SongModel song;

  const AddToPlaylistDialog({super.key, required this.song});

  @override
  ConsumerState<AddToPlaylistDialog> createState() => _AddToPlaylistDialogState();
}

class _AddToPlaylistDialogState extends ConsumerState<AddToPlaylistDialog> {
  final Set<String> _selectedPlaylistIds = {};

  @override
  Widget build(BuildContext context) {
    final playlists = ref.watch(userPlaylistsProvider);

    return Dialog(
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.largeBorderRadius),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Column(
                children: [
                  Text(
                    'Add to Playlist',
                    style: AppTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppConstants.spacingS),
                  Text(
                    widget.song.title,
                    style: AppTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: playlists.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.spacingXL),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.queue_music_rounded,
                              color: AppTheme.textSecondary,
                              size: 48,
                            ),
                            const SizedBox(height: AppConstants.spacingM),
                            Text(
                              'No playlists yet',
                              style: AppTheme.titleMedium,
                            ),
                            const SizedBox(height: AppConstants.spacingS),
                            Text(
                              'Create a playlist first',
                              style: AppTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = playlists[index];
                        final isSelected = _selectedPlaylistIds.contains(playlist.id);
                        final alreadyInPlaylist = playlist.songIds.contains(widget.song.id);

                        return CheckboxListTile(
                          value: isSelected || alreadyInPlaylist,
                          onChanged: alreadyInPlaylist
                              ? null
                              : (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedPlaylistIds.add(playlist.id);
                                    } else {
                                      _selectedPlaylistIds.remove(playlist.id);
                                    }
                                  });
                                },
                          title: Text(
                            playlist.name,
                            style: AppTheme.titleMedium.copyWith(
                              color: alreadyInPlaylist ? AppTheme.textTertiary : null,
                            ),
                          ),
                          subtitle: Text(
                            alreadyInPlaylist
                                ? 'Already in playlist'
                                : '${playlist.songIds.length} songs',
                            style: AppTheme.bodySmall.copyWith(
                              color: alreadyInPlaylist ? AppTheme.textTertiary : null,
                            ),
                          ),
                          secondary: alreadyInPlaylist
                              ? const Icon(Icons.check_rounded, color: AppTheme.primaryColor)
                              : null,
                          activeColor: AppTheme.primaryColor,
                          checkColor: AppTheme.textPrimary,
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        _showCreatePlaylistDialog();
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('New Playlist'),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _selectedPlaylistIds.isEmpty
                          ? null
                          : () {
                              _addToSelectedPlaylists();
                            },
                      icon: const Icon(Icons.add_rounded),
                      label: Text('Add (${_selectedPlaylistIds.length})'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog() {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Create Playlist'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'Playlist name',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                nameController.dispose();
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  final playlists = ref.read(userPlaylistsProvider.notifier);
                  final current = ref.read(userPlaylistsProvider);
                  final newPlaylist = PlaylistEntry(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    songIds: [widget.song.id],
                  );
                  playlists.state = [...current, newPlaylist];
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Created "$name" with "${widget.song.title}"')),
                  );
                }
                nameController.dispose();
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _addToSelectedPlaylists() {
    final playlists = ref.read(userPlaylistsProvider.notifier);
    final current = ref.read(userPlaylistsProvider);

    final updatedPlaylists = current.map((playlist) {
      if (_selectedPlaylistIds.contains(playlist.id)) {
        if (playlist.songIds.contains(widget.song.id)) {
          return playlist;
        }
        return playlist.copyWith(
          songIds: [...playlist.songIds, widget.song.id],
        );
      }
      return playlist;
    }).toList();

    playlists.state = updatedPlaylists;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${widget.song.title}" to ${_selectedPlaylistIds.length} playlist(s)'),
      ),
    );

    Navigator.pop(context);
  }
}
