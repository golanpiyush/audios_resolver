import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'audios_resolver_method_channel.dart';

abstract class AudiosResolverPlatform extends PlatformInterface {
  /// Constructs a AudiosResolverPlatform.
  AudiosResolverPlatform() : super(token: _token);

  static final Object _token = Object();

  static AudiosResolverPlatform _instance = MethodChannelAudiosResolver();

  /// The default instance of [AudiosResolverPlatform] to use.
  ///
  /// Defaults to [MethodChannelAudiosResolver].
  static AudiosResolverPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AudiosResolverPlatform] when
  /// they register themselves.
  static set instance(AudiosResolverPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
