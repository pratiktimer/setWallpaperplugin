package com.prateektimer.wallpaper;
import android.app.Activity;
import android.app.WallpaperManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Build;
import androidx.annotation.NonNull;
import java.io.File;
import java.io.IOException;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** WallpaperPlugin */
public class WallpaperPlugin implements MethodCallHandler {
    private final MethodChannel channel;
    private int id;
    private String res = "";
    private Activity activity;

    /**HomeScreen
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "wallpaper");
        channel.setMethodCallHandler(new WallpaperPlugin(registrar.activity(), channel));
    }

    private WallpaperPlugin(Activity activity, MethodChannel channel) {
        this.activity = activity;
        this.channel = channel;
        this.channel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "getPlatformVersion":
                result.success("" + Build.VERSION.RELEASE);
                break;
            case "HomeScreen":
                result.success(setWallpaper(1, (String) call.arguments));
                break;
            case "LockScreen":
                result.success( setWallpaper(2, (String) call.arguments));
                break;
            case "Both":
                result.success(setWallpaper(3, (String) call.arguments));
                break;
            default:
                result.notImplemented();
                break;
        }
    }
    private String setWallpaper(int i, String path) {
        id=i;
        File imgFile = new  File(activity.getCacheDir(), path);
        // set bitmap to wallpaper
        Bitmap bitmap = BitmapFactory.decodeFile(imgFile.getAbsolutePath());
        WallpaperManager wallpaperManager = WallpaperManager.getInstance(activity);
        if (id == 1) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_SYSTEM);
                    res="Home Screen Set Successfully";
                }
                else{
                    res="To Set Home Screen Requires Api Level 24";
                }


            } catch (IOException ex) {
                ex.printStackTrace();
            }
        }
        else if (id == 2) try {

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_LOCK);
                res="Lock Screen Set Successfully";
            }
            else {
                res="To Set Lock Screen Requires Api Level 24";
            }


        } catch (IOException e) {
            res = e.toString();
            e.printStackTrace();
        }
        else if (id == 3) {
            try {
                wallpaperManager.setBitmap(bitmap);
                res="Home And Lock Screen Set Successfully";
            } catch (IOException e) {
                res = e.toString();
                e.printStackTrace();
            }

        }
        return res;

    }
}

