import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:sawors_media_common/meta.dart';
import 'package:xml/xml.dart';

extension MovieMetaNFO on MovieMeta {
  static MovieMeta fromNFO(
    XmlDocument xmlDocument,
    String metaLanguage, {
    String? internalIdOverride,
  }) {
    final originalNFO = xmlDocument;
    final data = xmlDocument.getElement("movie");
    if (data == null) {
      throw ArgumentError("this is not a correct NFO");
    }
    final title = data.getElement("title")?.innerText ?? "";
    final releaseDate = DateTime.tryParse(
      data.getElement("releasedate")?.innerText ?? "",
    );
    final plot = data.getElement("plot")?.innerText ?? "";
    final tagLine = data.getElement("tagline")?.innerText ?? "";
    final originalTitle = data.getElement("originaltitle")?.innerText ?? "";
    final runtime =
        int.tryParse(data.getElement("runtime")?.innerText ?? "0") ?? 0;
    final countries = data
        .findElements("country")
        .map((e) => e.innerText)
        .toList();
    final genres = data.findElements("genre").map((e) => e.innerText).toList();
    final tags = data.findElements("tag").map((e) => e.innerText).toList();
    final studios = data
        .findElements("studio")
        .map(
          // TODO : Studio from text
          (e) => StudioMeta(
            name: e.innerText,
            description: "",
            type: StudioMetaType.production,
          ),
        )
        .toList();
    final production = data
        .findElements("actor")
        // TODO : Person database integration
        .map((e) => PersonMetaNFO.fromNFO(e, DateTime(0), metaLanguage))
        .toList();

    return MovieMeta(
      production: production,
      title: title,
      releaseDate: releaseDate,
      plot: plot,
      tagLine: tagLine,
      originalTitle: originalTitle,
      metaLanguage: metaLanguage,
      runtime: runtime,
      countries: countries,
      genres: genres,
      tags: tags,
      studios: studios,
      databasesIds: {
        "imdb": data.getElement("imdbid")?.innerText,
        "tmdb": data.getElement("tmdbid")?.innerText,
      },
      originalNFO: originalNFO,
      metaId:
          internalIdOverride ??
          MediaMeta.internalIdFromTitle(originalTitle, releaseDate?.year ?? 0),
    );
  }
}

extension PersonMetaNFO on PersonMeta {
  static PersonMeta fromNFO(
    XmlElement nfo,
    DateTime birth,
    String metaLanguage,
  ) {
    final String role =
        nfo.getElement("type")?.innerText.toLowerCase() ?? "other";
    final type =
        PersonMetaType.values.firstWhereOrNull((w) => w.name == role) ??
        PersonMetaType.other;
    final String name = nfo.getElement("name")?.innerText ?? "Mystery Man";
    final String character = nfo.getElement("role")?.innerText ?? "Mystery Man";
    switch (type) {
      case PersonMetaType.actor:
        return ActorPersonMeta(
          type: type,
          name: name,
          birth: birth,
          character: character,
        );
      case PersonMetaType.voice:
        return VoicePersonMeta(
          type: type,
          name: name,
          birth: birth,
          character: character,
          language: metaLanguage,
        );
      default:
        return PersonMeta(
          type:
              PersonMetaType.values.firstWhereOrNull((w) => w.name == role) ??
              PersonMetaType.other,
          name: name,
          birth: birth,
        );
    }
  }
}

class MetaManager {
  // TODO : handle multiple libraries and index everything at the startup of the server
  final Map<String, String> _metaDirMatch = {};

  Iterable<String> get libraryIds => _metaDirMatch.keys;

  Future<void> loadLibraries(List<Directory> libraries) async {
    for (Directory d in libraries) {
      for (var fe in d.listSync()) {
        if (await FileSystemEntity.isDirectory(fe.path)) {
          final meta = await _getMetaFromDir(fe.path);
          if (meta != null) {
            final String id = meta.metaId;
            _metaDirMatch[id] = fe.path;
          }
        }
      }
    }
  }

  Future<MovieMeta?> getMeta(String metaId) async {
    final path = _metaDirMatch[metaId];
    if (path == null) {
      return null;
    }
    return _getMetaFromDir(path);
  }

  Future<MovieMeta?> _getMetaFromDir(
    String directoryPath, {
    writeMissingJson = true,
    overwriteExistingJson = false,
  }) async {
    final File jsonMeta = File("$directoryPath/meta.json");
    bool forceJsonWrite = writeMissingJson;
    if (await jsonMeta.exists()) {
      try {
        final rez = MovieMeta.fromJson(
          jsonDecode(await jsonMeta.readAsString()),
        );
        if (overwriteExistingJson) {
          await jsonMeta.writeAsString(jsonEncode(rez.toJson()));
        }
        return rez;
      } on FormatException {
        // ignore and do NFO
        forceJsonWrite = true;
      } on TypeError {
        forceJsonWrite = true;
      }
    }
    final File legacyMeta = File("$directoryPath/movie.nfo");
    if (await legacyMeta.exists()) {
      try {
        final fContent = await legacyMeta.readAsString();
        final rez = MovieMetaNFO.fromNFO(XmlDocument.parse(fContent), "fr");
        if (forceJsonWrite) {
          await jsonMeta.writeAsString(jsonEncode(rez.toJson()));
        }
        return rez;
      } catch (E) {
        print(E);
      }
    }
    return null;
  }

  Future<List<int>?> getResource(
    String metaId,
    MetaResourceIdentifier identifier,
  ) async {
    final path = _metaDirMatch[metaId];
    if (path == null) {
      return null;
    }
    final resourcePath = File(
      "$path/${identifier.name}.${identifier == MetaResourceIdentifier.logo ? "png" : "jpg"}",
    );
    final exists = await resourcePath.exists();
    if (exists) {
      final Uint8List bytes = await resourcePath.readAsBytes();
      return bytes;
    }
    return null;
  }
}
