package com.prateektimer.wallpaper;

import static androidx.core.content.FileProvider.getUriForFile;

import android.content.Context;
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;

import java.io.File;

import io.flutter.Log;

public final class WallpaperHelper {
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
        if (file == null || options == null) {
            return null;
        }
        Bitmap bitmap = BitmapFactory.decodeFile(file.getAbsolutePath());
        // decodeFile can return null for invalid/unreadable images; avoid NPE.
        if (bitmap == null) {
            return null;
        }
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

                int finalWidth = (int) maxWidth;
                int finalHeight = (int) maxHeight;

                Bitmap resized = null;
                if (options == RequestSizeOptions.RESIZE_EXACT) {
                    // Fix: Scale to requested dimensions (finalWidth/finalHeight), not original width/height.
                    resized = Bitmap.createScaledBitmap(bitmap, finalWidth, finalHeight, false);
                    bitmap.recycle();
                    return resized;
                } else {
                    if (ratioMax > ratioBitmap) {
                        finalWidth = (int) ((float) maxHeight * ratioBitmap);
                    } else {
                        finalHeight = (int) ((float) maxWidth / ratioBitmap);
                    }
                    Bitmap scaled = Bitmap.createScaledBitmap(bitmap, finalWidth, finalHeight, true);
                    // Fix: Recycle original to avoid bitmap memory leak.
                    bitmap.recycle();
                    return scaled;
                }
            }
            return bitmap;

        } catch (Exception e) {
            Log.w("AIC", "Failed to resize cropped image, return bitmap before resize", e);
        }
        return bitmap;
    }

    /**
     * Returns a content URI for the given file for use with FileProvider.
     * Returns null if context or file is null, or if the provider authority is not available.
     */
    public static Uri getImageContentUri(Context context, File file) {
        if (context == null || file == null) {
            return null;
        }
        try {
            String authority = context.getPackageName() + ".com.prateektimer.wallpaper.provider";
            return getUriForFile(context, authority, file);
        } catch (IllegalArgumentException e) {
            Log.w("WallpaperHelper", "FileProvider failed for file: " + file.getPath(), e);
            return null;
        }
    }

    /**
     * Resolves the file path for the given download location. Returns null if context is null
     * or if the requested storage directory is not available (e.g. external storage unmounted).
     */
    public static File GetFile(int location, Context activity, String imageName, String ext) {
        if (activity == null || imageName == null || ext == null) {
            return null;
        }
        File dir;
        switch (location) {
            case 0:
                dir = activity.getCacheDir();
                break;
            case 1:
                dir = activity.getFilesDir();
                break;
            case 2:
            default:
                dir = activity.getExternalFilesDir(null);
                break;
        }
        if (dir == null) {
            return null;
        }
        return new File(dir, imageName + "." + ext);
    }

    enum RequestSizeOptions {
        RESIZE_FIT,
        RESIZE_INSIDE,
        RESIZE_EXACT,
        RESIZE_CENTRE_CROP
    }
}
