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
  required AuthManager tokenManager,
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
        if (!(await tokenManager.checkCredentials(userid, password))) {
          return Response.forbidden("Bad password or user does not exist");
        }
        final token = tokenManager.createTokenForUser(userid);
        final signed = tokenManager.signToken(token, userid);
        return Response.ok(signed);
      } catch (e) {
        print(e);
        return Response.forbidden("bad credentials");
      }
    case "register":
      final String body = await request.readAsString();
      try {
        final payload = jsonDecode(body);
        final String? registerKey = request.requestedUri.queryParameters["key"];
        if (registerKey == null ||
            !tokenManager.isRegisterKeyValid(registerKey)) {
          return Response.forbidden("Empty or invalid register key provided.");
        }
        // user can effectively register
        final userData = payload["userdata"];
        final displayName = userData["displayName"];
        userData["userid"] =
            User.userIdFromName(userData["displayName"] ?? "") ??
            randomAlphaNumeric(8).toLowerCase();
        if (ServerDataBases.checkIfUsernameExists(displayName)) {
          return Response.forbidden("A user with the same name already exists");
        }
        int iter = 0;
        while (ServerDataBases.checkIfUserIdExists(userData["userid"])) {
          userData["userid"] = randomAlphaNumeric(
            8 + (iter / 10).floor(),
          ).toLowerCase();
          if (iter > 500) {
            return Response.internalServerError(
              body:
                  "To many attempts at trying to find a suitable user id, wtf is happening ?",
            );
          }
        }
        final String password = payload["password"];
        if (password.isEmpty) {
          return Response.forbidden("Empty password not allowed");
        }
        final User userdata = User.fromJson(userData);
        ServerDataBases.saveUserData(userdata);
        final salt = tokenManager.getRandomSalt();
        final pHash = tokenManager.hashPassword(password, salt);
        final credDb = sqlite3.open(ServerLocalFiles.credentialsDatabase.path);
        credDb.execute(
          "INSERT INTO credentials (userid,password,salt) VALUES (?,?,?);",
          [userData["userid"], pHash, salt],
        );
        credDb.dispose();
        tokenManager.consumeRegisterKey(registerKey);
        return Response.ok(jsonEncode(userdata.toJson()));
      } catch (_) {
        return Response.internalServerError(
          body: "Internal server error : probably an incorrect json",
        );
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

  return _handleAuthenticatedRequest(request, auth, tokenManager);
}

Future<Response> _handleAuthenticatedRequest(
  Request request,
  String token,
  AuthManager tokenManager,
) async {
  final Map<String, String> headers = request.headers;
  final List<String> path = request.requestedUri.pathSegments;

  switch (path[1]) {
    case "check-token":
      final checked = tokenManager.checkToken(token);
      return checked
          ? Response.ok("valid token")
          : Response.unauthorized("bad token (expired or invalid)");
  }

  return Response.notFound("");
}
