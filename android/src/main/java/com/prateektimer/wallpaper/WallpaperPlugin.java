package com.prateektimer.wallpaper;

import static android.app.WallpaperManager.FLAG_LOCK;
import static android.app.WallpaperManager.FLAG_SYSTEM;
import static com.prateektimer.wallpaper.WallpaperHelper.GetFile;
import static com.prateektimer.wallpaper.WallpaperHelper.getImageContentUri;
import static com.prateektimer.wallpaper.WallpaperHelper.recycleBitmap;
import static com.prateektimer.wallpaper.WallpaperHelper.resizeBitmap;

import android.app.Activity;
import android.app.WallpaperManager;
import android.content.ActivityNotFoundException;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Build;
import android.util.DisplayMetrics;

import androidx.annotation.NonNull;

import java.io.File;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

public class WallpaperPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {

    private static final String CHANNEL_NAME = "com.prateektimer.wallpaper/wallpaper";
    private static final int SYSTEM_WALLPAPER_REQUEST_CODE = 2;
    private static final int REQUEST_SIZE_OPTIONS_MAX_INDEX = 3;
    private static final int WALLPAPER_FIT_MAX_INDEX = 4;
    private static final int LOCATION_MAX_INDEX = 2;

    private Context context;
    private MethodChannel channel;
    private Activity activity;
    private ExecutorService executorService;
    private MethodChannel.Result pendingSystemWallpaperResult;
    private PluginRegistry.ActivityResultListener activityResultListener;
    private ActivityPluginBinding activityPluginBinding;

