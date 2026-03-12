import 'dart:convert';
import 'dart:io';

import 'package:random_string/random_string.dart';
import 'package:sawors_media_common/user.dart';
import 'package:sawors_media_server/logging.dart';
import 'package:sawors_media_server/token_manager.dart';
import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart';

import '../databases.dart';
import '../server_local_files.dart';

Future<Response> handleRegisterRequest(
  Request request,
  AuthManager authManager,
  ServerLogger logger,
) async {
  final String body = await request.readAsString();
  final ip =
      (request.context['shelf.io.connection_info'] as HttpConnectionInfo?)
          ?.remoteAddress
          .address;
  try {
    final payload = jsonDecode(body);
    final String? registerKey = payload["register-key"];
    if (registerKey == null || !authManager.isRegisterKeyValid(registerKey)) {
      return Response.forbidden("Empty or invalid register key provided.");
    }
    // user can effectively register
    final userData = payload["userdata"];
    userData["userid"] =
        User.userIdFromName(userData["displayName"] ?? "") ??
        randomAlphaNumeric(8).toLowerCase();
    if (ServerDataBases.checkIfUserIdExists(userData["userid"])) {
      return Response.forbidden("A user with the same ID already exists");
    }
    final String password = payload["password"];
    if (password.isEmpty) {
      return Response.forbidden("Empty password not allowed");
    }
    final User userdata = User.fromJson(userData);
    ServerDataBases.saveUserData(userdata);
    final salt = authManager.getRandomSalt();
    final pHash = await authManager.hashPassword(password, salt);
    final credDb = sqlite3.open(ServerLocalFiles.credentialsDatabase.path);
    credDb.execute(
      "INSERT INTO credentials (userid,password,salt) VALUES (?,?,?);",
      [userData["userid"], pHash, salt],
    );
    credDb.dispose();
    authManager.consumeRegisterKey(registerKey);
    logger.logUserAction(
      userData["userid"],
      ip,
      UserLogType.register,
      "registered with key: $registerKey",
    );
    return Response.ok(jsonEncode(userdata.toJson()));
  } catch (e) {
    return Response.internalServerError(
      body: "Internal server error : probably an incorrect json",
    );
  }
}
