// Developed by S. M. Mahmud Iqbal
// SnapFlow Media Models

class FormatOption {
  final String formatId;
  final String label;
  final String? resolution;
  final String? quality;
  final String ext;
  final String filesizeStr;
  final bool isAudioOnly;
  final String? directUrl;

  FormatOption({
    required this.formatId,
    required this.label,
    this.resolution,
    this.quality,
    required this.ext,
    required this.filesizeStr,
    required this.isAudioOnly,
    this.directUrl,
  });

  factory FormatOption.fromJson(Map<String, dynamic> json, {required bool isAudio}) {
    return FormatOption(
      formatId: json['format_id']?.toString() ?? '',
      label: json['label'] ?? (isAudio ? 'Audio Stream' : 'Video'),
      resolution: json['resolution'],
      quality: json['quality'],
      ext: json['ext'] ?? (isAudio ? 'mp3' : 'mp4'),
      filesizeStr: json['filesize_str'] ?? 'Unknown size',
      isAudioOnly: isAudio || (json['is_audio_only'] == true),
      directUrl: json['direct_url'],
    );
  }
}

class MediaInfo {
  final String title;
  final String uploader;
  final String durationStr;
  final String thumbnail;
  final String platform;
  final String url;
  final List<FormatOption> videoFormats;
  final List<FormatOption> audioFormats;
  final String authorCredit;

  MediaInfo({
    required this.title,
    required this.uploader,
    required this.durationStr,
    required this.thumbnail,
    required this.platform,
    required this.url,
    required this.videoFormats,
    required this.audioFormats,
    required this.authorCredit,
  });

  factory MediaInfo.fromJson(Map<String, dynamic> json) {
    var rawVideo = (json['video_formats'] as List<dynamic>?) ?? [];
    var rawAudio = (json['audio_formats'] as List<dynamic>?) ?? [];

    return MediaInfo(
      title: json['title'] ?? 'Untitled Media',
      uploader: json['uploader'] ?? 'Unknown Creator',
      durationStr: json['duration_str'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      platform: json['platform'] ?? 'Video',
      url: json['url'] ?? '',
      videoFormats: rawVideo.map((v) => FormatOption.fromJson(v, isAudio: false)).toList(),
      audioFormats: rawAudio.map((a) => FormatOption.fromJson(a, isAudio: true)).toList(),
      authorCredit: json['author_credit'] ?? 'Developed by S. M. Mahmud Iqbal',
    );
  }
}

class DownloadedTask {
  final String id;
  final String title;
  final String filePath;
  final String qualityLabel;
  final bool isAudio;
  final DateTime date;

  DownloadedTask({
    required this.id,
    required this.title,
    required this.filePath,
    required this.qualityLabel,
    required this.isAudio,
    required this.date,
  });
}
