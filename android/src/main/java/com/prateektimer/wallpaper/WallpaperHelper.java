package com.prateektimer.wallpaper;

import static androidx.core.content.FileProvider.getUriForFile;

import android.content.Context;
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
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
        return resizeBitmap(file, maxWidth, maxHeight, options, null, 0, 0);
    }

    static Bitmap resizeBitmap(File file, int maxWidth, int maxHeight, RequestSizeOptions options, WallpaperFit fit) {
        return resizeBitmap(file, maxWidth, maxHeight, options, fit, 0, 0);
    }

    static Bitmap resizeBitmap(File file, int maxWidth, int maxHeight, RequestSizeOptions options, WallpaperFit fit, double alignmentX, double alignmentY) {
        if (file == null || options == null) {
            return null;
        }

        maxWidth = getScreenWidth(maxWidth);
        maxHeight = getScreenHeight(maxHeight);

        BitmapFactory.Options decodeOptions = new BitmapFactory.Options();
        decodeOptions.inJustDecodeBounds = true;
        BitmapFactory.decodeFile(file.getAbsolutePath(), decodeOptions);
        if (decodeOptions.outWidth <= 0 || decodeOptions.outHeight <= 0) {
            return null;
        }

        decodeOptions.inJustDecodeBounds = false;
        decodeOptions.inSampleSize = calculateInSampleSize(decodeOptions, maxWidth, maxHeight);
        Bitmap bitmap = BitmapFactory.decodeFile(file.getAbsolutePath(), decodeOptions);
        if (bitmap == null) {
            return null;
        }
        try {
            if (fit != null) {
                return applyWallpaperFit(bitmap, maxWidth, maxHeight, fit, alignmentX, alignmentY);
            }

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
                    resized = Bitmap.createScaledBitmap(bitmap, finalWidth, finalHeight, false);
                    recycleIfDifferent(bitmap, resized);
                    return resized;
                } else {
                    if (ratioMax > ratioBitmap) {
                        finalWidth = (int) ((float) maxHeight * ratioBitmap);
                    } else {
                        finalHeight = (int) ((float) maxWidth / ratioBitmap);
                    }
                    Bitmap scaled = Bitmap.createScaledBitmap(bitmap, finalWidth, finalHeight, true);
                    recycleIfDifferent(bitmap, scaled);
                    return scaled;
                }
            }
            return bitmap;

        } catch (Exception e) {
            Log.w("AIC", "Failed to resize cropped image, return bitmap before resize", e);
        }
        return bitmap;
    }

    private static Bitmap applyWallpaperFit(Bitmap bitmap, int maxWidth, int maxHeight, WallpaperFit fit, double alignmentX, double alignmentY) {
        if (fit == WallpaperFit.NONE) {
            return bitmap;
        }

        int width = bitmap.getWidth();
        int height = bitmap.getHeight();
        if (width <= 0 || height <= 0 || maxWidth <= 0 || maxHeight <= 0) {
            return bitmap;
        }

        if (fit == WallpaperFit.FILL) {
            Bitmap resized = Bitmap.createScaledBitmap(bitmap, maxWidth, maxHeight, true);
            recycleIfDifferent(bitmap, resized);
            return resized;
        }

        if (fit == WallpaperFit.CENTER) {
            Bitmap canvasBitmap = Bitmap.createBitmap(maxWidth, maxHeight, Bitmap.Config.ARGB_8888);
            Canvas canvas = new Canvas(canvasBitmap);
            canvas.drawColor(Color.BLACK);
            float left = alignedOffset(maxWidth - width, alignmentX);
            float top = alignedOffset(maxHeight - height, alignmentY);
            canvas.drawBitmap(bitmap, left, top, null);
            recycleBitmap(bitmap);
            return canvasBitmap;
        }

        float scaleWidth = (float) maxWidth / (float) width;
        float scaleHeight = (float) maxHeight / (float) height;
        float scale = fit == WallpaperFit.COVER ? Math.max(scaleWidth, scaleHeight) : Math.min(scaleWidth, scaleHeight);
        int scaledWidth = Math.max(1, Math.round(width * scale));
        int scaledHeight = Math.max(1, Math.round(height * scale));
        Bitmap scaled = Bitmap.createScaledBitmap(bitmap, scaledWidth, scaledHeight, true);
        recycleIfDifferent(bitmap, scaled);

        if (fit == WallpaperFit.CONTAIN) {
            return scaled;
        }

        int cropLeft = alignedCropOffset(scaledWidth - maxWidth, alignmentX);
        int cropTop = alignedCropOffset(scaledHeight - maxHeight, alignmentY);
        int cropWidth = Math.min(maxWidth, scaledWidth - cropLeft);
        int cropHeight = Math.min(maxHeight, scaledHeight - cropTop);
        Bitmap cropped = Bitmap.createBitmap(scaled, cropLeft, cropTop, cropWidth, cropHeight);
        recycleIfDifferent(scaled, cropped);
        return cropped;
    }

    private static float alignedOffset(int availableSpace, double alignment) {
        return availableSpace * alignmentFactor(alignment);
    }

    private static int alignedCropOffset(int overflow, double alignment) {
        if (overflow <= 0) {
            return 0;
        }
        return clamp(Math.round(overflow * alignmentFactor(alignment)), 0, overflow);
    }

    private static float alignmentFactor(double alignment) {
        if (Double.isNaN(alignment) || Double.isInfinite(alignment)) {
            alignment = 0;
        }
        double clamped = Math.max(-1, Math.min(1, alignment));
        return (float) ((clamped + 1) / 2);
    }

    private static int clamp(int value, int min, int max) {
        return Math.max(min, Math.min(max, value));
    }

    private static int calculateInSampleSize(BitmapFactory.Options options, int reqWidth, int reqHeight) {
        int height = options.outHeight;
        int width = options.outWidth;
        int inSampleSize = 1;

        if (reqWidth <= 0 || reqHeight <= 0) {
            return inSampleSize;
        }

        while ((height / inSampleSize) > reqHeight * 2 || (width / inSampleSize) > reqWidth * 2) {
            inSampleSize *= 2;
        }

        return inSampleSize;
    }

    static void recycleBitmap(Bitmap bitmap) {
        if (bitmap != null && !bitmap.isRecycled()) {
            bitmap.recycle();
        }
    }

    private static void recycleIfDifferent(Bitmap original, Bitmap replacement) {
        if (original != replacement) {
            recycleBitmap(original);
        }
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

    enum WallpaperFit {
        COVER,
        CONTAIN,
        FILL,
        CENTER,
        NONE
    }
}
