// lib/models/video.dart
class Video {
  final String videoId;
  final String title;
  final String? description;
  final String thumbnailUrl;
  final String channelId;
  final String? channelTitle;
  final DateTime publishedAt;
  final int durationSeconds;
  final VideoProgress? progress;

  Video({
    required this.videoId,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.channelId,
    required this.channelTitle,
    required this.publishedAt,
    required this.durationSeconds,
    this.progress,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      videoId: json['videoId'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      channelId: json['channelId'] as String? ?? '',
      channelTitle: json['channelTitle'] as String?,
      publishedAt: DateTime.tryParse(json['publishedAt']?.toString() ?? '') ??
          DateTime.now(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      progress: json['progress'] != null
          ? VideoProgress.fromJson(
        json['progress'] as Map<String, dynamic>,
      )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'videoId': videoId,
    'title': title,
    'description': description,
    'thumbnailUrl': thumbnailUrl,
    'channelId': channelId,
    'channelTitle': channelTitle,
    'publishedAt': publishedAt.toIso8601String(),
    'durationSeconds': durationSeconds,
    'progress': progress?.toJson(),
  };
}

class VideoProgress {
  final int positionSeconds;
  final double completedPercent;
  final DateTime updatedAt;

  VideoProgress({
    required this.positionSeconds,
    required this.completedPercent,
    required this.updatedAt,
  });

  factory VideoProgress.fromJson(Map<String, dynamic> json) {
    return VideoProgress(
      positionSeconds: (json['positionSeconds'] as num?)?.toInt() ?? 0,
      completedPercent: (json['completedPercent'] as num?)?.toDouble() ?? 0,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'positionSeconds': positionSeconds,
    'completedPercent': completedPercent,
    'updatedAt': updatedAt.toIso8601String(),
  };
}
