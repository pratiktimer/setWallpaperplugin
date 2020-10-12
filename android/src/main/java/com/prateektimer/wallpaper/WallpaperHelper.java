package com.prateektimer.wallpaper;

import android.content.ContentValues;
import android.content.Context;
import android.content.res.Resources;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Rect;
import android.net.Uri;
import android.provider.MediaStore;

import java.io.File;

import io.flutter.Log;
import io.flutter.app.FlutterActivity;

public class WallpaperHelper {
    enum RequestSizeOptions {
        RESIZE_FIT,
        RESIZE_INSIDE,
        RESIZE_EXACT,
        RESIZE_CENTRE_CROP;
    }

    public static int getScreenWidth(int reqWidth) {
        if (reqWidth == 0)
            return Resources.getSystem().getDisplayMetrics().widthPixels;
        return reqWidth;
    }

    public static int getScreenHeight(int reqHeight) {
        if (reqHeight == 0)
            return Resources.getSystem().getDisplayMetrics().heightPixels;
        return reqHeight;
    }

    static Bitmap resizeBitmap(File file, int reqWidth, int reqHeight, RequestSizeOptions options) {
        Bitmap bitmap = BitmapFactory.decodeFile(file.getAbsolutePath());
        try {
            reqWidth = getScreenWidth(reqWidth);
            reqHeight = getScreenHeight(reqHeight);
            if (reqWidth > 0 && reqHeight > 0 &&
                    (options == RequestSizeOptions.RESIZE_FIT ||
                            options == RequestSizeOptions.RESIZE_INSIDE ||
                            options == RequestSizeOptions.RESIZE_EXACT ||
                            options == RequestSizeOptions.RESIZE_CENTRE_CROP)) {

                Bitmap resized = null;
                if (options == RequestSizeOptions.RESIZE_EXACT) {
                    resized = Bitmap.createScaledBitmap(bitmap, reqWidth, reqHeight, false);
                } else {
                    int width = bitmap.getWidth();
                    int height = bitmap.getHeight();
                    float scale = Math.max(width / (float) reqWidth, height / (float) reqHeight);
                    if (scale > 1 || options == RequestSizeOptions.RESIZE_FIT) {
                        resized = Bitmap.createScaledBitmap(bitmap, (int) (width / scale), (int) (height / scale), false);
                    }
                    if (scale > 1 || options == RequestSizeOptions.RESIZE_CENTRE_CROP) {
                        int smaller_side = (height - width) > 0 ? width : height;
                        int half_smaller_side = smaller_side / 2;
                        Rect initialRect = new Rect(0, 0, width, height);
                        Rect finalRect = new Rect(initialRect.centerX() - half_smaller_side, initialRect.centerY() - half_smaller_side,
                                initialRect.centerX() + half_smaller_side, initialRect.centerY() + half_smaller_side);
                        bitmap = Bitmap.createBitmap(bitmap, finalRect.left, finalRect.top, finalRect.width(), finalRect.height(), null, true);
                        //keep in mind we have square as request for cropping, otherwise - it is useless
                        resized = Bitmap.createScaledBitmap(bitmap, reqWidth, reqHeight, false);
                    }

                }
                if (resized != null) {
                    if (resized != bitmap) {
                        bitmap.recycle();
                    }
                    return resized;
                }
            }
        } catch (Exception e) {
            Log.w("AIC", "Failed to resize cropped image, return bitmap before resize", e);
        }
        return bitmap;
    }

    public static Uri getImageContentUri(Context context, File imageFile) {
        String filePath = imageFile.getAbsolutePath();
        Log.d("Tag", filePath);
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

    public static File GetFile(int location, FlutterActivity activity, String imageName) {
        File file = null;
        switch (location)
        {
            case 0:
                file = new File(activity.getCacheDir(),imageName + ".jpeg");
                break;
            case 1:
                file = new File(activity.getFilesDir(),imageName + ".jpeg");
                break;
            case 2:
                file= new File(activity.getExternalFilesDir(null), imageName + ".jpeg");
                break;
            default:
                file= new File(activity.getExternalFilesDir(null), imageName + ".jpeg");
                break;
        }
        return  file;
    }


}
