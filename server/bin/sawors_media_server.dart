import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:random_string/random_string.dart';
import 'package:sawors_media_server/response_handler.dart';
import 'package:sawors_media_server/server_local_files.dart';
import 'package:sawors_media_server/token_manager.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

void main(List<String> args) async {
  await ServerLocalFiles.initializeLocalFiles();
  await ServerLocalFiles.initializeCredentialsDb();

  final TokenManager tokenManager = TokenManager(
    serverId: 'media.sawors.net',
    // since tokens are not kept between server restarts, it is not necessary to
    // keep it between sessions.
    // TO CHANGE IF I DECIDE TO STORE TOKENS
    secretKey: SecretKey(
      Platform.environment["SAWORS_MEDIA_SECRET_KEY"] ?? randomString(32),
    ),
  );

  Map<String, String?> progArgs = Map.fromEntries(
    args.map((v) {
      final split = v.split("=");
      return MapEntry(split[0], split.elementAtOrNull(1));
    }),
  );

  var handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler((req) => handleRequest(req, tokenManager: tokenManager));

  var server = await shelf_io.serve(
    handler,
    '127.0.0.1',
    int.tryParse(progArgs["--port"] ?? "") ?? 4141,
  );

  // Enable content compression
  server.autoCompress = true;

  // final String username = "Sawors";
  // final List<int> salt = tokenManager.getRandomSalt();
  // final List<int> passwordHash = await tokenManager.hashPassword(
  //   "skibidi",
  //   salt,
  // );
  // final db = sqlite3.open(ServerLocalFiles.credentialsDatabase.path);
  // db.execute(
  //   "INSERT INTO credentials (name, password, salt) VALUES (?, ?, ?)",
  //   [username.toLowerCase(), passwordHash, salt],
  // );

  stdout.writeln('Serving at https://${server.address.host}:${server.port}');
}
