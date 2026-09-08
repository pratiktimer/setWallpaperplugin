// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this file is governed by a BSD-style license.

/// Recommended wallpaper dimensions reported by the platform.
class WallpaperSize {
  /// Creates a recommended wallpaper size.
  const WallpaperSize({required this.width, required this.height});

  /// Recommended width in physical pixels.
  final int width;

  /// Recommended height in physical pixels.
  final int height;

  @override
  bool operator ==(Object other) {
    return other is WallpaperSize &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => 'WallpaperSize(width: $width, height: $height)';
}
