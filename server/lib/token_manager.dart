import 'dart:math';

import 'package:collection/collection.dart';
import 'package:cryptography/cryptography.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:random_string/random_string.dart';
import 'package:sawors_media_server/server_local_files.dart';
import 'package:sqlite3/sqlite3.dart';

class AuthManager {
  final String serverId;
  final JWTKey _secretKey;
  // 30 days
  final int defaultLoginExpirationTimeMs = 30 * 24 * 3600_000;
  // 7 days
  final int defaultRegisterKeyExpirationTimeMs = 7 * 24 * 3600_000;
  final Set<String> _storedTokens = {};

  AuthManager({required this.serverId, required JWTKey secretKey})
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
      "exp": epoch + (expirationTimeMs ?? defaultLoginExpirationTimeMs),
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

  Future<bool> checkCredentials(String userid, String password) async {
    final db = sqlite3.open(ServerLocalFiles.credentialsDatabase.path);
    final select = db.select("SELECT * FROM credentials WHERE userid = ?", [
      userid,
    ]);
    db.dispose();
    if (select.rows.isEmpty) {
      print("User not found");
      return false;
    }
    final List<int> salt = select.first["salt"];
    final List<int> storedPassword = select.first["password"];
    final pHash = await hashPassword(password, salt);
    return ListEquality().equals(storedPassword, pHash);
  }

  String createRegisterKey({
    int? expirationTimeMs,
    String? keyOverride,
    int keyLength = 8,
  }) {
    final String regKey =
        keyOverride ?? randomAlphaNumeric(keyLength).toLowerCase();
    final db = sqlite3.open(ServerLocalFiles.registerKeysDatabase.path);
    final now = DateTime.now().millisecondsSinceEpoch;
    db.execute(
      "INSERT OR REPLACE INTO keys (key_value,created,valid_until) VALUES (?,?,?);",
      [
        regKey,
        now,
        now + (expirationTimeMs ?? defaultRegisterKeyExpirationTimeMs),
      ],
    );
    db.dispose();
    return regKey;
  }

  bool isRegisterKeyValid(String registerKey) {
    final db = sqlite3.open(ServerLocalFiles.registerKeysDatabase.path);
    final now = DateTime.now().millisecondsSinceEpoch;
    final select = db.select("SELECT * FROM keys WHERE key_value = ?;", [
      registerKey,
    ]);
    if (select.isEmpty) {
      return false;
    }
    final validity = int.tryParse(select.first["valid_until"]);
    final isExpired = validity != null && validity < now;
    if (isExpired) {
      db.execute("DELETE FROM keys WHERE valid_until < ?;", [now]);
    }
    db.dispose();
    return select.isNotEmpty && (validity == null || !isExpired);
  }

  void consumeRegisterKey(String registerKey) {
    final db = sqlite3.open(ServerLocalFiles.registerKeysDatabase.path);
    db.execute("DELETE FROM keys WHERE key_value = ?;", [registerKey]);
    db.dispose();
  }
}
