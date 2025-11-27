// lib/services/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/user.dart';
import '../models/video.dart';
import '../models/app_notification.dart';
import 'session_manager.dart';

class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> _post(
      String path,
      Map<String, dynamic> body, {
        bool auth = false,
      }) async {
    final uri = Uri.parse('$kApiBaseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (auth) {
      final token = await SessionManager.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    final resp = await _client.post(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      if (resp.body.isEmpty) return {};
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception(
          'POST $path failed: ${resp.statusCode} ${resp.body}');
    }
  }

  Future<Map<String, dynamic>> _get(
      String path, {
        Map<String, dynamic>? query,
        bool auth = false,
      }) async {
    final uri = Uri.parse('$kApiBaseUrl$path').replace(
      queryParameters: query,
    );
    final headers = <String, String>{};
    if (auth) {
      final token = await SessionManager.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    final resp = await _client.get(uri, headers: headers);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      if (resp.body.isEmpty) return {};
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('GET $path failed: ${resp.statusCode} ${resp.body}');
    }
  }

  // ---------- Auth ----------

  Future<AppUser> register(String name, String email, String password) async {
    final data = await _post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });

    final userJson = data['user'] as Map<String, dynamic>;
    final token = data['accessToken'] as String;
    final user = AppUser.fromJson(userJson);
    await SessionManager.saveSession(token, user);
    return user;
  }

  Future<AppUser> login(String email, String password) async {
    final data = await _post('/auth/login', {
      'email': email,
      'password': password,
    });

    final userJson = data['user'] as Map<String, dynamic>;
    final token = data['accessToken'] as String;
    final user = AppUser.fromJson(userJson);
    await SessionManager.saveSession(token, user);
    return user;
  }

  // ---------- Videos ----------

  Future<List<Video>> fetchLatestVideos() async {
    final data = await _get('/videos/latest');
    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => Video.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Video> fetchVideoDetails(String videoId, String? userId) async {
    final data = await _get(
      '/videos/$videoId',
      query: userId != null ? {'userId': userId} : null,
    );
    return Video.fromJson(data);
  }

  Future<void> sendVideoProgress({
    required String userId,
    required String videoId,
    required int positionSeconds,
    required double completedPercent,
  }) async {
    await _post('/videos/progress', {
      'userId': userId,
      'videoId': videoId,
      'positionSeconds': positionSeconds,
      'completedPercent': completedPercent,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // ---------- Notifications ----------

  Future<List<AppNotification>> fetchNotifications(String userId) async {
    final data =
    await _get('/notifications', query: {'userId': userId});
    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> sendTestPush({
    required String userId,
    required String title,
    required String body,
  }) async {
    await _post('/notifications/send-test', {
      'userId': userId,
      'title': title,
      'body': body,
      'mode': 'self',
    });
  }

  Future<void> deleteNotification(String id) async {
    final uri = Uri.parse('$kApiBaseUrl/notifications/$id');
    final resp = await _client.delete(uri);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception(
          'DELETE /notifications/$id failed: ${resp.statusCode} ${resp.body}');
    }
  }

  Future<void> markNotificationsRead(
      String userId, List<String> ids) async {
    if (ids.isEmpty) return;
    await _post('/notifications/mark-read', {
      'userId': userId,
      'ids': ids,
    });
  }
}
