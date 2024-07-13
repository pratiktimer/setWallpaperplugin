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
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class WallpaperPlugin extends FlutterActivity implements FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {

    WallpaperManager wallpaperManager;
    double maxWidth, maxHeight;
    int options, location;
    String imageName = "myimage";
    String fileExtension ="jpeg";
    private Context context;
    private MethodChannel channel;
    private String result = "";
    private FlutterActivity activity;
    private ExecutorService executorService;

    public WallpaperPlugin() {
        executorService = Executors.newSingleThreadExecutor();
    }

    @SuppressWarnings("deprecation")
    public static void registerWith(io.flutter.plugin.common.PluginRegistry.Registrar registrar) {
        WallpaperPlugin instance = new WallpaperPlugin();
        instance.channel = new MethodChannel(registrar.messenger(), "com.prateektimer.wallpaper/wallpaper");
        instance.channel.setMethodCallHandler(instance);
        instance.context = registrar.context();
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
                maxWidth = call.argument("maxWidth");
                maxHeight = call.argument("maxHeight");
                options = call.argument("RequestSizeOptions");
                location = call.argument("location");
                imageName = call.argument("imageName");
                imageName = imageName == null ? "myimage" : imageName;
                fileExtension = call.argument("fileExtension");

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
                location = call.argument("location");
                imageName = call.argument("imageName");
                imageName = imageName == null ? "myimage" : imageName;

                result.success(setSystemWallpaper());
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.M)
    private String setSystemWallpaper() {
        wallpaperManager = WallpaperManager.getInstance(activity);

        File file = GetFile(location, activity, imageName, fileExtension);
        Uri contentURI = getImageContentUri(activity, file);
        Intent intent = new Intent(wallpaperManager.getCropAndSetWallpaperIntent(contentURI));
        String mime = "image/*";
        intent.setDataAndType(contentURI, mime);
        try {
            result = "System Screen Set Successfully";
            activity.startActivityForResult(intent, 2);
        } catch (ActivityNotFoundException e) {
            // handle error
            result = e.toString();
        }
        return result;
    }

    @RequiresApi(api = Build.VERSION_CODES.N)
    public void setHomeScreen(@NonNull MethodChannel.Result result) {
        executorService.submit(() -> {
            try {
                wallpaperManager = WallpaperManager.getInstance(context);
                File file = GetFile(location, context, imageName, fileExtension);
                if (file != null && file.exists()) {
                    Bitmap bitmap = resizeBitmap(file, (int) maxWidth, (int) maxHeight, WallpaperHelper.RequestSizeOptions.values()[options]);
                    wallpaperManager.setBitmap(bitmap, null, true, FLAG_SYSTEM);
                    result.success("Home Screen Set Successfully");
                } else {
                    result.error("FILE_NOT_FOUND", "The Specified File Not Found", null);
                }
            } catch (Exception exception) {
                result.error("EXCEPTION", exception.toString(), null);
            }
        });
    }

    @RequiresApi(api = Build.VERSION_CODES.N)
    public void setLockScreen(@NonNull MethodChannel.Result result) {
        executorService.submit(() -> {
            try {
                wallpaperManager = WallpaperManager.getInstance(context);
                File file = GetFile(location, context, imageName, fileExtension);
                if (file != null && file.exists()) {
                    Bitmap bitmap = resizeBitmap(file, (int) maxWidth, (int) maxHeight, WallpaperHelper.RequestSizeOptions.values()[options]);
                    wallpaperManager.setBitmap(bitmap, null, true, FLAG_LOCK);
                    result.success("Lock Screen Set Successfully");
                } else {
                    result.error("FILE_NOT_FOUND", "The Specified File Not Found", null);
                }
            } catch (Exception exception) {
                result.error("EXCEPTION", exception.toString(), null);
            }
        });
    }

    @RequiresApi(api = Build.VERSION_CODES.N)
    public void setHomeLockScreen(@NonNull MethodChannel.Result result) {
        executorService.submit(() -> {
            try {
                wallpaperManager = WallpaperManager.getInstance(context);
                File file = GetFile(location, context, imageName, fileExtension);
                if (file != null && file.exists()) {
                    Bitmap bitmap = resizeBitmap(file, (int) maxWidth, (int) maxHeight, WallpaperHelper.RequestSizeOptions.values()[options]);
                    wallpaperManager.setBitmap(bitmap, null, true, FLAG_SYSTEM);
                    wallpaperManager.setBitmap(bitmap, null, true, FLAG_LOCK);
                    result.success("Home and Lock Screen Set Successfully");
                } else {
                    result.error("FILE_NOT_FOUND", "The Specified File Not Found", null);
                }
            } catch (Exception exception) {
                result.error("EXCEPTION", exception.toString(), null);
            }
        });
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (resultCode == RESULT_OK) {
            result = "System Screen Set Successfully";
        } else if (resultCode == RESULT_CANCELED) {
            result = "Setting Wallpaper Cancelled";
        } else {
            result = "Something Went Wrong";
        }
        super.onActivityResult(requestCode, resultCode, data);
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = (FlutterActivity) binding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    }

    @Override
    public void onDetachedFromActivity() {
    }
}
