// Developed by S. M. Mahmud Iqbal
// SnapFlow API & Download Service

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/media_item.dart';

class ApiService {
  // Default to local backend; can be replaced with production API endpoint
  static String baseUrl = 'http://10.0.2.2:8000'; // Standard Android Emulator localhost

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  /// Extract media information and available stream formats
  Future<MediaInfo> extractMedia(String url) async {
    try {
      final response = await _dio.post(
        '$baseUrl/api/extract',
        data: {'url': url},
      );

      if (response.statusCode == 200 && response.data != null) {
        return MediaInfo.fromJson(response.data);
      } else {
        throw Exception('Extraction failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['detail'] != null) {
        throw Exception(e.response!.data['detail']);
      }
      throw Exception('Network error: Could not reach backend server at $baseUrl');
    }
  }

  /// Download file with real-time percentage progress callback
  Future<String> downloadMedia({
    required String mediaUrl,
    required String formatId,
    required bool isAudio,
    required String title,
    required void Function(double progress, String status) onProgress,
  }) async {
    try {
      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
      }
      dir ??= await getApplicationDocumentsDirectory();

      final sanitizedTitle = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
      final ext = isAudio ? 'mp3' : 'mp4';
      final fileName = '${sanitizedTitle}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final savePath = '${dir.path}/$fileName';

      final downloadUrl = '$baseUrl/api/download?url=${Uri.encodeComponent(mediaUrl)}&format_id=${Uri.encodeComponent(formatId)}&is_audio=$isAudio';

      onProgress(0.0, 'Starting download...');

      await _dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final percent = received / total;
            onProgress(percent, '${(percent * 100).toStringAsFixed(0)}% (${(received / (1024 * 1024)).toStringAsFixed(1)} MB / ${(total / (1024 * 1024)).toStringAsFixed(1)} MB)');
          } else {
            onProgress(0.5, '${(received / (1024 * 1024)).toStringAsFixed(1)} MB downloaded...');
          }
        },
      );

      onProgress(1.0, 'Download Complete');
      return savePath;
    } catch (e) {
      throw Exception('Download failed: $e');
    }
  }
}
