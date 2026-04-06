# audios_resolver

Resolves YouTube video IDs to direct audio stream URLs via InnerTube Android client ladder. No API key required.

## Install

```yaml
dependencies:
  audios_resolver: ^0.1.0
```

## Usage

```dart
import 'package:audios_resolver/audios_resolver.dart';

final resolver = AudiosResolver();

// Single
final result = await resolver.fetchSingle('dQw4w9WgXcQ');

// Batch (max 30)
final results = await resolver.fetchBatch(['id1', 'id2'], concurrency: 3);

// Force refresh
final fresh = await resolver.fetchSingle('dQw4w9WgXcQ', forceRefresh: true);

resolver.dispose();
```

## Result Properties

| Property        | Type       | Description                                      |
|-----------------|------------|--------------------------------------------------|
| `url`           | `String`   | Direct audio stream URL                          |
| `itag`          | `int`      | 251 (opus 160k), 250 (opus 70k), 140 (m4a 128k) |
| `codec`         | `String`   | `opus` or `m4a`                                  |
| `bitrate`       | `int`      | bps                                              |
| `contentLength` | `int?`     | bytes                                            |
| `clientUsed`    | `String`   | InnerTube client that resolved                   |
| `expiresAt`     | `DateTime` | ~6h from resolution                              |
| `isExpired`     | `bool`     | Check before playback                            |

## Notes

- URLs expire in ~6h — check `isExpired`, use `forceRefresh: true` to renew
- Client fallback order: `ANDROID_MUSIC → ANDROID_VR → ANDROID → ANDROID_TESTSUITE`
- Android uses Kotlin + Ktor natively; all other platforms use pure Dart
- Concurrent requests for the same ID are deduplicated automatically

## License

MIT