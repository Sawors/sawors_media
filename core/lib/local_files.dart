import 'dart:io';

abstract class LocalFiles {
  static Directory get configDir {
    if (Platform.isLinux || Platform.isMacOS) {
      return Directory("${Platform.environment["HOME"]}/.config/sawors-media");
    } else if (Platform.isWindows) {
      return Directory(
        "${Platform.environment['UserProfile']}\\AppData\\Local\\sawors-media",
      );
    }

    throw PlatformImplementationException(
      "Config directory not implemented for this platform !",
    );
  }

  static Directory get dataDir {
    if (Platform.isLinux || Platform.isMacOS) {
      return Directory(
        "${Platform.environment["HOME"]}/.local/share/sawors-media",
      );
    } else if (Platform.isWindows) {
      return Directory("${Platform.environment['ProgramData']}\\sawors-media");
    }

    throw PlatformImplementationException(
      "Data directory not implemented for this platform !",
    );
  }
}

class PlatformImplementationException extends Error {
  final String message;
  PlatformImplementationException(this.message);
}
