/// Placement control for modern wallpaper fit modes.
///
/// Alignment values use the same coordinate convention as Flutter's
/// `Alignment`: -1 is start/top, 0 is centered, and 1 is end/bottom.
class WallpaperAlignment {
  /// Creates a wallpaper alignment.
  const WallpaperAlignment(this.x, this.y)
    : assert(x >= -1 && x <= 1),
      assert(y >= -1 && y <= 1);

  /// Horizontal placement from left (-1) to right (1).
  final double x;

  /// Vertical placement from top (-1) to bottom (1).
  final double y;

  /// Centered horizontally and vertically.
  static const center = WallpaperAlignment(0, 0);

  /// Top-left placement.
  static const topLeft = WallpaperAlignment(-1, -1);

  /// Top-center placement.
  static const topCenter = WallpaperAlignment(0, -1);

  /// Top-right placement.
  static const topRight = WallpaperAlignment(1, -1);

  /// Center-left placement.
  static const centerLeft = WallpaperAlignment(-1, 0);

  /// Center-right placement.
  static const centerRight = WallpaperAlignment(1, 0);

  /// Bottom-left placement.
  static const bottomLeft = WallpaperAlignment(-1, 1);

  /// Bottom-center placement.
  static const bottomCenter = WallpaperAlignment(0, 1);

  /// Bottom-right placement.
  static const bottomRight = WallpaperAlignment(1, 1);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WallpaperAlignment && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'WallpaperAlignment($x, $y)';
}
