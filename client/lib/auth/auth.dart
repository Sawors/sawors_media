import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:sawors_media_common/user.dart';

class AuthService {
  final Dio _dio;
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  AuthService(this._dio);

  Future<bool> login(String userid, String password, {useToken = true}) async {
    try {
      final response = await _dio.post(
        '/login',
        data: jsonEncode({'userid': userid, 'password': password}),
      );

      if (response.statusCode == 200 && useToken) {
        final token = response.data;
        if (token != null) {
          await _storage.write(key: 'jwt-$userid', value: token);
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
          await _storage.write(key: 'jwt-$userid', value: token);
          return true;
        }
      }
    } catch (e) {
      print('Signup error: $e');
    }
    return false;
  }

  Future<String?> getToken(String userid) async {
    return await _storage.read(key: 'jwt-$userid');
  }

  Future<void> logout(String userid) async {
    await _storage.delete(key: 'jwt-$userid');
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
  final String userid;
  User? _user;

  AuthProvider(this._authService, this.userid);

  bool get isAuthenticated => _user != null;

  Future<bool> login(String userid, String password, {useToken = true}) async {
    var success = await _authService.login(
      userid,
      password,
      useToken: useToken,
    );
    if (success) {
      try {
        final userResponse = await GetIt.instance<Dio>().get("/user-data");
        final User user = User.fromJson(jsonDecode(userResponse.data));
        _user = user;
      } catch (e) {
        // THIS SHOULD NEVER HAPPEN
        if (kDebugMode) {
          print("THIS SHOULD NEVER HAPPEN : $e");
        }
      }
      notifyListeners();
    }
    return success;
  }

  Future<bool> loginWithToken() async {
    try {
      final userResponse = await GetIt.instance<Dio>().get("/user-data");
      final User user = User.fromJson(jsonDecode(userResponse.data));
      _user = user;
      return true;
    } on DioException catch (e) {
      if (e.type != DioExceptionType.badResponse) {
        rethrow;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  Future<void> logout(String userid) async {
    await _authService.logout(userid);
    _user = null;
    //_user = null;
    notifyListeners();
  }

  User getUser() {
    if (_user == null) {
      throw StateError("User cannot be logged out when getUser() is called");
    }
    return _user!;
  }
}
