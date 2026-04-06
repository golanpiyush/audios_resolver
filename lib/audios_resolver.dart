
import 'audios_resolver_platform_interface.dart';

class AudiosResolver {
  Future<String?> getPlatformVersion() {
    return AudiosResolverPlatform.instance.getPlatformVersion();
  }
}
