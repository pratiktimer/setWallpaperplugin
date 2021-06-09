package com.prateektimer.wallpaper;

import android.content.ContentValues;
import android.content.Context;
import android.content.res.Resources;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.provider.MediaStore;

import java.io.File;

import io.flutter.Log;

public final class WallpaperHelper
{
    enum RequestSizeOptions {
        RESIZE_FIT,
        RESIZE_INSIDE,
        RESIZE_EXACT,
        RESIZE_CENTRE_CROP
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

    static Bitmap resizeBitmap(File file, int maxWidth, int maxHeight, RequestSizeOptions options) {
        Bitmap bitmap = BitmapFactory.decodeFile(file.getAbsolutePath());
        try {
            maxWidth = getScreenWidth(maxWidth);
            maxHeight = getScreenHeight(maxHeight);

            if (maxWidth > 0 && maxHeight > 0 &&
                    (options == RequestSizeOptions.RESIZE_FIT ||
                            options == RequestSizeOptions.RESIZE_INSIDE ||
                            options == RequestSizeOptions.RESIZE_EXACT ||
                            options == RequestSizeOptions.RESIZE_CENTRE_CROP)) {


                int width = bitmap.getWidth();
                int height = bitmap.getHeight();
                float ratioBitmap = (float) width / (float) height;
                float ratioMax = (float) maxWidth / (float) maxHeight;

                int finalWidth = maxWidth;
                int finalHeight = maxHeight;

                Bitmap resized = null;
                if (options == RequestSizeOptions.RESIZE_EXACT) {
                    resized = Bitmap.createScaledBitmap(bitmap, width, height, false);
                } else {

                    if (ratioMax > ratioBitmap) {
                        finalWidth = (int) ((float) maxHeight * ratioBitmap);
                    } else {
                        finalHeight = (int) ((float) maxWidth / ratioBitmap);
                    }
                    bitmap = Bitmap.createScaledBitmap(bitmap, finalWidth, finalHeight, true);

                }

                if (resized != null) {
                    if (resized != bitmap) {
                        bitmap.recycle();
                    }
                    return resized;
                }

            }
            return bitmap;

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

        if (cursor != null && cursor.moveToFirst())
        {
            int id = cursor.getInt(cursor
                    .getColumnIndex(MediaStore.MediaColumns._ID));
            Uri baseUri = Uri.parse("content://media/external/images/media");

            cursor.close();
            return Uri.withAppendedPath(baseUri, "" + id);
        }
        else
        {
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

    public static File GetFile(int location, Context activity, String imageName) {
        File file;
        switch (location) {
            case 0:
                file = new File(activity.getCacheDir(), imageName + ".jpeg");
                break;
            case 1:
                file = new File(activity.getFilesDir(), imageName + ".jpeg");
                break;
            case 2:
            default:
                file = new File(activity.getExternalFilesDir(null), imageName + ".jpeg");
                break;
        }
        return file;
    }
}
