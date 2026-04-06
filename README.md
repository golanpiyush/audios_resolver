# audios_resolver

Resolves YouTube video IDs to **direct audio stream URLs** using the InnerTube Android client ladder.

- ✅ No API key required
- ✅ Works on Android, iOS, Web, Linux, macOS, Windows
- ✅ Automatic client fallback: `ANDROID_MUSIC → ANDROID_VR → ANDROID → ANDROID_TESTSUITE`
- ✅ Result caching with automatic expiry detection
- ✅ Batch resolution with configurable concurrency
- ✅ Native Kotlin/Ktor on Android — pure Dart `http` on all other platforms

---

## Installation

```yaml
dependencies:
  audios_resolver: ^1.0.0
```

---

## Usage

### Resolve a single video

```dart
import 'package:audios_resolver/audios_resolver.dart';

final resolver = AudiosResolver();

final result = await resolver.fetchSingle('dQw4w9WgXcQ');

if (result != null) {
  print(result.url);       // Direct googlevideo.com URL
  print(result.codec);     // e.g. "opus" or "mp4a.40.2"
  print(result.bitrate);   // bits per second
  print(result.clientUsed);// e.g. "ANDROID_MUSIC"
}
```

### Resolve multiple videos

```dart
final results = await resolver.fetchBatch(
  ['dQw4w9WgXcQ', 'VIDEO_ID_2', 'VIDEO_ID_3'],
  concurrency: 3,
);

for (final entry in results.entries) {
  print('${entry.key}: ${entry.value.url}');
}
```

### Force refresh (bypass cache)

```dart
final result = await resolver.fetchSingle('dQw4w9WgXcQ', forceRefresh: true);
```

### Clean up

```dart
resolver.dispose();
```

---

## AudioResolverResult

| Field           | Type       | Description                                    |
|-----------------|------------|------------------------------------------------|
| `videoId`       | `String`   | The YouTube video ID                           |
| `url`           | `String`   | Direct audio stream URL (googlevideo.com)      |
| `itag`          | `int`      | Format itag (251 = opus 160k, 140 = m4a 128k) |
| `mimeType`      | `String`   | Full MIME type string                          |
| `codec`         | `String`   | Extracted codec name                           |
| `bitrate`       | `int`      | Bitrate in bits/sec                            |
| `contentLength` | `int?`     | File size in bytes (if available)              |
| `loudnessDb`    | `double?`  | Loudness value in dB (if available)            |
| `clientUsed`    | `String`   | Which InnerTube client succeeded               |
| `userAgent`     | `String`   | User-Agent used for the resolved URL           |
| `expiresAt`     | `DateTime` | When the URL expires (~6 hours from resolution)|
| `isExpired`     | `bool`     | Whether the URL has expired                    |

---

## Platform implementation

| Platform          | Implementation         |
|-------------------|------------------------|
| Android           | Kotlin + Ktor (native) |
| iOS               | Pure Dart              |
| Web               | Pure Dart              |
| Linux             | Pure Dart              |
| macOS             | Pure Dart              |
| Windows           | Pure Dart              |

---

## Notes

- URLs expire after approximately 6 hours. The plugin caches results and exposes `isExpired` for you to check before playback.
- The InnerTube client ladder is tried in order: `ANDROID_MUSIC` → `ANDROID_VR` → `ANDROID` → `ANDROID_TESTSUITE`. The first client that returns a direct URL wins.
- This plugin only resolves audio URLs. Video streams and cipher-protected streams are intentionally ignored.