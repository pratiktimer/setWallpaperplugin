// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this file is governed by a BSD-style license.

import 'dart:async';
import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'wallpaper_enums.dart';
import 'wallpaper_alignment.dart';
import 'wallpaper_download.dart';
import 'method_channel_wallpaper.dart';
import 'wallpaper_size.dart';

/// Abstract platform interface for wallpaper operations.
///
/// **Architecture:** This follows the platform_interface pattern used by Flutter
/// plugins (e.g. shared_preferences, path_provider). The plugin exposes a single
/// public API ([Wallpaper]) which delegates to [WallpaperPlatform.instance].
/// Platform-specific code (Android, iOS, etc.) lives in implementations of this
/// interface. The default implementation is [MethodChannelWallpaper], which
/// communicates with native code via method channels. Tests can replace [instance]
/// with a mock to avoid hitting the platform.
abstract class WallpaperPlatform extends PlatformInterface {
  /// Creates a [WallpaperPlatform]. Not used directly; use [instance].
  WallpaperPlatform() : super(token: _token);

  static final Object _token = Object();

  /// Default implementation: method channel (Android, etc.).
  static WallpaperPlatform _instance = MethodChannelWallpaper();

  /// The active platform implementation.
  ///
  /// Defaults to [MethodChannelWallpaper]. Tests and custom implementations
  /// can set this to a mock or another implementation.
  static WallpaperPlatform get instance => _instance;

  /// Sets the platform implementation (e.g. for testing).
  static set instance(WallpaperPlatform value) {
    PlatformInterface.verifyToken(value, _token);
    _instance = value;
  }

  /// Platform version string, or null if unavailable.
  Future<String?> getPlatformVersion();

  /// Platform-recommended wallpaper dimensions.
  Future<WallpaperSize> recommendedWallpaperSize() {
    throw UnimplementedError(
      'recommendedWallpaperSize() has not been implemented.',
    );
  }

  /// Open the platform wallpaper chooser UI.
  Future<String> openWallpaperChooser() {
    throw UnimplementedError(
      'openWallpaperChooser() has not been implemented.',
    );
  }

  /// Set home screen wallpaper from an already-downloaded image.
  Future<String> homeScreen({
    String imageName = 'myimage',
    ImageFormat fileExtension = ImageFormat.jpeg,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeFit,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  });

  /// Set lock screen wallpaper from an already-downloaded image.
  Future<String> lockScreen({
    String imageName = 'myimage',
    ImageFormat fileExtension = ImageFormat.jpeg,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeFit,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  });

  /// Set both home and lock screen from an already-downloaded image.
  Future<String> bothScreen({
    String imageName = 'myimage',
    ImageFormat fileExtension = ImageFormat.jpeg,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeFit,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  });

  /// Open the system wallpaper UI (crop/set flow). Requires activity on Android.
  Future<String> systemScreen({
    String imageName = 'myimage',
    ImageFormat fileExtension = ImageFormat.jpeg,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  });

  /// Set wallpaper from a local file path.
  Future<String> setFromFile(
    String filePath, {
    WallpaperTarget target = WallpaperTarget.home,
    String? imageName,
    ImageFormat? fileExtension,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeFit,
    WallpaperFit? fit,
    WallpaperAlignment? alignment,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) {
    throw UnimplementedError('setFromFile() has not been implemented.');
  }

  /// Set wallpaper from in-memory image bytes.
  Future<String> setFromBytes(
    Uint8List imageBytes, {
    WallpaperTarget target = WallpaperTarget.home,
    String? imageName,
    ImageFormat fileExtension = ImageFormat.jpeg,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeFit,
    WallpaperFit? fit,
    WallpaperAlignment? alignment,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) {
    throw UnimplementedError('setFromBytes() has not been implemented.');
  }

  /// Set wallpaper from a Flutter asset.
  Future<String> setFromAsset(
    String assetPath, {
    String? package,
    WallpaperTarget target = WallpaperTarget.home,
    String? imageName,
    ImageFormat? fileExtension,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeFit,
    WallpaperFit? fit,
    WallpaperAlignment? alignment,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) {
    throw UnimplementedError('setFromAsset() has not been implemented.');
  }

  /// Stream of download progress (e.g. "45%") for saving an image from [url].
  Stream<String> imageDownloadProgress(
    String url, {
    String imageName = 'myimage',
    ImageFormat fileExtension = ImageFormat.jpeg,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  });

  /// Starts a typed, cancellable wallpaper image download.
  WallpaperDownloadOperation download(
    String url, {
    WallpaperDownloadOptions options = const WallpaperDownloadOptions(),
  }) {
    throw UnimplementedError('download() has not been implemented.');
  }

  /// Clears plugin-managed temporary wallpaper downloads.
  Future<void> clearCache() {
    throw UnimplementedError('clearCache() has not been implemented.');
  }
}
