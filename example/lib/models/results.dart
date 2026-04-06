import 'package:equatable/equatable.dart';

/// Result of resolving an audio stream for a YouTube video.
class AudioResolverResult extends Equatable {
  final String videoId;
  final String url;
  final int itag;
  final String mimeType;
  final String codec;
  final int bitrate;
  final int? contentLength;
  final double? loudnessDb;
  final String clientUsed;
  final String userAgent;
  final DateTime expiresAt;

  const AudioResolverResult({
    required this.videoId,
    required this.url,
    required this.itag,
    required this.mimeType,
    required this.codec,
    required this.bitrate,
    required this.contentLength,
    required this.loudnessDb,
    required this.clientUsed,
    required this.userAgent,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Create from a Map (from platform channel)
  factory AudioResolverResult.fromMap(Map<String, dynamic> map) {
    return AudioResolverResult(
      videoId: map['videoId'] as String,
      url: map['url'] as String,
      itag: map['itag'] as int,
      mimeType: map['mimeType'] as String,
      codec: map['codec'] as String,
      bitrate: map['bitrate'] as int,
      contentLength: map['contentLength'] as int?,
      loudnessDb: (map['loudnessDb'] as num?)?.toDouble(),
      clientUsed: map['clientUsed'] as String,
      userAgent: map['userAgent'] as String,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(map['expiresAtMs'] as int),
    );
  }

  /// Convert to Map (for platform channel)
  Map<String, dynamic> toMap() {
    return {
      'videoId': videoId,
      'url': url,
      'itag': itag,
      'mimeType': mimeType,
      'codec': codec,
      'bitrate': bitrate,
      'contentLength': contentLength,
      'loudnessDb': loudnessDb,
      'clientUsed': clientUsed,
      'userAgent': userAgent,
      'expiresAtMs': expiresAt.millisecondsSinceEpoch,
    };
  }

  @override
  List<Object?> get props => [
    videoId,
    url,
    itag,
    mimeType,
    codec,
    bitrate,
    contentLength,
    loudnessDb,
    clientUsed,
    userAgent,
    expiresAt,
  ];

  @override
  String toString() {
    return 'AudioResolverResult(videoId=$videoId, itag=$itag, '
        'codec=$codec, bitrate=${bitrate ~/ 1000}kbps, client=$clientUsed)';
  }
}
