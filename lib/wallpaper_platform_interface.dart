import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:wallpaper/wallpaper.dart';
import 'wallpaper_method_channel.dart';
import 'dart:async';

/// Abstract class that defines the platform interface for managing wallpapers.
///
/// Implementations of this class should provide platform-specific methods
/// for setting wallpapers and managing wallpaper-related operations.
abstract class WallpaperPlatform extends PlatformInterface {
  /// Constructs a WallpaperPlatform.
  WallpaperPlatform() : super(token: _token);

  static final Object _token = Object();

  static WallpaperPlatform _instance = MethodChannelWallpaper();

  /// The default instance of [WallpaperPlatform] to use.
  ///
  /// Defaults to [MethodChannelWallpaper].
  static WallpaperPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [WallpaperPlatform] when
  /// they register themselves.
  static set instance(WallpaperPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Retrieves the platform version.
  ///
  /// This method should be implemented to return a `Future` that resolves to
  /// a `String` representing the current platform version.
  ///
  /// Throws an [UnimplementedError] if the platform-specific implementation
  /// is not provided.
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// [homeScreen] is to set home screen
  /// [imageName] -> Name of the downloaded image to set as home screen
  /// [width] and [height] -> send the width and height to use while setting the image as wallpaper else will use the entire image as it is
  /// [options] to use when setting wallpaper [RESIZE_FIT], [RESIZE_INSIDE], [RESIZE_EXACT],[RESIZE_CENTRE_CROP]
  /// [location] where the image is downloaded
  Future<String> homeScreen({
    String imageName = "myimage",
    ImageFormat fileExtension = ImageFormat.jpeg,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeFit,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  });

  /// [bothScreen]is to set home and lock screen
  /// [imageName] -> Name of the downloaded image to set as home screen
  /// [width] and [height] -> send the width and height to use while setting the image as wallpaper else will use the entire image as it is
  /// [options] to use when setting wallpaper [RESIZE_FIT], [RESIZE_INSIDE], [RESIZE_EXACT],[RESIZE_CENTRE_CROP]
  /// [location] where the image is downloaded
  Future<String> lockScreen({
    String imageName = "myimage",
    ImageFormat fileExtension = ImageFormat.jpeg,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeFit,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  });

  /// [systemScreen] gives you the option to use default wallpaper system which allows you to set home, lock screen or both
  /// [location] where the image is downloaded
  /// Requires Read and Write Storage Permissions
  Future<String> bothScreen({
    String imageName = "myimage",
    ImageFormat fileExtension = ImageFormat.jpeg,
    double width = 0,
    double height = 0,
    RequestSizeOptions options = RequestSizeOptions.resizeFit,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  });

  /// before using [homeScreen], [lockScreen] , [bothScreen], [systemScreen] . we need to download image .
  /// [imageName] -> after downloading image name to be saved so when using home screen, etc we can pass this name and
  /// [location]
  /// location where the image is downloaded
  Future<String> systemScreen({
    String imageName = "myimage",
    ImageFormat fileExtension = ImageFormat.jpeg,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  });

  /// before using homeScreen, lockScreen , bothScreen, systemScreen . we need to download image .
  /// [imageName] -> after downloading image name to be saved so when using home screen, etc we can pass this name and
  ///  [location]
  /// location where the image is downloaded
  Stream<String> imageDownloadProgress(
    String url, {
    String imageName = "myimage",
    ImageFormat fileExtension = ImageFormat.jpeg,
    DownloadLocation location = DownloadLocation.temporaryDirectory,
  });
}
