import 'dart:convert';

import 'package:sawors_media_common/user.dart';
import 'package:sawors_media_server/server_local_files.dart';
import 'package:sqlite3/sqlite3.dart';

abstract class ServerDataBases {
  static Future<void> initializeDatabases() async {
    await ServerLocalFiles.credentialsDatabase.create(recursive: true);
    final credDb = sqlite3.open(ServerLocalFiles.credentialsDatabase.path);
    credDb.execute("""
    CREATE TABLE IF NOT EXISTS credentials (
      key INTEGER NOT NULL PRIMARY KEY,
      userid TEXT UNIQUE NOT NULL,
      password BLOB NOT NULL,
      salt BLOB NOT NULL
    )
    """);
    credDb.dispose();
    await ServerLocalFiles.userinfoDatabase.create(recursive: true);
    final userDb = sqlite3.open(ServerLocalFiles.userinfoDatabase.path);
    userDb.execute("""
    CREATE TABLE IF NOT EXISTS users (
      key INTEGER NOT NULL PRIMARY KEY,
      userid TEXT UNIQUE NOT NULL,
      display_name TEXT NOT NULL,
      profile_picture TEXT,
      preferences TEXT
    )
    """);
    userDb.dispose();
    await ServerLocalFiles.registerKeysDatabase.create(recursive: true);
    final regKeyDb = sqlite3.open(ServerLocalFiles.registerKeysDatabase.path);
    regKeyDb.execute("""
    CREATE TABLE IF NOT EXISTS keys (
      id INTEGER NOT NULL PRIMARY KEY,
      key_value TEXT UNIQUE NOT NULL,
      created TEXT,
      valid_until TEXT
    )
    """);
    regKeyDb.dispose();
  }

  static void saveUserData(User user) {
    final db = sqlite3.open(ServerLocalFiles.userinfoDatabase.path);
    db.execute(
      """REPLACE INTO users (userid,display_name,profile_picture,preferences) VALUES (?,?,?,?)""",
      [
        user.userid,
        user.displayName,
        user.profilePicture?.toString(),
        jsonEncode(user.preferences.toJson()),
      ],
    );
    db.dispose();
  }

  static User? getUserData(String userid) {
    final db = sqlite3.open(ServerLocalFiles.userinfoDatabase.path);
    final select = db.select("SELECT * FROM users WHERE userid = ?", [userid]);
    db.dispose();
    if (select.isEmpty) {
      return null;
    }
    final preferences = select.first["preferences"];
    return User(
      userid: userid,
      profilePicture: Uri.tryParse(select.first["profile_picture"]),
      displayName: select.first["display_name"],
      preferences: preferences != null
          ? UserPreferences.fromJson(jsonDecode(preferences))
          : null,
    );
  }

  static bool checkIfUsernameExists(String displayName) {
    final userInfoDb = sqlite3.open(ServerLocalFiles.userinfoDatabase.path);
    final result = userInfoDb.select(
      "SELECT EXISTS (SELECT 1 FROM users WHERE LOWER(display_name) = ?);",
      [displayName.toLowerCase()],
    );
    userInfoDb.dispose();
    return result.isNotEmpty;
  }

  static bool checkIfUserIdExists(String userid) {
    if (!User.validateUserId(userid)) {
      throw FormatException("userid is not correct");
    }
    final userInfoDb = sqlite3.open(ServerLocalFiles.userinfoDatabase.path);
    final result = userInfoDb.select(
      "SELECT EXISTS (SELECT 1 FROM users WHERE userid = ?);",
      [userid.toLowerCase()],
    );
    userInfoDb.dispose();
    return result.first.values.any((v) => v == 1);
  }
}
