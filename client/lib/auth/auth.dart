import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final Dio _dio;
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  AuthService(this._dio);

  Future<bool> login(String userid, String password) async {
    try {
      final response = await _dio.post(
        '/login',
        data: jsonEncode({'userid': userid, 'password': password}),
      );

      if (response.statusCode == 200) {
        final token = response.data; // Ensure this matches your API response
        if (token != null) {
          await _storage.write(key: 'jwt', value: token);
          return true;
        }
      }
    } catch (e) {
      print('Login error: $e');
    }
    return false;
  }

  Future<bool> signup(String userid, String password) async {
    try {
      final response = await _dio.post(
        '/register',
        data: jsonEncode({'userid': userid, 'password': password}),
      );

      if (response.statusCode == 200) {
        final token = response.data; // Ensure this matches your API response
        if (token != null) {
          await _storage.write(key: 'jwt', value: token);
          return true;
        }
      }
    } catch (e) {
      print('Signup error: $e');
    }
    return false;
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt');
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt');
  }

  Map<String, dynamic> parseJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid token');
    }
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    return json.decode(payload);
  }
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  bool _isAuthenticated = false;

  AuthProvider(this._authService);

  bool get isAuthenticated => _isAuthenticated;

  Future<bool> login(String email, String password) async {
    var success = await _authService.login(email, password);
    print(success);
    if (success) {
      _isAuthenticated = true;
      //await _updateUser();
      notifyListeners();
    }
    return success;
  }

  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    //_user = null;
    notifyListeners();
  }
}
