import 'dart:async';

import 'package:audios_resolver/audios_resolver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audios_resolver/audios_resolver_platform_interface.dart';

/// The method channel implementation of [AudiosResolverPlatform].
class MethodChannelAudiosResolver extends AudiosResolverPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('audios_resolver');

  @override
  Future<AudioResolverResult?> fetchSingle({
    required String videoId,
    bool forceRefresh = false,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'fetchSingle',
        {
          'videoId': videoId,
          'forceRefresh': forceRefresh,
        },
      );
      if (result == null) return null;
      return AudioResolverResult.fromMap(result.cast<String, dynamic>());
    } on PlatformException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, AudioResolverResult?>> fetchBatch({
    required List<String> videoIds,
    bool forceRefresh = false,
    int concurrency = 5,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'fetchBatch',
        {
          'videoIds': videoIds,
          'forceRefresh': forceRefresh,
          'concurrency': concurrency,
        },
      );
      if (result == null) return {};

      return result.map(
        (key, value) => MapEntry(
          key as String,
          value != null
              ? AudioResolverResult.fromMap(value.cast<String, dynamic>())
              : null,
        ),
      );
    } on PlatformException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await methodChannel.invokeMethod('clearCache');
    } on PlatformException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(PlatformException e) {
    return Exception('${e.code}: ${e.message}');
  }
}
