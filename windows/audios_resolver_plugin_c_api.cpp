#include "include/audios_resolver/audios_resolver_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "audios_resolver_plugin.h"

void AudiosResolverPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  audios_resolver::AudiosResolverPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
