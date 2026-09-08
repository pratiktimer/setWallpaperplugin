/// Options for resizing the image when setting wallpaper.
enum RequestSizeOptions {
  /// Resize to fit within dimensions while maintaining aspect ratio (may letterbox).
  resizeFit,

  /// Resize to fit inside dimensions; entire image visible, may not fill.
  resizeInside,

  /// Resize exactly to dimensions; aspect ratio may not be preserved.
  resizeExact,

  /// Resize to fill dimensions, cropped to center (aspect ratio preserved).
  resizeCentreCrop,
}

/// Where the downloaded image file is stored.
enum DownloadLocation {
  /// Temporary directory (may be cleaned by system).
  temporaryDirectory,

  /// Application internal directory (private to the app).
  applicationDirectory,

  /// External storage (may require permissions, visible to other apps).
  externalDirectory,
}

/// Supported image file format for download and set operations.
enum ImageFormat { jpeg, png }

/// Target screen when setting wallpaper.
enum WallpaperTarget {
  /// Home screen only.
  home,

  /// Lock screen only.
  lock,

  /// Both home and lock screen.
  both,
}

/// Modern fit behavior for source-based wallpaper APIs.
///
/// These values are opt-in and do not change legacy [RequestSizeOptions]
/// behavior.
enum WallpaperFit {
  /// Scale to cover the requested dimensions and crop from the center.
  cover,

  /// Scale to fit inside the requested dimensions without cropping.
  contain,

  /// Scale exactly to the requested dimensions.
  fill,

  /// Center the image on a canvas with the requested dimensions.
  center,

  /// Use the decoded image without an additional fit transform.
  none,
}
