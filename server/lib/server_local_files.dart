import 'dart:io';

import 'package:sawors_media_common/local_files.dart';

extension ServerLocalFiles on LocalFiles {
  static Directory get serverDataDir {
    return Directory("${LocalFiles.dataDir.path}/server");
  }

  static Directory get serverConfigDir {
    return Directory("${LocalFiles.configDir.path}/server");
  }

  static Directory get serverBrandingDir {
    return Directory("${serverDataDir.path}/branding");
  }

  static File get credentialsDatabase {
    return File("${serverDataDir.path}/credentials.sqlite");
  }

  static File get loggingDatabase {
    return File("${serverDataDir.path}/logs.sqlite");
  }

  static File get userinfoDatabase {
    return File("${serverDataDir.path}/users.sqlite");
  }

  static File get registerKeysDatabase {
    return File("${serverDataDir.path}/register-keys.sqlite");
  }

  static Future<void> initializeLocalFiles() async {
    await serverDataDir.create(recursive: true);
    await serverConfigDir.create(recursive: true);
  }
}
