import 'dart:convert';
import 'dart:io';

import 'package:sawors_media_server/content/meta.dart';
import 'package:sawors_media_server/handler/authenticated/meta_handler.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

void main() {
  test('calculate', () {
    //expect(calculate(), 42);
  });

  test("nfo parsing", () async {
    final mFile = File(
      "test/resources/movies/A Minecraft Movie (2025)/movie.nfo",
    );
    final meta = MovieMetaNFO.fromNFO(
      XmlDocument.parse(await mFile.readAsString()),
      "fr",
    );
    print(JsonEncoder.withIndent("  ").convert(meta.toJson()));
    final oFile = File(
      "test/resources/movies/A Minecraft Movie (2025)/movie.json",
    );
    await oFile.writeAsString(jsonEncode(meta.toJson()));
    print(
      "FSize: n:${(await mFile.stat()).size} j:${(await oFile.stat()).size}",
    );
  });

  test("meta query", () async {
    final MetaManager metaManager = MetaManager();
    await metaManager.loadLibraries([Directory("test/resources/movies/")]);
    final String metaRef = "a-minecraft-movie_2025";
    final response = await handleMetaRequest(
      Request(
        "get",
        Uri.parse("https://media.sawors.net/api/meta"),
        body: jsonEncode({
          "meta": [metaRef],
          "fields": "all",
        }),
      ),
      metaManager,
    );
    print(
      JsonEncoder.withIndent(
        "    ",
      ).convert(jsonDecode((await response?.readAsString()) ?? "{}")),
    );

    final responseResource = await handleResourceRequest(
      Request(
        "get",
        Uri.parse("https://media.sawors.net/api/resource"),
        body: jsonEncode({
          "meta": [
            "a-minecraft-movie_20252",
            "a-minecraft-movie_20253",
            "a-minecraft-movie_20254",
            "a-minecraft-movie_20255",
            "a-minecraft-movie_20256",
            "a-minecraft-movie_20257",
            "a-minecraft-movie_20258",
            "a-minecraft-movie_20259",
            "a-minecraft-movie_20251",
            "a-minecraft-movie_20250",
          ],
          //"resources": "all",
          "resources": "all",
        }),
      ),
      metaManager,
    );
    final t0 = DateTime.now().millisecondsSinceEpoch;
    final body = jsonDecode(await responseResource?.readAsString() ?? "");
    final t1 = DateTime.now().millisecondsSinceEpoch - t0;
    print("fetch: ${t1}ms | mean: ${t1 / body.length}ms");
    final t0Raw = DateTime.now().millisecondsSinceEpoch;
    final responseResourceRaw = await handleRawResourceRequest(
      Request(
        "get",
        Uri.parse("https://media.sawors.net/api/resource-raw"),
        body: jsonEncode({
          "meta": "a-minecraft-movie_20252",
          //"resources": "all",
          "resource": "backdrop",
        }),
      ),
      metaManager,
    );
    final bodyRaw = await responseResourceRaw?.read().single;
    File out = File("/home/sawors/Downloads/image.jpg");
    await out.writeAsBytes(bodyRaw ?? []);
    final t1Raw = DateTime.now().millisecondsSinceEpoch - t0Raw;
    print("fetchRaw: ${t1Raw}ms | mean: ${t1Raw / body.length}ms");
    //print(JsonEncoder.withIndent("    ").convert(jsonDecode(body ?? "")));
  });

  test("init metamanager", () async {
    final MetaManager metaManager = MetaManager();
    await metaManager.loadLibraries([Directory("test/resources/movies/")]);
  });
}
