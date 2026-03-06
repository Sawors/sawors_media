import 'dart:io';

import 'package:sawors_media_common/local_files.dart';
import 'package:sqlite3/sqlite3.dart';

extension ServerLocalFiles on LocalFiles {
  static Directory get serverDataDir {
    return Directory("${LocalFiles.dataDir.path}/server");
  }

  static Directory get serverConfigDir {
    return Directory("${LocalFiles.configDir.path}/server");
  }

  static File get credentialsDatabase {
    return File("${serverDataDir.path}/credentials.sqlite");
  }

  static Future<void> initializeLocalFiles() async {
    await serverDataDir.create(recursive: true);
    await serverConfigDir.create(recursive: true);
  }

  static Future<void> initializeCredentialsDb() async {
    await credentialsDatabase.create(recursive: true);
    final db = sqlite3.open(credentialsDatabase.path);
    db.execute("""
    CREATE TABLE IF NOT EXISTS credentials (
      key INTEGER NOT NULL PRIMARY KEY,
      name TEXT UNIQUE NOT NULL,
      password BLOB NOT NULL,
      salt BLOB NOT NULL
    )
    """);
  }
}
