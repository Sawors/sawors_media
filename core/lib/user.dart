import 'package:json_annotation/json_annotation.dart';
import 'package:sawors_media_common/utils.dart';
import 'package:string_validator/string_validator.dart';

part "user.g.dart";

@JsonSerializable(createJsonSchema: true)
class User {
  final String userid;
  final Uri? profilePicture;
  final String displayName;
  late final UserPreferences preferences;

  User({
    required this.userid,
    required this.profilePicture,
    required this.displayName,
    UserPreferences? preferences,
  }) {
    this.preferences = preferences ?? UserPreferences();
  }

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  /// Connect the generated [_$PersonToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$UserToJson(this);

  /// The JSON Schema for this class.
  static const jsonSchema = _$UserJsonSchema;

  static bool validateUsername(
    String username, {
    List<String>? allowedChars,
    int maxLength = 16,
  }) {
    final List<String> usedAllowedChars = allowedChars ?? ["-", " ", "_", "."];
    return username.isNotEmpty &&
        username.length <= maxLength &&
        removeDiacritics(
          username
              // could be reduced to a .splitMapJoin
              .split("")
              .map((s) => usedAllowedChars.contains(s) ? "" : s)
              .join(),
        ).isAlphanumeric;
  }

  static String? userIdFromName(String username) {
    if (!validateUsername(username)) {
      return null;
    }
    final commonConv = ["_", " ", "-"];
    final String converted = removeDiacritics(username.toLowerCase())
        .split("")
        .map((c) {
          if (c.isAlphanumeric) {
            return c;
          }
          if (commonConv.contains(c)) {
            return "-";
          }
          return "";
        })
        .join();
    return validateUserId(converted) ? converted : null;
  }

  static bool validateUserId(String userid) {
    return (!userid.split("").any((c) => c.isAlpha && c.isUppercase)) &&
        validateUsername(userid, allowedChars: ["-"]);
  }
}

@JsonSerializable(createJsonSchema: true)
class UserPreferences {
  final String language;
  final String theme;
  final int ageLimit;

  UserPreferences({
    this.language = "en-us",
    this.theme = "default-dark",
    this.ageLimit = -1,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      _$UserPreferencesFromJson(json);

  /// Connect the generated [_$PersonToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$UserPreferencesToJson(this);

  /// The JSON Schema for this class.
  static const jsonSchema = _$UserPreferencesJsonSchema;
}
