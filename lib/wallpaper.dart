import 'dart:async';

import 'package:flutter/services.dart';
import 'package:wallpaper/wallpaper_platform_interface.dart';

/// Enum representing different options for resizing images.
enum RequestSizeOptions {
  /// Resize the image to fit within the specified dimensions while maintaining
  /// the aspect ratio. Parts of the image may be letterboxed.
  resizeFit,

  /// Resize the image to fit within the specified dimensions while maintaining
  /// the aspect ratio. The entire image is visible, but it may not fill the
  /// specified dimensions.
  resizeInside,

  /// Resize the image exactly to the specified dimensions. The aspect ratio
  /// may not be preserved, resulting in potential distortion.
  resizeExact,

  /// Resize the image to fill the specified dimensions while maintaining the
  /// aspect ratio. The image is cropped to fill the specified dimensions,
  /// with the focus centered.
  resizeCentreCrop,
}

/// Enum representing different locations for downloading files.
enum DownloadLocation {
  /// Download files to a temporary directory. Files in this location may be
  /// automatically cleaned up by the system.
  temporaryDirectory,

  /// Download files to the application's internal directory. Files in this
  /// location are private to the application and not accessible to other apps
  /// or users.
  applicationDirectory,

  /// Download files to the external storage directory. Files in this location
  /// are accessible to other applications and may require permissions.
  externalDirectory,
}

/// Enum representing different image formats.
enum ImageFormat {
  /// JPEG image format.
  jpeg,

  /// PNG image format.
  png,
}

/// Utility class for setting wallpapers and managing wallpaper-related operations.
///
/// ## Error handling
///
/// Methods that call the platform (homeScreen, lockScreen, bothScreen, systemScreen,
/// getPlatformVersion) may throw [PlatformException] when the platform returns an error.
/// Use [PlatformException.code] for programmatic handling and [PlatformException.message]
/// for user-facing text.
///
/// Common error codes (Android):
/// - `FILE_NOT_FOUND` – Image file not found at the expected path; download the image first.
/// - `DECODE_ERROR` – Image file could not be decoded (corrupted or unsupported format).
/// - `STORAGE_UNAVAILABLE` – Storage path for the given [DownloadLocation] could not be resolved.
/// - `SET_WALLPAPER_FAILED` – WallpaperManager failed to set the bitmap (e.g. I/O error).
/// - `PERMISSION_DENIED` – Required permission (e.g. SET_WALLPAPER) was denied.
/// - `INVALID_ARGUMENT` – Invalid [RequestSizeOptions] or [DownloadLocation] index.
/// - `NO_ACTIVITY` – System wallpaper picker requires an activity; plugin not attached.
/// - `ACTIVITY_NOT_FOUND` – No app on device to handle wallpaper crop/set.
/// - `PLUGIN_DETACHED` – Plugin was detached from the engine before the call completed.
/// - `DETACHED` – Activity was detached before system wallpaper selection completed.
class Wallpaper {
  /// Retrieves the platform version.
  ///
  /// Throws [PlatformException] if the platform call fails (e.g. plugin not registered).
  static Future<String?> getPlatformVersion() async {
    final version = await WallpaperPlatform.instance.getPlatformVersion();
    return version;
  }

  /// Sets the wallpaper for the home screen.
  ///
  /// Throws [PlatformException] on failure; see class documentation for error codes
  /// (e.g. `FILE_NOT_FOUND`, `DECODE_ERROR`, `PERMISSION_DENIED`).
  static Future<String> homeScreen({
    String imageName = "myimage",
    ImageFormat fileExtension = ImageFormat.jpeg,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeCentreCrop,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) async {
    return await WallpaperPlatform.instance.homeScreen(
      width: width,
      height: height,
      options: options,
      location: location,
      imageName: imageName,
      fileExtension: fileExtension,
    );
  }

  /// Sets the wallpaper for the lock screen.
  ///
  /// Throws [PlatformException] on failure; see class documentation for error codes.
  static Future<String> lockScreen({
    String imageName = "myimage",
    ImageFormat fileExtension = ImageFormat.jpeg,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeExact,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) async {
    return await WallpaperPlatform.instance.lockScreen(
      width: width,
      height: height,
      options: options,
      location: location,
      imageName: imageName,
      fileExtension: fileExtension,
    );
  }

  /// Sets the wallpaper for both the home and lock screens simultaneously.
  ///
  /// Throws [PlatformException] on failure; see class documentation for error codes.
  static Future<String> bothScreen({
    String imageName = "myimage",
    ImageFormat fileExtension = ImageFormat.jpeg,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeExact,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) async {
    return await WallpaperPlatform.instance.bothScreen(
      width: width,
      height: height,
      options: options,
      location: location,
      imageName: imageName,
      fileExtension: fileExtension,
    );
  }

  /// Sets the wallpaper using the system's default behavior (opens system picker).
  ///
  /// Throws [PlatformException] on failure; see class documentation for error codes
  /// (e.g. `NO_ACTIVITY`, `FILE_NOT_FOUND`, `ACTIVITY_NOT_FOUND`).
  static Future<String> systemScreen({
    String imageName = "myimage",
    ImageFormat fileExtension = ImageFormat.jpeg,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) async {
    return await WallpaperPlatform.instance.systemScreen(
      location: location,
      imageName: imageName,
      fileExtension: fileExtension,
    );
  }

  /// Retrieves a stream of download progress for an image.
  ///
  /// The stream may emit progress strings (e.g. "45%") and close on success, or
  /// add an error if the download fails. Platform errors from the native side
  /// are not used by this method (download runs in Dart); errors are generic.
  static Stream<String> imageDownloadProgress(
    String url, {
    String imageName = 'myimage',
    ImageFormat fileExtension = ImageFormat.jpeg,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) async* {
    try {
      yield* WallpaperPlatform.instance.imageDownloadProgress(
        url,
        imageName: imageName,
        location: location,
      );
    } catch (ex) {
      rethrow;
    }
  }
}
