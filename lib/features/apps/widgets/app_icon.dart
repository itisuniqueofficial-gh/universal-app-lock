import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../services/platform/platform_service.dart';

/// Displays an installed application's real Android icon, fetched lazily over
/// the platform bridge and cached in-memory per package. Falls back to a
/// neutral placeholder if the icon is missing or fails to load.
class AppIcon extends StatelessWidget {
  const AppIcon({
    super.key,
    required this.platform,
    required this.packageName,
    this.size = 40,
  });

  final PlatformService platform;
  final String packageName;
  final double size;

  // Shared across instances so scrolling does not refetch icons.
  static final Map<String, Future<Uint8List?>> _cache = {};

  Future<Uint8List?> _load() => _cache.putIfAbsent(
    packageName,
    () => platform.getApplicationIcon(packageName, sizePx: (size * 2).round()),
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: FutureBuilder<Uint8List?>(
        future: _load(),
        builder: (context, snapshot) {
          final bytes = snapshot.data;
          if (bytes != null && bytes.isNotEmpty) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                bytes,
                width: size,
                height: size,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => _fallback(context),
              ),
            );
          }
          return _fallback(context);
        },
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Icon(Icons.android, size: size * 0.6),
    );
  }
}
