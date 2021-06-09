import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

enum RequestSizeOptions {
  RESIZE_FIT,
  RESIZE_INSIDE,
  RESIZE_EXACT,
  RESIZE_CENTRE_CROP
}

// This are the locations where image can be downloaded
enum DownloadLocation {
  TEMPORARY_DIRECTORY,
  APPLICATION_DIRECTORY,
  EXTERNAL_DIRECTORY
}

class Wallpaper {
  static const MethodChannel _channel = const MethodChannel('com.prateektimer.wallpaper/wallpaper');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<String> homeScreen(
      {String imageName = "myimage",
      double width = 0,
      double height = 0,
      RequestSizeOptions options = RequestSizeOptions.RESIZE_CENTRE_CROP,
      DownloadLocation location = DownloadLocation.TEMPORARY_DIRECTORY}) async {
    final String resultvar = await _channel.invokeMethod('HomeScreen', {
      'maxWidth': width,
      'maxHeight': height,
      'RequestSizeOptions': options.index,
      'location': location.index,
      'imageName': imageName
    });
    return resultvar;
  }

  static Future<String> lockScreen(
      {String imageName = "myimage",
      double width = 0,
      double height = 0,
      RequestSizeOptions options = RequestSizeOptions.RESIZE_EXACT,
      DownloadLocation location = DownloadLocation.TEMPORARY_DIRECTORY}) async {
    final String resultvar = await _channel.invokeMethod('LockScreen', {
      'maxWidth': width,
      'maxHeight': height,
      'RequestSizeOptions': options.index,
      'location': location.index,
      'imageName': imageName
    });
    return resultvar;
  }

  static Future<String> bothScreen(
      {String imageName = "myimage",
      double width = 0,
      double height = 0,
      RequestSizeOptions options = RequestSizeOptions.RESIZE_EXACT,
      DownloadLocation location = DownloadLocation.TEMPORARY_DIRECTORY}) async {
    final String resultvar = await _channel.invokeMethod('Both', {
      'maxWidth': width,
      'maxHeight': height,
      'RequestSizeOptions': options.index,
      'location': location.index,
      'imageName': imageName
    });
    return resultvar;
  }

  static Future<String> systemScreen(
      {DownloadLocation location =
          DownloadLocation.TEMPORARY_DIRECTORY}) async {
    final String resultvar = await _channel.invokeMethod('SystemWallpaper', {
      'location': location.index,
    });
    return resultvar;
  }

  static Stream<String> ImageDownloadProgress(String url,
      {String imageName = 'myimage',
      DownloadLocation location =
          DownloadLocation.TEMPORARY_DIRECTORY}) async* {
    StreamController<String> streamController = new StreamController();
    try {
      var dir;
      switch (location) {
        case DownloadLocation.TEMPORARY_DIRECTORY:
          dir = await getTemporaryDirectory();
          break;
        case DownloadLocation.APPLICATION_DIRECTORY:
          dir = await getApplicationSupportDirectory();
          break;
        case DownloadLocation.EXTERNAL_DIRECTORY:
        default:
          dir = await getExternalStorageDirectory();
          break;
      }
      Dio dio = new Dio();
      dio
          .download(
            url,
            "${dir.path}/" + imageName + ".jpeg",
            onReceiveProgress: (int received, int total) {
              streamController
                  .add(((received / total) * 100).toStringAsFixed(0) + "%");
            },
          )
          .then((Response response) {})
          .catchError((ex) {
            streamController.add(ex.toString());
          })
          .whenComplete(() {
            streamController.close();
          });
      yield* streamController.stream;
    } catch (ex) {
      throw ex;
    }
  }
}
