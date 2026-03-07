import 'dart:convert';

import 'package:random_string/random_string.dart';
import 'package:sawors_media_common/user.dart';
import 'package:sawors_media_server/databases.dart';
import 'package:sawors_media_server/server_local_files.dart';
import 'package:sawors_media_server/token_manager.dart';
import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart';

Future<Response> handleRequest(
  Request request, {
  required AuthManager authManager,
}) async {
  final Map<String, String> headers = request.headers;
  final List<String> path = request.requestedUri.pathSegments;
  final String? auth = headers["authorization"];

  print(
    "[${DateTime.now().toString()}] ${request.method} ${request.requestedUri.path}",
  );
  print("|  header : ${jsonEncode(headers)}");

  if (path.isEmpty || path.first != "api") {
    return Response.badRequest(
      body:
          "The requested path should always start with api/ to reach the server !",
    );
  }

  // paths accessible without an auth token
  switch (path[1]) {
    case "login":
      try {
        final String body = await request.readAsString();
        print("|  body   : $body");
        final data = jsonDecode(body);
        final String? password = data["password"];
        final String? userid = data["userid"]?.toString().toLowerCase();
        if (userid == null ||
            password == null ||
            !User.validateUsername(userid)) {
          return Response.badRequest(body: "Bad json request");
        }
        if (!(await authManager.checkCredentials(userid, password))) {
          return Response.forbidden("Bad password or user does not exist");
        }
        final token = authManager.createTokenForUser(userid);
        final signed = authManager.signToken(token, userid);
        return Response.ok(signed);
      } catch (e) {
        print(e);
        return Response.forbidden("bad credentials");
      }
    case "register":
      final String body = await request.readAsString();
      try {
        final payload = jsonDecode(body);
        final String? registerKey = payload["register-key"];
        if (registerKey == null ||
            !authManager.isRegisterKeyValid(registerKey)) {
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
        return Response.ok(jsonEncode(userdata.toJson()));
      } catch (e) {
        print(e);
        return Response.internalServerError(
          body: "Internal server error : probably an incorrect json",
        );
      }
    case "username-available":
      final String body = (await request.readAsString()).trim();
      if (!User.validateUserId(body)) {
        return Response.badRequest(
          body: "The body received is not a correct user id",
        );
      }
      if (ServerDataBases.checkIfUserIdExists(body)) {
        return Response.ok("false");
      } else {
        return Response.ok("true");
      }
    case "validate-reg-key":
      final String body = (await request.readAsString()).trim();
      if (authManager.isRegisterKeyValid(body)) {
        return Response.ok("true");
      } else {
        return Response.ok("false");
      }
    case "test":
      final Map<String, String> rspBody = {
        "test": "ok",
        "timestamp": DateTime.timestamp().millisecondsSinceEpoch.toString(),
      };
      return Response.ok(jsonEncode(rspBody));
  }

  if (auth == null || auth.isEmpty) {
    return Response.unauthorized(
      "Unauthenticated access forbidden for this path",
    );
  }

  return _handleAuthenticatedRequest(request, auth, authManager);
}

Future<Response> _handleAuthenticatedRequest(
  Request request,
  String token,
  AuthManager authManager,
) async {
  final Map<String, String> headers = request.headers;
  final List<String> path = request.requestedUri.pathSegments;

  switch (path[1]) {
    case "check-token":
      final checked = authManager.checkToken(token);
      return checked
          ? Response.ok("valid token")
          : Response.unauthorized("bad token (expired or invalid)");
  }

  return Response.notFound("");
}
