import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PickedMedia {
  final XFile file;
  final String type;

  const PickedMedia({
    required this.file,
    required this.type,
  });
}

class MediaPickerWidget extends StatefulWidget {
  final List<PickedMedia> selectedMedia;
  final ValueChanged<List<PickedMedia>> onChanged;

  const MediaPickerWidget({
    super.key,
    required this.selectedMedia,
    required this.onChanged,
  });

  @override
  State<MediaPickerWidget> createState() => _MediaPickerWidgetState();
}

class _MediaPickerWidgetState extends State<MediaPickerWidget> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage(imageQuality: 85);
    if (images.isEmpty) return;

    widget.onChanged([
      ...widget.selectedMedia,
      ...images.map((file) => PickedMedia(file: file, type: 'image')),
    ]);
  }

  Future<void> _pickVideo() async {
    final video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;

    widget.onChanged([
      ...widget.selectedMedia,
      PickedMedia(file: video, type: 'video'),
    ]);
  }

  void _removeAt(int index) {
    final next = [...widget.selectedMedia]..removeAt(index);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Media',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.image_outlined),
                label: const Text('Images'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickVideo,
                icon: const Icon(Icons.videocam_outlined),
                label: const Text('Video'),
              ),
            ),
          ],
        ),
        if (widget.selectedMedia.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.selectedMedia.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = widget.selectedMedia[index];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 96,
                        height: 96,
                        color: Colors.black12,
                        child: item.type == 'image'
                            ? Image.file(
                                File(item.file.path),
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.play_circle_outline, size: 36),
                      ),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: InkWell(
                        onTap: () => _removeAt(index),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(3),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
