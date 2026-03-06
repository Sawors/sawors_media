import 'dart:io';

import 'package:sawors_media_common/media.dart';
import 'package:xml/xml.dart';

extension MetaNFO on Metadata {
  static Future<Metadata> fromNFO(File nfo) async {
    final data = await nfo.readAsString();
    final xml = XmlDocument.parse(data);
    return Metadata.fromMap({});
  }
}
