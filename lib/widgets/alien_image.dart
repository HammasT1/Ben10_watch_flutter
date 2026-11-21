import 'package:flutter/material.dart';

import '../models/alien.dart';

/// The alien's silhouette asset painted in a single [tint] color.
class AlienImage extends StatelessWidget {
  const AlienImage({super.key, required this.alien, required this.tint});

  final Alien alien;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
      child: Image.asset(
        alien.image,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) =>
            const Center(child: Icon(Icons.question_mark, size: 48)),
      ),
    );
  }
}

/// Lighter version of an alien color for text and silhouettes on dark
/// backgrounds.
Color alienHighlight(Color color) => Color.lerp(color, Colors.white, 0.35)!;
