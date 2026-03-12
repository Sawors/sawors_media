import 'dart:convert';
import 'dart:io';

import 'package:sawors_media_common/user.dart';
import 'package:sawors_media_server/logging.dart';
import 'package:sawors_media_server/token_manager.dart';
import 'package:shelf/shelf.dart';

import '../databases.dart';

Future<Response> handleLoginRequest(
  Request request,
  AuthManager authManager,
  ServerLogger logger,
) async {
  final ip =
      (request.context['shelf.io.connection_info'] as HttpConnectionInfo?)
          ?.remoteAddress
          .address;
  try {
    final String body = await request.readAsString();
    final data = jsonDecode(body);
    final String? password = data["password"];
    final String? userid = data["userid"]?.toString().toLowerCase();
    if (userid == null || password == null || !User.validateUsername(userid)) {
      return Response.badRequest(body: "Bad json request");
    }
    if (!ServerDataBases.checkIfUserIdExists(userid)) {
      return Response.forbidden("User does not exist");
    }
    if (!(await authManager.checkCredentials(userid, password))) {
      logger.logUserAction(
        userid,
        ip,
        UserLogType.error,
        "user failed to login",
      );
      return Response.forbidden("Bad password or user does not exist");
    }
    final token = authManager.createTokenForUser(userid);
    final signed = authManager.signToken(token, userid);
    logger.logUserAction(
      userid,
      ip,
      UserLogType.login,
      "generated token: $signed",
    );

    print("Signed : $signed");
    return Response.ok(signed);
  } catch (e) {
    return Response.forbidden("bad credentials");
  }
}
