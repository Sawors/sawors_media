import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class Homepage extends StatelessWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // di/service_locator.dart

    final now = DateTime.timestamp().millisecondsSinceEpoch;
    GetIt.instance<Dio>().get("/test").then((r) {
      try {
        final stamp = int.parse(jsonDecode(r.data)["timestamp"]);
        print("Server latency : ${stamp - now}ms");
      } catch (_) {}
    });
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Home", style: Theme.of(context).textTheme.displayMedium),
            TextButton(
              onPressed: () {
                final now = DateTime.timestamp().millisecondsSinceEpoch;
                GetIt.instance<Dio>().get("/test").then((r) {
                  try {
                    final stamp = int.parse(jsonDecode(r.data)["timestamp"]);
                    print("Server latency : ${stamp - now}ms");
                  } catch (_) {}
                });
              },
              child: Text(
                "test connection",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton(
              onPressed: () {
                GetIt.instance<Dio>().get("/check-token").then((r) {
                  try {
                    print("Valid token");
                  } catch (_) {}
                }, onError: (e) => print("Auth failure"));
              },
              child: Text(
                "test auth",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
