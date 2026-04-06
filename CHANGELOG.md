
## 1.0.1

### Fixed
- Resolved name conflicts with existing pub.dev packages

## 1.0.0

### Added
- Initial release
- Support for resolving YouTube audio streams
- Multiple InnerTube clients (Android Music, Android VR, Android, Android Testsuite)
- Automatic client fallback for better success rate
- Cache management with automatic expiration
- Batch resolution with configurable concurrency
- Visitor data handling for LOGIN_REQUIRED scenarios
- Support for opus (160kbps, 70kbps) and m4a (128kbps) formats

### Features
- Single video resolution
- Batch video resolution (up to 30 videos)
- Force refresh option
- Automatic cache invalidation based on URL expiry
- In-flight request deduplication