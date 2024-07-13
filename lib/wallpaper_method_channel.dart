import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wallpaper/wallpaper.dart';
import 'dart:async';

import 'wallpaper_platform_interface.dart';

/// An implementation of [WallpaperPlatform] that uses method channels.
class MethodChannelWallpaper extends WallpaperPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel =
      const MethodChannel('com.prateektimer.wallpaper/wallpaper');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await WallpaperPlatform.instance.getPlatformVersion();
    return version;
  }

  @override
  Future<String> homeScreen(
      {String imageName = "myimage",
      ImageFormat fileExtension = ImageFormat.jpeg,
      double width = 0,
      double height = 0,
      RequestSizeOptions options = RequestSizeOptions.resizeFit,
      DownloadLocation location = DownloadLocation.temporaryDirectory}) async {
    final String resultvar = await methodChannel.invokeMethod('HomeScreen', {
      'maxWidth': width,
      'maxHeight': height,
      'RequestSizeOptions': options.index,
      'location': location.index,
      'imageName': imageName,
      'fileExtension': _imageFormatToExtension(fileExtension)
    });
    return resultvar;
  }

  @override
  Future<String> lockScreen(
      {String imageName = "myimage",
      ImageFormat fileExtension = ImageFormat.jpeg,
      double width = 0,
      double height = 0,
      RequestSizeOptions options = RequestSizeOptions.resizeFit,
      DownloadLocation location = DownloadLocation.temporaryDirectory}) async {
    final String resultvar = await methodChannel.invokeMethod('LockScreen', {
      'maxWidth': width,
      'maxHeight': height,
      'RequestSizeOptions': options.index,
      'location': location.index,
      'imageName': imageName,
      'fileExtension': _imageFormatToExtension(fileExtension),
    });
    return resultvar;
  }

  @override
  Future<String> bothScreen(
      {String imageName = "myimage",
      ImageFormat fileExtension = ImageFormat.jpeg,
      double width = 0,
      double height = 0,
      RequestSizeOptions options = RequestSizeOptions.resizeFit,
      DownloadLocation location = DownloadLocation.temporaryDirectory}) async {
    final String resultvar = await methodChannel.invokeMethod('Both', {
      'maxWidth': width,
      'maxHeight': height,
      'RequestSizeOptions': options.index,
      'location': location.index,
      'imageName': imageName,
      'fileExtension': _imageFormatToExtension(fileExtension),
    });
    return resultvar;
  }

  @override
  Future<String> systemScreen(
      {String imageName = "myimage",
      ImageFormat fileExtension = ImageFormat.jpeg,
      DownloadLocation location = DownloadLocation.temporaryDirectory}) async {
    final String resultvar =
        await methodChannel.invokeMethod('SystemWallpaper', {
      'location': location.index,
      'imageName': imageName,
      'fileExtension': _imageFormatToExtension(fileExtension),
    });
    return resultvar;
  }

  @override
  Stream<String> imageDownloadProgress(String url,
      {String imageName = 'myimage',
      ImageFormat fileExtension = ImageFormat.jpeg,
      DownloadLocation location = DownloadLocation.temporaryDirectory}) async* {
    StreamController<String> streamController = new StreamController();
    try {
      Directory? dir;
      switch (location) {
        case DownloadLocation.applicationDirectory:
          dir = await getApplicationSupportDirectory();
          break;
        case DownloadLocation.externalDirectory:
          dir = await getExternalStorageDirectory();
          break;
        case DownloadLocation.temporaryDirectory:
        default:
          dir = await getTemporaryDirectory();
          break;
      }
      dir ??= await getTemporaryDirectory();
      Dio dio = Dio();
      String fileName = _imageFormatToExtension(fileExtension);
      dio
          .download(
            url,
            "${dir.path}/$imageName.$fileName",
            onReceiveProgress: (int received, int total) {
              streamController
                  .add("${((received / total) * 100).toStringAsFixed(0)}%");
            },
          )
          .then((Response response) {})
          .catchError((ex) {
            streamController.add(ex.toString());
            streamController.close();
          })
          .whenComplete(() {
            streamController.close();
          });
      yield* streamController.stream;
    } catch (ex) {
      streamController.addError(ex.toString());
      streamController.close();
    }
  }

  String _imageFormatToExtension(ImageFormat format) {
    switch (format) {
      case ImageFormat.png:
        return 'png';
      case ImageFormat.jpeg:
      default:
        return 'jpeg';
    }
  }
}
