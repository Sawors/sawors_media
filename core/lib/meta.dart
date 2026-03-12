import 'package:json_annotation/json_annotation.dart';
import 'package:xml/xml.dart';

part 'meta.g.dart';

class Media {
  final Uri uri;
  final String name;

  Media({required this.uri, required this.name});
}

enum MediaMetaType { movie, music, series, season, episode, book }

abstract class MediaMeta {
  final String title;
  @JsonKey(includeToJson: false, readValue: _internalIdFromJson)
  final String metaId;

  MediaMeta({required this.title, required this.metaId});
  MediaMetaType get type;

  static String internalIdFromTitle(String title, int year) {
    return "${Uri.encodeComponent(title.toLowerCase().replaceAll(" ", "-"))}-${Uri.encodeComponent(year.toString())}";
  }

  static String _internalIdFromJson(
    Map<dynamic, dynamic> json,
    String jsonKey,
  ) => internalIdFromTitle(
    json["originalTitle"],
    DateTime.parse(json["releaseDate"]).year,
  );
}

@JsonSerializable(createJsonSchema: true)
class MovieMeta extends MediaMeta {
  final String originalTitle;
  final DateTime? releaseDate;
  final String tagLine;
  final String plot;
  final int runtime;
  final String metaLanguage;
  final List<String> countries;
  final List<String> genres;
  final List<String> tags;
  final List<PersonMeta> production;
  final List<StudioMeta> studios;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final XmlDocument? originalNFO;
  final Map<String, String?> databasesIds;

  MovieMeta({
    required super.title,
    required super.metaId,
    required this.production,
    required this.releaseDate,
    required this.plot,
    required this.tagLine,
    required this.originalTitle,
    required this.metaLanguage,
    required this.runtime,
    required this.countries,
    required this.genres,
    required this.tags,
    required this.studios,
    this.originalNFO,
    required this.databasesIds,
  });

  @override
  MediaMetaType get type => MediaMetaType.movie;

  factory MovieMeta.fromJson(Map<String, dynamic> json) =>
      _$MovieMetaFromJson(json);

  /// Connect the generated [_$PersonToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$MovieMetaToJson(this);

  /// The JSON Schema for this class.
  static const jsonSchema = _$MovieMetaJsonSchema;
}

enum PersonMetaType {
  actor,
  producer,
  musician,
  author,
  director,
  writer,
  voice,
  technician,
  other,
}

@JsonSerializable(createJsonSchema: true)
class PersonMeta {
  final PersonMetaType type;
  final String name;
  final DateTime birth;

  PersonMeta({required this.type, required this.name, required this.birth});

  factory PersonMeta.fromJson(Map<String, dynamic> json) =>
      _$PersonMetaFromJson(json);

  /// Connect the generated [_$PersonToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$PersonMetaToJson(this);

  /// The JSON Schema for this class.
  static const jsonSchema = _$PersonMetaJsonSchema;
}

@JsonSerializable(createJsonSchema: true)
class VoicePersonMeta extends ActorPersonMeta {
  final String language;

  VoicePersonMeta({
    required super.type,
    required super.name,
    required super.birth,
    required super.character,
    required this.language,
  });

  @override
  PersonMetaType get type => PersonMetaType.voice;

  factory VoicePersonMeta.fromJson(Map<String, dynamic> json) =>
      _$VoicePersonMetaFromJson(json);

  /// Connect the generated [_$PersonToJson] function to the `toJson` method.
  @override
  Map<String, dynamic> toJson() => _$VoicePersonMetaToJson(this);

  /// The JSON Schema for this class.
  static const jsonSchema = _$VoicePersonMetaJsonSchema;
}

@JsonSerializable(createJsonSchema: true)
class ActorPersonMeta extends PersonMeta {
  late final String character;

  ActorPersonMeta({
    required super.type,
    required super.name,
    required super.birth,
    required this.character,
  });

  @override
  PersonMetaType get type => PersonMetaType.actor;
  factory ActorPersonMeta.fromJson(Map<String, dynamic> json) =>
      _$ActorPersonMetaFromJson(json);

  /// Connect the generated [_$PersonToJson] function to the `toJson` method.
  @override
  Map<String, dynamic> toJson() => _$ActorPersonMetaToJson(this);

  /// The JSON Schema for this class.
  static const jsonSchema = _$ActorPersonMetaJsonSchema;
}

enum StudioMetaType { production, vfx, voice }

@JsonSerializable(createJsonSchema: true)
class StudioMeta {
  final String name;
  final String description;
  final StudioMetaType type;

  StudioMeta({
    required this.name,
    required this.description,
    required this.type,
  });

  factory StudioMeta.fromJson(Map<String, dynamic> json) =>
      _$StudioMetaFromJson(json);

  /// Connect the generated [_$PersonToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$StudioMetaToJson(this);

  /// The JSON Schema for this class.
  static const jsonSchema = _$StudioMetaJsonSchema;
}

enum MetaResourceIdentifier { poster, backdrop, logo, thumbnail, quickview }
