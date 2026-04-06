import 'dart:async';

import 'package:audios_resolver/audios_resolver.dart';
import 'package:audios_resolver/audios_resolver_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The interface that platform implementations must implement.
abstract class AudiosResolverPlatform extends PlatformInterface {
  /// Constructs a AudiosResolverPlatform.
  AudiosResolverPlatform() : super(token: _token);

  static final Object _token = Object();

  static AudiosResolverPlatform _instance = MethodChannelAudiosResolver();

  /// The default instance of [AudiosResolverPlatform] to use.
  static AudiosResolverPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AudiosResolverPlatform] when
  /// they register themselves.
  static set instance(AudiosResolverPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Resolve a single video ID to an audio URL.
  Future<AudioResolverResult?> fetchSingle({
    required String videoId,
    bool forceRefresh = false,
  }) {
    throw UnimplementedError('fetchSingle() has not been implemented.');
  }

  /// Resolve multiple video IDs to audio URLs.
  Future<Map<String, AudioResolverResult?>> fetchBatch({
    required List<String> videoIds,
    bool forceRefresh = false,
    int concurrency = 5,
  }) {
    throw UnimplementedError('fetchBatch() has not been implemented.');
  }

  /// Clear the cache.
  Future<void> clearCache() {
    throw UnimplementedError('clearCache() has not been implemented.');
  }
}
