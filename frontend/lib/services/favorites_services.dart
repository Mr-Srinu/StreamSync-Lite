// lib/services/favorites_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const _key = 'favorite_video_ids';

  static Future<Set<String>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return <String>{};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e.toString()).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  static Future<void> _save(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(ids.toList()));
  }

  static Future<void> add(String videoId) async {
    final ids = await loadFavorites();
    ids.add(videoId);
    await _save(ids);
  }

  static Future<void> remove(String videoId) async {
    final ids = await loadFavorites();
    ids.remove(videoId);
    await _save(ids);
  }

  static Future<bool> isFavorite(String videoId) async {
    final ids = await loadFavorites();
    return ids.contains(videoId);
  }
}
