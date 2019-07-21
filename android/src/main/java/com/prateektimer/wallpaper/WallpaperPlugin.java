package com.prateektimer.wallpaper;
import android.app.Activity;
import android.app.WallpaperManager;
import android.graphics.Bitmap;
import android.graphics.drawable.Drawable;
import android.os.Build;
import android.support.annotation.NonNull;
import android.support.annotation.RequiresApi;
import android.widget.ImageView;

import com.squareup.picasso.Callback;
import com.squareup.picasso.Picasso;
import com.squareup.picasso.Target;
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
  private  String res="No Result";
  private Activity activity;
  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "wallpaper");
    channel.setMethodCallHandler(new WallpaperPlugin(registrar.activity(),channel));
  }
  private WallpaperPlugin(Activity activity, MethodChannel channel){
    this.activity=activity;
    this.channel=channel;
    this.channel.setMethodCallHandler(this);
  }
  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
      switch (call.method) {
          case "getPlatformVersion":
              result.success("" + Build.VERSION.RELEASE);
              break;
          case "HomeScreen":
              setWallpaper(1, (String) call.arguments);
              result.success(setFlag("home screen"));
              break;
          case "LockScreen":
              setWallpaper(2, (String) call.arguments);
              result.success(setFlag("lock screen"));
              break;
          case "Both":
              setWallpaper(3, (String) call.arguments);
              result.success(setFlag("Both screen"));
              break;
          default:
              result.notImplemented();
              break;
      }
  }

  private String setWallpaper(int i,String path) {
    id=i;
    try {
      Picasso.get().load(path).into(new Target() {
        @RequiresApi(api = Build.VERSION_CODES.N)
        @Override
        public void onBitmapLoaded(Bitmap bitmap, Picasso.LoadedFrom from) {
          WallpaperManager wallpaperManager = WallpaperManager.getInstance(activity);
          if (id == 1) {
            try {
              wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_SYSTEM);

            } catch (IOException ex) {
              ex.printStackTrace();
            }
          } else if (id == 2) {
            //if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
              wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_LOCK);


            } catch (IOException e) {
              res = e.toString();
              e.printStackTrace();
            }
            // }
          } else if (id == 3) {
            try {
              wallpaperManager.setBitmap(bitmap);

            } catch (IOException e) {
              res = e.toString();
              e.printStackTrace();
            }

          }

        }

        @Override
        public void onBitmapFailed(Exception e, Drawable errorDrawable) {

        }

        @Override
        public void onPrepareLoad(Drawable placeHolderDrawable) {
        }

      });
    }catch (Exception e){
     res=e.toString();
    }

    return res;

  }

  private String setFlag(String result) {
    res=result;
    return  res;
  }


}