    public WallpaperPlugin() {
        executorService = Executors.newSingleThreadExecutor();
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
        context = binding.getApplicationContext();
        channel.setMethodCallHandler(this);
        if (executorService == null || executorService.isShutdown()) {
            executorService = Executors.newSingleThreadExecutor();
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        detachActivity(true);
        if (channel != null) {
            channel.setMethodCallHandler(null);
            channel = null;
        }
        context = null;
        if (executorService != null) {
            executorService.shutdown();
            executorService = null;
        }
    }

    @Override
    public void onMethodCall(MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "getPlatformVersion":
                result.success(Build.VERSION.RELEASE);
                break;
            case "getRecommendedWallpaperSize":
                result.success(getRecommendedWallpaperSize());
                break;
            case "OpenWallpaperChooser":
                openWallpaperChooser(result);
                break;
            case "HomeScreen":
            case "LockScreen":
            case "Both":
                WallpaperRequest request = parseWallpaperRequest(call, result);
                if (request == null) {
                    break;
                }
                if ("HomeScreen".equals(call.method)) {
                    setHomeScreen(request, result);
                } else if ("LockScreen".equals(call.method)) {
                    setLockScreen(request, result);
                } else {
                    setHomeLockScreen(request, result);
                }
                break;
            case "SystemWallpaper":
                WallpaperFileRequest fileRequest = parseFileRequest(call, result);
                if (fileRequest != null) {
                    setSystemWallpaper(fileRequest, result);
                }
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private Map<String, Integer> getRecommendedWallpaperSize() {
        WallpaperManager wallpaperManager = WallpaperManager.getInstance(context);
        int width = wallpaperManager.getDesiredMinimumWidth();
        int height = wallpaperManager.getDesiredMinimumHeight();

        if (width <= 0 || height <= 0) {
            DisplayMetrics metrics = context.getResources().getDisplayMetrics();
            width = metrics.widthPixels;
            height = metrics.heightPixels;
        }

        Map<String, Integer> size = new HashMap<>();
        size.put("width", width);
        size.put("height", height);
        return size;
    }

    private void openWallpaperChooser(@NonNull MethodChannel.Result result) {
        if (activity == null) {
            result.error("NO_ACTIVITY", "Plugin not attached to an activity. Cannot open wallpaper chooser.", null);
            return;
        }
        try {
            Intent intent = new Intent(Intent.ACTION_SET_WALLPAPER);
            activity.startActivity(intent);
            result.success("Wallpaper Chooser Opened Successfully");
        } catch (ActivityNotFoundException e) {
            result.error("ACTIVITY_NOT_FOUND", "No app found to handle wallpaper chooser. " + e.getMessage(), null);
        } catch (SecurityException e) {
            result.error("PERMISSION_DENIED", "Permission denied opening wallpaper chooser: " + e.getMessage(), null);
        } catch (Exception e) {
            result.error("WALLPAPER_CHOOSER_FAILED", "Failed to open wallpaper chooser: " + e.getMessage(), null);
        }
    }

    private WallpaperRequest parseWallpaperRequest(MethodCall call, MethodChannel.Result result) {
        WallpaperFileRequest fileRequest = parseFileRequest(call, result);
        if (fileRequest == null) {
            return null;
        }

        Integer options = call.argument("RequestSizeOptions");
        if (options == null || options < 0 || options > REQUEST_SIZE_OPTIONS_MAX_INDEX) {
            result.error("INVALID_ARGUMENT", "RequestSizeOptions must be 0-3 (resizeFit, resizeInside, resizeExact, resizeCentreCrop).", null);
            return null;
        }

        Double maxWidth = call.argument("maxWidth");
        Double maxHeight = call.argument("maxHeight");
        Integer fitIndex = call.argument("WallpaperFit");
        WallpaperHelper.WallpaperFit fit = null;
        if (fitIndex != null) {
            if (fitIndex < 0 || fitIndex > WALLPAPER_FIT_MAX_INDEX) {
                result.error("INVALID_ARGUMENT", "WallpaperFit must be 0-4 (cover, contain, fill, center, none).", null);
                return null;
            }
            fit = WallpaperHelper.WallpaperFit.values()[fitIndex];
        }
        Double alignmentX = call.argument("WallpaperAlignmentX");
        Double alignmentY = call.argument("WallpaperAlignmentY");
        return new WallpaperRequest(
                fileRequest.location,
                fileRequest.imageName,
                fileRequest.fileExtension,
                maxWidth != null ? maxWidth : 0,
                maxHeight != null ? maxHeight : 0,
                WallpaperHelper.RequestSizeOptions.values()[options],
                fit,
                alignmentX != null ? alignmentX : 0,
                alignmentY != null ? alignmentY : 0
        );
    }

    private WallpaperFileRequest parseFileRequest(MethodCall call, MethodChannel.Result result) {
        Integer location = call.argument("location");
        if (location == null || location < 0 || location > LOCATION_MAX_INDEX) {
            result.error("INVALID_ARGUMENT", "location must be 0 (temporary), 1 (application), or 2 (external).", null);
            return null;
        }

        String imageName = call.argument("imageName");
        String fileExtension = call.argument("fileExtension");
        return new WallpaperFileRequest(
                location,
                imageName != null && !imageName.isEmpty() ? imageName : "myimage",
                fileExtension != null && !fileExtension.isEmpty() ? fileExtension : "jpeg"
        );
    }

    private void setSystemWallpaper(@NonNull WallpaperFileRequest request, @NonNull MethodChannel.Result result) {
        if (activity == null) {
            result.error("NO_ACTIVITY", "Plugin not attached to an activity. Cannot open system wallpaper picker.", null);
            return;
        }
        if (pendingSystemWallpaperResult != null) {
            result.error("OPERATION_IN_PROGRESS", "A system wallpaper picker is already open.", null);
            return;
        }
        try {
            File file = GetFile(request.location, activity, request.imageName, request.fileExtension);
            if (file == null) {
                result.error("STORAGE_UNAVAILABLE", "Could not resolve storage path for location " + request.location + ". External storage may be unmounted.", null);
                return;
            }
            if (!file.exists()) {
                result.error("FILE_NOT_FOUND", "Image file not found: " + file.getAbsolutePath() + ". Download the image first.", null);
                return;
            }
            Uri contentUri = getImageContentUri(activity, file);
            if (contentUri == null) {
                result.error("FILE_PROVIDER_ERROR", "Could not get content URI for image. Check FileProvider configuration.", null);
                return;
            }
            WallpaperManager wm = WallpaperManager.getInstance(activity);
            Intent intent = new Intent(wm.getCropAndSetWallpaperIntent(contentUri));
            intent.setDataAndType(contentUri, "image/*");
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
            pendingSystemWallpaperResult = result;
            activity.startActivityForResult(intent, SYSTEM_WALLPAPER_REQUEST_CODE);
        } catch (ActivityNotFoundException e) {
            pendingSystemWallpaperResult = null;
            result.error("ACTIVITY_NOT_FOUND", "No app found to handle wallpaper crop/set. " + e.getMessage(), null);
        } catch (SecurityException e) {
            pendingSystemWallpaperResult = null;
            result.error("PERMISSION_DENIED", "Permission denied for wallpaper or storage: " + e.getMessage(), null);
        } catch (Exception e) {
            pendingSystemWallpaperResult = null;
            result.error("SYSTEM_WALLPAPER_FAILED", "Failed to open system wallpaper picker: " + e.getMessage(), null);
        }
    }

    public void setHomeScreen(@NonNull WallpaperRequest request, @NonNull MethodChannel.Result result) {
        submitWallpaperTask(request, result, WallpaperTarget.HOME);
    }

    public void setLockScreen(@NonNull WallpaperRequest request, @NonNull MethodChannel.Result result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            result.error("UNSUPPORTED_ANDROID_VERSION", "Lock screen wallpaper requires Android 7.0 (API 24) or newer.", null);
            return;
        }
        submitWallpaperTask(request, result, WallpaperTarget.LOCK);
    }

    public void setHomeLockScreen(@NonNull WallpaperRequest request, @NonNull MethodChannel.Result result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            result.error("UNSUPPORTED_ANDROID_VERSION", "Setting both home and lock screen wallpaper requires Android 7.0 (API 24) or newer.", null);
            return;
        }
        submitWallpaperTask(request, result, WallpaperTarget.BOTH);
    }

