class Media {
  final Uri uri;
  final String name;

  Media({required this.uri, required this.name});
}

class Metadata {
  final Map<String, dynamic> _raw;

  Metadata.fromMap(this._raw);
}
