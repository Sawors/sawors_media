import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:sawors_media_common/meta.dart';
import 'package:sawors_media_server/content/meta.dart';
import 'package:shelf/shelf.dart';

Future<Response?> handleMetaRequest(
  Request request,
  MetaManager metaManager,
) async {
  final String body = await request.readAsString();
  try {
    final jsonData = jsonDecode(body);
    final Iterable<String> metas = jsonData["meta"] is List<dynamic>
        ? (jsonData["meta"] as List<dynamic>).map((e) => e.toString())
        : [jsonData["meta"].toString()];
    final Iterable<String> fields =
        jsonData["fields"] != null && jsonData["fields"] is List<dynamic>
        ? (jsonData["fields"] as List<dynamic>).map((e) => e.toString())
        : [];
    final Map<String, dynamic> response = {};
    for (String m in metas) {
      try {
        final metaQueryResult = await metaManager.getMeta(m);
        print(metaQueryResult);
        final json = metaQueryResult?.toJson();
        if (json != null && fields.isNotEmpty) {
          json.removeWhere((k, v) => !fields.contains(k));
        }
        response[m] = json;
      } catch (e) {
        print(e);
        response[m] = null;
      }
    }
    return Response.ok(jsonEncode(response));
  } catch (e) {
    print(e);
    return Response.badRequest(body: "Bad json body");
  }
}

Future<Response?> handleResourceRequest(
  Request request,
  MetaManager metaManager,
) async {
  final String body = await request.readAsString();
  try {
    final jsonData = jsonDecode(body);
    final Iterable<String> metas = jsonData["meta"] is List<dynamic>
        ? (jsonData["meta"] as List<dynamic>).map((e) => e.toString())
        : [jsonData["meta"].toString()];
    final Iterable<String> resources = jsonData["resources"] != null
        ? jsonData["resources"] is String
              ? [jsonData["resources"]]
              : (jsonData["resources"] as List<dynamic>).map(
                  (e) => e.toString(),
                )
        : [];
    final Map<String, dynamic> response = {};
    Future<List<int>?> getResource(
      String metaId,
      MetaResourceIdentifier resourceIdentifier,
    ) async {
      final file = File(
        "test/resources/movies/A Minecraft Movie (2025)/${resourceIdentifier.name}.${resourceIdentifier == MetaResourceIdentifier.logo ? "png" : "jpg"}",
      );
      if (!await file.exists()) {
        return null;
      }
      final bytes = await file.readAsBytes();
      return bytes;
    }

    final t0 = DateTime.now().millisecondsSinceEpoch;
    for (String m in metas) {
      try {
        if (resources.isNotEmpty) {
          final keys = response.keys;
          final resourceMap = {};
          if (resources.any((r) => r == "all")) {
            for (MetaResourceIdentifier mri in MetaResourceIdentifier.values) {
              resourceMap[mri.name] = await metaManager.getResource(m, mri);
            }
            response[m] = resourceMap;
            continue;
          }
          for (String res in resources) {
            final identifier = MetaResourceIdentifier.values.firstWhereOrNull(
              (v) => v.name == res,
            );
            if (identifier == null) {
              resourceMap[res] = null;
              continue;
            }
            if (keys.contains(res)) {
              continue;
            }
            // TODO : Evaluate 3 approaches :
            //  - base64-encoding the images
            //  - returning the raw ints (which implies parsing both ways ?) -> now we are doing it as raw-bytes
            //  - returning an URL to a CDN to access the image
            resourceMap[res] = await metaManager.getResource(m, identifier);
          }
          response[m] = resourceMap;
        }
      } catch (e) {
        response[m] = null;
      }
    }
    print("Read time : ${DateTime.now().millisecondsSinceEpoch - t0}ms");
    return Response.ok(jsonEncode(response));
  } catch (e) {
    print(e);
    return Response.badRequest(body: "Bad json body");
  }
}

Future<Response?> handleRawResourceRequest(
  Request request,
  MetaManager metaManager,
) async {
  final String body = await request.readAsString();
  try {
    final jsonData = jsonDecode(body);
    final String meta = jsonData["meta"];
    final String resource = jsonData["resource"];

    final identifier = MetaResourceIdentifier.values.firstWhereOrNull(
      (v) => v.name == resource,
    );
    if (identifier == null) {
      return Response.notFound("Resource does not exist");
    }
    final rData = await metaManager.getResource(meta, identifier);
    return Response.ok(rData);
  } catch (e) {
    print(e);
    return Response.badRequest(body: "Bad json body");
  }
}