    private void submitWallpaperTask(@NonNull WallpaperRequest request, @NonNull MethodChannel.Result result, @NonNull WallpaperTarget target) {
        if (executorService == null) {
            result.error("PLUGIN_DETACHED", "Plugin has been detached from the engine", null);
            return;
        }
        final Context appContext = context;
        if (appContext == null) {
            result.error("PLUGIN_DETACHED", "Context is null; plugin may have been detached.", null);
            return;
        }

        executorService.submit(() -> setWallpaperOnBackgroundThread(appContext, request, result, target));
    }

    private void setWallpaperOnBackgroundThread(Context appContext, WallpaperRequest request, MethodChannel.Result result, WallpaperTarget target) {
        Bitmap bitmap = null;
        try {
            File file = GetFile(request.location, appContext, request.imageName, request.fileExtension);
            if (file == null) {
                result.error("STORAGE_UNAVAILABLE", "Could not resolve storage path for location " + request.location + ".", null);
                return;
            }
            if (!file.exists()) {
                result.error("FILE_NOT_FOUND", "Image file not found: " + file.getAbsolutePath() + ". Download the image first.", null);
                return;
            }
            bitmap = resizeBitmap(file, (int) request.maxWidth, (int) request.maxHeight, request.options, request.fit, request.alignmentX, request.alignmentY);
            if (bitmap == null) {
                result.error("DECODE_ERROR", "Failed to decode image file. File may be corrupted or not a supported image format.", null);
                return;
            }

            WallpaperManager wm = WallpaperManager.getInstance(appContext);
            switch (target) {
                case HOME:
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        wm.setBitmap(bitmap, null, true, FLAG_SYSTEM);
                    } else {
                        wm.setBitmap(bitmap);
                    }
                    result.success("Home Screen Set Successfully");
                    break;
                case LOCK:
                    wm.setBitmap(bitmap, null, true, FLAG_LOCK);
                    result.success("Lock Screen Set Successfully");
                    break;
                case BOTH:
                    wm.setBitmap(bitmap, null, true, FLAG_SYSTEM);
                    wm.setBitmap(bitmap, null, true, FLAG_LOCK);
                    result.success("Home and Lock Screen Set Successfully");
                    break;
            }
        } catch (IOException e) {
            result.error("SET_WALLPAPER_FAILED", "Failed to set wallpaper: " + e.getMessage(), null);
        } catch (SecurityException e) {
            result.error("PERMISSION_DENIED", "Permission denied for setting wallpaper: " + e.getMessage(), null);
        } catch (Exception e) {
            result.error(target.errorCode, "Unexpected error setting wallpaper: " + e.getMessage(), null);
        } finally {
            recycleBitmap(bitmap);
        }
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        attachActivity(binding);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        detachActivity(true);
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        attachActivity(binding);
    }

    @Override
    public void onDetachedFromActivity() {
        detachActivity(true);
    }

    private void attachActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
        activityPluginBinding = binding;
        activityResultListener = (requestCode, resultCode, data) -> {
            if (requestCode == SYSTEM_WALLPAPER_REQUEST_CODE && pendingSystemWallpaperResult != null) {
                String message;
                if (resultCode == Activity.RESULT_OK) {
                    message = "System Screen Set Successfully";
                } else if (resultCode == Activity.RESULT_CANCELED) {
                    message = "Setting Wallpaper Cancelled";
                } else {
                    message = "Something Went Wrong";
                }
                pendingSystemWallpaperResult.success(message);
                pendingSystemWallpaperResult = null;
                return true;
            }
            return false;
        };
        binding.addActivityResultListener(activityResultListener);
    }

    private void detachActivity(boolean completePendingResult) {
        if (activityPluginBinding != null && activityResultListener != null) {
            activityPluginBinding.removeActivityResultListener(activityResultListener);
        }
        activityPluginBinding = null;
        activityResultListener = null;
        activity = null;
        if (completePendingResult && pendingSystemWallpaperResult != null) {
            pendingSystemWallpaperResult.error("DETACHED", "Activity detached before wallpaper selection completed", null);
            pendingSystemWallpaperResult = null;
        }
    }

    static class WallpaperFileRequest {
        final int location;
        final String imageName;
        final String fileExtension;

        WallpaperFileRequest(int location, String imageName, String fileExtension) {
            this.location = location;
            this.imageName = imageName;
            this.fileExtension = fileExtension;
        }
    }

    static final class WallpaperRequest extends WallpaperFileRequest {
        final double maxWidth;
        final double maxHeight;
        final WallpaperHelper.RequestSizeOptions options;
        final WallpaperHelper.WallpaperFit fit;
        final double alignmentX;
        final double alignmentY;

        WallpaperRequest(int location, String imageName, String fileExtension, double maxWidth, double maxHeight, WallpaperHelper.RequestSizeOptions options, WallpaperHelper.WallpaperFit fit, double alignmentX, double alignmentY) {
            super(location, imageName, fileExtension);
            this.maxWidth = maxWidth;
            this.maxHeight = maxHeight;
            this.options = options;
            this.fit = fit;
            this.alignmentX = alignmentX;
            this.alignmentY = alignmentY;
        }
    }

    private enum WallpaperTarget {
        HOME("HOME_SCREEN_FAILED"),
        LOCK("LOCK_SCREEN_FAILED"),
        BOTH("BOTH_SCREEN_FAILED");

        final String errorCode;

        WallpaperTarget(String errorCode) {
            this.errorCode = errorCode;
        }
    }
}
