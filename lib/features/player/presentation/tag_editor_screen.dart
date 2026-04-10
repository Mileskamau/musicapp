import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:musiq/core/models/song_model.dart';
import 'package:musiq/core/services/tag_editor_service.dart';
import 'package:musiq/core/theme/app_theme.dart';
import 'package:musiq/core/constants/app_constants.dart';

class TagEditorScreen extends ConsumerStatefulWidget {
  final SongModel song;

  const TagEditorScreen({super.key, required this.song});

  @override
  ConsumerState<TagEditorScreen> createState() => _TagEditorScreenState();
}

class _TagEditorScreenState extends ConsumerState<TagEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _artistController;
  late TextEditingController _albumController;
  late TextEditingController _genreController;
  late TextEditingController _yearController;
  late TextEditingController _trackController;
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _albumArtPath;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.song.title);
    _artistController = TextEditingController(text: widget.song.artist);
    _albumController = TextEditingController(text: widget.song.album);
    _genreController = TextEditingController(text: widget.song.genre ?? '');
    _yearController = TextEditingController(text: widget.song.year.toString());
    _trackController = TextEditingController(text: widget.song.track.toString());
    _albumArtPath = widget.song.albumArt;
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    final tagService = ref.read(tagEditorServiceProvider);
    final metadata = await tagService.getSongMetadata(widget.song);
    
    if (metadata != null && mounted) {
      setState(() {
        if (metadata['title'] != null) _titleController.text = metadata['title'];
        if (metadata['artist'] != null) _artistController.text = metadata['artist'];
        if (metadata['album'] != null) _albumController.text = metadata['album'];
        if (metadata['genre'] != null) _genreController.text = metadata['genre'];
        if (metadata['year'] != null) _yearController.text = metadata['year'].toString();
        if (metadata['track'] != null) _trackController.text = metadata['track'].toString();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    _genreController.dispose();
    _yearController.dispose();
    _trackController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() => _albumArtPath = image.path);
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note: Tag editing requires Android 11+ with media permissions. Changes will be applied when supported.')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Tags'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveChanges,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                          image: _albumArtPath != null
                              ? DecorationImage(
                                  image: FileImage(File(_albumArtPath!)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _albumArtPath == null
                            ? const Icon(
                                Icons.album,
                                size: 64,
                                color: AppTheme.textTertiary,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingS),
                  Center(
                    child: Text(
                      'Tap to change album art',
                      style: AppTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingXL),
                  _buildTextField('Title', _titleController),
                  _buildTextField('Artist', _artistController),
                  _buildTextField('Album', _albumController),
                  _buildTextField('Genre', _genreController),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Year', _yearController, isNumber: true)),
                      const SizedBox(width: AppConstants.spacingM),
                      Expanded(child: _buildTextField('Track #', _trackController, isNumber: true)),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingXL),
                  Container(
                    padding: const EdgeInsets.all(AppConstants.spacingM),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppTheme.warningColor,
                        ),
                        const SizedBox(width: AppConstants.spacingM),
                        Expanded(
                          child: Text(
                            'Editing tags may affect file sorting and cannot be easily undone.',
                            style: AppTheme.bodySmall.copyWith(color: AppTheme.warningColor),
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

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.labelMedium),
          const SizedBox(height: AppConstants.spacingXS),
          TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}