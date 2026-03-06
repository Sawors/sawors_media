import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:sawors_media_common/user.dart';
import 'package:sawors_media_server/server_local_files.dart';
import 'package:sawors_media_server/token_manager.dart';
import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart';

Future<Response> handleRequest(
  Request request, {
  required TokenManager tokenManager,
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
        final String? username = data["name"]?.toString().toLowerCase();
        if (username == null ||
            password == null ||
            !User.validateUsername(username)) {
          return Response.badRequest(body: "Bad json request");
        }
        final db = sqlite3.open(ServerLocalFiles.credentialsDatabase.path);
        final select = db.select("SELECT * FROM credentials WHERE name = ?", [
          username,
        ]);
        if (select.rows.isEmpty) {
          print("User not found");
          return Response.badRequest(
            body: "User not found, please register instead of logging in",
          );
        }
        final List<int> salt = select.first["salt"];
        final List<int> storedPassword = select.first["password"];
        final pHash = await tokenManager.hashPassword(password, salt);
        if (!ListEquality().equals(storedPassword, pHash)) {
          return Response.forbidden("Bad password");
        }
        final token = tokenManager.createTokenForUser(username);
        final signed = tokenManager.signToken(token, username);
        return Response.ok(signed);
      } catch (e) {
        print(e);
        return Response.forbidden("bad credentials");
      }
      return Response.ok("token");
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
  TokenManager tokenManager,
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
