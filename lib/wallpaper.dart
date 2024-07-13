import 'dart:async';
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
class Wallpaper {
  /// Retrieves the platform version.
  static Future<String?> getPlatformVersion() async {
    final version = await WallpaperPlatform.instance.getPlatformVersion();
    return version;
  }

  /// Sets the wallpaper for the home screen.
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
    );
  }

  /// Sets the wallpaper for both the home and lock screens simultaneously.
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
    );
  }

  /// Sets the wallpaper using the system's default behavior.
  static Future<String> systemScreen({
    String imageName = "myimage",
    ImageFormat fileExtension = ImageFormat.jpeg,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  }) async {
    return await WallpaperPlatform.instance.systemScreen(
      location: location,
      imageName: imageName,
    );
  }

  /// Retrieves a stream of download progress for an image.
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
