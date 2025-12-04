import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/auth_response.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../models/api_error.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1';

  String? _accessToken;

  void setTokens(String accessToken, String refreshToken) {
    _accessToken = accessToken;
    print('✓ setTokens() called: token length = ${accessToken.length}');
  }

  void clearTokens() {
    _accessToken = null;
  }

  Map<String, String> _getHeaders({bool requiresAuth = false}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      if (_accessToken != null && _accessToken!.isNotEmpty) {
        headers['Authorization'] = 'Bearer $_accessToken';
        final preview = _accessToken!.length > 20 
            ? _accessToken!.substring(0, 20) + '...'
            : _accessToken!;
        print('✓ Auth header added: Bearer $preview');
      } else {
        print('✗ Auth required but token is null or empty!');
      }
    }

    return headers;
  }

  Future<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      return fromJson(jsonResponse);
    } else if (response.statusCode == 400 || response.statusCode == 401 || response.statusCode == 409 || response.statusCode == 422) {
      try {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        String message = error['message'] as String? ?? 'Request failed';
        
        if (response.statusCode == 409) {
          message = 'Account with this email already exists';
        } else if (response.statusCode == 401 || response.statusCode == 404) {
          message = 'Invalid email or password';
        }
        
        throw ApiError(
          message: message,
          statusCode: response.statusCode,
          code: error['code'] as String?,
        );
      } catch (e) {
        if (e is ApiError) rethrow;
        throw ApiError(
          message: 'Request failed',
          statusCode: response.statusCode,
        );
      }
    } else if (response.statusCode == 500) {
      throw ApiError(
        message: 'Server error',
        statusCode: response.statusCode,
      );
    } else {
      throw ApiError(
        message: 'Unknown error',
        statusCode: response.statusCode,
      );
    }
  }

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/register');
      print('POST $uri');
      
      final response = await http.post(
        uri,
        headers: _getHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      print('Response: ${response.statusCode}');
      
      return _handleResponse(response, (json) => AuthResponse.fromJson(json));
    } catch (e) {
      print('✗ Register error: $e');
      throw ApiError(
        message: 'Network error: $e',
        code: 'NETWORK_ERROR',
      );
    }
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/login');
      print('POST $uri');
      
      final response = await http.post(
        uri,
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      print('Response: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      return _handleResponse(response, (json) => AuthResponse.fromJson(json));
    } catch (e) {
      print('✗ Login error: $e');
      throw ApiError(
        message: 'Network error: $e',
        code: 'NETWORK_ERROR',
      );
    }
  }

  Future<List<Task>> getTasks({String? status}) async {
    final uri = Uri.parse('$baseUrl/tasks').replace(
      queryParameters: status != null ? {'status': status} : {},
    );

    print('GET $uri');
    
    final response = await http.get(
      uri,
      headers: _getHeaders(requiresAuth: true),
    );

    print('Response: ${response.statusCode}');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final tasksList = jsonResponse['tasks'] as List<dynamic>? ?? [];
      print('✓ Tasks count: ${tasksList.length}');
      return tasksList
          .map((task) => Task.fromJson(task as Map<String, dynamic>))
          .toList();
    } else {
      print('✗ Error: ${response.statusCode}');
      throw ApiError(
        message: 'Failed to fetch tasks',
        statusCode: response.statusCode,
      );
    }
  }

  Future<Task> createTask({
    required String title,
    required String description,
    required String status,
    required int ownerId,
  }) async {
    final uri = Uri.parse('$baseUrl/tasks');
    print('POST $uri');
    
    final response = await http.post(
      uri,
      headers: _getHeaders(requiresAuth: true),
      body: jsonEncode({
        'title': title,
        'description': description,
        'status': status,
        'owner_id': ownerId,
      }),
    );

    print('Response: ${response.statusCode}');
    print('Body: ${response.body}');

    return _handleResponse(response, (json) => Task.fromJson(json));
  }

  Future<Task> updateTask({
    required int taskId,
    required String title,
    required String description,
    required String status,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tasks/$taskId'),
      headers: _getHeaders(requiresAuth: true),
      body: jsonEncode({
        'title': title,
        'description': description,
        'status': status,
      }),
    );

    return _handleResponse(response, (json) => Task.fromJson(json));
  }

  Future<void> deleteTask(int taskId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/tasks/$taskId'),
      headers: _getHeaders(requiresAuth: true),
    );

    if (response.statusCode != 200) {
      throw ApiError(
        message: 'Failed to delete task',
        statusCode: response.statusCode,
      );
    }
  }

  Future<User> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/profile'),
      headers: _getHeaders(requiresAuth: true),
    );

    return _handleResponse(response, (json) => User.fromJson(json));
  }
}
