import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sawors_media_common/meta.dart';

class ClientMetaManager {
  final Map<String, MovieMeta?> _metas;
  final Dio dio;

  ClientMetaManager({required this.dio, Map<String, MovieMeta>? metas})
    : _metas = metas ?? {};

  Iterable<String> get metas => _metas.keys;

  Future<Iterable<String>> fetchMetas() async {
    final response = await dio.get("library-list");
    final body = response.data;
    if (body != null) {
      final rez = jsonDecode(body) as List<dynamic>;
      _metas.addEntries(rez.map((r) => MapEntry(r, null)));
    }
    return _metas.keys;
  }

  Future<MovieMeta?> getMeta(
    String metaId, {
    bool useCache = true,
    bool forceRefreshCache = false,
  }) async {
    return (await getMultipleMetas(
      [metaId],
      useCache: useCache,
      forceRefreshCache: forceRefreshCache,
    ))?.values.first;
  }

  Future<Map<String, MovieMeta?>?> getMultipleMetas(
    List<String> metaId, {
    bool useCache = true,
    bool forceRefreshCache = false,
  }) async {
    final toFetch = [];
    final Map<String, MovieMeta?> result = {};
    for (String id in metaId) {
      final cached = _metas[id];
      if (cached != null && !forceRefreshCache) {
        result[id] = cached;
      } else {
        toFetch.add(id);
      }
    }
    try {
      final dr = await dio.get("/meta", data: jsonEncode({"meta": toFetch}));
      final data = dr.data;
      final jsonData = jsonDecode(data);
      result.addEntries(
        (jsonData as Map<String, dynamic>).entries.map((entry) {
          final p = entry.value;
          final m = entry.key;
          if (p != null) {
            final meta = MovieMeta.fromJson(p);
            _metas[m] = meta;
            return MapEntry(m.toString(), meta);
          }
          return MapEntry(m.toString(), null);
        }),
      );
      return result;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      rethrow;
    }
  }

  Future<List<int>?> getResource(
    String metaId,
    MetaResourceIdentifier resource,
  ) async {
    try {
      final response = await dio.get(
        "/resource",
        data: jsonEncode({"meta": metaId, "resource": resource.name}),
        options: Options(responseType: ResponseType.bytes),
      );
      final data = response.data as List<int>;
      return data;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    return null;
  }
}
