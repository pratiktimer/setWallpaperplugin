#include "include/wallpaper/wallpaper_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "wallpaper_plugin.h"

void WallpaperPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  wallpaper::WallpaperPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
