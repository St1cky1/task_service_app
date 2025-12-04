import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  final SecureStorageService _storageService;

  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  AuthProvider({
    required ApiService apiService,
    required SecureStorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> initializeAuth() async {
    final hasTokens = await _storageService.hasTokens();
    if (hasTokens) {
      final token = await _storageService.getAccessToken();
      final refreshToken = await _storageService.getRefreshToken();
      
      if (token != null && refreshToken != null) {
        _apiService.setTokens(token, refreshToken);
        _isAuthenticated = true;
        notifyListeners();
      }
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.register(
        name: name,
        email: email,
        password: password,
      );

      _user = response.user;
      _apiService.setTokens(response.accessToken, response.refreshToken);
      await _storageService.saveTokens(response.accessToken, response.refreshToken);
      await _storageService.saveUserId(response.user.id);
      _isAuthenticated = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      _user = response.user;
      _apiService.setTokens(response.accessToken, response.refreshToken);
      await _storageService.saveTokens(response.accessToken, response.refreshToken);
      await _storageService.saveUserId(response.user.id);
      _isAuthenticated = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _storageService.clearAll();
      _apiService.clearTokens();
      _user = null;
      _isAuthenticated = false;
      _error = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
