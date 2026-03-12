import 'dart:convert';

import 'package:sawors_media_common/user.dart';
import 'package:sawors_media_server/content/meta.dart';
import 'package:sawors_media_server/databases.dart';
import 'package:sawors_media_server/handler/authenticated/meta_handler.dart';
import 'package:sawors_media_server/handler/login_handler.dart';
import 'package:sawors_media_server/logging.dart';
import 'package:sawors_media_server/token_manager.dart';
import 'package:shelf/shelf.dart';

import 'handler/branding_request.dart';
import 'handler/register_handler.dart';

//
// Future<Response> handleRequest(
//   Request request, {
//   required AuthManager authManager,
//   ServerLogger? logger,
// }) async {
//   if (auth == null || auth.isEmpty) {
//     return Response.unauthorized(
//       "Unauthenticated access forbidden for this path",
//     );
//   }
//
//   return _handleAuthenticatedRequest(
//     request,
//     auth,
//     authManager,
//     logger: logger,
//   );
// }
//
// Future<Response> _handleAuthenticatedRequest(
//   Request request,
//   String token,
//   AuthManager authManager, {
//   ServerLogger? logger,
// }) async {
//   final Map<String, String> headers = request.headers;
//   final List<String> path = request.requestedUri.pathSegments;
//   final ip =
//       (request.context['shelf.io.connection_info'] as HttpConnectionInfo?)
//           ?.remoteAddress
//           .address;
//
//   final String? userid = authManager.getUserIdOfToken(token);
//   if (userid == null) {
//     logger?.logSystemAction(
//       ServerLogType.error,
//       "a JWT with no user has been validated",
//     );
//     return Response.internalServerError(
//       body: "no user associated with this token",
//     );
//   }
//
//   switch (path[1]) {
//     case "check-token":
//       final checked = authManager.checkToken(token);
//       return checked
//           ? Response.ok("valid token")
//           : Response.unauthorized("bad token (expired or invalid)");
//     case "user-data":
//       final user = ServerDataBases.getUserData(userid);
//       return Response.ok(jsonEncode(user?.toJson()));
//   }
//
//   return Response.notFound("");
// }

class ServerResponseHandler {
  final AuthManager authManager;
  final ServerLogger logger;
  final MetaManager metaManager;

  ServerResponseHandler({
    required this.authManager,
    required this.logger,
    required this.metaManager,
  });

  Future<Response> requestEntryPoint(Request request) async {
    final Map<String, String> headers = request.headers;
    final String? auth = headers["authorization"];
    final noAuthPass = await handleRequest(request);
    if (noAuthPass != null) {
      return noAuthPass;
    }

    if (auth == null || auth.isEmpty) {
      return Response.unauthorized(
        "This request does not exist, or you must be authentified to do it.",
      );
    }

    final String? userid = authManager.getUserIdOfToken(auth);
    if (userid == null || !authManager.checkToken(auth)) {
      logger.logSystemAction(
        ServerLogType.error,
        "a JWT with no user has been validated (or the token was created with an old secret key)",
      );
      return Response.internalServerError(
        body: "No user associated with this token, or token invalid.",
      );
    }

    final authPass = await handleAuthenticatedRequest(request, userid);

    return authPass ?? Response.notFound("Request not found");
  }

  Future<Response?> handleRequest(Request request) async {
    final Map<String, String> headers = request.headers;
    final List<String> path = request.requestedUri.pathSegments;

    if (path.isEmpty || path.first != "api") {
      return Response.badRequest(
        body:
            "The requested path should always start with api/ to reach the server !",
      );
    }

    // paths accessible without an auth token
    switch (path[1]) {
      case "check-token":
        final token = headers["authorization"];
        if (token == null) {
          return Response.unauthorized("you sent a null token");
        }
        final checked = authManager.checkToken(token);
        return checked
            ? Response.ok("valid token")
            : Response.unauthorized("bad token (expired or invalid)");
      case "login":
        return handleLoginRequest(request, authManager, logger);
      case "register":
        return handleRegisterRequest(request, authManager, logger);
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
      case "branding":
        return handleBrandingRequest(request);
    }
    return null;
  }

  Future<Response?> handleAuthenticatedRequest(
    Request request,
    String userid,
  ) async {
    final List<String> path = request.requestedUri.pathSegments;

    switch (path[1]) {
      case "user-data":
        final user = ServerDataBases.getUserData(userid);
        return Response.ok(jsonEncode(user?.toJson()));
      case "meta":
        return handleMetaRequest(request, metaManager);
      case "library-list":
        return Response.ok(jsonEncode(metaManager.libraryIds.toList()));
      // One day, I might stop being stupid and remove this.
      case "resource-bundled":
        return handleResourceRequest(request, metaManager);
      // And this is the correct way (above is juste pure malice and hate for my processing power)
      case "resource":
        return handleRawResourceRequest(request, metaManager);
    }
    return null;
  }
}
