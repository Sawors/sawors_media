dynamic getPathMapValue(
  Map<String, dynamic> map,
  String path, {
  dynamic defaultValue,
  String pathSeparator = ".",
}) {
  final split = path.split(pathSeparator);
  dynamic parent = map;
  for (String sub in split) {
    if (!parent is Map<String, Object?>) {
      return defaultValue;
    }
    if (!(parent as Map<String, Object?>).containsKey(sub)) {
      return defaultValue;
    }
    final child = parent[sub];
    parent = child;
  }

  return parent;
}

Map<String, dynamic> setPathMapValue(
  Map<String, dynamic> map,
  String path,
  dynamic value, {
  String pathSeparator = ".",
}) {
  final split = path.split(pathSeparator);
  Map<String, dynamic> parent = map;
  for (String sub in split.sublist(0, split.length - 1)) {
    if (!parent.containsKey(sub)) {
      parent[sub] = {} as Map<String, dynamic>;
    }
    parent = parent[sub];
  }
  parent[split.last] = value;
  return map;
}
