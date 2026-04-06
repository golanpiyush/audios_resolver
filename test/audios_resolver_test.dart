import 'package:flutter_test/flutter_test.dart';
import 'package:audios_resolver/audios_resolver.dart';
import 'package:audios_resolver/audios_resolver_platform_interface.dart';
import 'package:audios_resolver/audios_resolver_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAudiosResolverPlatform
    with MockPlatformInterfaceMixin
    implements AudiosResolverPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final AudiosResolverPlatform initialPlatform = AudiosResolverPlatform.instance;

  test('$MethodChannelAudiosResolver is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAudiosResolver>());
  });

  test('getPlatformVersion', () async {
    AudiosResolver audiosResolverPlugin = AudiosResolver();
    MockAudiosResolverPlatform fakePlatform = MockAudiosResolverPlatform();
    AudiosResolverPlatform.instance = fakePlatform;

    expect(await audiosResolverPlugin.getPlatformVersion(), '42');
  });
}
