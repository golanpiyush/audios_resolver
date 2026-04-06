#ifndef FLUTTER_PLUGIN_AUDIOS_RESOLVER_PLUGIN_H_
#define FLUTTER_PLUGIN_AUDIOS_RESOLVER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace audios_resolver {

class AudiosResolverPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  AudiosResolverPlugin();

  virtual ~AudiosResolverPlugin();

  // Disallow copy and assign.
  AudiosResolverPlugin(const AudiosResolverPlugin&) = delete;
  AudiosResolverPlugin& operator=(const AudiosResolverPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace audios_resolver

#endif  // FLUTTER_PLUGIN_AUDIOS_RESOLVER_PLUGIN_H_
