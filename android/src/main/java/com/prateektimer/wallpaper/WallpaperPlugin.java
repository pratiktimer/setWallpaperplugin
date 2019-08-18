package com.prateektimer.wallpaper;
import android.Manifest;
import android.app.WallpaperManager;
import android.content.ActivityNotFoundException;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.MediaStore;

import androidx.annotation.NonNull;

import java.io.File;
import java.io.IOException;

import io.flutter.Log;
import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** WallpaperPlugin */
public class WallpaperPlugin extends FlutterActivity implements MethodCallHandler {
    public static final int MY_PERMISSIONS_REQUEST_READ_EXTERNAL_STORAGE = 123;
    private final MethodChannel channel;
    private int id;
    private String res = "";
    FlutterActivity activity;
    private final Registrar mRegistrar;


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        this.channel.setMethodCallHandler(this);
    }
    private Context getActiveContext() {
        return (mRegistrar.activity() != null) ? mRegistrar.activity() : mRegistrar.context();
    }

    /**
     * HomeScreen
     * Plugin registration.
     */

    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "wallpaper");
        channel.setMethodCallHandler(new WallpaperPlugin((FlutterActivity) registrar.activity(), channel, registrar));
    }

    private WallpaperPlugin(FlutterActivity activity, MethodChannel channel, Registrar mRegistrar) {
        this.activity = activity;
        this.channel = channel;
        this.mRegistrar = mRegistrar;
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
                result.success(setWallpaper(2, (String) call.arguments));
                break;
            case "Both":
                result.success(setWallpaper(3, (String) call.arguments));
                break;
            case "SystemWallpaer":
                result.success(setWallpaper(4,(String) call.arguments));
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private String setWallpaper(int i, String path) {
        id = i;
        WallpaperManager wallpaperManager = WallpaperManager.getInstance(activity);

        File file = new File(activity.getExternalFilesDir(null),path);
        //File file = new File(Activity.ge);
        //Activity.getDir("flutter", 0).getPath()
        // set bitmap to wallpaper
        Bitmap bitmap = BitmapFactory.decodeFile(file.getAbsolutePath());
        if (id == 1) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_SYSTEM);
                    res = "Home Screen Set Successfully";
                } else {
                    res = "To Set Home Screen Requires Api Level 24";
                }


            } catch (IOException ex) {
                ex.printStackTrace();
            }
        } else if (id == 2) try {

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_LOCK);
                res = "Lock Screen Set Successfully";
            } else {
                res = "To Set Lock Screen Requires Api Level 24";
            }


        } catch (IOException e) {
            res = e.toString();
            e.printStackTrace();
        }
        else if (id == 3) {
            try {
                wallpaperManager.setBitmap(bitmap);
                res = "Home And Lock Screen Set Successfully";
            } catch (IOException e) {
                res = e.toString();
                e.printStackTrace();
            }

        }
else if(id==4){
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (activity.checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE)
                        != PackageManager.PERMISSION_GRANTED&&
                        activity.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE)
                                != PackageManager.PERMISSION_GRANTED) {
                    activity.requestPermissions(new String[]{Manifest.permission.READ_EXTERNAL_STORAGE,Manifest.permission.WRITE_EXTERNAL_STORAGE},1);
                }
                else {
                    Uri uri = Uri.fromFile(file);
                    Uri contentURI = getImageContentUri(getActiveContext(), file);

                    Intent intent = new Intent(wallpaperManager.getCropAndSetWallpaperIntent(contentURI));
                    String mime = "image/*";
                    if (intent != null) {
                        intent.setDataAndType(contentURI, mime);
                    }
                    try {
                        mRegistrar.activity().startActivityForResult(intent,2);
                    } catch (ActivityNotFoundException e) {
                        //handle error
                        res = "Error To Set Wallpaer";
                    }
                }
            }
        }

        return res;
    }

    public static Uri getImageContentUri(Context context, File imageFile) {
        String filePath = imageFile.getAbsolutePath();
        Log.d("Tag",filePath);
        Cursor cursor = context.getContentResolver().query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                new String[]{MediaStore.Images.Media._ID},
                MediaStore.Images.Media.DATA + "=? ",
                new String[]{filePath}, null);

        if (cursor != null && cursor.moveToFirst()) {
            int id = cursor.getInt(cursor
                    .getColumnIndex(MediaStore.MediaColumns._ID));
            Uri baseUri = Uri.parse("content://media/external/images/media");
            return Uri.withAppendedPath(baseUri, "" + id);
        } else {
            if (imageFile.exists()) {
                ContentValues values = new ContentValues();
                values.put(MediaStore.Images.Media.DATA, filePath);
                return context.getContentResolver().insert(
                        MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values);
            } else {
                return null;
            }
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        Log.d("Tag","resultcode="+resultCode+"requestcode="+requestCode);
        if(resultCode==RESULT_OK){
            res = "System Screen Set Successfully";
        }
        else if(resultCode==RESULT_CANCELED){
            res="setting Wallpaper Cancelled";
        }
        else{
            res = "Something Went Wrong";
        }
        super.onActivityResult(requestCode, resultCode, data);
    }
}