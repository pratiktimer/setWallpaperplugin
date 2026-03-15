package com.prateektimer.wallpaper;

import static android.app.WallpaperManager.FLAG_LOCK;
import static android.app.WallpaperManager.FLAG_SYSTEM;
import static com.prateektimer.wallpaper.WallpaperHelper.GetFile;
import static com.prateektimer.wallpaper.WallpaperHelper.getImageContentUri;
import static com.prateektimer.wallpaper.WallpaperHelper.resizeBitmap;

import android.Manifest;
import android.app.WallpaperManager;
import android.content.ActivityNotFoundException;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Build;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import java.io.File;
import java.io.IOException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

public class WallpaperPlugin extends FlutterActivity implements FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {

    /** Request code for system wallpaper picker; must match value used in startActivityForResult. */
    private static final int SYSTEM_WALLPAPER_REQUEST_CODE = 2;

    /** Valid range for RequestSizeOptions enum index (0..3). */
    private static final int REQUEST_SIZE_OPTIONS_MAX_INDEX = 3;

    /** Valid range for DownloadLocation (0=temporary, 1=application, 2=external). */
    private static final int LOCATION_MAX_INDEX = 2;

    WallpaperManager wallpaperManager;
    double maxWidth, maxHeight;
    int options, location;
    String imageName = "myimage";
    String fileExtension ="jpeg";
    private Context context;
    private MethodChannel channel;
    private FlutterActivity activity;
    private ExecutorService executorService;
    /** Pending result for SystemWallpaper; completed when the system wallpaper activity returns. */
    private MethodChannel.Result pendingSystemWallpaperResult;
    /** Listener for activity result; registered so we receive result from system wallpaper UI. */
    private PluginRegistry.ActivityResultListener activityResultListener;
    private ActivityPluginBinding activityPluginBinding;

