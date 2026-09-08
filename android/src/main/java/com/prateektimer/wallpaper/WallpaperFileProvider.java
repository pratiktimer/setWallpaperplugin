package com.prateektimer.wallpaper;

import android.net.Uri;
import android.webkit.MimeTypeMap;

import androidx.annotation.NonNull;
import androidx.core.content.FileProvider;

/** FileProvider that reports image MIME types reliably for wallpaper picker intents. */
public final class WallpaperFileProvider extends FileProvider {
    @Override
    public String getType(@NonNull Uri uri) {
        String type = super.getType(uri);
        if (type != null && type.startsWith("image/")) {
            return type;
        }

        String extension = MimeTypeMap.getFileExtensionFromUrl(uri.toString());
        if (extension == null || extension.isEmpty()) {
            String path = uri.getLastPathSegment();
            int dot = path == null ? -1 : path.lastIndexOf('.');
            extension = dot >= 0 && dot < path.length() - 1 ? path.substring(dot + 1) : "";
        }

        String lowerExtension = extension.toLowerCase();
        if ("jpeg".equals(lowerExtension) || "jpg".equals(lowerExtension)) {
            return "image/jpeg";
        }
        if ("png".equals(lowerExtension)) {
            return "image/png";
        }

        return type != null ? type : "image/*";
    }
}
