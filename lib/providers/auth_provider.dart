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
  bool _isInitialized = false;

  AuthProvider({
    required ApiService apiService,
    required SecureStorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;

  Future<void> initializeAuth() async {
    try {
      print('=== initializeAuth started ===');
      final hasTokens = await _storageService.hasTokens();
      print('hasTokens: $hasTokens');
      
      if (hasTokens) {
        final token = await _storageService.getAccessToken();
        final refreshToken = await _storageService.getRefreshToken();
        
        print('token: ${token != null ? "found (length: ${token.length})" : "null"}');
        print('refreshToken: ${refreshToken != null ? "found (length: ${refreshToken.length})" : "null"}');
        
        if (token != null && refreshToken != null) {
          _apiService.setTokens(token, refreshToken);
          _isAuthenticated = true;
          print('✓ Auth initialized: user authenticated');
        } else {
          print('✗ Token or refreshToken is null');
        }
      } else {
        print('✓ Auth initialized: no saved tokens');
      }
    } catch (e) {
      print('✗ Auth initialization error: $e');
    } finally {
      _isInitialized = true;
      print('=== initializeAuth completed, isInitialized=true ===');
      notifyListeners();
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
      _error = _formatErrorMessage(e.toString(), 'registration');
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
      print('=== login() starting ===');
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      print('✓ login response received: accessToken length = ${response.accessToken.length}');
      _user = response.user;
      _apiService.setTokens(response.accessToken, response.refreshToken);
      print('✓ setTokens called');
      await _storageService.saveTokens(response.accessToken, response.refreshToken);
      await _storageService.saveUserId(response.user.id);
      _isAuthenticated = true;
      print('✓ login complete: _isAuthenticated = true');
      _error = null;
    } catch (e) {
      print('✗ login error: $e');
      _error = _formatErrorMessage(e.toString(), 'login');
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _formatErrorMessage(String error, String action) {
    if (error.contains('Account with this email already exists')) {
      return 'This email is already registered. Please use a different email or log in.';
    } else if (error.contains('Invalid email or password')) {
      return 'Invalid email or password. Please try again.';
    } else if (error.contains('Network error')) {
      return 'Network connection error. Please check your connection.';
    }
    return error;
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
