package com.prateektimer.wallpaper;
import android.app.Activity;
import android.app.WallpaperManager;
import android.graphics.Bitmap;
import android.graphics.drawable.Drawable;
import android.os.Build;

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
  Activity activity;
  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "wallpaper");
    channel.setMethodCallHandler(new WallpaperPlugin(registrar.activity(),channel));
  }
  WallpaperPlugin(Activity activity,MethodChannel channel){
    this.activity=activity;
    this.channel=channel;
    this.channel.setMethodCallHandler(this);
  }
  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (call.method.equals("getPlatformVersion")) {
      result.success("Asus Zenfone max pro m2" + android.os.Build.VERSION.RELEASE);
    }
    else if(call.method.equals("HomeScreen")){
      result.success(setWallpaper(1,(String) call.arguments));
    }
    else if(call.method.equals("LockScreen")){
      result.success(setWallpaper(2,(String) call.arguments));
    }
    else if(call.method.equals("Both")){
      result.success(setWallpaper(3,(String) call.arguments));
    }
    else {
      result.notImplemented();
    }
  }
  private String setWallpaper(int i,String path) {
    id=i;
    Picasso.get().load(path).into(target);
    return res;
  }
  private Target target = new Target() {
    @Override
    public void onBitmapLoaded(Bitmap bitmap, Picasso.LoadedFrom from) {
      WallpaperManager wallpaperManager = WallpaperManager.getInstance(activity);
      if(id==1) {
        try {
          wallpaperManager.setBitmap(bitmap);
          res="Home Screen Is Set Successfully!";
        } catch (IOException ex) {
          ex.printStackTrace();
        }
      }
      else if(id==2){
        //if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
          try {
            wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_LOCK);
            res="Lock Screen Is Set Successfully!";
          } catch (IOException e) {
            res=e.toString();
            e.printStackTrace();
          }
       // }
      }
      else if(id==3){
        try {
          wallpaperManager.setBitmap(bitmap);
        } catch (IOException e) {
          res=e.toString();
          e.printStackTrace();
        }
       // if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
          try {
            wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_LOCK);
            res="Home And Lock Screen Are Set Successfully!";
          } catch (IOException e) {
            res=e.toString();
            e.printStackTrace();
        //  }
        }
      }

    }
    @Override
    public void onBitmapFailed(Exception e, Drawable errorDrawable) {
    }
    @Override
    public void onPrepareLoad(Drawable placeHolderDrawable) {
    }
  };

}
