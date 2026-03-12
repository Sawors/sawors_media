import 'dart:io';

import 'package:sawors_media_server/databases.dart';
import 'package:sawors_media_server/server_local_files.dart';
import 'package:sqlite3/sqlite3.dart';

class ServerLogger {
  final Database _dbConnection = sqlite3.open(
    ServerLocalFiles.loggingDatabase.path,
  );
  void logUserAction(
    String userid,
    String? ip,
    UserLogType type,
    String message, {
    printToStdout = true,
  }) {
    final now = DateTime.timestamp();
    _dbConnection.execute(
      "INSERT INTO logs (timestamp,userid,ip,type,message) VALUES (?,?,?,?,?)",
      [now.toIso8601String(), userid.toLowerCase(), ip, type.name, message],
    );
    if (printToStdout) {
      printToStd(now, type.name, userid, message);
    }
  }

  void logSystemAction(
    ServerLogType type,
    String message, {
    printToStdout = true,
  }) {
    final now = DateTime.timestamp();
    _dbConnection.execute(
      "INSERT INTO logs (timestamp,userid,ip,type,message) VALUES (?,?,?,?,?)",
      [
        now.toIso8601String(),
        ServerDataBases.systemUserId,
        null,
        type.name,
        message,
      ],
    );
    if (printToStdout) {
      printToStd(now, type.name, ServerDataBases.systemUserId, message);
    }
  }

  void printToStd(
    DateTime timestamp,
    String typeString,
    String userid,
    String message,
  ) {
    stdout.writeln(
      "[${timestamp.toLocal()}] ${typeString.toUpperCase().replaceAll("-", "_")} | $userid : $message",
    );
  }

  void dispose() {
    _dbConnection.dispose();
  }
}

enum ServerLogType { start, stop, error, message }

enum UserLogType { login, logout, register, message, error }
