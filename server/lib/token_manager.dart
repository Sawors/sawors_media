import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class TokenManager {
  final String serverId;
  final JWTKey _secretKey;
  // 30 days
  final int defaultExpirationTimeMs = 30 * 24 * 3600_000;
  final Set<String> _storedTokens = {};

  TokenManager({required this.serverId, required JWTKey secretKey})
    : _secretKey = secretKey;

  String signToken(JWT token, String username) {
    final signed = token.sign(_secretKey);
    _storedTokens.add(signed);
    return signed;
  }

  JWT createTokenForUser(String username, {int? expirationTimeMs}) {
    final epoch = DateTime.timestamp().millisecondsSinceEpoch;
    return JWT({
      "sub": username,
      "iss": serverId,
      "iat": epoch,
      "exp": epoch + (expirationTimeMs ?? defaultExpirationTimeMs),
    });
  }

  bool checkToken(String token) {
    if (_storedTokens.contains(token)) {
      final now = DateTime.timestamp().millisecondsSinceEpoch;
      final decoded = JWT.tryVerify(token, _secretKey);
      final expiration =
          int.tryParse((decoded?.payload?["exp"] ?? "0").toString()) ?? 0;
      final isExpired = expiration < now;
      if (!isExpired) {
        return true;
      } else {
        _storedTokens.remove(token);
        return false;
      }
    }
    return false;
  }

  List<int> getRandomSalt({int length = 32}) {
    final random = Random();
    return List.generate(length, (i) => random.nextInt(1 << 32));
  }

  Future<List<int>> hashPassword(String password, List<int> salt) async {
    return (await Argon2id(
      parallelism: 1,
      memory: 9216,
      iterations: 4,
      hashLength: 128,
    ).deriveKeyFromPassword(password: password, nonce: salt)).extractBytes();
  }
}
