// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this file is governed by a BSD-style license.

/// Strongly typed enums for the wallpaper plugin.
///
/// These enums are the single source of truth for the public API. Platform-specific
/// representations (e.g. integer indices for method channel) are derived only at
/// the platform implementation boundary, not in the API layer.

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
enum ImageFormat {
  jpeg,
  png,
}
