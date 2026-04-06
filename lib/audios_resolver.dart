library audios_resolver;

import 'package:audios_resolver/audios_resolver.dart';

// Export the model class
export 'src/models.dart';

// Export the platform interface
export 'audios_resolver_platform_interface.dart';

// Export the method channel implementation
export 'audios_resolver_method_channel.dart';

/// The main entry point for the audios_resolver plugin.
class AudiosResolver {
  /// Resolve a single video ID to an audio URL.
  static Future<AudioResolverResult?> fetchSingle({
    required String videoId,
    bool forceRefresh = false,
  }) {
    return AudiosResolverPlatform.instance.fetchSingle(
      videoId: videoId,
      forceRefresh: forceRefresh,
    );
  }

  /// Resolve multiple video IDs to audio URLs.
  static Future<Map<String, AudioResolverResult?>> fetchBatch({
    required List<String> videoIds,
    bool forceRefresh = false,
    int concurrency = 5,
  }) {
    return AudiosResolverPlatform.instance.fetchBatch(
      videoIds: videoIds,
      forceRefresh: forceRefresh,
      concurrency: concurrency,
    );
  }

  /// Clear the cache.
  static Future<void> clearCache() {
    return AudiosResolverPlatform.instance.clearCache();
  }
}
