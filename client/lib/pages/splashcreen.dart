import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:sawors_media_client/pages/routing.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: GetIt.instance<Dio>().get("check-token"),
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.connectionState == ConnectionState.done) {
          String goto = RouteName.login;
          if (asyncSnapshot.hasData) {
            if (asyncSnapshot.data?.data == "valid token") {
              print("Token validated");
              goto = RouteName.home;
            }
          }

          Future.delayed(Duration(milliseconds: 10), () {
            if (context.mounted) {
              Navigator.of(context, rootNavigator: true).pushNamed(goto);
            }
          });
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
