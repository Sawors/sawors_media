import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:sawors_media_client/auth/auth.dart';
import 'package:sawors_media_client/meta/meta_manager.dart';
import 'package:sawors_media_client/pages/routing.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
  static Future<void> loadApp(BuildContext context) async {
    final metaManager = GetIt.instance<ClientMetaManager>();
    print("init meta");
    await metaManager.fetchMetas();
    // and do all the rest of the logic of loading the app here
  }
}

class _SplashScreenState extends State<SplashScreen> {
  static Future<void> _startupProcedure(BuildContext context) async {
    final authManager = Provider.of<AuthProvider>(context);
    final loggedIn = await authManager.loginWithToken();
    if (loggedIn && context.mounted) {
      return SplashScreen.loadApp(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authManager = Provider.of<AuthProvider>(context);
    return FutureBuilder(
      future: _startupProcedure(context),
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.connectionState == ConnectionState.done) {
          if (authManager.isAuthenticated) {
            print("is_auth");
            Future.delayed(Duration(milliseconds: 10), () {
              if (context.mounted) {
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).popAndPushNamed(RouteName.home);
              }
            });
          } else {
            final error = asyncSnapshot.error;
            if (asyncSnapshot.hasError &&
                error is DioException &&
                error.type == DioExceptionType.connectionError) {
              print("Rediving");
              final int tryCooldown = 5;
              return StreamBuilder(
                stream: Stream.periodic(Duration(seconds: tryCooldown), (c) {
                  return GetIt.instance<Dio>().get("check-token");
                }),
                builder: (context, streamvalue) {
                  return Scaffold(
                    body: FutureBuilder(
                      future: streamvalue.data,
                      builder: (context, erCheck) {
                        if (erCheck.connectionState == ConnectionState.done) {
                          final error = erCheck.error;
                          if (error != null &&
                              (error is! DioException ||
                                  error.type !=
                                      DioExceptionType.connectionError)) {
                            Future.delayed(Duration(milliseconds: 10), () {
                              if (context.mounted) {
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).popAndPushNamed(RouteName.startup);
                              }
                            });
                          }
                        }
                        return Center(
                          child: Column(
                            spacing: 10,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Server is unreachable",
                                style: Theme.of(context).textTheme.displayMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              StreamBuilder(
                                stream: Stream.periodic(
                                  Duration(seconds: 1),
                                  (i) => i,
                                ),
                                builder: (context, value) {
                                  return Text(
                                    "Trying again in ${tryCooldown - ((value.data ?? 0) + 1)} seconds...",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Theme.of(context).dividerColor,
                                        ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            } else {
              Future.delayed(Duration(milliseconds: 10), () {
                if (context.mounted) {
                  Navigator.of(
                    context,
                    rootNavigator: true,
                  ).popAndPushNamed(RouteName.login);
                }
              });
            }
          }
        }
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 50,
              children: [
                Text(
                  "Logging in...",
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                SizedBox(
                  height: 5,
                  width: 400,
                  child: LinearProgressIndicator(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
