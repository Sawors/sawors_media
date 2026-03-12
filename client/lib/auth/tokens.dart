import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenService {
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<void> saveToken(String token, String userid) async {
    await _storage.write(key: 'jwt-$userid', value: token);
  }

  Future<String?> getToken(String userid) async {
    return await _storage.read(key: 'jwt-$userid');
  }

  Future<void> deleteToken(String userid) async {
    await _storage.delete(key: 'jwt-$userid');
  }
}
