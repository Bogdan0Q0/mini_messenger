import 'dart:io';
import 'package:flutter/material.dart';

/// Просмотр фото на весь экран: листание влево-вправо, масштаб щипком.
class PhotoViewerScreen extends StatefulWidget {
  final List<String> paths;
  final int initialIndex;

  const PhotoViewerScreen({
    super.key,
    required this.paths,
    this.initialIndex = 0,
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.paths.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.paths.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(
                child: Image.file(
                  File(widget.paths[i]),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(Icons.broken_image,
                      color: Colors.white54, size: 64),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  if (widget.paths.length > 1)
                    Text('${_index + 1} / ${widget.paths.length}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 15)),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
