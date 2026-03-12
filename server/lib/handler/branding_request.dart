import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';

import '../server_local_files.dart';

final Map<String, dynamic> _branding = {};
const resources = [
  "favicon",
  "logo-color",
  "logo-light",
  "logo-dark",
  "icon-color",
  "icon-dark",
  "icon-light",
];

Future<Response> handleBrandingRequest(Request request) async {
  if (_branding.isEmpty) {
    final bFile = File(
      "${ServerLocalFiles.serverBrandingDir.path}/branding.json",
    );
    final defaultTitle = "Sawors Media";
    _branding["images"] = {"title": defaultTitle};

    if (await bFile.exists()) {
      try {
        final fData = jsonDecode(await bFile.readAsString());
        _branding["title"] = fData["title"] ?? defaultTitle;
        for (String f in resources) {
          final replacement = fData["images"]?[f];
          _branding["images"][f] = replacement ?? f;
        }
      } catch (_) {}
    }
  }
  final String body = (await request.readAsString()).trim();
  final List<String> fields = body.isNotEmpty
      ? (jsonDecode(body) as List<dynamic>).map((v) => v.toString()).toList()
      : resources;
  final Map<String, dynamic> rspBody = {"name": _branding["title"]};
  Future<void> addField(String fieldName) async {
    if (fields.isEmpty || fields.contains(fieldName)) {
      File logoFile = File(
        "${ServerLocalFiles.serverDataDir.path}/branding/${_branding["images"]?[fieldName] ?? fieldName}.png",
      );
      if (await logoFile.exists()) {
        final logoFileData = await logoFile.readAsBytes();
        rspBody[fieldName] = base64Encode(logoFileData);
      } else {
        rspBody[fieldName] = null;
      }
    }
  }

  for (String f in resources) {
    await addField(f);
  }
  return Response.ok(jsonEncode(rspBody));
}