    public WallpaperPlugin() {
        executorService = Executors.newSingleThreadExecutor();
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        channel = new MethodChannel(binding.getBinaryMessenger(), "com.prateektimer.wallpaper/wallpaper");
        context = binding.getApplicationContext();
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        channel = null;
        // Fix: Shutdown executor to avoid thread leak when plugin is detached.
        if (executorService != null) {
            executorService.shutdown();
            executorService = null;
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.N)
    @Override
    public void onMethodCall(MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "getPlatformVersion":
                result.success("" + Build.VERSION.RELEASE);
                break;
            case "HomeScreen":
            case "LockScreen":
            case "Both":
                if (context == null) {
                    result.error("PLUGIN_DETACHED", "Plugin not attached to engine; context is null.", null);
                    break;
                }
                Double maxWidthObj = call.argument("maxWidth");
                Double maxHeightObj = call.argument("maxHeight");
                maxWidth = (maxWidthObj != null) ? maxWidthObj : 0;
                maxHeight = (maxHeightObj != null) ? maxHeightObj : 0;
                Integer optionsObj = call.argument("RequestSizeOptions");
                Integer locationObj = call.argument("location");
                if (locationObj == null || locationObj < 0 || locationObj > LOCATION_MAX_INDEX) {
                    result.error("INVALID_ARGUMENT", "location must be 0 (temporary), 1 (application), or 2 (external).", null);
                    break;
                }
                location = locationObj;
                imageName = call.argument("imageName");
                imageName = (imageName != null && !imageName.isEmpty()) ? imageName : "myimage";
                fileExtension = call.argument("fileExtension");
                fileExtension = (fileExtension != null && !fileExtension.isEmpty()) ? fileExtension : "jpeg";

                if (optionsObj == null || optionsObj < 0 || optionsObj > REQUEST_SIZE_OPTIONS_MAX_INDEX) {
                    result.error("INVALID_ARGUMENT", "RequestSizeOptions must be 0-3 (resizeFit, resizeInside, resizeExact, resizeCentreCrop).", null);
                    break;
                }
                options = optionsObj;

                switch (call.method) {
                    case "HomeScreen":
                        setHomeScreen(result);
                        break;
                    case "LockScreen":
                        setLockScreen(result);
                        break;
                    case "Both":
                        setHomeLockScreen(result);
                        break;
                    default:
                        result.notImplemented();
                        break;
                }
                break;
            case "SystemWallpaper":
                Integer systemLocationObj = call.argument("location");
                if (systemLocationObj == null || systemLocationObj < 0 || systemLocationObj > LOCATION_MAX_INDEX) {
                    result.error("INVALID_ARGUMENT", "location must be 0 (temporary), 1 (application), or 2 (external).", null);
                    break;
                }
                location = systemLocationObj;
                imageName = call.argument("imageName");
                imageName = (imageName != null && !imageName.isEmpty()) ? imageName : "myimage";
                fileExtension = call.argument("fileExtension");
                fileExtension = (fileExtension != null && !fileExtension.isEmpty()) ? fileExtension : "jpeg";
                setSystemWallpaper(result);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    /**
     * Starts the system wallpaper picker and completes the given result when the user finishes.
     * Returns meaningful errors for null activity, missing file, or provider/security issues.
     */
    @RequiresApi(api = Build.VERSION_CODES.M)
    private void setSystemWallpaper(@NonNull MethodChannel.Result result) {
        if (activity == null) {
            result.error("NO_ACTIVITY", "Plugin not attached to an activity. Cannot open system wallpaper picker.", null);
            return;
        }
        try {
            File file = GetFile(location, activity, imageName, fileExtension);
            if (file == null) {
                result.error("STORAGE_UNAVAILABLE", "Could not resolve storage path for location " + location + ". External storage may be unmounted.", null);
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

    @RequiresApi(api = Build.VERSION_CODES.N)
    public void setHomeScreen(@NonNull MethodChannel.Result result) {
        if (executorService == null) {
            result.error("PLUGIN_DETACHED", "Plugin has been detached from the engine", null);
            return;
        }
        executorService.submit(() -> {
            try {
                if (context == null) {
                    result.error("PLUGIN_DETACHED", "Context is null; plugin may have been detached.", null);
                    return;
                }
                File file = GetFile(location, context, imageName, fileExtension);
                if (file == null) {
                    result.error("STORAGE_UNAVAILABLE", "Could not resolve storage path for location " + location + ".", null);
                    return;
                }
                if (!file.exists()) {
                    result.error("FILE_NOT_FOUND", "Image file not found: " + file.getAbsolutePath() + ". Download the image first.", null);
                    return;
                }
                Bitmap bitmap = resizeBitmap(file, (int) maxWidth, (int) maxHeight, WallpaperHelper.RequestSizeOptions.values()[options]);
                if (bitmap == null) {
                    result.error("DECODE_ERROR", "Failed to decode image file. File may be corrupted or not a supported image format.", null);
                    return;
                }
                WallpaperManager wm = WallpaperManager.getInstance(context);
                wm.setBitmap(bitmap, null, true, FLAG_SYSTEM);
                result.success("Home Screen Set Successfully");
            } catch (IOException e) {
                result.error("SET_WALLPAPER_FAILED", "Failed to set home screen wallpaper: " + e.getMessage(), null);
            } catch (SecurityException e) {
                result.error("PERMISSION_DENIED", "Permission denied for setting wallpaper: " + e.getMessage(), null);
            } catch (Exception e) {
                result.error("HOME_SCREEN_FAILED", "Unexpected error setting home screen: " + e.getMessage(), null);
            }
        });
    }

    @RequiresApi(api = Build.VERSION_CODES.N)
    public void setLockScreen(@NonNull MethodChannel.Result result) {
        if (executorService == null) {
            result.error("PLUGIN_DETACHED", "Plugin has been detached from the engine", null);
            return;
        }
        executorService.submit(() -> {
            try {
                if (context == null) {
                    result.error("PLUGIN_DETACHED", "Context is null; plugin may have been detached.", null);
                    return;
                }
                File file = GetFile(location, context, imageName, fileExtension);
                if (file == null) {
                    result.error("STORAGE_UNAVAILABLE", "Could not resolve storage path for location " + location + ".", null);
                    return;
                }
                if (!file.exists()) {
                    result.error("FILE_NOT_FOUND", "Image file not found: " + file.getAbsolutePath() + ". Download the image first.", null);
                    return;
                }
                Bitmap bitmap = resizeBitmap(file, (int) maxWidth, (int) maxHeight, WallpaperHelper.RequestSizeOptions.values()[options]);
                if (bitmap == null) {
                    result.error("DECODE_ERROR", "Failed to decode image file. File may be corrupted or not a supported image format.", null);
                    return;
                }
                WallpaperManager wm = WallpaperManager.getInstance(context);
                wm.setBitmap(bitmap, null, true, FLAG_LOCK);
                result.success("Lock Screen Set Successfully");
            } catch (IOException e) {
                result.error("SET_WALLPAPER_FAILED", "Failed to set lock screen wallpaper: " + e.getMessage(), null);
            } catch (SecurityException e) {
                result.error("PERMISSION_DENIED", "Permission denied for setting wallpaper: " + e.getMessage(), null);
            } catch (Exception e) {
                result.error("LOCK_SCREEN_FAILED", "Unexpected error setting lock screen: " + e.getMessage(), null);
            }
        });
    }

    @RequiresApi(api = Build.VERSION_CODES.N)
    public void setHomeLockScreen(@NonNull MethodChannel.Result result) {
        if (executorService == null) {
            result.error("PLUGIN_DETACHED", "Plugin has been detached from the engine", null);
            return;
        }
        executorService.submit(() -> {
            try {
                if (context == null) {
                    result.error("PLUGIN_DETACHED", "Context is null; plugin may have been detached.", null);
                    return;
                }
                File file = GetFile(location, context, imageName, fileExtension);
                if (file == null) {
                    result.error("STORAGE_UNAVAILABLE", "Could not resolve storage path for location " + location + ".", null);
                    return;
                }
                if (!file.exists()) {
                    result.error("FILE_NOT_FOUND", "Image file not found: " + file.getAbsolutePath() + ". Download the image first.", null);
                    return;
                }
                Bitmap bitmap = resizeBitmap(file, (int) maxWidth, (int) maxHeight, WallpaperHelper.RequestSizeOptions.values()[options]);
                if (bitmap == null) {
                    result.error("DECODE_ERROR", "Failed to decode image file. File may be corrupted or not a supported image format.", null);
                    return;
                }
                WallpaperManager wm = WallpaperManager.getInstance(context);
                wm.setBitmap(bitmap, null, true, FLAG_SYSTEM);
                wm.setBitmap(bitmap, null, true, FLAG_LOCK);
                result.success("Home and Lock Screen Set Successfully");
            } catch (IOException e) {
                result.error("SET_WALLPAPER_FAILED", "Failed to set wallpaper: " + e.getMessage(), null);
            } catch (SecurityException e) {
                result.error("PERMISSION_DENIED", "Permission denied for setting wallpaper: " + e.getMessage(), null);
            } catch (Exception e) {
                result.error("BOTH_SCREEN_FAILED", "Unexpected error setting home and lock screen: " + e.getMessage(), null);
            }
        });
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = (FlutterActivity) binding.getActivity();
        activityPluginBinding = binding;
        // Fix: Register listener so we receive the system wallpaper activity result and complete
        // the pending method channel result (instead of returning success before user confirms).
        activityResultListener = (requestCode, resultCode, data) -> {
            if (requestCode == SYSTEM_WALLPAPER_REQUEST_CODE && pendingSystemWallpaperResult != null) {
                String message;
                if (resultCode == android.app.Activity.RESULT_OK) {
                    message = "System Screen Set Successfully";
                } else if (resultCode == android.app.Activity.RESULT_CANCELED) {
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

    @Override
    public void onDetachedFromActivityForConfigChanges() {
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    }

    @Override
    public void onDetachedFromActivity() {
        if (activityPluginBinding != null && activityResultListener != null) {
            activityPluginBinding.removeActivityResultListener(activityResultListener);
        }
        activityPluginBinding = null;
        activityResultListener = null;
        activity = null;
        if (pendingSystemWallpaperResult != null) {
            pendingSystemWallpaperResult.error("DETACHED", "Activity detached before wallpaper selection completed", null);
            pendingSystemWallpaperResult = null;
        }
    }
}
