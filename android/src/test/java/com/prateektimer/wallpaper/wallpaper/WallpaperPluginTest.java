package com.prateektimer.wallpaper;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import org.junit.Test;

/**
 * This demonstrates a simple unit test of the Java portion of this plugin's implementation.
 *
 * Once you have built the plugin's example app, you can run these tests from the command
 * line by running `./gradlew testDebugUnitTest` in the `example/android/` directory, or
 * you can run them directly from IDEs that support JUnit such as Android Studio.
 */

public class WallpaperPluginTest {
  @Test
  public void onMethodCall_getPlatformVersion_returnsExpectedValue() {
    WallpaperPlugin plugin = new WallpaperPlugin();

    final MethodCall call = new MethodCall("getPlatformVersion", null);
    MethodChannel.Result mockResult = mock(MethodChannel.Result.class);
    plugin.onMethodCall(call, mockResult);

    verify(mockResult).success(android.os.Build.VERSION.RELEASE);
  }

  @Test
  public void onMethodCall_invalidLocation_returnsInvalidArgument() {
    WallpaperPlugin plugin = new WallpaperPlugin();
    MethodChannel.Result mockResult = mock(MethodChannel.Result.class);
    Map<String, Object> arguments = validWallpaperArguments();
    arguments.put("location", 9);

    plugin.onMethodCall(new MethodCall("HomeScreen", arguments), mockResult);

    verify(mockResult).error(
        eq("INVALID_ARGUMENT"),
        eq("location must be 0 (temporary), 1 (application), or 2 (external)."),
        isNull());
  }

  @Test
  public void onMethodCall_invalidResizeOption_returnsInvalidArgument() {
    WallpaperPlugin plugin = new WallpaperPlugin();
    MethodChannel.Result mockResult = mock(MethodChannel.Result.class);
    Map<String, Object> arguments = validWallpaperArguments();
    arguments.put("RequestSizeOptions", 9);

    plugin.onMethodCall(new MethodCall("HomeScreen", arguments), mockResult);

    verify(mockResult).error(
        eq("INVALID_ARGUMENT"),
        eq("RequestSizeOptions must be 0-3 (resizeFit, resizeInside, resizeExact, resizeCentreCrop)."),
        isNull());
  }

  @Test
  public void onMethodCall_invalidWallpaperFit_returnsInvalidArgument() {
    WallpaperPlugin plugin = new WallpaperPlugin();
    MethodChannel.Result mockResult = mock(MethodChannel.Result.class);
    Map<String, Object> arguments = validWallpaperArguments();
    arguments.put("WallpaperFit", 9);

    plugin.onMethodCall(new MethodCall("HomeScreen", arguments), mockResult);

    verify(mockResult).error(
        eq("INVALID_ARGUMENT"),
        eq("WallpaperFit must be 0-4 (cover, contain, fill, center, none)."),
        isNull());
  }

  private static Map<String, Object> validWallpaperArguments() {
    Map<String, Object> arguments = new HashMap<>();
    arguments.put("location", 0);
    arguments.put("imageName", "myimage");
    arguments.put("fileExtension", "jpeg");
    arguments.put("maxWidth", 1080.0);
    arguments.put("maxHeight", 1920.0);
    arguments.put("RequestSizeOptions", 0);
    return arguments;
  }
}
