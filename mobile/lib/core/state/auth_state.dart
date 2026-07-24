import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';

enum AuthStatus { unknown, signedOut, signedIn }

/// Holds auth/session state for the whole app: tokens, current user, and
/// register/login/forgot-password against the backend's email+password Auth
/// module. Register and login both sign the user in directly (no separate
/// verification step) — only password reset has an intermediate code step.
class AuthState extends ChangeNotifier {
  AuthState(this.apiClient);

  final ApiClient apiClient;

  AuthStatus status = AuthStatus.unknown;
  String? lastError;
  String? devResetCodeHint;
  String? _pendingResetEmail;

  static const _accessTokenKey = 'car_nanny_access_token';
  static const _refreshTokenKey = 'car_nanny_refresh_token';

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_refreshTokenKey);
    final accessToken = prefs.getString(_accessTokenKey);
    if (accessToken != null && refreshToken != null) {
      apiClient.accessToken = accessToken;
      status = AuthStatus.signedIn;
    } else {
      status = AuthStatus.signedOut;
    }
    notifyListeners();
  }

  Future<bool> register(String email, String password, String fullName, {String? phoneNumber}) async {
    lastError = null;
    try {
      final response = await apiClient.dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'fullName': fullName,
        if (phoneNumber != null && phoneNumber.isNotEmpty) 'phoneNumber': phoneNumber,
      });
      await _persistTokens(response.data as Map<String, dynamic>);
      status = AuthStatus.signedIn;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      lastError = ApiClient.messageFrom(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    lastError = null;
    try {
      final response = await apiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      await _persistTokens(response.data as Map<String, dynamic>);
      status = AuthStatus.signedIn;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      lastError = ApiClient.messageFrom(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestPasswordReset(String email) async {
    lastError = null;
    try {
      final response = await apiClient.dio.post('/auth/forgot-password', data: {'email': email});
      _pendingResetEmail = email;
      devResetCodeHint = response.data['devCode'] as String?;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      lastError = ApiClient.messageFrom(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmPasswordReset(String code, String newPassword) async {
    if (_pendingResetEmail == null) return false;
    lastError = null;
    try {
      await apiClient.dio.post('/auth/reset-password', data: {
        'email': _pendingResetEmail,
        'code': code,
        'newPassword': newPassword,
      });
      return true;
    } on DioException catch (e) {
      lastError = ApiClient.messageFrom(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> _persistTokens(Map<String, dynamic> tokenResponse) async {
    final accessToken = tokenResponse['accessToken'] as String;
    final refreshToken = tokenResponse['refreshToken'] as String;
    apiClient.accessToken = accessToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    apiClient.accessToken = null;
    status = AuthStatus.signedOut;
    notifyListeners();
  }
}
