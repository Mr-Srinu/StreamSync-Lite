import 'package:dio/dio.dart';

class ApiService {
  ApiService._internal();

  static final ApiService instance = ApiService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: const String.fromEnvironment('BACKEND_URL', defaultValue: 'http://localhost:3000'),
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  String? _token;

  Future<void> register(String name, String email, String password) async {
    final res = await _dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
    });
    _token = res.data['token'];
    _dio.options.headers['Authorization'] = 'Bearer $_token';
  }

  Future<void> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    _token = res.data['token'];
    _dio.options.headers['Authorization'] = 'Bearer $_token';
  }

  Future<List<dynamic>> getLatestVideos() async {
    final res = await _dio.get('/videos/latest');
    return List<dynamic>.from(res.data['items'] ?? []);
  }

  Future<List<dynamic>> getNotifications() async {
    final res = await _dio.get('/notifications', queryParameters: {'userId': '1'});
    return List<dynamic>.from(res.data['items'] ?? []);
  }

  Future<void> sendTestPush(String title, String body) async {
    await _dio.post('/notifications/send-test', data: {
      'userId': '1',
      'title': title,
      'body': body,
    });
  }
}
