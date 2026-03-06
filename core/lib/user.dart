import 'package:string_validator/string_validator.dart';

class User {
  final String id;
  final Uri profilePicture;
  final String key;
  final String displayName;

  User({
    required this.id,
    required this.profilePicture,
    required this.key,
    required this.displayName,
  });

  static bool validateUsername(String username) {
    final List<String> allowedChars = ["-", " ", "_", "."];
    return username.isNotEmpty &&
        username.length < 16 &&
        isAlphanumeric(
          username
              // could be reduced to a .splitMapJoin
              .split("")
              .map((s) => allowedChars.contains(s) ? "" : s)
              .join(),
        );
  }
}
