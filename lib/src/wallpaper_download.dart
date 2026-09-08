import 'dart:async';

import 'package:flutter/services.dart';

import 'wallpaper_enums.dart';

/// Cache behavior for typed wallpaper downloads.
enum WallpaperCachePolicy {
  /// Always download and overwrite the target file.
  overwrite,

  /// Reuse an existing target file when it already exists.
  reuse,
}

/// Options for a typed wallpaper download.
class WallpaperDownloadOptions {
  const WallpaperDownloadOptions({
    this.imageName,
    this.fileExtension = ImageFormat.jpeg,
    this.location = DownloadLocation.temporaryDirectory,
    this.headers,
    this.connectTimeout,
    this.receiveTimeout,
    this.cachePolicy = WallpaperCachePolicy.overwrite,
  });

  /// Optional storage basename. Omit to generate an operation-scoped name.
  final String? imageName;

  /// Image format used for the downloaded file extension.
  final ImageFormat fileExtension;

  /// Where the downloaded file is stored.
  final DownloadLocation location;

  /// Optional HTTP request headers.
  final Map<String, String>? headers;

  /// Optional connection timeout.
  final Duration? connectTimeout;

  /// Optional receive timeout.
  final Duration? receiveTimeout;

  /// Whether to reuse an existing file with the same name.
  final WallpaperCachePolicy cachePolicy;
}

/// Typed progress event emitted by [WallpaperDownloadOperation.progress].
class WallpaperDownloadProgress {
  const WallpaperDownloadProgress({
    required this.receivedBytes,
    required this.totalBytes,
  });

  /// Bytes received so far.
  final int receivedBytes;

  /// Total bytes expected, or `-1` when the server did not provide a length.
  final int totalBytes;

  /// Download percentage, or `null` when total size is unknown.
  double? get percentage =>
      totalBytes <= 0 ? null : (receivedBytes / totalBytes) * 100;
}

/// Successful download details.
class WallpaperDownloadedFile {
  const WallpaperDownloadedFile({
    required this.path,
    required this.imageName,
    required this.fileExtension,
    required this.location,
    required this.fromCache,
  });

  /// Absolute local path of the downloaded image.
  final String path;

  /// Basename to pass to legacy wallpaper APIs if needed.
  final String imageName;

  /// Stored image format.
  final ImageFormat fileExtension;

  /// Storage location.
  final DownloadLocation location;

  /// Whether this result reused an existing file.
  final bool fromCache;
}

/// Handle for a typed, cancellable wallpaper image download.
class WallpaperDownloadOperation {
  const WallpaperDownloadOperation({
    required this.progress,
    required this.completed,
    required Future<void> Function() cancel,
  }) : _cancel = cancel;

  /// Typed progress events.
  final Stream<WallpaperDownloadProgress> progress;

  /// Completes with downloaded-file details, or throws [PlatformException].
  final Future<WallpaperDownloadedFile> completed;

  final Future<void> Function() _cancel;

  /// Cancels the in-flight download.
  Future<void> cancel() => _cancel();
}
