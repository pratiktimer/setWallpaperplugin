import 'dart:async';

import 'package:flutter/services.dart';

class Wallpaper {
  static const MethodChannel _channel =
      const MethodChannel('wallpaper');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
  static Future<String> HomeScreen(String url) async {
    final String resultvar=await _channel.invokeMethod('HomeScreen',url );
    return resultvar;
  }
  static Future<String> LockScreen(String url) async {
    final String resultvar= await _channel.invokeMethod('LockScreen',url );
    return resultvar;
  }
  static Future<String> Both(String url) async {
    final String resultvar=await _channel.invokeMethod('Both',url );
    return resultvar;
  }
}
