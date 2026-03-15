// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this file is governed by a BSD-style license.

import 'dart:async';

import 'package:flutter/services.dart';

import 'src/wallpaper_enums.dart';
import 'src/wallpaper_platform_interface.dart';

// Re-export enums and platform interface for public use and testing.
export 'src/wallpaper_enums.dart' show RequestSizeOptions, DownloadLocation, ImageFormat;
export 'src/wallpaper_platform_interface.dart' show WallpaperPlatform;

/// Target screen when setting wallpaper (for [Wallpaper.setWallpaper]).
enum WallpaperTarget {
  /// Home screen only.
  home,

  /// Lock screen only.
  lock,

  /// Both home and lock screen.
  both,
}

/// Options for setting wallpaper (home, lock, or both).
///
/// Use with [Wallpaper.setWallpaper] for a single, strongly-typed call.
/// All fields have defaults; only override what you need.
class SetWallpaperOptions {
  const SetWallpaperOptions({
    this.imageName = 'myimage',
    this.fileExtension = ImageFormat.jpeg,
    this.width = 0,
    this.height = 0,
    this.resizeOption = RequestSizeOptions.resizeCentreCrop,
    this.location = DownloadLocation.temporaryDirectory,
  });

  /// Basename of the downloaded image file (without extension).
  final String imageName;

  /// Image format (determines file extension).
  final ImageFormat fileExtension;

  /// Max width for resize; 0 means use screen width.
  final double width;

  /// Max height for resize; 0 means use screen height.
  final double height;

  /// How to resize the image to fit the screen.
  final RequestSizeOptions resizeOption;

  /// Where the image was downloaded (must match [Wallpaper.imageDownloadProgress]).
  final DownloadLocation location;
}

/// Options for the system wallpaper picker (crop/set UI).
class SystemWallpaperOptions {
  const SystemWallpaperOptions({
    this.imageName = 'myimage',
    this.fileExtension = ImageFormat.jpeg,
    this.location = DownloadLocation.temporaryDirectory,
  });

  final String imageName;
  final ImageFormat fileExtension;
  final DownloadLocation location;
}

/// Public API for setting wallpapers and downloading images.
///
/// **Architecture:**
/// - This class is the only public entry point. It delegates to [WallpaperPlatform.instance].
/// - Platform-specific code lives in [WallpaperPlatform] implementations (see [MethodChannelWallpaper] in `src/`).
/// - All options use strongly typed enums ([RequestSizeOptions], [DownloadLocation], [ImageFormat]); no raw strings for these.
///
/// **Backward compatibility:** [homeScreen], [lockScreen], [bothScreen], [systemScreen], [imageDownloadProgress],
/// and [getPlatformVersion] keep the same signatures and behavior. The new [setWallpaper] and [systemScreenWithOptions]
/// methods offer a cleaner API using [SetWallpaperOptions] and [SystemWallpaperOptions].
///
/// **Errors:** Methods throw [PlatformException] on failure. Use [PlatformException.code] and [PlatformException.message].
/// Common codes: `FILE_NOT_FOUND`, `DECODE_ERROR`, `STORAGE_UNAVAILABLE`, `SET_WALLPAPER_FAILED`, `PERMISSION_DENIED`,
/// `INVALID_ARGUMENT`, `NO_ACTIVITY`, `ACTIVITY_NOT_FOUND`, `PLUGIN_DETACHED`, `DETACHED`.
class Wallpaper {
  Wallpaper._();

  static final WallpaperPlatform _platform = WallpaperPlatform.instance;

  /// Returns the platform version string, or null if unavailable.
  ///
  /// Throws [PlatformException] if the platform call fails.
  static Future<String?> getPlatformVersion() => _platform.getPlatformVersion();

  /// Sets the wallpaper for the given [target] using [options].
  ///
  /// **Improved API:** Prefer this over [homeScreen]/[lockScreen]/[bothScreen] when
  /// you have an [SetWallpaperOptions] object or want a single call for any target.
  static Future<String> setWallpaper(WallpaperTarget target, SetWallpaperOptions options) {
    switch (target) {
      case WallpaperTarget.home:
        return _platform.homeScreen(
          imageName: options.imageName,
          fileExtension: options.fileExtension,
          width: options.width,
          height: options.height,
          options: options.resizeOption,
          location: options.location,
        );
      case WallpaperTarget.lock:
        return _platform.lockScreen(
          imageName: options.imageName,
          fileExtension: options.fileExtension,
          width: options.width,
          height: options.height,
          options: options.resizeOption,
          location: options.location,
        );
      case WallpaperTarget.both:
        return _platform.bothScreen(
          imageName: options.imageName,
          fileExtension: options.fileExtension,
          width: options.width,
          height: options.height,
          options: options.resizeOption,
          location: options.location,
        );
    }
  }

  /// Sets the home screen wallpaper. [imageName] and [location] must match the download.
  ///
  /// Throws [PlatformException] on failure (e.g. `FILE_NOT_FOUND`, `DECODE_ERROR`).
  static Future<String> homeScreen({
    String imageName = 'myimage',
    ImageFormat fileExtension = ImageFormat.jpeg,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeCentreCrop,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) =>
      _platform.homeScreen(
        imageName: imageName,
        fileExtension: fileExtension,
        width: width,
        height: height,
        options: options,
        location: location,
      );

  /// Sets the lock screen wallpaper.
  static Future<String> lockScreen({
    String imageName = 'myimage',
    ImageFormat fileExtension = ImageFormat.jpeg,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeExact,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) =>
      _platform.lockScreen(
        imageName: imageName,
        fileExtension: fileExtension,
        width: width,
        height: height,
        options: options,
        location: location,
      );

  /// Sets both home and lock screen to the same image.
  static Future<String> bothScreen({
    String imageName = 'myimage',
    ImageFormat fileExtension = ImageFormat.jpeg,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeExact,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) =>
      _platform.bothScreen(
        imageName: imageName,
        fileExtension: fileExtension,
        width: width,
        height: height,
        options: options,
        location: location,
      );

  /// Opens the system wallpaper picker (crop/set). Requires activity on Android.
  static Future<String> systemScreen({
    String imageName = 'myimage',
    ImageFormat fileExtension = ImageFormat.jpeg,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) =>
      _platform.systemScreen(
        imageName: imageName,
        fileExtension: fileExtension,
        location: location,
      );

  /// Opens the system wallpaper picker with [SystemWallpaperOptions].
  static Future<String> systemScreenWithOptions(SystemWallpaperOptions options) =>
      _platform.systemScreen(
        imageName: options.imageName,
        fileExtension: options.fileExtension,
        location: options.location,
      );

  /// Stream of download progress (e.g. "45%") for saving an image from [url].
  ///
  /// Use the same [imageName], [fileExtension], and [location] when calling
  /// [homeScreen], [lockScreen], [bothScreen], or [systemScreen] later.
  static Stream<String> imageDownloadProgress(
    String url, {
    String imageName = 'myimage',
    ImageFormat fileExtension = ImageFormat.jpeg,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) =>
      _platform.imageDownloadProgress(
        url,
        imageName: imageName,
        fileExtension: fileExtension,
        location: location,
      );
}
