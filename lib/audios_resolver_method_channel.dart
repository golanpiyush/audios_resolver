import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'audios_resolver_platform_interface.dart';

/// An implementation of [AudiosResolverPlatform] that uses method channels.
class MethodChannelAudiosResolver extends AudiosResolverPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('audios_resolver');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
