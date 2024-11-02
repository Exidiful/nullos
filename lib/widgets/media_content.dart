import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class MediaContent extends StatelessWidget {
  final String url;
  final double aspectRatio;

  const MediaContent({
    super.key,
    required this.url,
    this.aspectRatio = 16 / 9,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: NetworkImage(url),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
