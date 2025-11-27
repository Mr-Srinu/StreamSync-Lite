// lib/services/download_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video.dart';

/// Simple local cache for video metadata marked as "downloaded".
/// NOTE: We only cache metadata, not the actual YouTube video file,
/// to respect YouTube TOS.
class DownloadService {
  static const _key = 'cached_videos';

  /// Load all cached videos from local storage.
  static Future<List<Video>> loadDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Video.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Corrupt data? Reset.
      return [];
    }
  }

  static Future<void> _save(List<Video> videos) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
    jsonEncode(videos.map((v) => v.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  /// Add (or upsert) a video into cache.
  static Future<void> add(Video v) async {
    final list = await loadDownloads();
    final existingIndex =
    list.indexWhere((x) => x.videoId == v.videoId);
    if (existingIndex >= 0) {
      list[existingIndex] = v;
    } else {
      list.add(v);
    }
    await _save(list);
  }

  /// Remove a single video from cache.
  static Future<void> remove(String videoId) async {
    final list = await loadDownloads();
    list.removeWhere((v) => v.videoId == videoId);
    await _save(list);
  }

  /// Clear all cached videos.
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<bool> isDownloaded(String videoId) async {
    final list = await loadDownloads();
    return list.any((v) => v.videoId == videoId);
  }
}
