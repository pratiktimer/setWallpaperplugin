package com.prateektimer.wallpaper;

import android.Manifest;
import android.app.WallpaperManager;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Build;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import java.io.File;

import io.flutter.Log;
import io.flutter.app.FlutterActivity;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import static com.prateektimer.wallpaper.WallpaperHelper.GetFile;
import static com.prateektimer.wallpaper.WallpaperHelper.getImageContentUri;
import static com.prateektimer.wallpaper.WallpaperHelper.resizeBitmap;

public class WallpaperPlugin extends FlutterActivity implements FlutterPlugin, MethodCallHandler {

    private MethodChannel channel;
    FlutterActivity activity;
    io.flutter.plugin.common.PluginRegistry.Registrar mRegistrar;
    WallpaperManager wallpaperManager;
    private String res = "";
    double maxWidth, maxHeight;
    int options, location;
    String imageName = "myimage";

    @SuppressWarnings("deprecation")
    public static void registerWith(io.flutter.plugin.common.PluginRegistry.Registrar registrar) {
        WallpaperPlugin instance = new WallpaperPlugin();
        instance.channel = new MethodChannel(registrar.messenger(), "wallpaper");
        instance.activity = (FlutterActivity) registrar.activity();
        instance.mRegistrar = registrar;
        instance.channel.setMethodCallHandler(instance);
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        channel = new MethodChannel(binding.getBinaryMessenger(), "wallpaper");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        channel = null;
    }

    @RequiresApi(api = Build.VERSION_CODES.N)
    @Override
    public void onMethodCall(MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "getPlatformVersion":
                result.success("" + Build.VERSION.RELEASE);
                break;
            case "HomeScreen":
                maxWidth = call.argument("maxWidth");
                maxHeight = call.argument("maxHeight");
                options = call.argument("RequestSizeOptions");
                location = call.argument("location");
                imageName = call.argument("imageName");
                result.success(setHomeScreen());
                break;
            case "LockScreen":
                maxWidth = call.argument("maxWidth");
                maxHeight = call.argument("maxHeight");
                options = call.argument("RequestSizeOptions");
                location = call.argument("location");
                imageName = call.argument("imageName");
                result.success(setLockScreen((int) maxWidth, (int) maxHeight, options));
                break;
            case "Both":
                maxWidth = call.argument("maxWidth");
                maxHeight = call.argument("maxHeight");
                options = call.argument("RequestSizeOptions");
                location = call.argument("location");
                imageName = call.argument("imageName");
                result.success(setHomeLockScreen((int) maxWidth, (int) maxHeight, options));
                break;
            case "SystemWallpaper":
                wallpaperManager = WallpaperManager.getInstance(activity);
                location = call.argument("location");

                if (activity.checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE)
                        != PackageManager.PERMISSION_GRANTED&&
                        activity.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE)
                                != PackageManager.PERMISSION_GRANTED) {
                    activity.requestPermissions(new String[]{Manifest.permission.READ_EXTERNAL_STORAGE,Manifest.permission.WRITE_EXTERNAL_STORAGE},1);
                }
                else {
                    File file = GetFile(location,activity,imageName);
                    Uri contentURI = getImageContentUri(activity,file);
                    Intent intent = new Intent(wallpaperManager.getCropAndSetWallpaperIntent(contentURI));
                    String mime = "image/*";
                    if (intent != null) {
                        intent.setDataAndType(contentURI, mime);
                    }
                    try {
                        mRegistrar.activity().startActivityForResult(intent,2);
                    } catch (ActivityNotFoundException e) {
                        //handle error
                        res = "Error To Set Wallpaper";
                    }
                }
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.N)
    public String setHomeScreen() {
        try {

            wallpaperManager = WallpaperManager.getInstance(activity);
            File file = GetFile(location,activity,imageName);
            if (file != null && file.exists()) {
                Bitmap bitmap = resizeBitmap(file, (int) maxWidth, (int) maxHeight, WallpaperHelper.RequestSizeOptions.values()[options]);
                wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_SYSTEM);
                return "Home Screen Set Successfully";
            } else {
                return "The Specified File Not Found";
            }

        } catch (Exception exception) {
            return exception.toString();
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.N)
    public String setLockScreen(int reqWidth, int reqHeight, int options) {
        try {

            wallpaperManager = WallpaperManager.getInstance(activity);
            File file = GetFile(location,activity,imageName);
            if (file != null && file.exists()) {
                Bitmap bitmap = resizeBitmap(file, reqWidth, reqHeight, WallpaperHelper.RequestSizeOptions.values()[options]);
                wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_LOCK);
                return "Lock Screen Set Successfully";
            } else {
                return "The Specified File Not Found";
            }

        } catch (Exception exception) {
            return exception.toString();
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.N)
    public String setHomeLockScreen(int reqWidth, int reqHeight, int options) {
        try {

            wallpaperManager = WallpaperManager.getInstance(activity);
            File file = GetFile(location,activity,imageName);
            if (file != null && file.exists()) {

                Bitmap bitmap = resizeBitmap(file, reqWidth, reqHeight, WallpaperHelper.RequestSizeOptions.values()[options]);
                wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_SYSTEM);
                return "Home and Lock Screen Set Successfully";
            } else {
                return "The Specified File Not Found";
            }

        } catch (Exception exception) {
            return exception.toString();
        }
    }
    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        Log.d("Tag","resultcode="+resultCode+"requestcode="+requestCode);
        if(resultCode==RESULT_OK){
            res = "System Screen Set Successfully";
        }
        else if(resultCode==RESULT_CANCELED){
            res="Setting Wallpaper Cancelled";
        }
        else{
            res = "Something Went Wrong";
        }
        super.onActivityResult(requestCode, resultCode, data);
    }

}